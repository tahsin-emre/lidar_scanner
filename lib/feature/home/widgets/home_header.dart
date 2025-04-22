part of '../view/home_view.dart';

final class _Header extends StatelessWidget {
  const _Header({required this.hasLidar, required this.deviceInfo});
  final bool hasLidar;
  final String deviceInfo;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.view_in_ar, size: 100, color: Colors.blue),
        const SizedBox(height: 24),
        Text(
          '3D Object Scanner',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Scan real-world objects and create 3D models',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Device Capabilities',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasLidar ? Icons.check_circle : Icons.error,
                      color: hasLidar ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: Text(deviceInfo)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
