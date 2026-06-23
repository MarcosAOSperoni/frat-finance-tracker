import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frat_finance_tracker/shared/services/supabase_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Starting app initialization...');

  // Load environment variables
  print('📄 Loading environment variables...');
  await dotenv.load(fileName: ".env");
  print('✅ Environment variables loaded');

  // Skip Firebase for now - just testing
  print('⏭️ Skipping Firebase initialization for testing');

  // Initialize Supabase
  print('🗄️ Initializing Supabase...');
  await SupabaseService.initialize();
  print('✅ Supabase initialized');

  print('🎉 Running app...');
  runApp(
    const ProviderScope(
      child: FratFinanceApp(),
    ),
  );
}
