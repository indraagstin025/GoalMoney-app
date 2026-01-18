import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

import '../../providers/goal_provider.dart';
import 'add_goal_screen.dart';
import 'goal_detail_screen.dart';
import 'edit_goal_screen.dart';
import 'deposit_screen.dart';

class GoalListScreen extends StatefulWidget {
  const GoalListScreen({Key? key}) : super(key: key);

  @override
  State<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<GoalProvider>(context, listen: false).fetchGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalProvider = Provider.of<GoalProvider>(context);
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Goals'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await goalProvider.fetchGoals();
        },
        child: goalProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : goalProvider.goals.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: goalProvider.goals.length,
                itemBuilder: (context, index) {
                  final goal = goalProvider.goals[index];
                  return _buildGoalCard(context, goal, currency, goalProvider);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddGoalScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_rounded, size: 80, color: Colors.blue.shade100),
          const SizedBox(height: 16),
          const Text(
            'No goals yet!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start your financial journey now.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, dynamic goal, NumberFormat currency, dynamic goalProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icon/Image
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        image: goal.photoPath != null && File(goal.photoPath!).existsSync()
                            ? DecorationImage(
                                image: FileImage(File(goal.photoPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: goal.photoPath == null || !File(goal.photoPath!).existsSync()
                          ? Icon(Icons.star_rounded, color: Colors.blue.shade300, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Title & Amount
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currency.format(goal.currentAmount)} / ${currency.format(goal.targetAmount)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'deposit',
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text('Deposit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'deposit') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DepositScreen(goalId: goal.id, goalName: goal.name),
                            ),
                          );
                        } else if (value == 'edit') {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => EditGoalScreen(goal: goal)),
                          );
                        } else if (value == 'delete') {
                          _confirmDelete(context, goal, goalProvider);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (goal.progress / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.blue.shade50,
                    valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic goal, dynamic goalProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: const Text('Are you sure you want to delete this goal and its transactions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              goalProvider.deleteGoal(goal.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goal deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
