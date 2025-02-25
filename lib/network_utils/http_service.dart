import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> getLatestPackageVersionFromApi(String packageName) async {
  final url = Uri.parse('https://pub.dev/api/packages/$packageName');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['latest']['version']; // Extracts the latest version
    } else {
      return 'Package not found';
    }
  } catch (e) {
    return 'Error fetching version';
  }
}
