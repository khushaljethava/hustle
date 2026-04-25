import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';

class BackupService {
  static const String _prefsEntry = 'prefs.json';
  static const String _dbEntry = 'hustle.db';

  final SharedPreferences _prefs;

  BackupService(this._prefs);

  /// Exports DB + SharedPreferences as a single `.hustle-backup` zip,
  /// dropped in the temp dir and opened via share sheet.
  /// Returns the path of the generated file.
  Future<String> exportBackup() async {
    final dbPath = p.join(await getDatabasesPath(), AppConstants.dbName);
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception('Database not found.');
    }

    final prefsMap = <String, Object?>{};
    for (final key in _prefs.getKeys()) {
      prefsMap[key] = _prefs.get(key);
    }

    final archive = Archive()
      ..addFile(ArchiveFile(
        _dbEntry,
        await dbFile.length(),
        await dbFile.readAsBytes(),
      ))
      ..addFile(ArchiveFile.string(_prefsEntry, jsonEncode(prefsMap)));

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) throw Exception('Failed to create backup zip.');

    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final outDir = await getTemporaryDirectory();
    final outPath = p.join(outDir.path, 'hustle-$stamp.hustle-backup');
    final outFile = File(outPath);
    await outFile.writeAsBytes(encoded, flush: true);

    await Share.shareXFiles(
      [XFile(outPath, mimeType: 'application/zip')],
      subject: 'Hustle backup',
      text: 'Keep this file safe — it contains all your Hustle data.',
    );
    return outPath;
  }

  /// Restores from a `.hustle-backup` / `.zip` file. Returns `true` on success.
  /// On success the caller should close the DB and restart the app.
  Future<bool> restoreBackup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? dbArchive;
    ArchiveFile? prefsArchive;
    for (final entry in archive) {
      if (entry.name == _dbEntry) dbArchive = entry;
      if (entry.name == _prefsEntry) prefsArchive = entry;
    }
    if (dbArchive == null) return false;

    // Overwrite DB
    final dbPath = p.join(await getDatabasesPath(), AppConstants.dbName);
    final dbFile = File(dbPath);
    await dbFile.writeAsBytes(dbArchive.content as List<int>, flush: true);

    // Restore prefs (if present)
    if (prefsArchive != null) {
      final decoded = jsonDecode(utf8.decode(prefsArchive.content as List<int>))
          as Map<String, dynamic>;
      await _prefs.clear();
      for (final entry in decoded.entries) {
        final v = entry.value;
        if (v is bool) {
          await _prefs.setBool(entry.key, v);
        } else if (v is int) {
          await _prefs.setInt(entry.key, v);
        } else if (v is double) {
          await _prefs.setDouble(entry.key, v);
        } else if (v is String) {
          await _prefs.setString(entry.key, v);
        } else if (v is List) {
          await _prefs.setStringList(
            entry.key,
            v.map((e) => e.toString()).toList(),
          );
        }
      }
    }
    return true;
  }
}
