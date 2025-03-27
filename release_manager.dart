import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final oldVersion = args[0];
  final newVersion = args[1];

  final oldCode = await Process.run('git', ['show', '$oldVersion:main.dart']);
  final newCode = await Process.run('git', ['show', '$newVersion:main.dart']);

  final uri = Uri.parse('http://localhost:5000/analyze');
  final request = await HttpClient().postUrl(uri);
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode({
    'old_code': oldCode.stdout.toString(),
    'new_code': newCode.stdout.toString()
  }));

  final response = await request.close();
  final result = jsonDecode(await response.transform(utf8.decoder).join());
  print('Change Type: ${result['Predicted Change Type']}');
}
