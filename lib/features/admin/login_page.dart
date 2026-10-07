import 'package:flutter/material.dart';
import '../../core/ctx.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../widgets/common.dart';
import '../../widgets/org_logo.dart';
import '../shell/top_controls.dart';

/// Admin sign-in (front-end demo: credentials are checked locally, nothing is secure).
class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});
  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final _u = TextEditingController(text: 'admin');
  final _p = TextEditingController();
  bool _err = false, _show = false, _busy = false;

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_u.text.trim().isEmpty || _p.text.isEmpty) {
      setState(() => _err = true);
      return;
    }
    setState(() {
      _busy = true;
      _err = false;
    });
    await Future.delayed(const Duration(milliseconds: 700)); // simulated server round-trip
    if (!mounted) return;
    final ok = context.app.login(_u.text, _p.text);
    if (!ok) setState(() {
      _err = true;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [CI.espressoDeep, p.dark ? const Color(0xFF0E0806) : CI.forest])),
        child: SafeArea(
          child: Stack(children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(padding: const EdgeInsets.all(14), child: Row(mainAxisSize: MainAxisSize.min, children: const [LangToggle(), SizedBox(width: 8), ThemeToggle()])),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: CI.gold.withValues(alpha: .5)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 40)]),
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Center(child: OrgLogo(height: 70, framed: false)),
                      const SizedBox(height: 18),
                      Text(context.tr('admin_login_title'), textAlign: TextAlign.center, style: TS.h2(p)),
                      const SizedBox(height: 4),
                      Text(context.tr('admin_login_sub'), textAlign: TextAlign.center, style: TS.bodyS(p)),
                      const SizedBox(height: 22),
                      TextField(
                        controller: _u,
                        autofocus: false,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: context.tr('admin_user'), prefixIcon: const Icon(Icons.person_outline_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _p,
                        obscureText: !_show,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: context.tr('admin_pass'),
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(icon: Icon(_show ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _show = !_show)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      if (_err)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(_u.text.trim().isEmpty ? context.tr('admin_user_req') : (_p.text.isEmpty ? context.tr('admin_pass_req') : context.tr('admin_error')), style: TextStyle(color: p.alert, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      const SizedBox(height: 18),
                      _busy
                          ? const Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.6)))
                          : Center(child: PrimaryButton(context.tr('admin_signin'), icon: Icons.login_rounded, onTap: _submit)),
                      const SizedBox(height: 14),
                      Center(child: TextButton(onPressed: context.app.closeLogin, child: Text(context.tr('admin_back')))),
                      const SizedBox(height: 4),
                      Text(context.tr('admin_demo_hint'), textAlign: TextAlign.center, style: TS.h3(p).copyWith(fontSize: 12.5, color: p.gold)),
                      const SizedBox(height: 4),
                      Text(context.tr('admin_demo_note'), textAlign: TextAlign.center, style: TS.bodyS(p).copyWith(fontSize: 11)),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
