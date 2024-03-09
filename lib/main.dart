import 'package:flutter/material.dart';

import 'package:flutter_animated_tooltip/animated_tooltip.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animated Tooltip Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Animated Tooltip Demo'),
        ),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedTooltip(
                      message: 'This is an inverted tooltip.',
                      child: Icon(Icons.info),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: AnimatedTooltip(
                        message: 'This is a centered tooltip.',
                        child: Icon(Icons.info),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedTooltip(
                      message: 'This is a right-aligned tooltip.',
                      child: Icon(Icons.info),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
