import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:vnote/core/di/di.dart';
import 'package:vnote/core/theme/app_theme.dart';
import 'package:vnote/core/theme/theme_provider.dart';
import 'package:vnote/data/models/event_model.dart';
import 'package:vnote/data/models/note_model.dart';
import 'package:vnote/data/models/payment_model.dart';
import 'package:vnote/firebase_options.dart';
import 'package:vnote/presentation/auth/cubit/auth_cubit.dart';
import 'package:vnote/presentation/cubit/notes/notes_cubit.dart';
import 'package:vnote/presentation/screens/splash_screen/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // Handle errors from async operations (if available)
  try {
    PlatformDispatcher.instance.onError = (error, stack) {
      return true;
    };
  } catch (e) {
    // Error handler setup failed
  }

  try {
    // Initialize Firebase (only if not already initialized)
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Continue with app initialization even if Firebase fails
    // This allows the app to run in development without Firebase
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(NoteModelAdapter());
  Hive.registerAdapter(PaymentModelAdapter());
  Hive.registerAdapter(EventModelAdapter());

  // Open Hive Boxes
  await Hive.openBox<NoteModel>('notes_box');
  await Hive.openBox<PaymentModel>('payments_box');
  await Hive.openBox<EventModel>('events_box');

  // Configure Dependency Injection
  configureDependencies();

  // Initialize ThemeProvider
  final themeProvider = getIt<ThemeProvider>();
  await themeProvider.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = getIt<ThemeProvider>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<NotesCubit>()),
        BlocProvider(create: (context) => getIt<AuthCubit>()),
      ],
      child: ChangeNotifierProvider.value(
        value: themeProvider,
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'VNote',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
