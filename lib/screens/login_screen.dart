/// Login Screen - Exact copy of web version (split screen with marketing left, form right)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'belloumi.karim.professional@gmail.com');
  final _passwordCtrl = TextEditingController(text: 'belloumi');
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final state = context.read<AppState>();
    final success = await state.login(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() => _error = 'Identifiants invalides ou serveur injoignable');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: isWide
              ? _buildWideLayout()
              : _buildNarrowLayout(),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Row(
        children: [
          // Left: Marketing panel
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(64),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 48),
                  const Text(
                    'Équilibrez vos lignes de confection\nen quelques minutes.',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E3A5F),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureBullet('Importez votre gamme SAM, vos postes et vos ouvriers (Excel ou CSV)'),
                  _buildFeatureBullet('Diagnostic de faisabilité avant calcul'),
                  _buildFeatureBullet('Répartition optimale des opérations, charge par poste, rendement'),
                  _buildFeatureBullet('Cadence minimale atteignable avec vos moyens'),
                  const SizedBox(height: 32),
                  const Text(
                    'Essai gratuit 30 jours, sans carte bancaire.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF667085),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right: Login form
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(48),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: _buildLoginForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          _buildLogo(),
          const SizedBox(height: 32),
          const Text(
            'Équilibrez vos lignes de confection\nen quelques minutes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A5F),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatureBullet('Importez votre gamme SAM, vos postes et vos ouvriers (Excel ou CSV)'),
          _buildFeatureBullet('Diagnostic de faisabilité avant calcul'),
          _buildFeatureBullet('Répartition optimale des opérations, charge par poste, rendement'),
          _buildFeatureBullet('Cadence minimale atteignable avec vos moyens'),
          const SizedBox(height: 24),
          const Text(
            'Essai gratuit 30 jours, sans carte bancaire.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF667085),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildLoginForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.bar_chart, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Textile Line Balancer',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E3A5F),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF039855), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Color(0xFF344054), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Connexion',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E3A5F)),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF667085)),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || !v.contains('@') ? 'E-mail invalide' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordCtrl,
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF667085)),
            ),
            obscureText: true,
            validator: (v) => v == null || v.length < 4 ? 'Mot de passe trop court' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF04438)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFF04438), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Se connecter'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: () {}, child: const Text('Créer un compte')),
              TextButton(onPressed: () {}, child: const Text('Mot de passe oublié ?')),
            ],
          ),
        ],
      ),
    );
  }
}