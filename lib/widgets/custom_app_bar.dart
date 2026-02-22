import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable Custom App Bar with back button support
/// 
/// Features:
/// - Automatic back button (can be disabled)
/// - Title with optional subtitle
/// - Custom actions support
/// - Gradient background option
/// - Elevation control
/// - System UI overlay style
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? gradient;
  final double elevation;
  final bool centerTitle;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final double toolbarHeight;

  const CustomAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.elevation = 0,
    this.centerTitle = true,
    this.leading,
    this.bottom,
    this.systemOverlayStyle,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    
    Widget? effectiveLeading;
    if (leading != null) {
      effectiveLeading = leading;
    } else if (showBackButton && canPop) {
      effectiveLeading = IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
      );
    }

    Widget? titleWidget;
    if (title != null) {
      if (subtitle != null) {
        titleWidget = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: foregroundColor?.withOpacity(0.8) ??
                    theme.appBarTheme.foregroundColor?.withOpacity(0.8) ??
                    Colors.white70,
              ),
            ),
          ],
        );
      } else {
        titleWidget = Text(
          title!,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    }

    final appBar = AppBar(
      title: titleWidget,
      centerTitle: centerTitle,
      leading: effectiveLeading,
      actions: actions,
      elevation: elevation,
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: foregroundColor,
      bottom: bottom,
      systemOverlayStyle: systemOverlayStyle ??
          (gradient != null
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark),
      flexibleSpace: gradient != null
          ? Container(
              decoration: BoxDecoration(
                gradient: gradient,
              ),
            )
          : null,
    );

    if (gradient != null && backgroundColor == null) {
      return Container(
        decoration: BoxDecoration(gradient: gradient),
        child: appBar,
      );
    }

    return appBar;
  }
}

/// Simplified back button app bar for consistent navigation
class BackButtonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const BackButtonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
      ),
      actions: actions,
      elevation: 0,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}

/// Gradient app bar with back button
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade800,
            Colors.blue.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: showBackButton && canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
              )
            : null,
        actions: actions,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
    );
  }
}
