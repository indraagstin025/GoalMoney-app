import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/goal_provider.dart';
import '../../widgets/goal_card.dart';
import 'add_goal_screen.dart';

class GoalListScreen extends StatefulWidget {
  const GoalListScreen({Key? key}) : super(key: key);

  @override
  State<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      Provider.of<GoalProvider>(context, listen: false).fetchGoals();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _CustomHeader(),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade400],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: isDarkMode
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.monetization_on_rounded, size: 20),
                    text: 'Cash Goals',
                  ),
                  Tab(
                    icon: Icon(Icons.account_balance_wallet_rounded, size: 20),
                    text: 'E-Wallet Goals',
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: Consumer<GoalProvider>(
                builder: (context, goalProvider, child) {
                  if (goalProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final cashGoals = goalProvider.goals.where((g) {
                    final goalType = g.type ?? 'digital';
                    return goalType == 'cash';
                  }).toList();

                  final digitalGoals = goalProvider.goals.where((g) {
                    final goalType = g.type ?? 'digital';
                    return goalType == 'digital';
                  }).toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Cash Goals Tab
                      _buildGoalsList(context, cashGoals, isDarkMode, 'cash'),

                      // Digital Goals Tab
                      _buildGoalsList(
                        context,
                        digitalGoals,
                        isDarkMode,
                        'digital',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddGoalScreen()));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Goal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  Widget _buildGoalsList(
    BuildContext context,
    List<dynamic> goals,
    bool isDarkMode,
    String type,
  ) {
    if (goals.isEmpty) {
      return _EmptyState(isDarkMode: isDarkMode, type: type);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<GoalProvider>(context, listen: false).fetchGoals();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final goal = goals[index];
          return GoalCard(
            key: ValueKey(goal.id),
            goal: goal,
            isDarkMode: isDarkMode,
          );
        },
      ),
    );
  }
}

class _CustomHeader extends StatelessWidget {
  const _CustomHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Theme.of(context).cardTheme.color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // GoalMoney Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'GoalMoney',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.lightGreen,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDarkMode;
  final String type;

  const _EmptyState({Key? key, required this.isDarkMode, required this.type})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCash = type == 'cash';
    final icon = isCash
        ? Icons.money_rounded
        : Icons.account_balance_wallet_rounded;
    final title = isCash ? 'Belum Ada Goal Cash' : 'Belum Ada Goal E-Wallet';
    final subtitle = isCash
        ? 'Mulai menabung uang cash dengan\nmenambahkan goal cash pertama Anda'
        : 'Mulai menabung digital dengan\nmenambahkan goal e-wallet pertama Anda';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade100.withOpacity(0.3),
                  Colors.green.shade50.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: Colors.green.shade300),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AddGoalScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Tambah Goal ${isCash ? "Cash" : "E-Wallet"}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
