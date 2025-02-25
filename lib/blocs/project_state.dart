part of 'project_bloc.dart';

abstract class ProjectState extends Equatable {
  @override
  List<Object> get props => [];
}

class ProjectInitial extends ProjectState {}

class ProjectSelected extends ProjectState {
  final String projectPath;

  ProjectSelected(this.projectPath);

  @override
  List<Object> get props => [projectPath];
}

class ProjectIntegrated extends ProjectState {}

class AppRunning extends ProjectState {
  AppRunning();

  @override
  List<Object> get props => [];
}

class KilledApp extends ProjectState {
  KilledApp();

  @override
  List<Object> get props => [];
}

class ProjectError extends ProjectState {
  final String message;

  ProjectError(this.message);

  @override
  List<Object> get props => [message];
}



class ConfigureFlutterPathState extends ProjectState {
  final String flutterPath;

  ConfigureFlutterPathState(this.flutterPath);

  @override
  List<Object> get props => [flutterPath];
}

class ConfigureFlutterPathError extends ProjectState {
  ConfigureFlutterPathError();

  @override
  List<Object> get props => [];
}
