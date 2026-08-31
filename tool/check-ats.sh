#!/bin/bash
# Does a host satisfy App Transport Security?
#
# The app declares NO ATS exceptions, so iOS refuses a connection that fails
# any of the requirements below — at RUNTIME, in a citizen's hands, not at
# build time and not at review. This is the pre-flight for a base URL.
#
#   ./tool/check-ats.sh api.castillasorsogon.gov.ph
#
# Apple's requirements (ATS, as of iOS 15+):
#   • TLS 1.2 or later
#   • a certificate that validates against the system trust store
#   • forward secrecy — an ECDHE or DHE key exchange
#   • one of Apple's accepted ciphers (AES-GCM or ChaCha20-Poly1305 families)
#
# Exit 0 when every check passes.

set -uo pipefail
host="${1:?usage: check-ats.sh <hostname>}"
port="${2:-443}"
fail=0

say() { printf '  %-22s %s\n' "$1" "$2"; }
bad() { say "$1" "$2"; fail=1; }

printf '\nApp Transport Security — %s:%s\n\n' "$host" "$port"

# Certificate validity is curl's verdict, not a parse of the chain: 0 means the
# system trust store accepted it, which is the same question iOS asks.
verify=$(curl -sI --max-time 15 "https://$host:$port" -o /dev/null \
  -w '%{ssl_verify_result}' 2>/dev/null)
if [ "$verify" = "0" ]; then say "certificate" "valid"
else bad "certificate" "REJECTED by the system trust store (code $verify)"; fi

hs=$(echo | openssl s_client -connect "$host:$port" -servername "$host" \
  -tls1_2 2>/dev/null)
proto=$(printf '%s' "$hs" | grep -m1 'Protocol *:' | awk '{print $3}')
cipher=$(printf '%s' "$hs" | grep -m1 'Cipher *:' | awk '{print $3}')

case "$proto" in
  TLSv1.3|TLSv1.2) say "protocol" "$proto" ;;
  "")              bad "protocol" "no TLS 1.2 handshake — ATS refuses this host" ;;
  *)               bad "protocol" "$proto is below the TLS 1.2 floor" ;;
esac

case "$cipher" in
  ECDHE*|DHE*) say "forward secrecy" "$cipher" ;;
  "")          bad "forward secrecy" "no cipher negotiated" ;;
  *)           bad "forward secrecy" "$cipher has none — ATS requires ECDHE or DHE" ;;
esac

case "$cipher" in
  *GCM*|*CHACHA20*) say "cipher family" "accepted by ATS" ;;
  "")               : ;;
  *)                bad "cipher family" "$cipher is not on Apple's list" ;;
esac

printf '\n'
if [ "$fail" -eq 0 ]; then
  printf 'PASSES — the app can talk to this host with no ATS exception.\n\n'
else
  printf 'FAILS — the app cannot reach this host. Fix the host; do NOT add an\n'
  printf 'ATS exception, which weakens every other connection the app makes.\n\n'
fi
exit "$fail"
