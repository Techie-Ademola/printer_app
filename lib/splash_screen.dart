import 'dart:async';
import 'package:ygo_order/media.dart';
import 'package:flutter/material.dart';
import 'package:ygo_order/size_config.dart';
import 'package:ygo_order/heartbeat_animation.dart';
import 'package:ygo_order/webView/printer_setup.dart';

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({Key? key}) : super(key: key);

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      // After 3 seconds, navigate to the next page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PrinterSetup()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: HeartbeatAnimation(
            child: Center(
              child: Image.asset(
                "assets/ygo_order.png",
                height: height / 7.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
