import 'dart:io';

import 'package:automated_project_integration/blocs/project_bloc.dart';
import 'package:automated_project_integration/screens/project_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PackageIntegratorApp());
}

Process? flutterProcess;

class PackageIntegratorApp extends StatefulWidget {
  const PackageIntegratorApp({super.key});

  @override
  State<PackageIntegratorApp> createState() => _PackageIntegratorAppState();
}

class _PackageIntegratorAppState extends State<PackageIntegratorApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Package Integrator',
      home: BlocProvider(
        create: (context) => ProjectBloc(),
        child: ProjectSelectScreen(),
      ),
    );
  }
}

String? extractFlutterVersion(String flutterPath) {
  RegExp regex = RegExp(r'flutter_(windows|macos|linux)_(\d+\.\d+\.\d+)');
  Match? match = regex.firstMatch(flutterPath);
  return match != null ? 'flutter_${match.group(1)}_${match.group(2)}' : null;
}
