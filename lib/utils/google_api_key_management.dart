import 'package:flutter/material.dart';

class GoogleAPIKeyDialog extends StatelessWidget {
  final String projectPath;
  final Function(String) onAPIKeyEntered;

  const GoogleAPIKeyDialog({required this.projectPath, required this.onAPIKeyEntered});

  @override
  Widget build(BuildContext context) {
    TextEditingController apiKeyController = TextEditingController();

    return AlertDialog(
      title: Text("API Key"),
      content: TextField(
        controller: apiKeyController,
        decoration: InputDecoration(labelText: "Enter Google Maps API Key"),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            onAPIKeyEntered(apiKeyController.text);
            Navigator.pop(context);
          },
          child: Text("Ok"),
        ),
      ],
    );
  }
}
