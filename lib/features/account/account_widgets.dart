import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/format.dart';
import '../../core/geo/geo.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../data/account_data.dart';
import '../../widgets/common.dart';

/// ISO-2 → ISO-3 for the member countries (used to pre-fill the country from the device region).
const _iso2 = {
  'AO': 'AGO', 'BJ': 'BEN', 'BI': 'BDI', 'CM': 'CMR', 'CF': 'CAF', 'CG': 'COG', 'CD': 'COD', 'CI': 'CIV', 'ET': 'ETH', 'GA': 'GAB', 'GH': 'GHA',
  'GN': 'GIN', 'GQ': 'GNQ', 'KE': 'KEN', 'LR': 'LBR', 'MG': 'MDG', 'MW': 'MWI', 'NG': 'NGA', 'UG': 'UGA', 'RW': 'RWA', 'SL': 'SLE', 'TZ': 'TZA',
  'TG': 'TGO', 'ZM': 'ZMB', 'ZW': 'ZWE',
};

InputDecoration _dec(BuildContext c, String label, {IconData? icon, String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 18),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Human label of a purchase line (stored language-neutral).
String purchaseLabel(BuildContext c, Purchase p) {
  final parts = p.label.split('|');
  if (p.kind == 'plan') return '${c.tr(parts[0])} · ${c.tr(parts[1] == 'year' ? 'cyc_year' : 'cyc_month')}';
  final ref = parts.length > 1 ? parts[1] : '';
  return parts[0] == 'report' ? '${c.tr('pw_report')} · ${c.tr('rep_$ref')}' : '${parts[0].toUpperCase()} · ${c.tr('nav_$ref')}';
}

/// Short notice reminding that this is a front-end demonstration.
class DemoNotice extends StatelessWidget {
  final String textKey;
  const DemoNotice(this.textKey, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.gold.withValues(alpha: .1), borderRadius: BorderRadius.circular(12), border: Border.all(color: p.gold.withValues(alpha: .5))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.science_rounded, size: 18, color: p.gold),
        const SizedBox(width: 10),
        Expanded(child: Text(context.tr(textKey), style: TS.bodyS(p).copyWith(fontSize: 12))),
      ]),
    );
  }
}

// ===========================================================================
// Sign-up / sign-in / e-mail verification
// ===========================================================================
class AuthPanel extends StatefulWidget {
  final VoidCallback onAuthed;
  final bool startLogin;
  const AuthPanel({super.key, required this.onAuthed, this.startLogin = false});
  @override
  State<AuthPanel> createState() => _AuthPanelState();
}

class _AuthPanelState extends State<AuthPanel> {
  late String _mode = widget.startLogin ? 'login' : 'register'; // register | login | verify
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _user = TextEditingController(), _mail = TextEditingController();
  final _pw = TextEditingController(), _pw2 = TextEditingController(), _city = TextEditingController(), _addr = TextEditingController();
  final _geoCountry = TextEditingController(), _geoCity = TextEditingController(), _otherCountry = TextEditingController();
  final _loginId = TextEditingController(), _loginPw = TextEditingController(), _code = TextEditingController();
  String? _country, _gender; // _country: member country id, or 'OTHER'
  DateTime? _birth;
  bool _consent = false, _hide = true;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _user, _mail, _pw, _pw2, _city, _addr, _geoCountry, _geoCity, _otherCountry, _loginId, _loginPw, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _detectRegion(quiet: true);
    });
  }

  /// Approximate geolocation (country, city) from the device settings — no GPS, no server.
  void _detectRegion({bool quiet = false}) {
    final loc = approximateLocation();
    final member = loc.iso2 == null ? null : _iso2[loc.iso2!];
    setState(() {
      _geoCountry.text = member != null ? context.tr('mc_$member') : (loc.iso2 ?? '');
      if (loc.city != null) _geoCity.text = loc.city!;
      _country ??= member;
      if (_city.text.isEmpty && loc.city != null) _city.text = loc.city!;
    });
    if (!quiet) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(context.tr(loc.iso2 == null && loc.city == null ? 'acc_geo_none' : 'acc_geo_ok'))));
    }
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 30, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (d != null) setState(() => _birth = d);
  }

  void _submitRegister() {
    final ok = _form.currentState!.validate();
    final other = _country == 'OTHER';
    if (!ok || _birth == null || _country == null || (other && _otherCountry.text.trim().isEmpty) || _gender == null || !_consent) {
      setState(() => _error = 'acc_err_incomplete');
      return;
    }
    final err = context.app.register(
      fullName: _name.text,
      username: _user.text,
      email: _mail.text,
      password: _pw.text,
      country: other ? _otherCountry.text.trim() : _country!,
      city: _city.text,
      address: _addr.text,
      birth: _birth!,
      gender: _gender!,
      geoCountry: _geoCountry.text.trim(),
      geoCity: _geoCity.text.trim(),
    );
    setState(() {
      _error = err;
      if (err == null) _mode = 'verify';
    });
  }

  void _submitLogin() {
    final err = context.app.loginVisitor(_loginId.text, _loginPw.text);
    if (err == 'acc_err_unverified') {
      setState(() {
        _error = null;
        _mode = 'verify';
      });
    } else if (err != null) {
      setState(() => _error = err);
    } else {
      widget.onAuthed();
    }
  }

  void _submitCode() {
    final err = context.app.verifyCode(_code.text);
    if (err != null) {
      setState(() => _error = err);
    } else {
      widget.onAuthed();
    }
  }

  void _social(String provider) {
    context.app.socialLogin(provider, country: _country ?? 'CIV');
    widget.onAuthed();
  }

  Widget _row(List<Widget> kids) {
    if (!context.isMobile && context.w >= 900) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < kids.length; i++) ...[if (i > 0) const SizedBox(width: 12), Expanded(child: kids[i])],
        ]),
      );
    }
    return Column(children: [for (final k in kids) Padding(padding: const EdgeInsets.only(bottom: 12), child: k)]);
  }

  Widget _socialButtons() {
    final p = context.pal;
    Widget b(String id, IconData icon, String label) => OutlinedButton.icon(
          onPressed: () => _social(id),
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(foregroundColor: p.text, side: BorderSide(color: p.border), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 10, runSpacing: 10, children: [
        b('google', Icons.g_mobiledata_rounded, context.tr('acc_google')),
        b('apple', Icons.apple_rounded, context.tr('acc_apple')),
      ]),
      const SizedBox(height: 6),
      Text(context.tr('acc_social_note'), style: TS.bodyS(p).copyWith(fontSize: 11)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: Divider(color: p.border)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(context.tr('acc_or'), style: TS.bodyS(p))),
        Expanded(child: Divider(color: p.border)),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final errorText = _error == null ? null : context.tr(_error!);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_mode != 'verify')
        Segmented<String>(
          values: const ['register', 'login'],
          selected: _mode,
          label: (v) => context.tr(v == 'register' ? 'acc_create' : 'acc_signin'),
          onChanged: (v) => setState(() {
            _mode = v;
            _error = null;
          }),
        ),
      const SizedBox(height: 16),
      if (_mode == 'register') ..._registerForm(p),
      if (_mode == 'login') ..._loginForm(p),
      if (_mode == 'verify') ..._verifyForm(p),
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(children: [
            Icon(Icons.error_outline_rounded, size: 18, color: p.alert),
            const SizedBox(width: 8),
            Expanded(child: Text(errorText, style: TextStyle(color: p.alert, fontSize: 13, fontWeight: FontWeight.w600))),
          ]),
        ),
    ]);
  }

  List<Widget> _registerForm(Pal p) {
    final c = context;
    final genderItems = [for (final g in genders) DropdownMenuItem(value: g, child: Text(c.tr('gender_$g')))];
    return [
      _socialButtons(),
      const SizedBox(height: 16),
      Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Order and fields follow the client's list of mandatory identification information.
          SectionLabel(c.tr('acc_sec_identity')),
          // 1. full name
          _row([
            TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: _dec(c, c.tr('acc_fullname'), icon: Icons.badge_outlined), validator: (v) => (v ?? '').trim().length < 3 ? c.tr('acc_err_required') : null),
          ]),
          // 2. e-mail (unique + verification)
          _row([
            TextFormField(controller: _mail, keyboardType: TextInputType.emailAddress, decoration: _dec(c, c.tr('acc_email'), icon: Icons.mail_outline_rounded, hint: c.tr('acc_email_hint')), validator: (v) => validEmail(v ?? '') ? null : c.tr('acc_err_email')),
          ]),
          // 3. password (hashed) — or social sign-in above
          _row([
            TextFormField(
              controller: _pw,
              obscureText: _hide,
              decoration: _dec(c, c.tr('acc_password'), icon: Icons.lock_outline_rounded, hint: c.tr('acc_password_hint')).copyWith(suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18), onPressed: () => setState(() => _hide = !_hide))),
              validator: (v) => strongPassword(v ?? '') ? null : c.tr('acc_err_password'),
            ),
            TextFormField(controller: _pw2, obscureText: _hide, decoration: _dec(c, c.tr('acc_password2'), icon: Icons.lock_reset_rounded), validator: (v) => v == _pw.text ? null : c.tr('acc_err_password2')),
          ]),
          // 4. username
          _row([
            TextFormField(controller: _user, decoration: _dec(c, c.tr('acc_username'), icon: Icons.alternate_email_rounded), validator: (v) => RegExp(r'^[A-Za-z0-9_.]{3,24}$').hasMatch((v ?? '').trim()) ? null : c.tr('acc_err_username')),
          ]),
          // 5. approximate geolocation (country, city)
          SectionLabel(c.tr('acc_sec_geo'), trailing: TextButton.icon(onPressed: _detectRegion, icon: const Icon(Icons.my_location_rounded, size: 18), label: Text(c.tr('acc_geo')))),
          _row([
            TextFormField(controller: _geoCountry, decoration: _dec(c, c.tr('acc_geo_country'), icon: Icons.travel_explore_rounded)),
            TextFormField(controller: _geoCity, decoration: _dec(c, c.tr('acc_geo_city'), icon: Icons.near_me_outlined)),
          ]),
          // 6. date of birth / gender
          SectionLabel(c.tr('acc_sec_profile')),
          _row([
            InkWell(
              onTap: _pickBirth,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _dec(c, c.tr('acc_birth'), icon: Icons.cake_outlined),
                child: Text(_birth == null ? c.tr('acc_birth_pick') : _date(_birth!), style: TextStyle(color: _birth == null ? p.muted : p.text)),
              ),
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _gender,
              decoration: _dec(c, c.tr('acc_gender'), icon: Icons.person_outline_rounded),
              items: genderItems,
              onChanged: (v) => setState(() => _gender = v),
              validator: (v) => v == null ? c.tr('acc_err_required') : null,
            ),
          ]),
          // 7. address / city / country
          SectionLabel(c.tr('acc_sec_address')),
          _row([
            TextFormField(controller: _addr, decoration: _dec(c, c.tr('acc_address'), icon: Icons.home_outlined), validator: (v) => (v ?? '').trim().isEmpty ? c.tr('acc_err_required') : null),
          ]),
          _row([
            TextFormField(controller: _city, textCapitalization: TextCapitalization.words, decoration: _dec(c, c.tr('acc_city'), icon: Icons.location_city_rounded), validator: (v) => (v ?? '').trim().isEmpty ? c.tr('acc_err_required') : null),
            DropdownButtonFormField<String>(
              key: ValueKey('country_$_country'),
              isExpanded: true,
              initialValue: _country,
              decoration: _dec(c, c.tr('acc_country'), icon: Icons.public_rounded),
              items: [
                for (final id in [...memberCountries]..sort((a, b) => c.tr('mc_$a').compareTo(c.tr('mc_$b')))) DropdownMenuItem(value: id, child: Text(c.tr('mc_$id'), overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'OTHER', child: Text(c.tr('acc_country_other'), overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _country = v),
              validator: (v) => v == null ? c.tr('acc_err_required') : null,
            ),
          ]),
          if (_country == 'OTHER')
            _row([
              TextFormField(controller: _otherCountry, textCapitalization: TextCapitalization.words, decoration: _dec(c, c.tr('acc_country_other_name'), icon: Icons.flag_outlined), validator: (v) => (v ?? '').trim().isEmpty ? c.tr('acc_err_required') : null),
            ]),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            title: Text(c.tr('acc_consent'), style: TS.bodyS(p).copyWith(fontSize: 12.5)),
          ),
          const SizedBox(height: 8),
          DemoNotice('acc_demo_note'),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: PrimaryButton(c.tr('acc_create_btn'), icon: Icons.person_add_alt_1_rounded, onTap: _submitRegister)),
        ]),
      ),
    ];
  }

  List<Widget> _loginForm(Pal p) {
    final c = context;
    return [
      _socialButtons(),
      const SizedBox(height: 16),
      TextField(controller: _loginId, decoration: _dec(c, c.tr('acc_login_id'), icon: Icons.person_outline_rounded)),
      const SizedBox(height: 12),
      TextField(
        controller: _loginPw,
        obscureText: _hide,
        onSubmitted: (_) => _submitLogin(),
        decoration: _dec(c, c.tr('acc_password'), icon: Icons.lock_outline_rounded).copyWith(suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18), onPressed: () => setState(() => _hide = !_hide))),
      ),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: PrimaryButton(c.tr('acc_signin_btn'), icon: Icons.login_rounded, onTap: _submitLogin)),
      const SizedBox(height: 12),
      DemoNotice('acc_local_note'),
    ];
  }

  List<Widget> _verifyForm(Pal p) {
    final c = context;
    final app = c.app;
    return [
      Text(c.tr('acc_verify_title'), style: TS.h2(p)),
      const SizedBox(height: 6),
      Text(c.tr('acc_verify_d', [app.pendingEmail ?? '']), style: TS.bodyS(p)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: p.gold.withValues(alpha: .12), borderRadius: BorderRadius.circular(12), border: Border.all(color: p.gold.withValues(alpha: .6))),
        child: Row(children: [
          Icon(Icons.mark_email_read_rounded, color: p.gold),
          const SizedBox(width: 10),
          Expanded(child: Text(c.tr('acc_demo_code'), style: TS.bodyS(p).copyWith(fontSize: 12))),
          const SizedBox(width: 8),
          Text(app.pendingCode ?? '------', style: TS.h2(p).copyWith(letterSpacing: 4, color: p.gold)),
        ]),
      ),
      const SizedBox(height: 12),
      TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, onSubmitted: (_) => _submitCode(), decoration: _dec(c, c.tr('acc_code'), icon: Icons.pin_outlined)),
      SizedBox(width: double.infinity, child: PrimaryButton(c.tr('acc_verify_btn'), icon: Icons.verified_user_rounded, onTap: _submitCode)),
      const SizedBox(height: 8),
      TextButton(onPressed: () => setState(() => app.resendCode(app.pendingEmail ?? '')), child: Text(c.tr('acc_resend'))),
    ];
  }
}

// ===========================================================================
// Plans
// ===========================================================================
class PlanPicker extends StatefulWidget {
  final void Function(String planId, String cycle) onSelect;
  final String? currentPlan;
  const PlanPicker({super.key, required this.onSelect, this.currentPlan});
  @override
  State<PlanPicker> createState() => _PlanPickerState();
}

class _PlanPickerState extends State<PlanPicker> {
  String _cycle = 'month';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final cols = context.cols(desktop: 3, tablet: 3, mobile: 1);
    Widget card(PlanDef d) {
      final price = _cycle == 'year' ? d.yearUsd : d.monthUsd;
      final current = widget.currentPlan == d.id;
      final featured = d.id == 'pro';
      return GlassCard(
        accent: featured ? p.gold : null,
        selected: current,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(context.tr(d.nameKey), maxLines: 1, style: TS.h2(p))),
            if (featured) Chip2(context.tr('plan_popular'), p.gold),
            if (current) Chip2(context.tr('plan_current'), p.green),
          ]),
          const SizedBox(height: 4),
          Text(context.tr(d.descKey), style: TS.bodyS(p)),
          const SizedBox(height: 12),
          if (d.monthUsd == 0)
            Text(context.tr('plan_free_price'), style: TS.h1(p).copyWith(fontSize: 26))
          else ...[
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(Fmt.usd(price, 0), maxLines: 1, style: TS.h1(p).copyWith(fontSize: 26))),
            Text(context.tr(_cycle == 'year' ? 'plan_per_year' : 'plan_per_month'), style: TS.bodyS(p)),
          ],
          const SizedBox(height: 12),
          for (final f in d.featureKeys)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(f == 'pf_nodl' ? Icons.block_rounded : Icons.check_circle_rounded, size: 16, color: f == 'pf_nodl' ? p.muted : p.green),
                const SizedBox(width: 8),
                Expanded(child: Text(context.tr(f), style: TS.bodyS(p).copyWith(fontSize: 12.5, color: p.text))),
              ]),
            ),
          const SizedBox(height: 8),
          if (d.downloads)
            SizedBox(width: double.infinity, child: PrimaryButton(context.tr(current ? 'plan_renew' : 'plan_choose'), icon: Icons.workspace_premium_rounded, outlined: !featured, onTap: () => widget.onSelect(d.id, _cycle))),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Segmented<String>(values: const ['month', 'year'], selected: _cycle, label: (v) => context.tr(v == 'month' ? 'cyc_month' : 'cyc_year_save'), onChanged: (v) => setState(() => _cycle = v)),
      const SizedBox(height: 14),
      Grid(columns: cols, gap: 14, children: [for (final d in plans) card(d)]),
    ]);
  }
}

// ===========================================================================
// Simulated payment
// ===========================================================================
class PayPanel extends StatefulWidget {
  final String summaryKey; // already translated text is passed through [summary]
  final String summary;
  final double amountUsd;
  final void Function(String method) onPaid;
  const PayPanel({super.key, this.summaryKey = '', required this.summary, required this.amountUsd, required this.onPaid});
  @override
  State<PayPanel> createState() => _PayPanelState();
}

class _PayPanelState extends State<PayPanel> {
  String _method = 'momo';
  bool _busy = false;

  Future<void> _pay() async {
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    widget.onPaid(_method);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    IconData icon(String m) => switch (m) { 'momo' => Icons.smartphone_rounded, 'card' => Icons.credit_card_rounded, _ => Icons.account_balance_rounded };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
        child: Row(children: [
          Expanded(child: Text(widget.summary, style: TS.h3(p))),
          const SizedBox(width: 10),
          Text(Fmt.usd(widget.amountUsd, 2), style: TS.h2(p).copyWith(color: p.accent)),
        ]),
      ),
      const SizedBox(height: 14),
      SectionLabel(context.tr('pay_method')),
      for (final m in payMethods)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            selected: _method == m,
            onTap: _busy ? null : () => setState(() => _method = m),
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(icon(m), color: p.accent),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr('pm_$m'), style: TS.h3(p)), Text(context.tr('pm_${m}_d'), style: TS.bodyS(p).copyWith(fontSize: 11.5))])),
              Icon(_method == m ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: _method == m ? p.accent : p.muted, size: 20),
            ]),
          ),
        ),
      const SizedBox(height: 4),
      DemoNotice('pay_demo_note'),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: _busy
            ? Center(child: Column(children: [const SizedBox(height: 4), const CircularProgressIndicator(), const SizedBox(height: 8), Text(context.tr('pay_processing'), style: TS.bodyS(p))]))
            : PrimaryButton(context.tr('pay_btn', [Fmt.usd(widget.amountUsd, 2)]), icon: Icons.lock_rounded, onTap: _pay),
      ),
    ]);
  }
}

// ===========================================================================
// Paywall for downloads
// ===========================================================================

/// Returns true when the visitor may download now (active subscription, admin, or after a one-off payment).
Future<bool> ensureDownloadAccess(BuildContext context, {required String kind, required String ref}) async {
  final app = context.app;
  if (app.canDownload) return true;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => PaywallDialog(kind: kind, ref: ref),
  );
  return ok == true;
}

class PaywallDialog extends StatefulWidget {
  final String kind, ref; // kind: csv | pdf | png | report
  const PaywallDialog({super.key, required this.kind, required this.ref});
  @override
  State<PaywallDialog> createState() => _PaywallDialogState();
}

class _PaywallDialogState extends State<PaywallDialog> {
  String _step = 'offer'; // offer | auth | pay
  String? _planId, _cycle; // null planId = one-off payment of this download

  String get _itemLabel => '${widget.kind}|${widget.ref}';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = context.app;
    final mobile = context.isMobile;
    final what = widget.kind == 'report' ? '${context.tr('pw_report')} · ${context.tr('rep_${widget.ref}')}' : '${widget.kind.toUpperCase()} · ${context.tr('nav_${widget.ref}')}';
    Widget body;
    String title;
    if (_step == 'auth') {
      title = context.tr('pw_need_account');
      body = AuthPanel(onAuthed: () => setState(() => _step = app.canDownload ? 'offer' : 'offer'));
    } else if (_step == 'pay') {
      title = context.tr('pw_payment');
      final plan = _planId == null ? null : planById(_planId!);
      final amount = plan == null ? itemPriceUsd(widget.kind) : (_cycle == 'year' ? plan.yearUsd : plan.monthUsd);
      body = PayPanel(
        summary: plan == null ? what : '${context.tr(plan.nameKey)} · ${context.tr(_cycle == 'year' ? 'cyc_year' : 'cyc_month')}',
        amountUsd: amount,
        onPaid: (m) {
          if (plan == null) {
            app.buyItem(widget.kind, _itemLabel, m);
          } else {
            app.subscribe(plan.id, _cycle!, m);
          }
          Navigator.pop(context, true);
        },
      );
    } else {
      title = context.tr('pw_title');
      body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.lock_rounded, color: p.gold),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr('pw_intro', [what]), style: TS.bodyS(p).copyWith(color: p.text))),
        ]),
        const SizedBox(height: 14),
        if (app.me == null) ...[
          GlassCard(
            accent: p.gold,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.person_add_alt_1_rounded, color: p.accent),
                const SizedBox(width: 12),
                Expanded(child: Text(context.tr('pw_signin_first'), style: TS.bodyS(p).copyWith(color: p.text))),
              ]),
              const SizedBox(height: 10),
              PrimaryButton(context.tr('acc_signin_or_create'), onTap: () => setState(() => _step = 'auth')),
            ]),
          ),
          const SizedBox(height: 14),
        ],
        SectionLabel(context.tr('pw_one_off')),
        GlassCard(
          child: Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(what, style: TS.h3(p)), Text(context.tr('pw_one_off_d'), style: TS.bodyS(p).copyWith(fontSize: 11.5))]),
            PrimaryButton(Fmt.usd(itemPriceUsd(widget.kind), 2), icon: Icons.download_rounded, outlined: true, onTap: () {
              if (app.me == null) {
                setState(() => _step = 'auth');
              } else {
                setState(() {
                  _planId = null;
                  _step = 'pay';
                });
              }
            }),
          ]),
        ),
        const SizedBox(height: 16),
        SectionLabel(context.tr('pw_or_subscribe')),
        PlanPicker(onSelect: (id, cycle) {
          if (app.me == null) {
            setState(() => _step = 'auth');
          } else {
            setState(() {
              _planId = id;
              _cycle = cycle;
              _step = 'pay';
            });
          }
        }),
      ]);
    }
    final content = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        if (_step != 'offer') IconButton(onPressed: () => setState(() => _step = 'offer'), icon: const Icon(Icons.arrow_back_rounded)),
        Expanded(child: Text(title, style: TS.h1(p).copyWith(fontSize: mobile ? 20 : 24))),
        IconButton(onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.close_rounded)),
      ]),
      const SizedBox(height: 8),
      Flexible(child: SingleChildScrollView(child: body)),
    ]);
    return Dialog(
      backgroundColor: p.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: mobile ? 8 : 24, vertical: mobile ? 12 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: Padding(padding: EdgeInsets.all(mobile ? 14 : 22), child: content)),
    );
  }
}
