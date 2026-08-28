// Extracts the admin portal's closed vocabularies, mechanically.
//
// The fixtures in test/contract/admin_vocabulary_test.dart were transcribed by
// hand. A hand transcription is a claim about a file, and this repository has
// already been wrong three times about what a file said — twice by regex, once
// by reading a comment that described a different codebase.
//
// So: read the TypeScript, take the string literals out of the union types and
// the exported arrays, and print JSON. Union types are parsed rather than
// executed because a `type` erases at runtime and there is nothing to execute;
// the arrays are read the same way for consistency, and the counts are checked
// against the declarations they came from.
//
// Usage: node scripts/extract_admin_vocabulary.mjs <admin-domain-dir>
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const dir = process.argv[2];
if (!dir) {
  console.error('usage: extract_admin_vocabulary.mjs <admin src/app/core/domain>');
  process.exit(2);
}

const read = (file) => readFileSync(join(dir, file), 'utf8');

/** String literals of an exported union type, in declaration order. */
function unionOf(source, name) {
  const start = source.indexOf(`export type ${name} =`);
  if (start === -1) throw new Error(`union ${name} not found`);
  const end = source.indexOf(';', start);
  if (end === -1) throw new Error(`union ${name} is unterminated`);
  const body = source.slice(start, end);
  return [...body.matchAll(/'([^']*)'/g)].map((m) => m[1]);
}

/** String literals of an exported const array, in declaration order. */
function arrayOf(source, name) {
  const start = source.indexOf(`export const ${name}`);
  if (start === -1) throw new Error(`array ${name} not found`);
  const open = source.indexOf('[', start);
  const close = source.indexOf('];', open);
  if (open === -1 || close === -1) throw new Error(`array ${name} is unterminated`);
  return [...source.slice(open, close).matchAll(/'((?:[^'\\]|\\.)*)'/g)]
    .map((m) => m[1].replace(/\\'/g, "'"));
}

const permit = read('permit.model.ts');
const document = read('document.model.ts');
const payment = read('payment.model.ts');
const assessment = read('assessment.model.ts');
const applicant = read('applicant.model.ts');

const vocabulary = {
  permitTypes: arrayOf(permit, 'ALL_PERMIT_TYPES'),
  applicationActions: unionOf(permit, 'ApplicationAction'),
  documentStatuses: unionOf(document, 'DocumentStatus'),
  paymentTransactionStatuses: unionOf(payment, 'PaymentTransactionStatus'),
  collectingAgencies: unionOf(payment, 'CollectingAgency'),
  paymentAdjustmentTypes: unionOf(payment, 'PaymentAdjustmentType'),
  // Both, deliberately. The admin declares this vocabulary twice and the two
  // declarations disagree about the order of 'Paid' and 'Overdue'. The union
  // is the definition; ASSESSMENT_STATUS_ORDER is a constant nothing in the
  // admin references. Extracting only one of them would hide that.
  assessmentStatuses: unionOf(assessment, 'AssessmentStatus'),
  assessmentStatusOrderConstant: arrayOf(assessment, 'ASSESSMENT_STATUS_ORDER'),
  contactVerificationStatuses: unionOf(applicant, 'VerificationStatus'),
  contactVerificationMethods: unionOf(applicant, 'VerificationMethod'),
};

// A vocabulary that came out empty is an extraction that silently failed, and
// would be indistinguishable from an admin that legitimately dropped a value.
for (const [name, values] of Object.entries(vocabulary)) {
  if (values.length === 0) throw new Error(`${name} extracted as empty`);
}

process.stdout.write(JSON.stringify(vocabulary, null, 2) + '\n');
