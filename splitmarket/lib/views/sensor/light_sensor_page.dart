import 'package:flutter/material.dart';
import 'package:light/light.dart';
import 'package:provider/provider.dart';

import '../../core/themes/theme_notifier.dart';

class LightSensorPage extends StatefulWidget {
  const LightSensorPage({super.key});

  @override
  State<LightSensorPage> createState() => _LightSensorPageState();
}

class _LightSensorPageState extends State<LightSensorPage> {
  final Light _light = Light();

  String ambiente = "Lendo sensor...";
  String luminosidade = "--";

  @override
  void initState() {
    super.initState();

    _light.lightSensorStream.listen((lux) {
      setState(() {
        luminosidade = lux.toString();

        if (lux < 20) {
          ambiente = "🌙 Ambiente escuro";

          context.read<ThemeNotifier>().setDarkTheme();
        } else {
          ambiente = "☀️ Ambiente iluminado";

          context.read<ThemeNotifier>().setLightTheme();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sensor de Luminosidade"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              ambiente,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Luminosidade: $luminosidade lux",
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}