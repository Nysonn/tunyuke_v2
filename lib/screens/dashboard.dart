import 'package:Tunyuke/components/dashboard/dashboard_app_bar.dart';
import 'package:Tunyuke/components/dashboard/dashboard_bottom_nav_bar.dart';
import 'package:Tunyuke/components/dashboard/dashboard_cards_grid.dart';
import 'package:flutter/material.dart';
import 'package:Tunyuke/controllers/dashboard_controller.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late DashboardController _dashboardController; // Instance of our controller
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();

    _dashboardController = DashboardController();

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Create staggered animations for cards using data from the controller
    _cardAnimations = List.generate(
      _dashboardController.dashboardCardsData.length,
      (index) {
        return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(
              index * 0.1,
              0.4 + (index * 0.1),
              curve: Curves.easeOutBack,
            ),
          ),
        );
      },
    );

    // Start animations after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          _staggerController.forward();
        }
      });
    });

    // Listen to changes from the controller to rebuild UI
    _dashboardController.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    // This will trigger a rebuild when data in the controller changes (e.g., greeting, current index)
    setState(() {
      // The ValueNotifiers handle the specific data, no need to copy them here
    });
  }

  @override
  void dispose() {
    _dashboardController.removeListener(
      _onControllerChange,
    ); // Important to remove listener
    _dashboardController
        .dispose(); // Dispose the controller if it's no longer needed
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Use ValueListenableBuilder to rebuild only the AppBar when greeting/userName changes
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ValueListenableBuilder<String>(
          valueListenable: _dashboardController.currentTimeGreeting,
          builder: (context, greeting, child) {
            return ValueListenableBuilder<String>(
              valueListenable: _dashboardController.userName,
              builder: (context, userName, child) {
                return DashboardAppBar(
                  greeting: greeting,
                  userName: userName,
                  theme: theme,
                );
              },
            );
          },
        ),
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.05),
              Colors.white,
              theme.primaryColor.withOpacity(0.02),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            // Apply fade animation to the whole body content
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: DashboardCardsGrid(
                      cardsData: _dashboardController.dashboardCardsData,
                      cardAnimations: _cardAnimations,
                      onCardTapped: (routeName) => _dashboardController
                          .onDashboardCardTapped(context, routeName),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _dashboardController.currentIndex,
        builder: (context, currentIndex, child) {
          return DashboardBottomNavBar(
            currentIndex: currentIndex,
            onItemTapped: (index) =>
                _dashboardController.onBottomNavItemTapped(index, context),
            theme: theme,
          );
        },
      ),
    );
  }
}
