// Stub file for web compatibility
// On web, dart:io doesn't exist, so we provide this stub
class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isLinux => false;
  static bool get isWindows => false;
  static bool get isMacOS => false;
}

class Process {
  static Future<ProcessResult> run(
      String executable, List<String> arguments) async {
    throw UnsupportedError('Process.run is not supported on web');
  }
}

class ProcessResult {
  final int pid;
  final int exitCode;
  final dynamic stdout;
  final dynamic stderr;

  ProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
}

class File {
  File(String path);

  Future<bool> exists() async => false;
  Future<void> writeAsBytes(List<int> bytes) async {}
  Future<String> readAsString() async => '';
  Future<void> writeAsString(String contents) async {}
  Future<bool> delete() async => false;
  String get path => '';
}

class Directory {
  Directory(String path);

  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
  List<FileSystemEntity> listSync() => [];
  String get path => '';
}

abstract class FileSystemEntity {
  String get path;
}
