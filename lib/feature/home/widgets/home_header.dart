part of '../view/home_view.dart';

final class _Header extends StatelessWidget {
  const _Header({required this.hasLidar, required this.deviceInfo});
  final bool hasLidar;
  final String deviceInfo;
  static const _subtitle1 = 'Create detailed 3D models of real-world';
  static const _subtitle2 = 'environments with precision scanning';
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/app_icons/appstore.png',
          height: 180,
        ),
        const SizedBox(height: 24),
        Text(
          '3D Environment Scanner',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                _subtitle1,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              Text(
                _subtitle2,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasLidar ? Icons.sensors : Icons.sensors_off,
                        color: hasLidar ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Device Status',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    deviceInfo,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: hasLidar ? Colors.green[700] : Colors.red[700],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
