import 'package:flutter/material.dart';
import '../../../../../domain/entities/app_user.dart';
import '../../../../../domain/entities/user_role.dart';
import 'package:go_router/go_router.dart';
import 'package:payme/l10n/app_localizations.dart';

class UserListTile extends StatelessWidget {
  final AppUser user;
  final UserRole? role;

  const UserListTile({
    super.key,
    required this.user,
    this.role,
  });

  Color _parseRoleColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.blue;
    
    try {
      final hexString = colorHex.replaceAll('#', '');
      int colorValue = int.parse(hexString, radix: 16);
      
      if (colorValue <= 0xFFFFFF) {
        colorValue |= 0xFF000000;
      }
      return Color(colorValue);
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? _parseRoleColor(role?.color) : Colors.grey,
          child: Text(
            (user.displayName?.isNotEmpty == true) 
                ? user.displayName![0].toUpperCase() 
                : user.email[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Text(
              user.displayName ?? user.email,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: user.isActive ? null : TextDecoration.lineThrough,
                color: user.isActive ? null : Colors.grey,
              ),
            ),
            if (user.isOwner) ...[
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Colors.amber, size: 16),
            ]
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: TextStyle(color: user.isActive ? null : Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role?.name ?? AppLocalizations.of(context)!.unknownRole,
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
                if (!user.isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.inactive,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push('/users/${user.uid}');
        },
      ),
    );
  }
}
