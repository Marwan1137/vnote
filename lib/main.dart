import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vnote/core/di/di.dart';
import 'package:vnote/core/theme/app_theme.dart';
import 'package:vnote/data/models/note_model.dart';
import 'package:vnote/data/models/payment_model.dart';
import 'package:vnote/presentation/cubit/notes/notes_cubit.dart';
import 'package:vnote/presentation/screens/splash_screen/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(NoteModelAdapter());
  Hive.registerAdapter(PaymentModelAdapter());

  // Open Hive Boxes
  await Hive.openBox<NoteModel>('notes_box');
  await Hive.openBox<PaymentModel>('payments_box');

  // Configure Dependency Injection
  configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<NotesCubit>(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VNote',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
