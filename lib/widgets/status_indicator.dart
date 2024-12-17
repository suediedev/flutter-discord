import 'package:flutter/material.dart';
import '../models/member.dart';

class StatusIndicator extends StatelessWidget {
  final MemberStatus status;
  final double size;
  final bool showBorder;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 12,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getStatusColor(),
        border: showBorder
            ? Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: size * 0.2,
              )
            : null,
      ),
      child: _getStatusIcon(),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case MemberStatus.online:
        return Colors.green;
      case MemberStatus.idle:
        return Colors.orange;
      case MemberStatus.doNotDisturb:
        return Colors.red;
      case MemberStatus.offline:
        return Colors.grey;
    }
  }

  Widget? _getStatusIcon() {
    if (status == MemberStatus.doNotDisturb) {
      return Center(
        child: Container(
          width: size * 0.4,
          height: 2,
          color: Colors.white,
        ),
      );
    }
    if (status == MemberStatus.idle) {
      return Center(
        child: Container(
          width: size * 0.4,
          height: size * 0.4,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return null;
  }
}
