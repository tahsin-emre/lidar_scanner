import 'package:flutter/material.dart';
import 'package:lidar_scanner/feature/model_viewer/view/model_viewer_view.dart';
import 'package:lidar_scanner/feature/saved_scans/mixin/saved_scans_mixin.dart';
import 'package:lidar_scanner/product/utils/extensions/widget_ext.dart';
import 'package:share_plus/share_plus.dart';

class SavedScansView extends StatefulWidget {
  const SavedScansView({super.key});

  @override
  State<SavedScansView> createState() => _SavedScansViewState();
}

class _SavedScansViewState extends State<SavedScansView> with SavedScansMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Scans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadSavedScans,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (scanFiles.isEmpty) {
      return const Center(
        child: Text(
          'No saved scans found.\nExport a scan from the Scanner screen.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: scanFiles.length,
      itemBuilder: (context, index) {
        final scanFile = scanFiles[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.view_in_ar),
                title: Text(scanFile.fileName),
                trailing: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(scanFile.file.path)],
                        subject: scanFile.fileName,
                      ),
                    );
                  },
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Created: ${scanFile.formattedDate}'),
                    Text(
                      scanFile.file.path,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.visibility,
                    label: 'View',
                    onPressed: () {
                      ModelViewerView(modelPath: scanFile.file.path)
                          .push(context);
                    },
                  ),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: Colors.redAccent,
                    onPressed: () => _deleteScan(scanFile),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteScan(ScanFile scanFile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan?'),
        content: Text('Are you sure you want to delete ${scanFile.fileName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != null && confirm == true) {
      await scanFile.file.delete();
      showSnackBar('${scanFile.fileName} deleted.');
      await loadSavedScans();
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      onPressed: onPressed,
    );
  }
}
