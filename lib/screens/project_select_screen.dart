import 'dart:io';
import 'package:automated_project_integration/blocs/project_bloc.dart';
import 'package:automated_project_integration/network_utils/http_service.dart';
import 'package:automated_project_integration/utils/google_api_key_management.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;

class ProjectSelectScreen extends StatefulWidget {
  const ProjectSelectScreen({super.key});

  @override
  State<ProjectSelectScreen> createState() => _ProjectSelectScreenState();
}

class _ProjectSelectScreenState extends State<ProjectSelectScreen> {
  bool projectSelected = false;
  String flutterPath = '';
  String? apiKey;
  String projectPath = '';
  String? devicesId;
  String logs = '';


  @override
  void initState() {
    getPackageVersion();
    context.read<ProjectBloc>().add(ConfigurePath());
    super.initState();
  }

  getPackageVersion() async {
    String packageName = "google_maps_flutter"; // Example package
    String latestVersion = await getLatestPackageVersionFromApi(packageName);
    print('Latest version of $packageName: $latestVersion');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test demo app'),
        actions: [
          // BlocBuilder<ProjectBloc, ProjectState>(
          //   builder: (context, state) {
          //     if (state is ConfigureFlutterPathState) {
          //       flutterPath = state.flutterPath;
          //       context.read<ProjectBloc>().add(FindDeviceEvent(flutterPath));
          //     }
          //     if (state is FindDevices) {
          //       devices = state.devices;
          //     }
          //     return Row(
          //       spacing: 20,
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         //
          //       ],
          //     );
          //   },
          // ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Expanded(
              child: Column(
                spacing: 20,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<ProjectBloc, ProjectState>(
                    builder: (context, state) {
                      if (state is ProjectSelected) {
                        projectSelected = true;
                        projectPath = state.projectPath;
                      }
                      return Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: 50,
                            padding: EdgeInsets.only(left: 20),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              border: Border.all(width: 1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              projectPath.isEmpty
                                  ? 'Select Flutter Project'
                                  : projectPath,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          IconButton(
                              onPressed: () async {
                                try {
                                  String? selectedDirectory = await FilePicker
                                      .platform
                                      .getDirectoryPath(
                                          dialogTitle:
                                              'Select Flutter Project');
                                  if (selectedDirectory != null) {
                                    context.read<ProjectBloc>().add(
                                        SelectProjectEvent(selectedDirectory));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('No directory selected.')),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                              icon: Icon(Icons.file_open)),

                        ],
                      );
                    },
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:   BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, state) {
          if (!projectSelected) {
            return Container();
          }
          return BlocListener<ProjectBloc, ProjectState>(
            listener: (context, state) {
              if (state is ProjectIntegrated) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: Colors.green,
                    content: Text(
                        'Google maps integrated successfully')));
              }
            },
            child: ElevatedButton(
              onPressed: () async {
                final mapDemo = path.join(projectPath, 'android',
                    'app', 'src', 'main', 'AndroidManifest.xml');
                File mapDemoFile = File(mapDemo);
                bool isExist = await mapDemoFile.exists();
                if (isExist) {
                  if (mapDemoFile
                      .readAsStringSync()
                      .contains('com.google.android.geo.API_KEY')) {
                    context.read<ProjectBloc>().add(
                        IntegrateGoogleMapsEvent(
                            projectPath, flutterPath));
                    return;
                  } else {
                    await _openAPIKeyDialog();
                    context.read<ProjectBloc>().add(
                        IntegrateGoogleMapsEvent(
                            projectPath, flutterPath));
                  }
                }
              },
              style: ButtonStyle(
                backgroundColor:
                WidgetStatePropertyAll(Colors.blue),
                shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
              child: Text(
                'Integrate Package',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openAPIKeyDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return GoogleAPIKeyDialog(
          projectPath: projectPath,
          onAPIKeyEntered: (key) {
            setState(() {
              apiKey = key;
            });
            updateAndroidManifest(projectPath, key);
            updateiOSInfoPlist(projectPath, key);
          },
        );
      },
    );
  }
String projectName ='';
  void updateAndroidManifest(String projectPath, String apiKey) {
    projectName = projectPath.split("/").last;
    final manifestPath =
        '$projectPath/android/app/src/main/AndroidManifest.xml';
    final manifestFile = File(manifestPath);
    if (!manifestFile.existsSync()) {
      print("AndroidManifest.xml not found!");
      return;
    }
    String content = manifestFile.readAsStringSync();

    if (!content.contains(apiKey)) {
      content = content.replaceFirst(
        '</application>',
        '  <meta-data android:name="com.google.android.geo.API_KEY" android:value="$apiKey"/>\n</application>',
      );
    }
    if (!content.contains('ACCESS_FINE_LOCATION')) {
      content = content.replaceFirst(
        '<application',
        '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>\n'
            '    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>\n<application',
      );
    }
    manifestFile.writeAsStringSync(content);
  }

  // void updateiOSInfoPlist(String projectPath, String apiKey) {
  //   final plistPath = '$projectPath/ios/Runner/Info.plist';
  //
  //   // Ensure the file exists
  //   final plistFile = File(plistPath);
  //   if (!plistFile.existsSync()) {
  //     print("Error: Info.plist not found at $plistPath");
  //     return;
  //   }
  //
  //   // Check if the API key is already present
  //   String content = plistFile.readAsStringSync();
  //   if (content.contains(apiKey)) {
  //     print("GMSApiKey is already present. Skipping update.");
  //     return;
  //   }
  //
  //   try {
  //     // Use PlistBuddy to add keys safely
  //     Process.runSync('/usr/libexec/PlistBuddy',
  //         ['-c', 'Add :GMSApiKey string $apiKey', plistPath]);
  //     Process.runSync('/usr/libexec/PlistBuddy', [
  //       '-c',
  //       'Add :NSLocationAlwaysAndWhenInUseUsageDescription string "Allow Demo to access your location to track submissions."',
  //       plistPath
  //     ]);
  //     Process.runSync('/usr/libexec/PlistBuddy', [
  //       '-c',
  //       'Add :NSLocationAlwaysUsageDescription string "Allow Demo to access your location to track submissions."',
  //       plistPath
  //     ]);
  //     Process.runSync('/usr/libexec/PlistBuddy', [
  //       '-c',
  //       'Add :NSLocationWhenInUseUsageDescription string "Allow Demo to access your location to track submissions."',
  //       plistPath
  //     ]);
  //
  //     print("✅ Info.plist updated successfully!");
  //   } catch (e) {
  //     print("❌ Error updating Info.plist: $e");
  //   }
  //
  // }


  void updateiOSInfoPlist(String projectPath, String apiKey) {
    final plistPath = '$projectPath/ios/Runner/Info.plist';
    final plistFile = File(plistPath);
    String content = plistFile.readAsStringSync();

    if (!content.contains(apiKey)) {
      content = content.replaceFirst(
        '</dict>',
        '  <key>GMSApiKey</key>'
            '\n<string>$apiKey</string>'
            '\n<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>'
            '\n<string>Allow $projectName to access your location to get GPS Location coordinates to track submissions location.</string>'
            '\n<key>NSLocationAlwaysUsageDescription</key>'
            '\n<string>Allow $projectName to access your location to get GPS Location coordinates to track submissions location.</string>'
            '\n<key>NSLocationWhenInUseUsageDescription</key>'
            '\n<string>Allow $projectName to access your location to get GPS Location coordinates to track submissions location.</string>\n</dict>',
      );
      plistFile.writeAsStringSync(content);
    }
  }
}
