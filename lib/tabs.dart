import 'package:flutter/material.dart';

class WifiTabBar extends StatelessWidget {
  const WifiTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
            appBar: AppBar(
          bottom: const TabBar(tabs: [
            Tab(
              icon: Icon(Icons.wifi),
            ),
            Tab(
              icon: Icon(Icons.bluetooth),
            ),
            Tab(icon: Icon(Icons.radar)),
          ]),
        )),
      ),
    );
  }
}
