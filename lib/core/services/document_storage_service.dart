import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies picked documents into the app's own local storage (never
/// anywhere outside it) and cleans them up on removal. Each saved file
/// gets a unique on-disk name so re-importing a same-named file never
/// overwrites an existing one.
class DocumentStorageService {
  static const _maxSizeBytes = 25 * 1024 * 1024; // 25 MB

  int get maxFileSizeBytes => _maxSizeBytes;

  /// The folder every stored document lives in, once something has asked.
  ///
  /// **An absolute path to a file in this folder is not stable.** On iOS the
  /// app's container is `/var/mobile/Containers/Data/Application/<UUID>/…` and
  /// that UUID changes when the app is updated or reinstalled — so a path
  /// saved today can be dead tomorrow while the FILE is perfectly intact under
  /// a different prefix.
  ///
  /// So nothing durable stores a path. It stores the file's NAME and resolves
  /// it against this root at read time; [storedNameOf] and [resolveStoredName]
  /// are that pair.
  ///
  /// Cached because the callers that need it are synchronous — a snapshot
  /// writer cannot await a platform channel. Null until [primeRoot] has run,
  /// and every caller treats null as "cannot resolve", which degrades to the
  /// behaviour that existed before drafts kept any attachment at all.
  static String? _root;

  static String? get root => _root;

  /// Reads the documents directory once, at startup, so the synchronous
  /// callers below have something to work with.
  static Future<void> primeRoot() async {
    if (_root != null) return;
    final docsDir = await getApplicationDocumentsDirectory();
    _root = p.join(docsDir.path, 'my_documents');
  }

  /// For tests, which have no platform channels.
  static void setRootForTesting(String? root) => _root = root;

  /// The durable half of a path: the file's name, if it is one of ours.
  ///
  /// Null for a path outside our storage — a picker's temporary file, or a
  /// path from a previous install we cannot vouch for.
  static String? storedNameOf(String? absolutePath) {
    final root = _root;
    if (root == null || absolutePath == null || absolutePath.isEmpty) {
      return null;
    }
    return p.isWithin(root, absolutePath) ? p.basename(absolutePath) : null;
  }

  /// The current absolute path of a stored file, if it is still there.
  ///
  /// Existence is checked rather than assumed: the applicant may have cleared
  /// the app's storage, and a draft that claims to hold a document it cannot
  /// open is the failure this whole design exists to avoid.
  static String? resolveStoredName(String? storedName) {
    final root = _root;
    if (root == null || storedName == null || storedName.isEmpty) return null;
    // A name, never a path. A stored `../` would otherwise reach outside the
    // app's own storage.
    if (p.basename(storedName) != storedName) return null;
    final candidate = p.join(root, storedName);
    return File(candidate).existsSync() ? candidate : null;
  }

  Future<Directory> _documentsDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'my_documents'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copies [source] into local document storage under a unique file
  /// name, preserving its original extension. Returns the saved [File].
  Future<File> saveCopy(File source, {required String originalFileName}) async {
    final dir = await _documentsDir();
    final extension = p.extension(originalFileName);
    final uniqueName = 'doc_${DateTime.now().microsecondsSinceEpoch}$extension';
    final destination = p.join(dir.path, uniqueName);
    return source.copy(destination);
  }

  Future<int> fileSize(File file) => file.length();

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> fileExists(String path) => File(path).exists();
}
