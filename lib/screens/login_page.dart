import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';
import '../models/user_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  bool rememberMe = false;
  bool obscurePassword = true;
  bool isLoading = true;

  static const String adminEmail = 'admin@serenity.com';
  static const String adminPassword = 'Admin123';

  static const String rememberMeKey = 'remember_me';
  static const String savedEmailKey = 'saved_email';
  static const String savedPasswordKey = 'saved_password';

  @override
  void initState() {
    super.initState();
    loadSavedCredentials();
  }

  Future<void> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final savedRememberMe = prefs.getBool(rememberMeKey) ?? false;
    final savedEmail = prefs.getString(savedEmailKey) ?? '';
    final savedPassword = prefs.getString(savedPasswordKey) ?? '';

    setState(() {
      rememberMe = savedRememberMe;

      if (savedRememberMe) {
        emailController.text = savedEmail;
        passwordController.text = savedPassword;
      } else {
        emailController.clear();
        passwordController.clear();
      }

      isLoading = false;
    });
  }

  Future<void> updateRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      rememberMe = value;
    });

    await prefs.setBool(rememberMeKey, value);

    if (value) {
      await prefs.setString(savedEmailKey, emailController.text.trim());
      await prefs.setString(savedPasswordKey, passwordController.text);
    } else {
      await prefs.remove(savedEmailKey);
      await prefs.remove(savedPasswordKey);
    }
  }

  Future<void> updateSavedCredentials() async {
    if (!rememberMe) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(savedEmailKey, emailController.text.trim());
    await prefs.setString(savedPasswordKey, passwordController.text);
  }

  Future<void> saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    if (rememberMe) {
      await prefs.setBool(rememberMeKey, true);
      await prefs.setString(savedEmailKey, emailController.text.trim());
      await prefs.setString(savedPasswordKey, passwordController.text);
    } else {
      await prefs.setBool(rememberMeKey, false);
      await prefs.remove(savedEmailKey);
      await prefs.remove(savedPasswordKey);
    }
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email == adminEmail && password == adminPassword) {
      await saveCredentials();

      if (!mounted) return;
      final user = UserModel(
        name: 'Julian Thorne',
        role: 'Super Admin',
        email: email,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(user: user),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password')),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      body: SafeArea(
        child: isDesktop
            ? Row(
          children: [
            const Expanded(child: _BrandPanel()),
            Expanded(
              child: _LoginPanel(
                formKey: _formKey,
                emailController: emailController,
                passwordController: passwordController,
                emailFocusNode: emailFocusNode,
                passwordFocusNode: passwordFocusNode,
                rememberMe: rememberMe,
                obscurePassword: obscurePassword,
                onRememberChanged: (value) async {
                  await updateRememberMe(value ?? false);
                },
                onCredentialsChanged: () async {
                  await updateSavedCredentials();
                },
                onTogglePassword: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
                onLogin: login,
              ),
            ),
          ],
        )
            : SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 320, child: _BrandPanel()),
              _LoginPanel(
                formKey: _formKey,
                emailController: emailController,
                passwordController: passwordController,
                emailFocusNode: emailFocusNode,
                passwordFocusNode: passwordFocusNode,
                rememberMe: rememberMe,
                obscurePassword: obscurePassword,
                onRememberChanged: (value) async {
                  await updateRememberMe(value ?? false);
                },
                onCredentialsChanged: () async {
                  await updateSavedCredentials();
                },
                onTogglePassword: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
                onLogin: login,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2B3134),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF4BDDB7).withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B894),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 184, 148, 0.20),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.spa,
                      color: Colors.white,
                      size: 58,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Serenity Massage and Spa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Reclaiming clinical precision in the art of tranquility. Welcome back to your personal sanctuary.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFBBCAC3),
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: Color(0xFF6DFAD2),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'SANCTUARY OPERATIONAL',
                          style: TextStyle(
                            color: Color(0xFFBBCAC3),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool rememberMe;
  final bool obscurePassword;
  final Future<void> Function(bool?) onRememberChanged;
  final Future<void> Function() onCredentialsChanged;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onLogin;

  const _LoginPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.rememberMe,
    required this.obscurePassword,
    required this.onRememberChanged,
    required this.onCredentialsChanged,
    required this.onTogglePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4FAFD),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: const Border(
                  top: BorderSide(color: Color(0xFF00B894), width: 3),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(45, 52, 54, 0.08),
                    blurRadius: 30,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF161D1F),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please authenticate to access your wellness dashboard.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF586062),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'INSTITUTIONAL EMAIL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Color(0xFF586062),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      focusNode: emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(passwordFocusNode);
                      },
                      onChanged: (_) async {
                        await onCredentialsChanged();
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.mail_outline),
                        filled: true,
                        fillColor: const Color(0xFFE3E9EC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SECURE PASSWORD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: Color(0xFF586062),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF006B55),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordController,
                      focusNode: passwordFocusNode,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) async {
                        await onLogin();
                      },
                      onChanged: (_) async {
                        await onCredentialsChanged();
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: onTogglePassword,
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFE3E9EC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          activeColor: const Color(0xFF006B55),
                          onChanged: (value) async {
                            await onRememberChanged(value);
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Remember this session',
                            style: TextStyle(
                              color: Color(0xFF586062),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF006B55), Color(0xFF00B894)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 184, 148, 0.25),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await onLogin();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Text(
                            'Login to Sanctuary',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          label: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 14),
                    Center(
                      child: RichText(
                        text: const TextSpan(
                          text: 'New to our sanctuary? ',
                          style: TextStyle(
                            color: Color(0xFF586062),
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Request an Invite',
                              style: TextStyle(
                                color: Color(0xFF006B55),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 8,
              children: const [
                Text(
                  'Privacy Protocols',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.6,
                    color: Color(0xFF6C7A74),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Access Policy',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.6,
                    color: Color(0xFF6C7A74),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Digital Safety',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.6,
                    color: Color(0xFF6C7A74),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}