import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_model.dart';
import '../../routes/route_names.dart';
import '../../services/auth_service.dart';

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
  bool isLoggingIn = false;

  List<String> recentEmails = [];

  static const String rememberMeKey = 'remember_me';
  static const String savedEmailKey = 'saved_email';
  static const String savedPasswordKey = 'saved_password';
  static const String recentEmailsKey = 'recent_emails';

  @override
  void initState() {
    super.initState();
    initializePage();
  }

  Future<void> initializePage() async {
    await AuthService.seedSuperAdmin();
    await loadSavedCredentials();
  }

  Future<void> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    rememberMe = prefs.getBool(rememberMeKey) ?? false;
    emailController.text = prefs.getString(savedEmailKey) ?? '';
    passwordController.text = prefs.getString(savedPasswordKey) ?? '';
    recentEmails = prefs.getStringList(recentEmailsKey) ?? [];

    if (mounted) {
      setState(() => isLoading = false);
    }
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

    final email = emailController.text.trim();

    if (email.isNotEmpty && !recentEmails.contains(email)) {
      recentEmails.insert(0, email);

      if (recentEmails.length > 5) {
        recentEmails.removeLast();
      }

      await prefs.setStringList(recentEmailsKey, recentEmails);
    }
  }

  String normalizeRole(String role) {
    return role.toLowerCase().trim().replaceAll(' ', '_');
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoggingIn = true);

    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      final UserModel user = await AuthService.login(
        email: email,
        password: password,
      );

      await saveCredentials();

      if (!mounted) return;

      final role = normalizeRole(user.role);

      if (role == 'super_admin' || role == 'superadmin') {
        Navigator.pushReplacementNamed(
          context,
          RouteNames.superAdminDashboard,
          arguments: user,
        );
      } else if (role == 'client_admin' ||
          role == 'clientadmin' ||
          role == 'client') {
        if (user.mustChangePassword == true || user.profileCompleted == false) {
          Navigator.pushReplacementNamed(
            context,
            RouteNames.clientFirstSetup,
            arguments: user,
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            RouteNames.clientDashboard,
            arguments: user,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unknown user role detected: ${user.role}')),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('System error: $e')),
      );
    }

    if (mounted) {
      setState(() => isLoggingIn = false);
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                recentEmails: recentEmails,
                isLoggingIn: isLoggingIn,
                onTogglePassword: () {
                  setState(() => obscurePassword = !obscurePassword);
                },
                onRememberChanged: (v) {
                  setState(() => rememberMe = v ?? false);
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
                recentEmails: recentEmails,
                isLoggingIn: isLoggingIn,
                onTogglePassword: () {
                  setState(() => obscurePassword = !obscurePassword);
                },
                onRememberChanged: (v) {
                  setState(() => rememberMe = v ?? false);
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
                color: const Color(0xFF00B894).withOpacity(0.14),
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
                color: const Color(0xFF4BDDB7).withOpacity(0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.spa, size: 90, color: Colors.white),
                  SizedBox(height: 35),
                  Text(
                    'Serenity Massage and Spa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Reclaiming clinical precision in the art of tranquility.\nWelcome back to your personal sanctuary.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFBBCAC3),
                      fontSize: 16,
                      height: 1.6,
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
  final bool isLoggingIn;
  final List<String> recentEmails;
  final ValueChanged<bool?> onRememberChanged;
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
    required this.isLoggingIn,
    required this.recentEmails,
    required this.onRememberChanged,
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
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue value) {
                        if (value.text.isEmpty) {
                          return recentEmails;
                        }

                        return recentEmails.where(
                              (e) => e.toLowerCase().contains(
                            value.text.toLowerCase(),
                          ),
                        );
                      },
                      onSelected: (value) {
                        emailController.text = value;
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onEditingComplete) {
                        controller.text = emailController.text;

                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onChanged: (v) => emailController.text = v,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(
                              passwordFocusNode,
                            );
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.mail_outline),
                            hintText: 'Institutional Email',
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
                        );
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
                      onFieldSubmitted: (_) async => await onLogin(),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: 'Secure Password',
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
                          onChanged: onRememberChanged,
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
                            colors: [
                              Color(0xFF006B55),
                              Color(0xFF00B894),
                            ],
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
                          onPressed: isLoggingIn
                              ? null
                              : () async {
                            await onLogin();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: isLoggingIn
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'Login to Sanctuary',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          label: isLoggingIn
                              ? const SizedBox()
                              : const Icon(
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