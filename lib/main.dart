import 'package:calddy/core/constants/supabase_constants.dart';
import 'package:calddy/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화 (백엔드 연동)
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  // 네이버 지도 SDK 초기화
  await FlutterNaverMap().init(
    clientId: const String.fromEnvironment('NAVER_MAP_CLIENT_ID'),
  );

  // ProviderScope로 앱을 감싸 Riverpod 상태 관리 활성화
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Calddy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
