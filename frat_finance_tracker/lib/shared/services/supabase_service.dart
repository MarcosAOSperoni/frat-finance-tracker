import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient? _instance;

  static Future<void> initialize() async {
    // Determine which environment to use
    final env = dotenv.env['ENV'] ?? 'prod';
    print('🔧 Initializing Supabase in $env environment');

    // SECURITY: Validate environment variables based on ENV
    final String supabaseUrl;
    final String supabaseAnonKey;

    if (env == 'test') {
      supabaseUrl = dotenv.env['SUPABASE_URL_TEST'] ?? '';
      supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY_TEST'] ?? '';
      print('📊 Using TEST database');
    } else {
      supabaseUrl = dotenv.env['SUPABASE_URL_PROD'] ?? dotenv.env['SUPABASE_URL'] ?? '';
      supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY_PROD'] ?? dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      print('🚀 Using PRODUCTION database');
    }

    if (supabaseUrl.isEmpty) {
      throw Exception('SECURITY ERROR: SUPABASE_URL environment variable is required for $env environment');
    }

    if (supabaseAnonKey.isEmpty) {
      throw Exception('SECURITY ERROR: SUPABASE_ANON_KEY environment variable is required for $env environment');
    }

    // SECURITY: Validate HTTPS
    if (!supabaseUrl.startsWith('https://')) {
      throw Exception('SECURITY ERROR: Supabase URL must use HTTPS protocol');
    }

    // SECURITY: Validate URL format
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || uri.host.isEmpty) {
      throw Exception('SECURITY ERROR: Invalid Supabase URL format');
    }

    // Validate it's a supabase.co domain
    if (!uri.host.endsWith('.supabase.co')) {
      throw Exception('SECURITY ERROR: Supabase URL must be a valid *.supabase.co domain');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    _instance = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_instance == null) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  // Convenience getter for auth
  static GoTrueClient get auth => client.auth;
}
