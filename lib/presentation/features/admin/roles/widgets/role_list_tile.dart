import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:payme/domain/entities/user_role.dart';
import 'package:payme/l10n/app_localizations.dart';

class RoleListTile extends StatelessWidget {
  final UserRole role;

  const RoleListTile({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor = Colors.grey;
    if (role.color != null && role.color!.isNotEmpty) {
      // Parse hex color if needed. We assume Phase 2A predefined colors might just be standard names or hex.
      // For predefined palettes, we could map names to Colors. Assuming it's a hex string from Phase 1 or similar:
      try {
        String hexString = role.color!.replaceAll('#', '');
        if (hexString.length == 6) {
          hexString = 'FF$hexString';
        }
        badgeColor = Color(int.parse(hexString, radix: 16));
      } catch (e) {
        // Fallback to grey if parsing fails or it's a name
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: badgeColor,
          child: Icon(
            role.isSystemRole ? Icons.security : Icons.people,
            color: Colors.white,
          ),
        ),
        title: Text(
          role.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
              if (role.description != null && role.description!.isNotEmpty)
                Text(
                  role.isSystemRole && role.id == 'owner_role' 
                      ? AppLocalizations.of(context)!.systemOwnerDescription 
                      : role.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.priorityPrefix(role.priority),
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/roles/${role.id}'),
      ),
    );
  }
}
