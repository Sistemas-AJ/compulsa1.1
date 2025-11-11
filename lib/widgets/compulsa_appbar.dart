import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/appbar_avatar.dart';

class CompulsaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? additionalActions;
  final bool showAvatar;

  const CompulsaAppBar({
    Key? key,
    required this.title,
    this.additionalActions,
    this.showAvatar = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> actions = [];

    if (additionalActions != null) {
      actions.addAll(additionalActions!);
    }

    if (showAvatar) {
      actions.add(const AppBarAvatar());
    }

    return AppBar(
      title: Text(title),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      actions: actions.isNotEmpty ? actions : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
