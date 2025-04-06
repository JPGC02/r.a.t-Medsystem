import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/rat.dart';
import '../models/equipment.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../utils/signature_helper.dart';
import './equipment_form_screen.dart';
import './equipment_details_screen.dart';
import './equipment_delivery_screen.dart';

class RATDetailsScreen extends StatefulWidget {
  final String ratId;

  const RATDetailsScreen({super.key, required this.ratId});

  @override
  State<RATDetailsScreen> createState() => _RATDetailsScreenState();
}

class _RATDetailsScreenState extends State<RATDetailsScreen> {
  late AppStateProvider _provider;
  RAT? _rat;
  List<Equipment> _equipment = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    _provider = Provider.of<AppStateProvider>(context, listen: false);
    await _provider.refreshData();

    // Find the RAT
    try {
      final rat = _provider.rats.firstWhere((r) => r.id == widget.ratId);
      final equipment = _provider.getEquipmentForRAT(widget.ratId);

      setState(() {
        _rat = rat;
        _equipment = equipment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('RAT não encontrada'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_rat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes da RAT')),
        body: const Center(child: Text('RAT não encontrada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da RAT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRATInfoCard(),
              const SizedBox(height: 24),
              _buildEquipmentSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EquipmentFormScreen(ratId: widget.ratId),
            ),
          ).then((_) => _loadData());
        },
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Equipamento',
      ),
    );
  }

  Widget _buildRATInfoCard() {
    final deliveredCount = _equipment
        .where((e) => e.status == EquipmentStatus.delivered)
        .length;

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
                Expanded(
                  child: Text(
                    _rat!.clientName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _rat!.isClosed
                        ? AppTheme.deliveredColor
                        : AppTheme.withdrawnColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _rat!.isClosed ? 'Fechada' : 'Aberta',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Data',
              value: DateFormat('dd/MM/yyyy').format(_rat!.dateCreated),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.person,
              label: 'Responsável pela Retirada',
              value: _rat!.responsiblePerson,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.inventory,
              label: 'Equipamentos',
              value: '$deliveredCount/${_equipment.length} entregues',
              valueColor: deliveredCount == _equipment.length && _equipment.isNotEmpty
                  ? AppTheme.deliveredColor
                  : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Assinatura do Responsável',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SignatureHelper.displaySignature(_rat!.signature, height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentSection() {
    if (_equipment.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum equipamento adicionado',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EquipmentFormScreen(ratId: widget.ratId),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Equipamento'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Equipamentos (${_equipment.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EquipmentFormScreen(ratId: widget.ratId),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
          ],
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _equipment.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildEquipmentCard(_equipment[index]),
        ),
      ],
    );
  }

  Widget _buildEquipmentCard(Equipment equipment) {
    final bool isDelivered = equipment.status == EquipmentStatus.delivered;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EquipmentDetailsScreen(equipmentId: equipment.id),
            ),
          ).then((_) => _loadData());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${equipment.brand} ${equipment.model}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Série: ${equipment.serialNumber}',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        if (equipment.assetId.isNotEmpty) ...[  
                          const SizedBox(height: 4),
                          Text(
                            'Patrimônio: ${equipment.assetId}',
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AppTheme.statusChip(equipment.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EquipmentDetailsScreen(equipmentId: equipment.id),
                          ),
                        ).then((_) => _loadData());
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Detalhes'),
                    ),
                  ),
                  if (!isDelivered)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EquipmentDeliveryScreen(equipmentId: equipment.id),
                            ),
                          ).then((_) => _loadData());
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Entregar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.deliveredColor,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}