import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/kpi_card.dart';
import '../widgets/pump_switcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _pumpName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getDashboard();
      final pumpName = await AuthService.getCurrentPumpName();
      setState(() {
        _data = data;
        _pumpName = pumpName;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _money(String? val) => 'Rs ${NumberFormat('#,##0.00').format(double.tryParse(val ?? '0') ?? 0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pumpName.isEmpty ? 'Dashboard' : _pumpName),
        actions: [
          PumpSwitcher(onPumpChanged: _loadData),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      drawer: const AppDrawer(currentRoute: 'dashboard'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppTheme.danger.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppTheme.danger)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildContent() {
    final kpi = _data!['kpi'] as Map<String, dynamic>;
    final tanks = List<Map<String, dynamic>>.from(_data!['tanks'] ?? []);
    final chartData = List<Map<String, dynamic>>.from(_data!['chart_data'] ?? []);
    final recentSales = List<Map<String, dynamic>>.from(_data!['recent_sales'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Greeting ────────────────────────────────────────
        Text(
          _getGreeting(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),

        // ── KPI Cards ───────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            KpiCard(title: "TODAY'S REVENUE", value: _money(kpi['today_revenue']), icon: Icons.trending_up, gradient: AppTheme.salesGradient),
            KpiCard(title: "CASH COLLECTED", value: _money(kpi['today_cash']), icon: Icons.payments, gradient: AppTheme.cashGradient),
            KpiCard(title: "PURCHASES", value: _money(kpi['today_purchases']), icon: Icons.shopping_bag, gradient: AppTheme.purchaseGradient),
            KpiCard(title: "NET POSITION", value: _money(kpi['net_position']), icon: Icons.account_balance, gradient: AppTheme.netGradient),
          ],
        ),
        const SizedBox(height: 16),

        // ── Financial Summary Row ────────────────────────────
        Row(
          children: [
            Expanded(child: _FinSummaryCard(title: 'Receivable', value: _money(kpi['customer_receivable']), icon: Icons.arrow_downward, color: AppTheme.success)),
            const SizedBox(width: 10),
            Expanded(child: _FinSummaryCard(title: 'Payable', value: _money(kpi['supplier_payable']), icon: Icons.arrow_upward, color: AppTheme.danger)),
            const SizedBox(width: 10),
            Expanded(child: _FinSummaryCard(title: 'Monthly', value: _money(kpi['monthly_sales']), icon: Icons.calendar_month, color: AppTheme.info)),
          ],
        ),
        const SizedBox(height: 20),

        // ── 7-Day Chart ─────────────────────────────────────
        if (chartData.isNotEmpty) ...[
          const Text('Last 7 Days', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < chartData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              (chartData[idx]['label'] as String).split(' ')[0],
                              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(chartData.length, (i) {
                  final sales = (chartData[i]['sales'] as num).toDouble();
                  final purchases = (chartData[i]['purchases'] as num).toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(toY: sales, color: AppTheme.primary, width: 10, borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(toY: purchases, color: AppTheme.accent, width: 10, borderRadius: BorderRadius.circular(4)),
                    ],
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: AppTheme.primary, label: 'Sales'),
                const SizedBox(width: 20),
                _LegendDot(color: AppTheme.accent, label: 'Purchases'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Tank Levels ─────────────────────────────────────
        if (tanks.isNotEmpty) ...[
          const Text('Tank Levels', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...tanks.map((tank) => _TankLevelCard(tank: tank)),
          const SizedBox(height: 20),
        ],

        // ── Recent Sales ────────────────────────────────────
        if (recentSales.isNotEmpty) ...[
          const Text('Recent Sales', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: recentSales.take(8).map((s) {
                final isCash = s['payment_type'] == 'cash';
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: (isCash ? AppTheme.success : AppTheme.warning).withValues(alpha: 0.1),
                    child: Icon(
                      isCash ? Icons.payments : Icons.credit_card,
                      size: 18,
                      color: isCash ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                  title: Text(s['product_name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${s['vehicle_no'] ?? '-'}  |  ${s['quantity']} L',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  trailing: Text(
                    _money(s['total_amount']?.toString()),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

class _FinSummaryCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _FinSummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _TankLevelCard extends StatelessWidget {
  final Map<String, dynamic> tank;
  const _TankLevelCard({required this.tank});

  @override
  Widget build(BuildContext context) {
    final pct = (tank['percentage'] as num).toDouble();
    final color = pct > 40 ? AppTheme.success : (pct > 15 ? AppTheme.warning : AppTheme.danger);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tank['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${tank['product_name']} — ${NumberFormat('#,##0').format(tank['current_stock'])} / ${NumberFormat('#,##0').format(tank['capacity'])} L',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}
