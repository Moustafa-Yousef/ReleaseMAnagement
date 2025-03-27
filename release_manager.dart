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
  return ''; // لو مفيش تاغات، نرجع سلسلة فاضية
}

String incrementTag(String lastTag, String changeType) {
  // لو مفيش تاغات قبل كده، نبدأ من v1.0.0
  if (lastTag.isEmpty) return 'v1.0.0';

  // افتراض إن التاغ بصيغة vX.Y.Z
  final parts = lastTag.replaceFirst('v', '').split('.');
  int major = int.parse(parts[0]);
  int minor = int.parse(parts[1]);
  int patch = int.parse(parts[2]);

  // زيادة الإصدار بناءً على نوع التغيير
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

Future<void> createAndPushTag(String newTag) async {
  // إنشاء الـ tag
  final tagResult = await Process.run('git', ['tag', newTag]);
  if (tagResult.exitCode != 0) {
    print('Error creating tag: ${tagResult.stderr}');
    return;
  }

  // رفع الـ tag لـ GitHub
  final pushResult = await Process.run('git', ['push', 'origin', newTag]);
  if (pushResult.exitCode == 0) {
    print('New tag created and pushed: $newTag');
  } else {
    print('Error pushing tag: ${pushResult.stderr}');
  }
}

Future<String> getCodeFromVersion(String version) async {
  final process = await Process.run('git', ['show', version]);
  if (process.exitCode == 0) {
    return process.stdout.toString();
  } else {
    print('Error getting code for $version: ${process.stderr}');
    return '';
  }
}


void main(List<String> arguments) async {
  try {
    // لو مفيش أرجومنتات، نستخدم الإصدارات من Git
    String oldCode, newCode;
    String oldVersion, newVersion;

    if (arguments.length == 2) {
      oldCode = arguments[0];
      newCode = arguments[1];
    } else {
      // جلب الإصدارات من Git
      oldVersion = await getLastTag();
      newVersion = (await Process.run('git', ['rev-parse', '--short', 'HEAD'])).stdout.toString().trim();
      oldCode = await getCodeFromVersion(oldVersion.isEmpty ? 'HEAD^' : oldVersion);
      newCode = await getCodeFromVersion(newVersion);
    }

    // تحليل التغييرات
    final changeType = await analyzeCodeChanges(oldCode, newCode);
    print("Predicted Change Type: $changeType");

    // جلب آخر تاغ وتحديثه
    final lastTag = await getLastTag();
    final newTag = incrementTag(lastTag, changeType);

    // إنشاء ورفع الـ tag الجديد
    await createAndPushTag(newTag);
  } catch (e) {
    print('Error in release manager: $e');
    exit(1);
  }
}
