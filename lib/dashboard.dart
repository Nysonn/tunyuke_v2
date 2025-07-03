import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();

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

    // Create staggered animations for cards
    _cardAnimations = List.generate(4, (index) {
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
    });

    // Start animations after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          _staggerController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
          child: Column(
            children: [
              // Enhanced App Bar
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // Logo with consistent styling from welcome page
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.15),
                              blurRadius: 10.0,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Container(
                            height: 50.0,
                            width: 50.0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Image.network(
                              'https://res.cloudinary.com/df3lhzzy7/image/upload/v1749768253/unnamed_p6zzod.jpg',
                              height: 50.0,
                              width: 50.0,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 50.0,
                                  width: 50.0,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 25.0,
                                    color: Colors.grey[400],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.0),
                      // App title with gradient styling
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              theme.primaryColor,
                              theme.primaryColor.withOpacity(0.8),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            "Tunyuke Dashboard",
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dashboard Cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    children: [
                      _buildDashboardCard(
                        context: context,
                        index: 0,
                        icon: Icons.arrow_forward_rounded,
                        title: "To Kihumuro Campus",
                        onTap: () => Navigator.pushNamed(context, '/to_campus'),
                        gradientColors: [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      _buildDashboardCard(
                        context: context,
                        index: 1,
                        icon: Icons.arrow_back_rounded,
                        title: "From Kihumuro Campus",
                        onTap: () =>
                            Navigator.pushNamed(context, '/from_campus'),
                        gradientColors: [
                          theme.primaryColor.withOpacity(0.8),
                          theme.primaryColor.withOpacity(0.6),
                        ],
                      ),
                      _buildDashboardCard(
                        context: context,
                        index: 2,
                        icon: Icons.group_rounded,
                        title: "Schedule a Team Ride",
                        onTap: () =>
                            Navigator.pushNamed(context, '/schedule_team_ride'),
                        gradientColors: [
                          theme.primaryColor.withOpacity(0.9),
                          theme.primaryColor.withOpacity(0.7),
                        ],
                      ),
                      _buildDashboardCard(
                        context: context,
                        index: 3,
                        icon: Icons.people_outline_rounded,
                        title: "Onboard on a Scheduled Team Ride",
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/onboard_scheduled_ride',
                        ),
                        gradientColors: [
                          theme.primaryColor.withOpacity(0.7),
                          theme.primaryColor.withOpacity(0.5),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required List<Color> gradientColors,
  }) {
    return AnimatedBuilder(
      animation: _cardAnimations[index],
      builder: (context, child) {
        // Clamp the animation values to ensure they stay within valid ranges
        final animationValue = _cardAnimations[index].value.clamp(0.0, 1.0);

        return Transform.scale(
          scale: animationValue,
          child: Opacity(
            opacity: animationValue,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.white.withOpacity(0.95)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    blurRadius: 12.0,
                    offset: Offset(0, 6),
                    spreadRadius: 1.0,
                  ),
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 8.0,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  width: 1.0,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20.0),
                  splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  highlightColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.05),
                  child: Container(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon with gradient background
                        Container(
                          padding: EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors[0].withOpacity(0.25),
                                blurRadius: 8.0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(icon, size: 28.0, color: Colors.white),
                        ),
                        SizedBox(height: 14.0),
                        // Title with enhanced typography
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            letterSpacing: 0.2,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
