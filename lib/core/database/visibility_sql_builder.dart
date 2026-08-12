class VisibilitySqlBuilder {
  static String buildVisibilityClause(String tablePrefix, String? visibleToUserId) {
    if (visibleToUserId == null || visibleToUserId.isEmpty) {
      return '';
    }

    // Clients with 'everyone' visibility are always returned.
    // Otherwise, check if the current user exists in the client_user_visibility table for this client.
    return '''
      AND ($tablePrefix.visibility_type = 'everyone' 
           OR $tablePrefix.id IN (
             SELECT client_id FROM client_user_visibility WHERE user_id = ?
           ))
    ''';
  }
}
