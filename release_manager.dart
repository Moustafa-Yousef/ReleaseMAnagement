import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> analyzeCodeChanges(String oldCode, String newCode) async {
  var url = Uri.parse("http://localhost:5000/analyze");

  var response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"old_code": oldCode, "new_code": newCode}),
  );

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);
    print("Predicted Change Type: ${jsonResponse['Predicted Change Type']}");
  } else {
    print("Error: ${response.body}");
  }
}

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print("Usage: dart release_manager.dart <old_code> <new_code>");
    return;
  }

  String oldCode = arguments[0];
  String newCode = arguments[1];

  await analyzeCodeChanges(oldCode, newCode);
}

