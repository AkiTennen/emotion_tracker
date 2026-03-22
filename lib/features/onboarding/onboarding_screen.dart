import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'A place to get to know yourself better',
      description: 'Check in whenever you want, as often as you want. This is about the moment right now—not your morning, not your day, but how you feel this very second. Over time, you\'ll discover patterns and be able to drill deeper.',
      icon: Icons.self_improvement,
      color: Colors.blueGrey,
    ),
    _OnboardingData(
      title: 'A tool for personal insight',
      description: 'This is a warm space for reflection, not a medical tool or a diagnostic app. There is no AI involved and no one is here to judge you. It\'s a companion for your journey, even one you can use alongside therapy.',
      icon: Icons.favorite_outline,
      color: Colors.orangeAccent,
    ),
    _OnboardingData(
      title: 'Your data stays with you',
      description: 'Privacy is our priority. We have no accounts, no cloud, and no servers. Everything stays on your phone. You can back up your data or export it whenever you choose, but it never leaves your device without your action.',
      icon: Icons.lock_outline,
      color: Colors.teal,
    ),
    _OnboardingData(
      title: 'Start simple, get to know yourself',
      description: 'We start with the basics to avoid overwhelm and feature bloat. As you use the app, new layers like intensity sliders and body mapping will reveal themselves. Want it all now? You can unlock everything in Settings.',
      icon: Icons.auto_awesome_outlined,
      color: Colors.indigoAccent,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await SettingsService.setOnboardingShown(true);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final data = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          data.icon,
                          size: 100,
                          color: data.color.withOpacity(0.8),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          data.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  FloatingActionButton.extended(
                    onPressed: _nextPage,
                    label: Text(_currentPage == _pages.length - 1 ? 'Begin' : 'Next'),
                    icon: Icon(_currentPage == _pages.length - 1 ? Icons.check : Icons.arrow_forward),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
