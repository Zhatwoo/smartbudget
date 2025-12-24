import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:async';
import '../widgets/addexpenses.dart';
import 'expensesincomelist.dart';
import '../widgets/humbergersidebar.dart';
import '../widgets/notifications.dart';
import 'inflationTracker.dart';
import '../widgets/flower_petals_menu.dart';
import '../utils/route_transitions.dart';
import '../providers/providers.dart';
import '../models/transaction_model.dart';
import '../models/bill_model.dart';
import '../models/upcoming_bill_model.dart';
import '../models/inflation_item_model.dart';

// CustomClipper for curved header bottom edge
class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30); // Start curve
    path.quadraticBezierTo(
      size.width / 2, size.height, // Control point (creates arc)
      size.width, size.height - 30, // End point
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  
  late AnimationController _balanceAnimationController;
  late Animation<double> _balanceAnimation;
  late ScrollController _scrollController;
  late AnimationController _pieChartAnimationController;
  late Animation<Offset> _pieChartSlideAnimation;
  double _scrollOffset = 0.0;
  bool _showPieChart = false;
  int _currentInflationAlertIndex = 0;
  double _cardDragOffset = 0.0;
  bool _isDragging = false;
  
  // Double tap detection
  DateTime? _lastTap;
  Timer? _tapTimer;

  // Totals are now provided by providers - no need to calculate here

  // Calculate category spending from transactions
  List<CategorySpending> _calculateCategorySpending(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    // Filter transactions for current month
    final monthlyTransactions = transactions.where((t) => 
      t.date.isAfter(startOfMonth.subtract(const Duration(days: 1)))
    ).toList();

    // Group by category and sum expenses
    final categoryMap = <String, double>{};
    for (var transaction in monthlyTransactions) {
      if (transaction.type == 'expense') {
        categoryMap[transaction.category] = 
            (categoryMap[transaction.category] ?? 0) + transaction.amount.abs();
      }
    }

    // Map to CategorySpending with colors
    final categoryColors = {
      'Food': const Color(0xFFE74C3C),
      'Transport': const Color(0xFF4A90E2),
      'Bills': const Color(0xFFF39C12),
      'Shopping': const Color(0xFF27AE60),
      'Entertainment': const Color(0xFF9B59B6),
      'Healthcare': const Color(0xFFE67E22),
      'Education': const Color(0xFF3498DB),
      'Other': const Color(0xFF95A5A6),
    };

    final categoryEmojis = {
      'Food': '🍔',
      'Transport': '🚗',
      'Bills': '💡',
      'Shopping': '🛍️',
      'Entertainment': '🎬',
      'Healthcare': '🏥',
      'Education': '📚',
      'Other': '📦',
    };

    final categoryList = categoryMap.entries.map((entry) {
      return CategorySpending(
        name: entry.key,
        amount: entry.value,
        color: categoryColors[entry.key] ?? const Color(0xFF95A5A6),
        emoji: categoryEmojis[entry.key] ?? '📦',
      );
    }).toList();

    // Sort by amount descending and take top 4
    categoryList.sort((a, b) => b.amount.compareTo(a.amount));
    return categoryList.take(4).toList();
  }

  // Get recent transactions (last 4)
  List<Transaction> _getRecentTransactions(List<TransactionModel> transactions) {
    return transactions.take(4).map((t) {
      return Transaction(
        title: t.title,
        category: t.category,
        amount: t.type == 'expense' ? -t.amount.abs() : t.amount.abs(),
        date: t.date,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _balanceAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _balanceAnimation = CurvedAnimation(
      parent: _balanceAnimationController,
      curve: Curves.easeOutCubic,
    );
    _balanceAnimationController.forward();
    
    // Initialize scroll controller
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Initialize pie chart animation controller
    _pieChartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pieChartSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // Start from top (above view)
      end: Offset.zero, // End at normal position
    ).animate(CurvedAnimation(
      parent: _pieChartAnimationController,
      curve: Curves.easeOut,
    ));
    
    // Initialize inflation alerts page controller
    
    // Ensure default inflation items are initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inflationService = ref.read(inflationServiceProvider);
      inflationService.ensureDefaultItemsInitialized().catchError((e) {
        // Silently fail
      });
    });
  }
  
  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _balanceAnimationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pieChartAnimationController.dispose();
    _tapTimer?.cancel();
    super.dispose();
  }
  
  void _showFlowerPetalsMenu(BuildContext fabContext) {
    // Get FAB position
    final RenderBox? renderBox = fabContext.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final centerPosition = Offset(
        position.dx + size.width / 2,
        position.dy + size.height / 2,
      );
      FlowerPetalsMenu.show(context, centerPosition);
    }
  }
  
  void _handleFabTap(BuildContext fabContext) {
    final now = DateTime.now();
    
    // Cancel any existing timer
    _tapTimer?.cancel();
    
    if (_lastTap != null && now.difference(_lastTap!) < const Duration(milliseconds: 300)) {
      // Double tap detected
      _lastTap = null;
      _showFlowerPetalsMenu(fabContext);
    } else {
      // Single tap - wait to see if it's a double tap
      _lastTap = now;
      _tapTimer = Timer(const Duration(milliseconds: 300), () {
        // Single tap confirmed - open add transaction screen
        if (_lastTap != null) {
          _openAddTransactionScreen();
          _lastTap = null;
        }
      });
    }
  }
  
  void _openAddTransactionScreen() async {
    final result = await Navigator.of(context).push(
      SlideUpPageRoute(
        child: const AddExpenseIncomeScreen(),
      ),
    );
    
    // If transaction was saved, refresh the dashboard
    if (result == true) {
      // TODO: Refresh dashboard data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dashboard will be updated'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get data from providers (UI → Provider → Service → Firebase)
    final transactionsAsync = ref.watch(transactionsProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final totalIncome = ref.watch(totalIncomeProvider);
    final totalExpenses = ref.watch(totalExpensesProvider);
    final recentTransactionsList = ref.watch(recentTransactionsProvider);
    final inflationItemsAsync = ref.watch(inflationItemsProvider);
    final unreadNotificationsCount = ref.watch(unreadNotificationsCountProvider);
    
    // Handle loading state
    if (transactionsAsync.isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    
    final transactions = transactionsAsync.value ?? [];
    
    // Calculate category spending
    final categorySpending = _calculateCategorySpending(transactions);
    
    // Get recent transactions (convert to Transaction model for UI)
    final recentTransactions = _getRecentTransactions(transactions);
  
  // Helper method to combine user-input bills and auto-detected bills
  List<dynamic> _getCombinedBills(WidgetRef ref) {
    final userBillsAsync = ref.watch(billsProvider);
    final autoDetectedBills = ref.watch(upcomingBillsProvider);
    
    final allBills = <dynamic>[];
    
    // Add user-input bills (handle errors gracefully)
    userBillsAsync.when(
      data: (bills) {
        allBills.addAll(bills);
      },
      loading: () {
        // Still loading, don't add anything yet
      },
      error: (error, stack) {
        // Silently fail - just don't add user bills
      },
    );
    
    // Add auto-detected bills
    allBills.addAll(autoDetectedBills);
    
    // Sort by due date
    allBills.sort((a, b) {
      DateTime dateA, dateB;
      if (a is BillModel) {
        dateA = a.dueDate;
      } else {
        dateA = (a as UpcomingBillModel).dueDate;
      }
      if (b is BillModel) {
        dateB = b.dueDate;
      } else {
        dateB = (b as UpcomingBillModel).dueDate;
      }
      return dateA.compareTo(dateB);
    });
    
    return allBills;
  }
        
        final screenHeight = MediaQuery.of(context).size.height;
        final headerHeight = screenHeight * 0.33;
        final whiteSectionInitialTop = screenHeight * 0.28;
        
        // Calculate the height of profile/bell icon row area (should remain visible)
        // Top padding (12) + SafeArea top + icon height (40) + spacing = ~80-90px
        final profileRowHeight = 90.0;
        
        // Maximum translate: white section should stop just below profile/bell icons
        // This allows it to cover Total Balance section while keeping icons visible
        // maxTranslateY = distance from initial position to just below icons
        final maxTranslateY = whiteSectionInitialTop - profileRowHeight;
        
        // Calculate translate Y based on scroll offset
        // When scroll = 0: translateY = 0 (initial position)
        // When scroll > 0: translateY becomes negative (moves up)
        // Maximum: when white section reaches just below profile/bell icons
        final translateY = -(_scrollOffset.clamp(0.0, maxTranslateY));
        
        return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5), // Light gray background
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Blue Header Section (upper third of screen)
            // This stays in place, profile/bell icons remain visible
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: ClipPath(
                clipper: _CurvedHeaderClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4A90E2), // Bright Blue
                        Color(0xFF5DADE2), // Light Blue
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Row: Profile, Notification
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Profile Icon
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed('/settings');
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                            
                            // Notification Bell Icon with Badge
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed('/notifications');
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  // Unread badge (dynamic from provider)
                                  if (unreadNotificationsCount > 0)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          unreadNotificationsCount > 99 ? '99+' : unreadNotificationsCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02), // Reduced spacing
                        
                        // Total Balance Text
                        FadeTransition(
                          opacity: _balanceAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Total Balance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              FadeTransition(
                                opacity: _balanceAnimation,
                                child: Text(
                                  '₱${totalBalance.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12), // Reduced from 20
                              
                              // Income and Expenses Display
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    // Income
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.trending_up_rounded,
                                                color: Colors.white,
                                                size: 16, // Reduced from 18
                                              ),
                                              const SizedBox(width: 4), // Reduced from 6
                                              Text(
                                                'Income',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 11, // Reduced from 12
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6), // Reduced from 8
                                          Text(
                                            '₱${totalIncome.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16, // Reduced from 18
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Divider
                                    Container(
                                      width: 1.5,
                                      height: 35, // Reduced from 40
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.white.withOpacity(0.5),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    // Expenses
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.trending_down_rounded,
                                                color: Colors.white,
                                                size: 16, // Reduced from 18
                                              ),
                                              const SizedBox(width: 4), // Reduced from 6
                                              Text(
                                                'Expenses',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 11, // Reduced from 12
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6), // Reduced from 8
                                          Text(
                                            '₱${totalExpenses.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16, // Reduced from 18
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // White Body Section (starts below header, overlaps slightly, animates up on scroll)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              top: whiteSectionInitialTop + translateY,
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: Container(
                  color: Colors.white,
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        16.0, 
                        // Add extra top padding when white section covers header
                        // This ensures content doesn't get cut off
                        20.0 + (translateY.abs() > 0 ? headerHeight * 0.3 : 0), 
                        16.0, 
                        100.0
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Monthly Spending (Pie Chart)
                          _buildCategorySpendingSection(categorySpending),
                          const SizedBox(height: 20),

                          // Inflation Alerts (from Inflation Tracker)
                          _buildInflationAlertsSection(inflationItemsAsync),
                          const SizedBox(height: 20),

                          // Upcoming Bills (from user input + auto-detected)
                          _buildUpcomingBillsSection(_getCombinedBills(ref)),
                          const SizedBox(height: 20),

                          // Recent Transactions
                          _buildRecentTransactionsSection(recentTransactions),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.05,
        ),
        child: Transform.scale(
          scale: 1.05,
          child: Builder(
            builder: (fabContext) {
              return GestureDetector(
                onLongPress: () {
                  _showFlowerPetalsMenu(fabContext);
                },
                child: FloatingActionButton(
                  onPressed: () {
                    _handleFabTap(fabContext);
                  },
                  child: const Icon(Icons.add_rounded, size: 28),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  tooltip: 'Tap to add transaction, double tap or hold for menu',
                  shape: const CircleBorder(),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCategorySpendingSection(List<CategorySpending> categorySpending) {
    if (categorySpending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'No spending data yet',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    
    final total = categorySpending.fold<double>(
      0,
      (sum, category) => sum + category.amount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monthly Spending',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '₱${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Single Row with 4 Category Cards
        SizedBox(
          height: 110, // Reduced from 120 to fix overflow
          child: Row(
            children: categorySpending.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              final percentage = (category.amount / total * 100);
              return Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: percentage),
                  duration: Duration(milliseconds: 600 + (index * 80)),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedPercentage, child) {
                    return Padding(
                      padding: EdgeInsets.only(right: index < categorySpending.length - 1 ? 8 : 0),
                      child: InkWell(
                        onTap: () => _navigateToExpenses(category.name),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8), // Reduced from 10
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Emoji Icon
                              Container(
                                width: 36, // Reduced from 40
                                height: 36, // Reduced from 40
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    category.emoji ?? '📦',
                                    style: const TextStyle(fontSize: 18), // Reduced from 20
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4), // Reduced from 6
                              // Category Name
                              Text(
                                category.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10, // Reduced from 11
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3), // Reduced from 4
                              // Percentage
                              Text(
                                '${animatedPercentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 13, // Reduced from 14
                                  fontWeight: FontWeight.bold,
                                  color: category.color,
                                ),
                              ),
                              const SizedBox(height: 1), // Reduced from 2
                              // Amount
                              Text(
                                '₱${(category.amount / 1000).toStringAsFixed(0)}k',
                                style: TextStyle(
                                  fontSize: 9, // Reduced from 10
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        
        // Expandable Pie Chart Section (above expand button)
        if (_showPieChart)
          SlideTransition(
            position: _pieChartSlideAnimation,
            child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Centered Pie Chart
                      Center(
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            painter: PieChartPainter(categorySpending, total > 0 ? total : 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Full Expense Details with Amounts
                      ...categorySpending.map((category) {
                        final percentage = total > 0 ? (category.amount / total * 100) : 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: category.color.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Color Indicator
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: category.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Category Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          category.emoji ?? '📦',
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          category.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: category.color,
                                          ),
                                        ),
                                        Text(
                                          '₱${category.amount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
            ),
          ),
        
        // Expand Button (Down arrow icon only, centered, no border)
        Center(
          child: InkWell(
            onTap: () {
              setState(() {
                _showPieChart = !_showPieChart;
                if (_showPieChart) {
                  _pieChartAnimationController.forward();
                } else {
                  _pieChartAnimationController.reverse();
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInflationAlertsSection(AsyncValue<List<InflationItemModel>> inflationItemsAsync) {
    return inflationItemsAsync.when(
      data: (items) {
        // Convert inflation items to alerts
        final inflationAlerts = items.map((item) {
          return InflationAlert(
            item: item.name,
            change: item.percentageChange,
            isIncrease: item.isIncrease,
          );
        }).toList();
        
        return _buildInflationAlertsContent(inflationAlerts);
      },
      loading: () => Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Error loading inflation data',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInflationAlertsContent(List<InflationAlert> inflationAlerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Inflation Alerts',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // 3D Card Stacking with Swipe Navigation (React-inspired)
        if (inflationAlerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.trending_up_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No inflation alerts',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 161,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
              // Render cards in reverse order (back cards first, active card last so it's on top)
              // Support looping - show next cards even when at end/start
              ...(inflationAlerts.isEmpty 
                ? []
                : List.generate(
                  math.min(3, inflationAlerts.length), // Show current + next 2 cards (or less if not enough)
                  (i) {
                    // Calculate actual index with looping
                    int actualIndex = ((_currentInflationAlertIndex + i) % inflationAlerts.length).toInt();
                    int stackPosition = i;
                    
                    final alert = inflationAlerts[actualIndex];
                    final isActive = stackPosition == 0;
                    
                    // Calculate 3D transform values (similar to React component)
                    // translateZ: -8px per stack position (reduced for smaller cards)
                    // translateY: 5px per stack position (reduced for smaller cards)
                    // translateX: drag offset for active card only
                    // rotateY: rotation based on drag (0.2 degrees per pixel, converted to radians)
                    double translateZ = -8.0 * stackPosition;
                    double translateY = 5.0 * stackPosition;
                    double translateX = isActive ? _cardDragOffset : 0.0;
                    double rotateY = isActive ? (_cardDragOffset * 0.2) * (math.pi / 180) : 0.0; // 0.2 degrees per pixel
                    double opacity = isActive 
                        ? (1.0 - (math.min(_cardDragOffset.abs() / 100, 1.0) * 0.75)).clamp(0.25, 1.0)
                        : 1.0; // Full opacity for stacked cards
                    
                    Widget cardWidget = Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: _isDragging 
                            ? const Duration(milliseconds: 0) 
                            : const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // Perspective (700px equivalent)
                            ..translate(translateX, translateY, translateZ)
                            ..rotateY(rotateY),
                          child: Opacity(
                            opacity: opacity,
                            child: _buildInflationCard(alert, isActive, _isDragging),
                          ),
                        ),
                      ),
                    );
                    
                    // Cards behind are not interactive - use IgnorePointer to prevent any interaction
                    if (!isActive) {
                      return IgnorePointer(
                        ignoring: true,
                        child: cardWidget,
                      );
                    }
                    
                    // Return non-wrapped card for now - we'll wrap active card separately
                    return cardWidget;
                  },
                ).reversed.toList()), // Reverse to render active card last (on top)
              // Active card with gesture detector - rendered last so it's on top
              if (inflationAlerts.isNotEmpty)
                Builder(
                  builder: (context) {
                    final alert = inflationAlerts[_currentInflationAlertIndex];
                    final stackPosition = 0;
                    
                    double translateZ = -8.0 * stackPosition;
                    double translateY = 5.0 * stackPosition;
                    double translateX = _cardDragOffset;
                    double rotateY = (_cardDragOffset * 0.2) * (math.pi / 180);
                    double opacity = (1.0 - (math.min(_cardDragOffset.abs() / 100, 1.0) * 0.75)).clamp(0.25, 1.0);
                    
                    Widget activeCardWidget = Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: _isDragging 
                            ? const Duration(milliseconds: 0) 
                            : const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..translate(translateX, translateY, translateZ)
                            ..rotateY(rotateY),
                          child: Opacity(
                            opacity: opacity,
                            child: _buildInflationCard(alert, true, _isDragging),
                          ),
                        ),
                      ),
                    );
                    
                    return GestureDetector(
                      onHorizontalDragStart: (details) {
                        setState(() {
                          _isDragging = true;
                          _cardDragOffset = 0.0;
                        });
                      },
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _cardDragOffset += details.primaryDelta!;
                        });
                      },
                      onHorizontalDragEnd: (details) {
                        setState(() {
                          _isDragging = false;
                        });
                        
                        final threshold = 50.0;
                        final velocity = details.primaryVelocity ?? 0.0;
                        
                        if (_cardDragOffset.abs() > threshold || velocity.abs() > 500) {
                          if (_cardDragOffset > 0 || velocity > 0) {
                            // Swipe right - go to previous (loop to last if at first)
                            setState(() {
                              if (inflationAlerts.isNotEmpty) {
                                _currentInflationAlertIndex = ((_currentInflationAlertIndex - 1 + inflationAlerts.length) % inflationAlerts.length).toInt();
                              }
                              _cardDragOffset = 0.0;
                            });
                          } else {
                            // Swipe left - go to next (loop to first if at last)
                            setState(() {
                              if (inflationAlerts.isNotEmpty) {
                                _currentInflationAlertIndex = ((_currentInflationAlertIndex + 1) % inflationAlerts.length).toInt();
                              }
                              _cardDragOffset = 0.0;
                            });
                          }
                        } else {
                          setState(() {
                            _cardDragOffset = 0.0;
                          });
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: activeCardWidget,
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInflationTrackerSummary(AsyncValue<List<InflationItemModel>> inflationItemsAsync) {
    return inflationItemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.track_changes_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Inflation Tracker',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/inflation-tracker');
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length > 5 ? 5 : items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final percentageChange = item.percentageChange;
                  final isIncrease = item.isIncrease;
                  
                  return Container(
                    width: 140,
                    margin: EdgeInsets.only(
                      right: index == (items.length > 5 ? 4 : items.length - 1) ? 0 : 12,
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed('/inflation-tracker');
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _getColorFromString(item.color).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getIconFromString(item.icon),
                                    color: _getColorFromString(item.color),
                                    size: 18,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isIncrease
                                        ? const Color(0xFFE74C3C).withOpacity(0.1)
                                        : const Color(0xFF27AE60).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${isIncrease ? '+' : ''}${percentageChange.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isIncrease
                                          ? const Color(0xFFE74C3C)
                                          : const Color(0xFF27AE60),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₱${item.currentPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  item.unit,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  // Helper functions for inflation tracker summary
  Color _getColorFromString(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF4A90E2);
    }
  }

  IconData _getIconFromString(String iconString) {
    final iconMap = {
      'rice_bowl': Icons.rice_bowl,
      'local_drink': Icons.local_drink,
      'egg': Icons.egg,
      'local_gas_station': Icons.local_gas_station,
      'breakfast_dining': Icons.breakfast_dining,
      'shopping_cart': Icons.shopping_cart_rounded,
    };
    return iconMap[iconString] ?? Icons.shopping_cart_rounded;
  }

  Widget _buildInflationCard(InflationAlert alert, bool isActive, bool isDragging) {
    // Green for decrease, Red for increase
    final borderColor = alert.isIncrease 
        ? const Color(0xFFE74C3C) // Red for increase
        : const Color(0xFF27AE60); // Green for decrease
    final alertColor = borderColor;
    
    return InkWell(
      onTap: isActive && !_isDragging ? () {
        Navigator.of(context).pushNamed('/inflation-tracker');
      } : null, // Disable tap when dragging
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 7,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Minimalist Icon Container
            Container(
              width: 41,
              height: 41,
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                alert.isIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: alertColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    alert.item,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: alertColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${alert.isIncrease ? '+' : ''}${alert.change.toStringAsFixed(1)}% this month',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
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

  Widget _buildUpcomingBillsSection(List<dynamic> upcomingBills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Upcoming Bills',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (upcomingBills.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No upcoming bills',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: upcomingBills.length,
              itemBuilder: (context, index) {
                final bill = upcomingBills[index];
                
                // Handle both BillModel and UpcomingBillModel
                int daysUntilDue;
                Color borderColor;
                Color statusColor;
                String dueText;
                String billTitle;
                double billAmount;
                IconData billIcon;
                DateTime billDueDate;
                
                if (bill is BillModel) {
                  daysUntilDue = bill.daysUntilDue;
                  borderColor = bill.isOverdue 
                      ? const Color(0xFFE74C3C)
                      : bill.isDueSoon
                          ? const Color(0xFFF39C12)
                          : Colors.grey.withOpacity(0.3);
                  statusColor = bill.statusColor;
                  dueText = bill.statusText;
                  billTitle = bill.title;
                  billAmount = bill.amount;
                  billIcon = bill.icon;
                  billDueDate = bill.dueDate;
                } else {
                  final upBill = bill as UpcomingBillModel;
                  daysUntilDue = upBill.daysUntilDue;
                  borderColor = upBill.isOverdue 
                      ? const Color(0xFFE74C3C)
                      : upBill.isDueSoon
                          ? const Color(0xFFF39C12)
                          : Colors.grey.withOpacity(0.3);
                  statusColor = upBill.statusColor;
                  dueText = upBill.statusText;
                  billTitle = upBill.title;
                  billAmount = upBill.amount;
                  billIcon = upBill.icon;
                  billDueDate = upBill.dueDate;
                }
              
              return Container(
                width: 280,
                margin: EdgeInsets.only(
                  right: index == upcomingBills.length - 1 ? 0 : 16,
                ),
                child: InkWell(
                  onTap: () {
                    // Optional: Navigate to bill details
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: borderColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 7,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 41,
                              height: 41,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                billIcon,
                                color: statusColor,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    billTitle,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dueText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Amount',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '₱${billAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection(List<Transaction> recentTransactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/transactions');
              },
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...recentTransactions.asMap().entries.map((entry) {
          final index = entry.key;
          final transaction = entry.value;
          final isIncome = transaction.amount > 0;
          final amountColor = isIncome ? const Color(0xFF27AE60) : const Color(0xFFE74C3C);
          
          return Container(
            margin: EdgeInsets.only(bottom: index == recentTransactions.length - 1 ? 0 : 12),
            child: InkWell(
              onTap: () {
                // TODO: Navigate to transaction details
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: amountColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: amountColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                transaction.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(transaction.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isIncome ? '+' : '-'}₱${transaction.amount.abs().toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: amountColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToExpenses(String category) {
    Navigator.of(context).pushNamed('/transactions');
  }

  void _navigateToInflationTracker() {
    Navigator.of(context).pushNamed('/inflation-tracker');
  }
}

// Data Models
class CategorySpending {
  final String name;
  final double amount;
  final Color color;
  final String? emoji;

  CategorySpending({
    required this.name,
    required this.amount,
    required this.color,
    this.emoji,
  });
}

class InflationAlert {
  final String item;
  final double change;
  final bool isIncrease;

  InflationAlert({
    required this.item,
    required this.change,
    required this.isIncrease,
  });
}

class UpcomingBill {
  final String title;
  final double amount;
  final DateTime dueDate;
  final IconData icon;

  UpcomingBill({
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.icon,
  });
}

class Transaction {
  final String title;
  final String category;
  final double amount;
  final DateTime date;

  Transaction({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
  });
}

// Custom Painter for Pie Chart
class PieChartPainter extends CustomPainter {
  final List<CategorySpending> categories;
  final double total;

  PieChartPainter(this.categories, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double startAngle = -math.pi / 2; // Start from top

    for (var category in categories) {
      final sweepAngle = (category.amount / total) * 2 * math.pi;

      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

