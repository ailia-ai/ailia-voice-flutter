// download model

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

Future<Directory> getDocumentsDirectory(String subFolder) async {
  var doc = await getApplicationDocumentsDirectory();
  var basePath = p.join(doc.path, 'ailia MODELS flutter');
  final docDir = Directory(basePath);
  if (!docDir.existsSync()) {
    docDir.createSync();
  }
  basePath = p.join(basePath, subFolder);
  final subDir = Directory(basePath);
  if (!subDir.existsSync()) {
    subDir.createSync();
  }
  return subDir;
}

Future<String> getModelPath(String path) async {
  Directory tempDir = await getDocumentsDirectory("models");
  String tempPath = tempDir.path;
  var filePath = '$tempPath/$path';
  return filePath;
}

/// Downloads [url] to [filename] under the models directory.
///
/// The returned future completes with the downloaded file, or with an error
/// when the download fails, so that the caller can report it. The HTTP status,
/// the write and the rename are all awaited here; the partial file is removed
/// before the error is rethrown.
Future<File> downloadModel(
  String url,
  String filename, [
  void Function(File file)? downloadCallback,
]) async {
  var filePath = await getModelPath(filename);
  final File file = File(filePath);
  if (file.existsSync()) {
    downloadCallback?.call(file);
    return file;
  }
  // create the folder if not exists.
  final Directory dir = Directory(p.dirname(filePath));
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }

  var httpClient = http.Client();
  File tempFile = File('$filePath.tmp');

  try {
    var request = http.Request('GET', Uri.parse(url));
    http.StreamedResponse response = await httpClient.send(request);

    if (response.statusCode != 200) {
      throw Exception("$filename : ${response.statusCode}");
    }

    IOSink tempFileSink = tempFile.openWrite();
    try {
      await tempFileSink.addStream(response.stream);
    } finally {
      // Reports the write failure as well, so it must run on both paths.
      await tempFileSink.close();
    }

    await tempFile.rename(filePath);
  } catch (e) {
    if (tempFile.existsSync()) {
      await tempFile.delete();
    }
    rethrow;
  } finally {
    httpClient.close();
  }

  downloadCallback?.call(file);
  return file;
}
