import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _rateController = TextEditingController(text: '50');
  String _currency = 'USD';

  final _pages = const [
    _OnboardingPage(
      emoji: '⚡',
      title: 'Welcome to Hustle',
      subtitle: 'The all-in-one app for freelancers.\nTrack time, manage tasks, and get paid.',
      color: AppTheme.primaryColor,
    ),
    _OnboardingPage(
      emoji: '⏱️',
      title: 'Track Every Minute',
      subtitle: 'One tap to start tracking. Never lose a billable hour again.',
      color: AppTheme.secondaryColor,
    ),
    _OnboardingPage(
      emoji: '📋',
      title: 'Manage Tasks',
      subtitle: 'Organize work by client and priority. Stay on top of deadlines.',
      color: Color(0xFFFF6B6B),
    ),
    _OnboardingPage(
      emoji: '💰',
      title: 'Invoice in Seconds',
      subtitle: 'Turn tracked time into professional invoices with one tap.',
      color: AppTheme.successColor,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _businessController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _pages.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (!isLastPage)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _skip,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  ..._pages.map((p) => _PageContent(page: p)),
                  _SetupPage(
                    nameController: _nameController,
                    businessController: _businessController,
                    rateController: _rateController,
                    currency: _currency,
                    onCurrencyChanged: (c) => setState(() => _currency = c),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length + 1, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? AppTheme.primaryColor
                              : Colors.grey.withValues(alpha:0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLastPage ? _complete : _next,
                      child: Text(isLastPage ? "Let's Go! 🚀" : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _skip() {
    _pageController.animateToPage(
      _pages.length,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboarded, true);
    if (_nameController.text.isNotEmpty) {
      await prefs.setString(AppConstants.keyUserName, _nameController.text.trim());
    }
    if (_businessController.text.isNotEmpty) {
      await prefs.setString(AppConstants.keyBusinessName, _businessController.text.trim());
    }
    await prefs.setDouble(AppConstants.keyDefaultRate, double.tryParse(_rateController.text) ?? 50);
    await prefs.setString(AppConstants.keyCurrency, _currency);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(page.emoji, style: const TextStyle(fontSize: 56)),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha:0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SetupPage extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController businessController;
  final TextEditingController rateController;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;

  const _SetupPage({
    required this.nameController,
    required this.businessController,
    required this.rateController,
    required this.currency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Setup',
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tell us a bit about yourself\n(You can change this later)",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha:0.6),
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Your name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: businessController,
            decoration: const InputDecoration(
              hintText: 'Business name (optional)',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),
          Text('Default Hourly Rate', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: currency,
                  decoration: const InputDecoration(),
                  items: AppConstants.currencySymbols.keys
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (c) => onCurrencyChanged(c!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
