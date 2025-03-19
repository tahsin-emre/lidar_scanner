import 'package:flutter/material.dart';

extension WidgetExt on Widget {
  Widget expanded() => Expanded(child: this);
  Widget sliver() => SliverToBoxAdapter(child: this);

  Future<void> push(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => this),
    );
  }
}
