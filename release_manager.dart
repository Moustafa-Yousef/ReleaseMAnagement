import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<String> analyzeCodeChanges(String oldCode, String newCode) async {
  var url = Uri.parse("http://localhost:5000/analyze");
  var response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"old_code": oldCode, "new_code": newCode}),
  );

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse['Predicted Change Type'];
  } else {
    print("Error: ${response.body}");
    throw Exception('Failed to analyze code changes');
  }
}

Future<String> getLastTag() async {
  final process = await Process.run('git', ['describe', '--tags', '--abbrev=0']);
  if (process.exitCode == 0) {
    return process.stdout.toString().trim();
  }
  return ''; // لو مفيش تاغات
}

String incrementTag(String lastTag, String changeType) {
  if (lastTag.isEmpty) return 'v1.0.0';
  final parts = lastTag.replaceFirst('v', '').split('.');
  int major = int.parse(parts[0]);
  int minor = int.parse(parts[1]);
  int patch = int.parse(parts[2]);

  switch (changeType) {
    case 'major':
      major += 1;
      minor = 0;
      patch = 0;
      break;
    case 'minor':
      minor += 1;
      patch = 0;
      break;
    case 'patch':
      patch += 1;
      break;
    default:
      throw Exception('Unknown change type: $changeType');
  }
  return 'v$major.$minor.$patch';
}

Future<void> createAndPushTag(String newTag, String repoUrl) async {
  await Process.run('git', ['tag', newTag]);
  await Process.run('git', ['push', 'origin', newTag]);
  print('New tag created and pushed: $newTag');
}

Future<String> getCodeFromVersion(String version, String filePath) async {
  final process = await Process.run('git', ['show', '$version:$filePath']);
  if (process.exitCode == 0) {
    return process.stdout.toString();
  }
  return '';
}

void main(List<String> arguments) async {
  try {
    if (arguments.isEmpty) {
      print("Please provide a repository URL as an argument");
      exit(1);
    }

    String repoUrl = arguments[0];
    String tempDir = './temp_repo';
    
    // Clone الـ repo
    print("Cloning repository: $repoUrl");
    await Process.run('git', ['clone', repoUrl, tempDir]);
    Directory.current = tempDir;

    // Configure Git (لأننا في بيئة Docker)
    await Process.run('git', ['config', 'user.email', 'ci@example.com']);
    await Process.run('git', ['config', 'user.name', 'CI Bot']);

    // جلب الإصدارات
    String oldVersion = await getLastTag();
    String newVersion = (await Process.run('git', ['rev-parse', '--short', 'HEAD'])).stdout.toString().trim();
    String oldCode = await getCodeFromVersion(oldVersion.isEmpty ? newVersion : oldVersion, 'release_manager.dart');
    String newCode = (await File('release_manager.dar').readAsString());

    // تحليل التغييرات
    final changeType = await analyzeCodeChanges(oldCode, newCode);
    print("Predicted Change Type: $changeType");

    // تحديث الـ tag
    final lastTag = await getLastTag();
    final newTag = incrementTag(lastTag, changeType);
    await createAndPushTag(newTag, repoUrl);

  } catch (e) {
    print('Error: $e');
    exit(1);
  } finally {
    // تنظيف
    await Process.run('rm', ['-rf', './temp_repo']);
  }
}
