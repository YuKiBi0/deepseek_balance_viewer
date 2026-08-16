import 'package:flutter/material.dart';

import 'api_key_screen.dart';
import 'home_screen.dart';
import 'key_edit_screen.dart';
import 'services/key_store.dart';

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
        '/keys': (_) => const ApiKeyScreen(),
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
    _checkKeys();
  }

  Future<void> _checkKeys() async {
    final keys = await KeyStore().loadKeys();

    if (!mounted) return;
    if (keys.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const KeyEditScreen()),
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
