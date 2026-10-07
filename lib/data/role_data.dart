import 'package:flutter/material.dart';

/// Demo user profiles. Roles are simulated: nothing here is real access control.
class RoleDef {
  final String id, nameKey, descKey;
  final IconData icon;
  final Color color;
  final List<String> primary; // page ids shown first
  final Set<String> restricted; // page ids that are locked for this profile
  final String productionTab; // default tab of the "Production & Quality" hub
  final String chainTab;
  final Map<String, bool> perms;
  const RoleDef(this.id, this.nameKey, this.descKey, this.icon, this.color, this.primary, this.restricted, this.productionTab, this.chainTab, this.perms);
}

const permissionKeys = [
  'perm_view_dash',
  'perm_view_prices',
  'perm_view_income',
  'perm_view_trace',
  'perm_export',
  'perm_alerts',
  'perm_reports_sched',
  'perm_edit_data',
  'perm_validate',
  'perm_manage_users',
  'perm_sell',
];

const roles = <RoleDef>[
  RoleDef('coop', 'role_coop', 'role_coop_d', Icons.agriculture_rounded, Color(0xFF4F6F52),
      ['decision', 'production', 'revenue', 'certs', 'compare', 'market', 'forecast', 'alerts', 'reports', 'map'], {'simulator', 'sources'}, 'quality', 'flow',
      {'perm_view_dash': true, 'perm_view_prices': true, 'perm_view_income': true, 'perm_view_trace': true, 'perm_export': true, 'perm_alerts': true, 'perm_reports_sched': true, 'perm_edit_data': false, 'perm_validate': false, 'perm_manage_users': false, 'perm_sell': false}),
  RoleDef('exporter', 'role_exporter', 'role_exporter_d', Icons.inventory_2_rounded, Color(0xFFA66A3F),
      ['decision', 'market', 'chain', 'map', 'forecast', 'alerts', 'compare', 'simulator', 'sources', 'reports'], {'revenue', 'sustain'}, 'production', 'flow',
      {'perm_view_dash': true, 'perm_view_prices': true, 'perm_view_income': false, 'perm_view_trace': true, 'perm_export': true, 'perm_alerts': true, 'perm_reports_sched': true, 'perm_edit_data': false, 'perm_validate': false, 'perm_manage_users': false, 'perm_sell': false}),
  RoleDef('board', 'role_board', 'role_board_d', Icons.account_balance_rounded, Color(0xFF243D2A),
      ['decision', 'production', 'revenue', 'sustain', 'map', 'compare', 'market', 'anomalies', 'forecast', 'reports'], {}, 'production', 'flow',
      {'perm_view_dash': true, 'perm_view_prices': true, 'perm_view_income': true, 'perm_view_trace': true, 'perm_export': true, 'perm_alerts': true, 'perm_reports_sched': true, 'perm_edit_data': true, 'perm_validate': false, 'perm_manage_users': false, 'perm_sell': false}),
  RoleDef('roaster', 'role_roaster', 'role_roaster_d', Icons.local_cafe_rounded, Color(0xFF8B5A7C),
      ['decision', 'production', 'market', 'chain', 'certs', 'sustain', 'compare', 'forecast', 'alerts', 'reports'], {'revenue', 'simulator', 'sources'}, 'quality', 'lots',
      {'perm_view_dash': true, 'perm_view_prices': true, 'perm_view_income': false, 'perm_view_trace': true, 'perm_export': true, 'perm_alerts': true, 'perm_reports_sched': true, 'perm_edit_data': false, 'perm_validate': false, 'perm_manage_users': false, 'perm_sell': false}),
  RoleDef('ngo', 'role_ngo', 'role_ngo_d', Icons.volunteer_activism_rounded, Color(0xFF4F7F93),
      ['decision', 'sustain', 'revenue', 'certs', 'map', 'production', 'anomalies', 'compare', 'reports', 'alerts'], {'simulator', 'sources'}, 'climate', 'flow',
      {'perm_view_dash': true, 'perm_view_prices': true, 'perm_view_income': true, 'perm_view_trace': true, 'perm_export': true, 'perm_alerts': true, 'perm_reports_sched': true, 'perm_edit_data': false, 'perm_validate': false, 'perm_manage_users': false, 'perm_sell': false}),
  RoleDef('admin', 'role_admin', 'role_admin_d', Icons.admin_panel_settings_rounded, Color(0xFFB94A48),
      ['decision', 'market', 'production', 'revenue', 'sustain', 'certs', 'chain', 'map', 'compare', 'forecast', 'anomalies', 'alerts', 'reports', 'sources', 'simulator'], {}, 'production', 'flow',
      {'perm_view_dash': true, 'perm_view_prices': true, 'perm_view_income': true, 'perm_view_trace': true, 'perm_export': true, 'perm_alerts': true, 'perm_reports_sched': true, 'perm_edit_data': true, 'perm_validate': true, 'perm_manage_users': true, 'perm_sell': true}),
];

RoleDef roleById(String id) => roles.firstWhere((r) => r.id == id);

/// Public (non-admin) profiles that anyone can simulate from the profile selector.
List<RoleDef> get publicRoles => roles.where((r) => r.id != 'admin').toList();
