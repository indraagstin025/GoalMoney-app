import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/goal_provider.dart';
import '../../models/goal_filter_state.dart';
import '../../widgets/cards/goal_card.dart';
import '../../widgets/inputs/search_field.dart';
import '../../widgets/goals/goal_filter_sheet.dart';
import 'add_goal_screen.dart';
import '../../widgets/skeletons/goal_list_skeleton.dart';

/// Layar daftar goal.
/// Menampilkan semua goal yang dimiliki pengguna, dibagi menjadi tab Cash dan E-Wallet.
class GoalListScreen extends StatefulWidget {
  const GoalListScreen({Key? key}) : super(key: key);

  @override
  State<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  GoalFilterState _filterState = GoalFilterState();

  @override
  void initState() {
    super.initState();
    // Inisialisasi TabController untuk 2 tab: Cash dan E-Wallet
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);

    // Fetch data goal setelah frame pertama dirender
    Future.microtask(() {
      Provider.of<GoalProvider>(context, listen: false).fetchGoals();
    });
  }

  /// Callback saat teks pencarian berubah. Update state filter.
  void _onSearchChanged() {
    setState(() {
      _filterState = _filterState.copyWith(query: _searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
            // Header Kustom
            _CustomHeader(),

            // Bar Pencarian dan Filter
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SearchField(
                      controller: _searchController,
                      onChanged: (val) {},
                      onClear: () {
                        _searchController.clear();
                      },
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildFilterButton(context, isDarkMode),
                ],
              ),
            ),

            // Tab Bar untuk menavigasi antara Cash dan E-Wallet Goals
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

            // Konten Tab
            Expanded(
              child: Consumer<GoalProvider>(
                builder: (context, goalProvider, child) {
                  if (goalProvider.isLoading && goalProvider.goals.isEmpty) {
                    return const GoalListSkeleton();
                  }

                  // Terapkan filter pencarian pada list goal
                  final filteredGoals = _applyFilters(goalProvider.goals);

                  // Pisahkan goal berdasarkan tipe: cash atau digital (e-wallet)
                  final cashGoals = filteredGoals.where((g) {
                    final goalType = g.type ?? 'digital';
                    return goalType == 'cash';
                  }).toList();

                  final digitalGoals = filteredGoals.where((g) {
                    final goalType = g.type ?? 'digital';
                    return goalType == 'digital';
                  }).toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab Cash Goals
                      _buildGoalsList(context, cashGoals, isDarkMode, 'cash'),

                      // Tab Digital Goals
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
      // Tombol FAB untuk menambah goal baru
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

  /// Membangun list goal. Menampilkan placeholder jika kosong.
  Widget _buildGoalsList(
    BuildContext context,
    List<dynamic> goals,
    bool isDarkMode,
    String type,
  ) {
    if (goals.isEmpty) {
      // Tampilkan state kosong khusus jika sedang mencari/filter tapi tidak ketemu
      if (_filterState.isActive) {
        return _NoSearchResults(
          isDarkMode: isDarkMode,
          onReset: () {
            _searchController.clear();
            setState(() {
              _filterState = _filterState.reset();
            });
          },
        );
      }
      // Tampilkan state kosong default
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

  /// Menerapkan filter pencarian dan periode pada list goal.
  List<dynamic> _applyFilters(List<dynamic> goals) {
    return goals.where((goal) {
      // Filter Nama
      if (_filterState.query.isNotEmpty) {
        final name = goal.name.toString().toLowerCase();
        final query = _filterState.query.toLowerCase();
        if (!name.contains(query)) return false;
      }

      // Filter Periode (menggunakan tanggal pembuatan)
      final createdAtStr = goal.createdAt?.toString();
      if (createdAtStr != null) {
        try {
          final createdAt = DateTime.parse(createdAtStr);

          // Filter Bulan
          if (_filterState.month != null) {
            if (createdAt.month != _filterState.month) return false;
          }

          // Filter Tahun
          if (_filterState.year != null) {
            if (createdAt.year != _filterState.year) return false;
          }
        } catch (_) {
          // Jika parsing tanggal gagal, skip filter periode
        }
      }

      return true;
    }).toList();
  }

  /// Tombol untuk membuka sheet filter. Indikator merah muncul jika filter aktif.
  Widget _buildFilterButton(BuildContext context, bool isDarkMode) {
    final hasActiveFilters =
        _filterState.month != null || _filterState.year != null;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.shade200.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: hasActiveFilters
                  ? Colors.green.shade700
                  : Colors.grey.shade600,
            ),
            onPressed: () async {
              final newState = await showModalBottomSheet<GoalFilterState>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => GoalFilterSheet(
                  initialState: _filterState,
                  isDarkMode: isDarkMode,
                ),
              );

              if (newState != null) {
                setState(() {
                  _filterState = newState;
                });
              }
            },
          ),
        ),
        if (hasActiveFilters)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget tampilan saat pencarian tidak menemukan hasil.
class _NoSearchResults extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onReset;

  const _NoSearchResults({
    Key? key,
    required this.isDarkMode,
    required this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Tidak Ada Hasil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coba sesuaikan kata kunci atau filter Anda',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onReset,
            child: Text(
              'Reset Semua Filter',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header kustom dengan logo dan tombol kembali.
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
          // Logo GoalMoney
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

          // Tombol Kembali
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

/// Widget state kosong saat pengguna belum memiliki goal.
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
