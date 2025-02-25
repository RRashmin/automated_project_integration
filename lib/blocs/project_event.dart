part of 'project_bloc.dart';

abstract class ProjectEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class SelectProjectEvent extends ProjectEvent {
  final String directory;

  SelectProjectEvent(this.directory);

  @override
  List<Object> get props => [directory];
}

class IntegrateGoogleMapsEvent extends ProjectEvent {
  final String projectPath;
  final String flutterPath;

  IntegrateGoogleMapsEvent(this.projectPath, this.flutterPath);

  @override
  List<Object> get props => [projectPath];
}

class ConfigurePath extends ProjectEvent {
  final String? flutterPath;
  ConfigurePath({this.flutterPath});

  @override
  List<Object> get props => [flutterPath!];
}
