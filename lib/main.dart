import 'package:amber_mobile_client/app.dart';
import 'package:amber_mobile_client/core/bloc/app_bloc_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Bloc.observer = AppBlocObserver();
  runApp(const AmberApp());
}
