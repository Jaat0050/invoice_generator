class SupabaseConfig {
  SupabaseConfig._();

  /// Replace with your Supabase Project URL from Project Settings -> API
  /// Example: 'https://xyzabcdefg.supabase.co'
  static const String supabaseUrl = 'https://nsoasonpbhmcqstbeaqa.supabase.co';

  /// Replace with your Supabase Anon Key from Project Settings -> API
  /// Example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  static const String supabaseAnonKey = 'sb_publishable_tR_jKu3pBdI474T-toZftg_2eJ7_YbH';

  /// Returns true if valid custom Supabase credentials have been configured.
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && !supabaseUrl.contains('placeholder') && supabaseAnonKey.isNotEmpty && !supabaseAnonKey.contains('placeholder');
  }
}
