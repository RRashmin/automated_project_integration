import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

part 'project_event.dart';

part 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  ProjectBloc() : super(ProjectInitial()) {
    on<SelectProjectEvent>(_onSelectProject);
    on<IntegrateGoogleMapsEvent>(_onIntegrateGoogleMaps);
    on<ConfigurePath>(_configurePath);
  }

  Future<void> _onSelectProject(SelectProjectEvent event,
      Emitter<ProjectState> emit) async {
    if (File(join(event.directory, 'pubspec.yaml')).existsSync()) {
      emit(ProjectSelected(event.directory));
    } else {
      emit(ProjectError('Invalid Flutter project directory.'));
    }
  }

  Future<void> _configurePath(ConfigurePath event,
      Emitter<ProjectState> emit) async {
    String? flutterPath;

    if (event.flutterPath == null) {
      flutterPath = Platform.environment['FLUTTER_HOME'] ??
          Platform.environment['Path']
              ?.split(';')
              .firstWhere((path) => path.contains('flutter'),
              orElse: () => 'Flutter not found');
    } else {
      flutterPath = event.flutterPath;
    }
    if (flutterPath == null || flutterPath == 'Flutter not found' ||
        flutterPath.isEmpty) {
      emit(ConfigureFlutterPathError());
    }
    if (flutterPath != null) {
      emit(ConfigureFlutterPathState(flutterPath!));
    }
  }

  Future<void> _onIntegrateGoogleMaps(IntegrateGoogleMapsEvent event,
      Emitter<ProjectState> emit) async {
    final projectPath = event.projectPath;
    try {
      await _addDependency(projectPath);
      await _runFlutterPubGet(projectPath, event.flutterPath);
      await _addDemoWidget(projectPath);
      emit(ProjectIntegrated());
    } catch (e) {
      emit(ProjectError('Integration failed: $e'));
    }
  }


  Future<void> _addDependency(String projectPath) async {
    File pubspecFile = File('$projectPath/pubspec.yaml');
    if (!pubspecFile.existsSync()) return;

    String yamlContent = pubspecFile.readAsStringSync();
    var yaml = loadYaml(yamlContent);

    Map<String, dynamic> yamlMap = Map<String, dynamic>.from(yaml);

    yamlMap['dependencies'] =
    Map<String, dynamic>.from(yamlMap['dependencies'] ?? {});

    yamlMap['dependencies']['google_maps_flutter'] = '^2.10.0';
    yamlMap['dependencies']['geolocator'] = '^13.0.2';
    yamlMap['dependencies']['permission_handler'] = '^11.3.1';

    pubspecFile.writeAsStringSync(YamlWriter().write(yamlMap));
  }

  Future<void> _runFlutterPubGet(String projectPath, String flutterPath) async {
    await Process.run(
      '$flutterPath\\flutter.bat',
      ['pub', 'get'],
      workingDirectory: projectPath,
      runInShell: true,
    );
  }

  Future<void> _addDemoWidget(String projectPath) async {
    final main = join(projectPath, 'lib', 'main.dart');
    File mainDart = File(main);
    final mapDemo = join(projectPath, 'lib', 'map_demo.dart');
    File mapDemoFile = File(mapDemo);

    if (!await mapDemoFile.exists()) {
      const mapDemoContent = '''
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Marker? _currentMarker;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    // Request location permission
    PermissionStatus status = await Permission.location.request();
    if (status.isDenied) {
      print("Location permission denied");
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _currentMarker = Marker(
        markerId: MarkerId("current_location"),
        position: _currentLocation!,
        infoWindow: InfoWindow(title: "You are here"),
      );
    });

    // Move camera to current location
    _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google Maps")),
      body: _currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation!,
                zoom: 14.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              markers: _currentMarker != null ? {_currentMarker!} : {},
              myLocationEnabled: true, // Show blue dot for user location
              myLocationButtonEnabled: true,
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.my_location),
        onPressed: _getCurrentLocation,
      ),
    );
  }
}
''';

      await mapDemoFile.writeAsString(mapDemoContent);
      print('✅ map_demo.dart created successfully.');
    } else {
      print('ℹ️ map_demo.dart already exists.');
    }

    // Step 2: Modify main.dart to use MapDemo
    if (await mainDart.exists()) {
      String content = '''import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:${projectPath
          .split('\\')
          .last
          .split('/')
          .last}/map_demo.dart';

void main() {
 WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
      home: MapScreen(),
  ));
}''';

      await mainDart.writeAsString(content);
    } else {
      print('❌ main.dart does not exist.');
    }
  }
}
