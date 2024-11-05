import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ygo_order/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget defines the root of application.
  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fygo Order App',
      // theme: theme(),
      home: AppSplashScreen(),
    );
  }
}
