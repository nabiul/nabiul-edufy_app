import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'config/api_config.dart';
import 'services/api_client.dart';
import 'services/session_store.dart';
import 'theme/app_theme.dart';

class EdufyApp extends StatefulWidget {
  const EdufyApp({super.key});

  @override
  State<EdufyApp> createState() => _EdufyAppState();
}

class _EdufyAppState extends State<EdufyApp> {
  final SessionStore _sessionStore = SessionStore();
  late final ApiClient _apiClient;
  String? _token;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(onUnauthorized: _onLoggedOut);
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final results = await Future.wait([
      _sessionStore.readToken(),
      _sessionStore.readApiBaseUrl(),
    ]);
    var token = results[0];
    ApiConfig.setBaseUrl(results[1]);
    if (token != null) {
      try {
        await _apiClient.me(token);
      } on ApiException catch (error) {
        if (error.statusCode == 401) {
          await _sessionStore.clear();
          token = null;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _token = token;
      _loading = false;
    });
  }

  Future<void> _onLoggedIn(String token) async {
    await _sessionStore.saveToken(token);
    if (!mounted) return;
    setState(() => _token = token);
  }

  Future<void> _onLoggedOut() async {
    await _sessionStore.clear();
    if (!mounted) return;
    setState(() => _token = null);
  }

  Future<void> _onApiUrlChanged(String url) async {
    ApiConfig.setBaseUrl(url);
    await _sessionStore.saveApiBaseUrl(ApiConfig.baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EDUSOL',
      theme: AppTheme.light,
      home: _loading
          ? const _SplashScreen()
          : _token == null
          ? LoginScreen(
              apiClient: _apiClient,
              onLoggedIn: _onLoggedIn,
              onApiUrlChanged: _onApiUrlChanged,
            )
          : HomeScreen(
              apiClient: _apiClient,
              token: _token!,
              onLoggedOut: _onLoggedOut,
            ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
