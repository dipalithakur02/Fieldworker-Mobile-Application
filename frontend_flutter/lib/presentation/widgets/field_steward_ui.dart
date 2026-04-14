import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';

class FieldStewardColors {
  static const Color primary = Color(AppConstants.primaryColor);
  static const Color primaryDark = Color(0xFF0D631B);
  static const Color background = Color(AppConstants.backgroundColor);
  static const Color surfaceLow = Color(0xFFF2F4F3);
  static const Color surfaceHigh = Color(0xFFE6E9E8);
  static const Color surfaceHighest = Color(0xFFE1E3E2);
  static const Color onSurface = Color(0xFF191C1C);
  static const Color onSurfaceVariant = Color(0xFF40493D);
  static const Color outline = Color(0xFFBFCABA);
  static const Color secondaryContainer = Color(0xFFC6E9BE);
  static const Color primaryFixed = Color(0xFFA3F69C);
  static const Color tertiaryFixed = Color(0xFFFFD9E2);
  static const Color tertiaryContainer = Color(0xFFB14B6F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFFBC02D);
  static const Color error = Color(AppConstants.errorColor);
}

enum FieldStewardTab { home, farmers, crops, sync }

class FieldStewardScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? leading;
  final List<Widget>? actions;
  final FieldStewardTab? currentTab;
  final bool showBottomNav;
  final FloatingActionButton? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomOverlay;
  final VoidCallback? onHomeTap;
  final VoidCallback? onFarmersTap;
  final VoidCallback? onCropsTap;
  final VoidCallback? onSyncTap;

  const FieldStewardScaffold({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.actions,
    this.currentTab,
    this.showBottomNav = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomOverlay,
    this.onHomeTap,
    this.onFarmersTap,
    this.onCropsTap,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = showBottomNav ? 108.0 : 24.0;

    return Scaffold(
      backgroundColor: FieldStewardColors.background,
      drawer: const _FieldStewardDrawer(),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    FieldStewardColors.primary.withValues(alpha: 0.05),
                    Colors.white,
                    FieldStewardColors.secondaryContainer
                        .withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _FieldStewardTopBar(
                  title: title,
                  leading: leading,
                  actions: actions ?? const [],
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: bottomInset + mediaQuery.padding.bottom,
                    ),
                    child: body,
                  ),
                ),
              ],
            ),
          ),
          if (showBottomNav)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: _FieldStewardBottomNav(
                    currentTab: currentTab,
                    onHomeTap: onHomeTap,
                    onFarmersTap: onFarmersTap,
                    onCropsTap: onCropsTap,
                    onSyncTap: onSyncTap,
                  ),
                ),
              ),
            ),
          if (bottomOverlay != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: showBottomNav ? 92 : 0,
              child: SafeArea(
                top: false,
                child: bottomOverlay!,
              ),
            ),
        ],
      ),
    );
  }
}

class FieldStewardPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final bool expanded;
  final double height;

  const FieldStewardPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.expanded = true,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: FieldStewardColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: Size(expanded ? double.infinity : 0, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: icon == null
            ? child
            : Row(
                key: ValueKey(icon),
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 10),
                  child,
                ],
              ),
      ),
    );

    if (expanded) {
      return button;
    }

    return IntrinsicWidth(child: button);
  }
}

class FieldStewardSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const FieldStewardSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FieldStewardTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final IconData? icon;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? helperText;

  const FieldStewardTextField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.icon,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: FieldStewardColors.onSurfaceVariant,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: FieldStewardColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            prefixIcon: icon == null
                ? null
                : Icon(icon, color: FieldStewardColors.onSurfaceVariant),
            suffixIcon: suffix,
            filled: true,
            fillColor: FieldStewardColors.surfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: FieldStewardColors.primary,
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: FieldStewardColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: FieldStewardColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            hintStyle: TextStyle(
              color:
                  FieldStewardColors.onSurfaceVariant.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
            helperStyle: TextStyle(
              color: FieldStewardColors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class FieldStewardStatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  const FieldStewardStatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foregroundColor),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: foregroundColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class FieldStewardSectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? description;
  final Widget? trailing;

  const FieldStewardSectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: FieldStewardColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  color: FieldStewardColors.onSurface,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 10),
                Text(
                  description!,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: FieldStewardColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class FieldStewardIconChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const FieldStewardIconChip({
    super.key,
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? FieldStewardColors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor ?? FieldStewardColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldStewardTopBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget> actions;

  const _FieldStewardTopBar({
    required this.title,
    this.leading,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: FieldStewardColors.background.withValues(alpha: 0.82),
      ),
      child: Row(
        children: [
          leading ??
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(
                    Icons.menu,
                    color: FieldStewardColors.primaryDark,
                  ),
                ),
              ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: FieldStewardColors.primaryDark,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _FieldStewardDrawer extends StatelessWidget {
  const _FieldStewardDrawer();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final role = switch (user?.role) {
      'admin' => 'Admin',
      'farmer' => 'Farmer',
      _ => 'Field Worker',
    };

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FieldStewardColors.primary,
                    FieldStewardColors.primaryDark,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    (user?.name ?? '').trim().isNotEmpty
                        ? user!.name
                        : 'FieldSteward',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (user?.email ?? '').trim().isNotEmpty ? user!.email : role,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit User Details'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.of(context).pop();
                await context.read<AuthProvider>().logout();
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldStewardBottomNav extends StatelessWidget {
  final FieldStewardTab? currentTab;
  final VoidCallback? onHomeTap;
  final VoidCallback? onFarmersTap;
  final VoidCallback? onCropsTap;
  final VoidCallback? onSyncTap;

  const _FieldStewardBottomNav({
    required this.currentTab,
    this.onHomeTap,
    this.onFarmersTap,
    this.onCropsTap,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: FieldStewardColors.background.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              label: 'Home',
              icon: Icons.grid_view_rounded,
              selected: currentTab == FieldStewardTab.home,
              onTap: onHomeTap,
            ),
            _NavItem(
              label: 'Farmers',
              icon: Icons.person_add_alt_1_rounded,
              selected: currentTab == FieldStewardTab.farmers,
              onTap: onFarmersTap,
            ),
            _NavItem(
              label: 'Crops',
              icon: Icons.eco_rounded,
              selected: currentTab == FieldStewardTab.crops,
              onTap: onCropsTap,
            ),
            _NavItem(
              label: 'Sync',
              icon: Icons.cloud_sync_rounded,
              selected: currentTab == FieldStewardTab.sync,
              onTap: onSyncTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? FieldStewardColors.primaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  selected ? Colors.white : FieldStewardColors.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w800,
                color: selected
                    ? Colors.white
                    : FieldStewardColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
