import 'package:flutter/material.dart';

class ScannerInitializeCard extends StatelessWidget {
  const ScannerInitializeCard({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Start to scan '),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
