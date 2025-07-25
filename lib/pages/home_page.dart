// import 'package:flutter/material.dart';

// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF007C91),
//       body: Stack(
//         children: [
//           Align(
//             alignment: Alignment.center,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 30),
//               child: Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(35),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black12,
//                       blurRadius: 16,
//                       offset: Offset(0, 8),
//                     )
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text(
//                       "Welcome!",
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF007C91),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       "Track your SACCO savings\nfrom anywhere, anytime.",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Color(0xFF007C91),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 36, vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(25),
//                         ),
//                       ),
//                       onPressed: () {
//                         Navigator.pushNamed(context, '/register');
//                       },
//                       child: const Text(
//                         "Register",
//                         style: TextStyle(color: Colors.white, fontSize: 16),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Color(0xFF007C91),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 40, vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(25),
//                         ),
//                       ),
//                       onPressed: () {
//                         Navigator.pushNamed(context, '/login');
//                       },
//                       child: const Text(
//                         "Login",
//                         style: TextStyle(color: Colors.white, fontSize: 16),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isMediumScreen = screenSize.width >= 400 && screenSize.width < 600;
    final isLargeScreen = screenSize.width >= 600;
    
    // Responsive sizing
    final horizontalPadding = isSmallScreen ? 20.0 : isMediumScreen ? 30.0 : 40.0;
    final titleFontSize = isSmallScreen ? 32.0 : isMediumScreen ? 36.0 : 40.0;
    final subtitleFontSize = isSmallScreen ? 18.0 : isMediumScreen ? 20.0 : 22.0;
    final bodyFontSize = isSmallScreen ? 14.0 : isMediumScreen ? 15.0 : 16.0;
    final buttonPadding = isSmallScreen 
        ? const EdgeInsets.symmetric(horizontal: 32, vertical: 12)
        : isMediumScreen 
            ? const EdgeInsets.symmetric(horizontal: 36, vertical: 14)
            : const EdgeInsets.symmetric(horizontal: 40, vertical: 16);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF007C91),
              Color(0xFF005A6B),
              Color(0xFF003D47),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenSize.height - MediaQuery.of(context).padding.top,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        // Header Section
                        SizedBox(height: isSmallScreen ? 40 : 60),
                        
                        // App Logo/Icon
                        Container(
                          width: isSmallScreen ? 80 : isMediumScreen ? 100 : 120,
                          height: isSmallScreen ? 80 : isMediumScreen ? 100 : 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.account_balance,
                            size: isSmallScreen ? 40 : isMediumScreen ? 50 : 60,
                            color: Colors.white,
                          ),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 20 : 30),
                        
                        // Main Title
                        Text(
                          "Smart Sacco",
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        
                        // Subtitle
                        Text(
                          "Secure, Accessible Financial Growth",
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const Spacer(),
                        
                        // Main Content Card
                        SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 20 : 30,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
                              child: Column(
                                children: [
                                  // Welcome Message
                                  Text(
                                    "Welcome!",
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 26 : 28,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF007C91),
                                    ),
                                  ),
                                  
                                  SizedBox(height: isSmallScreen ? 16 : 20),
                                  
                                  // Description Text
                                  Text(
                                    "Secure financial management with accessible savings, loans, and investment tracking. Real-time updates with voice navigation support.",
                                    style: TextStyle(
                                      fontSize: bodyFontSize,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  
                                  SizedBox(height: isSmallScreen ? 16 : 20),
                                  
                                  // Features Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildFeatureIcon(
                                        icon: Icons.security,
                                        label: "Secure",
                                        isSmallScreen: isSmallScreen,
                                      ),
                                      _buildFeatureIcon(
                                        icon: Icons.speed,
                                        label: "Fast",
                                        isSmallScreen: isSmallScreen,
                                      ),
                                      _buildFeatureIcon(
                                        icon: Icons.accessibility,
                                        label: "Accessible",
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: isSmallScreen ? 24 : 32),
                                  
                                  // Action Buttons
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF007C91),
                                            foregroundColor: Colors.white,
                                            padding: buttonPadding,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(25),
                                            ),
                                            elevation: 8,
                                            shadowColor: const Color(0xFF007C91).withOpacity(0.3),
                                          ),
                                          onPressed: () {
                                            Navigator.pushNamed(context, '/register');
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.person_add, size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Join Smart Sacco",
                                                style: TextStyle(
                                                  fontSize: bodyFontSize,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      SizedBox(height: isSmallScreen ? 12 : 16),
                                      
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF007C91),
                                            padding: buttonPadding,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(25),
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFF007C91),
                                              width: 2,
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.pushNamed(context, '/login');
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.login, size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Login",
                                                style: TextStyle(
                                                  fontSize: bodyFontSize,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Footer
                        Padding(
                          padding: EdgeInsets.only(bottom: isSmallScreen ? 20 : 30),
                          child: Text(
                            "Secure • Accessible • Innovative",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureIcon({
    required IconData icon,
    required String label,
    required bool isSmallScreen,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFF007C91),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isSmallScreen ? 20 : 24,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF007C91),
          ),
        ),
      ],
    );
  }
}