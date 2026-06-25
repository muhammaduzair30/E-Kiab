import 'package:ekitab/core/constants/app_constants.dart';
import 'package:ekitab/core/theme/app_theme.dart';
import 'package:ekitab/core/theme/theme_provider.dart';
import 'package:ekitab/routes/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

/// Global flag indicating whether Firebase was successfully initialized.
/// Other parts of the app (e.g. Google Sign-In) should check this before
/// using Firebase APIs.
bool firebaseInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await dotenv.load(fileName: "scripts/.env");
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    firebaseInitialized = false;
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Open required Hive boxes
  await Future.wait([
    Hive.openBox<String>(AppConstants.hiveTokenBox),
    Hive.openBox(AppConstants.hiveSettingsBox),
    Hive.openBox(AppConstants.hiveOfflineBooksBox),
    Hive.openBox(AppConstants.hiveSyncQueueBox),
  ]);

  runApp(
    const ProviderScope(
      child: EKitabApp(),
    ),
  );
}

class EKitabApp extends ConsumerWidget {
  const EKitabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Enforce max text scale for accessibility without breaking layout
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
