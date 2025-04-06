import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../models/equipment.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import './rat_form_screen.dart';
import './rat_list_screen.dart';
import './equipment_history_screen.dart';
import './profile_screen.dart';
import './user_management_screen.dart';
import './login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Filters
  String? clientFilter;
  String? technicianFilter;
  DateTimeRange? dateRange;
  
  // Dashboard statistics
  int withdrawnEquipment = 0;
  int deliveredEquipment = 0;
  int openRATs = 0;
  double averageDays = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboardData();
    _checkAuthentication();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Check if user is authenticated
  void _checkAuthentication() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      if (!provider.isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }
  
  Future<void> _loadDashboardData() async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final stats = await provider.getDashboardStatistics(
      clientFilter: clientFilter,
      technicianFilter: technicianFilter,
      startDate: dateRange?.start,
      endDate: dateRange?.end,
    );
    
    setState(() {
      withdrawnEquipment = stats['withdrawnEquipment'];
      deliveredEquipment = stats['deliveredEquipment'];
      openRATs = stats['openRATs'];
      averageDays = stats['averageDays'];
    });
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? tempClientFilter = clientFilter;
        String? tempTechnicianFilter = technicianFilter;
        DateTimeRange? tempDateRange = dateRange;
        
        return AlertDialog(
          title: const Text('Filtrar Dashboard'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    hintText: 'Filtrar por cliente',
                    prefixIcon: Icon(Icons.business),
                  ),
                  initialValue: tempClientFilter,
                  onChanged: (value) => tempClientFilter = value.isNotEmpty ? value : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Técnico',
                    hintText: 'Filtrar por técnico',
                    prefixIcon: Icon(Icons.person),
                  ),
                  initialValue: tempTechnicianFilter,
                  onChanged: (value) => tempTechnicianFilter = value.isNotEmpty ? value : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Período'),
                  subtitle: Text(
                    tempDateRange != null
                        ? '${DateFormat('dd/MM/yyyy').format(tempDateRange.start)} - ${DateFormat('dd/MM/yyyy').format(tempDateRange.end)}'
                        : 'Nenhum período selecionado'
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final initialDateRange = tempDateRange ?? DateTimeRange(
                      start: DateTime.now().subtract(const Duration(days: 30)),
                      end: DateTime.now(),
                    );
                    
                    final result = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: initialDateRange,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppTheme.primaryColor,
                              onPrimary: Colors.white,
                              onSurface: AppTheme.textPrimaryColor,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    
                    if (result != null) {
                      tempDateRange = result;
                    }
                  },
                ),
                if (tempDateRange != null)
                  TextButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpar período'),
                    onPressed: () {
                      tempDateRange = null;
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  clientFilter = tempClientFilter;
                  technicianFilter = tempTechnicianFilter;
                  dateRange = tempDateRange;
                });
                Navigator.pop(context);
                _loadDashboardData();
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final user = provider.currentUser;
    final bool canCreateRats = user != null && 
                                (user.role == UserRole.admin || 
                                 user.role == UserRole.technician);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Tracking System'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
            Tab(text: 'Histórico', icon: Icon(Icons.history)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            tooltip: 'Perfil',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          EquipmentHistoryScreen(),
        ],
      ),
      floatingActionButton: canCreateRats ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RATFormScreen(),
            ),
          ).then((_) => _loadDashboardData());
        },
        child: const Icon(Icons.add),
        tooltip: 'Nova RAT',
      ) : null,
    );
  }

  Widget _buildDrawer() {
    final provider = Provider.of<AppStateProvider>(context);
    final user = provider.currentUser;
    final bool isAdmin = user?.role == UserRole.admin;
    final bool canCreateRats = user != null && 
                               (user.role == UserRole.admin || 
                                user.role == UserRole.technician);
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(user),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              _tabController.animateTo(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('RATs'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RATListScreen(),
                ),
              ).then((_) => _loadDashboardData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Histórico de Equipamentos'),
            onTap: () {
              _tabController.animateTo(1);
              Navigator.pop(context);
            },
          ),
          if (isAdmin) ...[  
            const Divider(),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Gerenciar Usuários'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagementScreen(),
                  ),
                );
              },
            ),
          ],
          if (canCreateRats) ...[  
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Nova RAT'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RATFormScreen(),
                  ),
                ).then((_) => _loadDashboardData());
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Meu Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmLogout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(User? user) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColorDark,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 30,
                child: Icon(
                  _getRoleIcon(user?.role),
                  size: 30,
                  color: _getRoleColor(user?.role),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Usuário',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getRoleName(user?.role),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Equipment Tracking',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Sistema de Controle de RAT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.technician:
        return Icons.engineering;
      case UserRole.viewer:
        return Icons.visibility;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.technician:
        return AppTheme.primaryColor;
      case UserRole.viewer:
        return Colors.teal;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getRoleName(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.technician:
        return 'Técnico';
      case UserRole.viewer:
        return 'Visualizador';
      default:
        return 'Usuário';
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Sistema'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    await provider.logout();

    if (!mounted) return;

    // Navigate to login screen and clear history
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildDashboardTab() {
    return Consumer<AppStateProvider>(  
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              _buildFilterSummary(),
              const SizedBox(height: 20),
              _buildStatisticCards(),
              const SizedBox(height: 24),
              _buildEquipmentStatusChart(),
              const SizedBox(height: 24),
              _buildRecentRATs(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSummary() {
    if (clientFilter == null && technicianFilter == null && dateRange == null) {
      return const SizedBox();
    }
    
    return Card(
      elevation: 1,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.filter_list, size: 18, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Filtros aplicados:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (clientFilter != null)
                  Chip(
                    label: Text('Cliente: $clientFilter'),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.primaryColorLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                if (technicianFilter != null)
                  Chip(
                    label: Text('Técnico: $technicianFilter'),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.primaryColorLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                if (dateRange != null)
                  Chip(
                    label: Text(
                      'Período: ${DateFormat('dd/MM/yy').format(dateRange!.start)} - ${DateFormat('dd/MM/yy').format(dateRange!.end)}'
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.primaryColorLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Equipamentos Retirados',
          value: withdrawnEquipment.toString(),
          icon: Icons.logout,
          color: AppTheme.withdrawnColor,
        ),
        _buildStatCard(
          title: 'Equipamentos Entregues',
          value: deliveredEquipment.toString(),
          icon: Icons.login,
          color: AppTheme.deliveredColor,
        ),
        _buildStatCard(
          title: 'RATs Abertas',
          value: openRATs.toString(),
          icon: Icons.description,
          color: AppTheme.warningColor,
        ),
        _buildStatCard(
          title: 'Média de Dias no Lab',
          value: averageDays.toStringAsFixed(1),
          icon: Icons.access_time,
          color: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentStatusChart() {
    final total = withdrawnEquipment + deliveredEquipment;
    if (total == 0) {
      return const SizedBox();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status dos Equipamentos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: withdrawnEquipment.toDouble(),
                            color: AppTheme.withdrawnColor,
                            title: '${(withdrawnEquipment / total * 100).toStringAsFixed(0)}%',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: deliveredEquipment.toDouble(),
                            color: AppTheme.deliveredColor,
                            title: '${(deliveredEquipment / total * 100).toStringAsFixed(0)}%',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildChartLegend(
                          color: AppTheme.withdrawnColor,
                          label: 'Retirados',
                          value: withdrawnEquipment.toString(),
                        ),
                        const SizedBox(height: 16),
                        _buildChartLegend(
                          color: AppTheme.deliveredColor,
                          label: 'Entregues',
                          value: deliveredEquipment.toString(),
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
    );
  }

  Widget _buildChartLegend({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label ($value)',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRATs() {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        final openRATsList = provider.rats.where((rat) => !rat.isClosed).toList();
        openRATsList.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
        final recentRATs = openRATsList.take(5).toList();

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RATs Recentes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RATListScreen(),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                      child: const Text('Ver todas'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (recentRATs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Nenhuma RAT aberta',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentRATs.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final rat = recentRATs[index];
                      final equipmentCount = provider
                          .getEquipmentForRAT(rat.id)
                          .length;
                      final deliveredCount = provider
                          .getEquipmentForRAT(rat.id)
                          .where((e) => e.status == EquipmentStatus.delivered)
                          .length;

                      return ListTile(
                        title: Text(
                          rat.clientName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Data: ${DateFormat('dd/MM/yyyy').format(rat.dateCreated)}\nResponsável: ${rat.responsiblePerson}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$deliveredCount/$equipmentCount',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: deliveredCount == equipmentCount
                                    ? AppTheme.deliveredColor
                                    : AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'equipamentos',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Navigate to RAT details
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}