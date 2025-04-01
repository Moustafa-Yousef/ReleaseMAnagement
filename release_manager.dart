import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<String> analyzeCommitMessage(String commitMessage) async {
  var url = Uri.parse("http://localhost:5000/analyze"); // أو عنوان الـ API الذي تحلل منه
  var response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"old_code": commitMessage, "new_code": commitMessage}),
  );

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);
    return jsonResponse['Predicted Change Type'];
  } else {
    print("Error: ${response.body}");
    throw Exception('Failed to analyze commit message');
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

Future<void> main(List<String> arguments) async {
  try {
    if (arguments.isEmpty) {
      print("Please provide a repository URL as an argument");
      exit(1);
    }

    String repoUrl = arguments[0];
    String tempDir = './temp_repo';

    // Clone الـ repo فقط لو حاجة ضرورية لكن في هذه الحالة نستخدم الريبو الموجود في الكونتينر
    // print("Cloning repository: $repoUrl");
    // await Process.run('git', ['clone', repoUrl, tempDir]);
    // Directory.current = tempDir;

    // عملية الحصول على آخر commit وقراءة الرسالة الخاصة به
    var process = await Process.run('git', ['log', '--format=%B', '-n', '1']);
    String commitMessage = process.stdout.toString().trim();

    // تحليل الـ commit message
    final changeType = await analyzeCommitMessage(commitMessage);
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
