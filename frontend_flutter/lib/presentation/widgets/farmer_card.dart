import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/farmer_model.dart';
import 'avatar_view.dart';
import 'field_steward_ui.dart';

class FarmerCard extends StatelessWidget {
  final FarmerModel farmer;
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onEdit;

  const FarmerCard({
    super.key,
    required this.farmer,
    this.onDelete,
    this.onEdit,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    await launchUrl(Uri(scheme: 'tel', path: phoneNumber));
  }

  Future<void> _sendSms(String phoneNumber) async {
    await launchUrl(Uri(scheme: 'sms', path: phoneNumber));
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    await launchUrl(
      Uri.parse('https://wa.me/$phoneNumber'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: FieldStewardColors.outline,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit farmer'),
                  onTap: () => Navigator.pop(context, 'edit'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete farmer'),
                  textColor: Colors.red,
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == 'edit') {
      await onEdit?.call();
    } else if (action == 'delete') {
      await onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final synced = farmer.syncStatus.toUpperCase() == 'SYNCED';

    return FieldStewardSurfaceCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarView(
                imagePath: farmer.profileImagePath,
                fallbackLabel: farmer.name,
                radius: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farmer.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: FieldStewardColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: FieldStewardColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            farmer.village,
                            style: const TextStyle(
                              color: FieldStewardColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FieldStewardStatusBadge(
                    label: synced ? 'Synced' : farmer.syncStatus,
                    backgroundColor: synced
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF8E1),
                    foregroundColor: synced
                        ? FieldStewardColors.success
                        : FieldStewardColors.warning,
                    icon: Icons.circle,
                  ),
                  IconButton(
                    onPressed: () => _showActions(context),
                    icon: const Icon(Icons.more_horiz_rounded),
                    color: FieldStewardColors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FieldStewardColors.surfaceLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: synced ? Colors.transparent : FieldStewardColors.outline,
                style: synced ? BorderStyle.none : BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MOBILE',
                        style: TextStyle(
                          color: FieldStewardColors.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        farmer.mobile,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _SmallRoundAction(
                  icon: Icons.call_rounded,
                  color: FieldStewardColors.primaryDark,
                  onTap: () => _makePhoneCall(farmer.mobile),
                ),
                const SizedBox(width: 8),
                _SmallRoundAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: const Color(0xFF25D366),
                  onTap: () => _openWhatsApp(farmer.mobile),
                ),
              ],
            ),
          ),
          if ((farmer.address ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              farmer.address!,
              style: const TextStyle(
                color: FieldStewardColors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FieldStewardPrimaryButton(
                  onPressed: farmer.id == null
                      ? null
                      : () {
                          Navigator.pushNamed(
                            context,
                            '/crop-entry',
                            arguments: farmer.id!,
                          );
                        },
                  icon: Icons.eco_rounded,
                  child: const Text(
                    'Add Crop',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SquareAction(
                icon: Icons.sms_outlined,
                onTap: () => _sendSms(farmer.mobile),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallRoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallRoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareAction({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FieldStewardColors.surfaceHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            icon,
            color: FieldStewardColors.onSurface,
          ),
        ),
      ),
    );
  }
}
