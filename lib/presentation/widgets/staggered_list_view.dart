import 'package:flutter/material.dart';

class StaggeredListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;

  const StaggeredListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: itemBuilder(context, index),
        );
      },
    );
  }
}
