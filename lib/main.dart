import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_key_screen.dart';
import 'home_screen.dart';

void main() {
  runApp(const DeepSeekBalanceApp());
}

class DeepSeekBalanceApp extends StatelessWidget {
  const DeepSeekBalanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeepSeek 余额查看器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/apikey': (_) => const ApiKeyScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('deepseek_api_key');

    if (!mounted) return;
    if (apiKey != null && apiKey.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/apikey');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
