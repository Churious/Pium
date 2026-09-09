/// Supabase 클라이언트 설정.
///
/// PIUM 프로젝트 anon key는 클라이언트용 공개 키입니다.
/// `--dart-define`으로 다른 환경 값을 덮어쓸 수 있습니다.
/// Kakao 등 Secret은 Edge Function에서만 사용합니다.
class SupabaseConfig {
  SupabaseConfig._();

  static const _defaultUrl = 'https://glhgqolncenyqtsyzuhz.supabase.co';
  static const _defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdsaGdxb2xuY2VueXF0c3l6dWh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg5NDA5MTcsImV4cCI6MjEwNDUxNjkxN30.9MJZwY2JNGJyCO4JCNbq8tO2-YC9dpIkn6RcQYx3OSk';

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultUrl,
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultAnonKey,
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
