import 'dart:async';
import 'package:flutter/material.dart';
import 'customer_signup_page.dart';
import 'customer_login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_book_page.dart';
import 'customer_login_page.dart';

class CustomerSplashPage extends StatefulWidget {
  const CustomerSplashPage({super.key});

  @override
  State<CustomerSplashPage> createState() => _CustomerSplashPageState();
}

class _CustomerSplashPageState extends State<CustomerSplashPage> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CustomerLandingPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF006B55),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SerenityLogo(size: 96),
              SizedBox(height: 24),
              Text(
                'Serenity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'MASSAGE & SPA',
                style: TextStyle(
                  color: Color(0xFFE6F5EF),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerLandingPage extends StatelessWidget {
  const CustomerLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFD),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  const Row(
                    children: [
                      SerenityLogo(size: 46),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Serenity',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF161D1F),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'MASSAGE & SPA',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF006B55),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 92),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00B894).withOpacity(0.14),
                          blurRadius: 36,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F5EF),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: SerenityLogo(
                              size: 48,
                              greenBackground: false,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Relax. Restore. Renew.',
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: TextStyle(
                            color: Color(0xFF161D1F),
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Book your massage and spa appointment with ease. Choose your service, preferred schedule, and therapist in one place.',
                          textAlign: TextAlign.center,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: Color(0xFF586062),
                            fontSize: 13,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              final user = FirebaseAuth.instance.currentUser;

                              if (user != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CustomerBookPage(),
                                  ),
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Login Required'),
                                    content: const Text(
                                      'Please login first before booking an appointment.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const CustomerLoginPage(),
                                            ),
                                          );
                                        },
                                        child: const Text('Login'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A884),
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: const Color(0x5900B894),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Book Appointment',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CustomerLoginPage(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF006B55),
                              side: const BorderSide(
                                color: Color(0xFF00B894),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 82),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerSignupPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'New here? Register Now',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF006B55),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SerenityLogo extends StatelessWidget {
  final double size;
  final bool greenBackground;

  const SerenityLogo({
    super.key,
    required this.size,
    this.greenBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: greenBackground
            ? const LinearGradient(
          colors: [Color(0xFF00B894), Color(0xFF006B55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: greenBackground ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(
        Icons.spa,
        color: greenBackground ? Colors.white : const Color(0xFF006B55),
        size: size * 0.55,
      ),
    );
  }
}