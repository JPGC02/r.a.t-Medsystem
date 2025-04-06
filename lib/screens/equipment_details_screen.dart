import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../models/equipment.dart';
import '../models/history_entry.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../utils/signature_helper.dart';
import './equipment_delivery_screen.dart';

class EquipmentDetailsScreen extends StatefulWidget {
  final String equipmentId;

  const EquipmentDetailsScreen({super.key, required this.equipmentId});

  @override
  State<EquipmentDetailsScreen> createState() => _EquipmentDetailsScreenState();
}

class _EquipmentDetailsScreenState extends State<EquipmentDetailsScreen> {
  Equipment? _equipment;
  List<HistoryEntry> _history = [];
  String? _clientName;
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

    final provider = Provider.of<AppStateProvider>(context, listen: false);
    await provider.refreshData();

    try {
      final equipment = provider.equipment.firstWhere((e) => e.id == widget.equipmentId);
      final history = provider.getHistoryForEquipment(widget.equipmentId);
      final rat = provider.rats.firstWhere((r) => r.id == equipment.ratId);

      setState(() {
        _equipment = equipment;
        _history = history;
        _clientName = rat.clientName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipamento nu00e3o encontrado'),
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

    if (_equipment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Equipamento')),
        body: const Center(child: Text('Equipamento nu00e3o encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Equipamento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainInfoCard(),
            const SizedBox(height: 24),
            _buildPhotoGallery(),
            const SizedBox(height: 24),
            _buildServiceAndAccessories(),
            const SizedBox(height: 24),
            _buildHistorySection(),
          ],
        ),
      ),
      floatingActionButton: _equipment!.status == EquipmentStatus.withdrawn
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EquipmentDeliveryScreen(equipmentId: widget.equipmentId),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.check),
              label: const Text('Registrar Entrega'),
              backgroundColor: AppTheme.deliveredColor,
            )
          : null,
    );
  }

  Widget _buildMainInfoCard() {
    final isDelivered = _equipment!.status == EquipmentStatus.delivered;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_equipment!.brand} ${_equipment!.model}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cliente: $_clientName',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                AppTheme.statusChip(_equipment!.status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.numbers,
              label: 'Nu00famero de Su00e9rie',
              value: _equipment!.serialNumber,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.tag,
              label: 'Patrimu00f4nio',
              value: _equipment!.assetId.isNotEmpty ? _equipment!.assetId : 'Nu00e3o informado',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Data de Retirada',
              value: DateFormat('dd/MM/yyyy').format(_equipment!.withdrawalDate),
            ),
            if (isDelivered && _equipment!.deliveryDate != null) ...[  
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Data de Entrega',
                value: DateFormat('dd/MM/yyyy').format(_equipment!.deliveryDate!),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.person,
                label: 'Responsu00e1vel pela Entrega',
                value: _equipment!.deliveryResponsiblePerson ?? 'Nu00e3o informado',
              ),
              if (_equipment!.deliverySignature != null) ...[  
                const SizedBox(height: 16),
                const Text(
                  'Assinatura de Entrega',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                SignatureHelper.displaySignature(_equipment!.deliverySignature!, height: 120),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGallery() {
    if (_equipment!.photos.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _equipment!.photos.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showPhotoFullScreen(index),
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: MemoryImage(base64Decode(_equipment!.photos[index])),
                      fit: BoxFit.cover,
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

  void _showPhotoFullScreen(int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          children: [
            PageView.builder(
              itemCount: _equipment!.photos.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.memory(
                      base64Decode(_equipment!.photos[index]),
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceAndAccessories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Serviu00e7o e Acessu00f3rios',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Serviu00e7o a ser Realizado',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(_equipment!.serviceDescription),
                if (_equipment!.accessories.isNotEmpty) ...[  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Acessu00f3rios',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _equipment!.accessories.map((accessory) {
                      return Chip(
                        label: Text(accessory),
                        backgroundColor: AppTheme.primaryColorLight.withOpacity(0.1),
                        side: const BorderSide(color: AppTheme.primaryColorLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Histu00f3rico',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (context, index) => const Divider(indent: 72, endIndent: 16),
              itemBuilder: (context, index) {
                final entry = _history[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: entry.type == HistoryEntryType.delivery
                        ? AppTheme.deliveredColor
                        : AppTheme.withdrawnColor,
                    child: Icon(
                      entry.type == HistoryEntryType.delivery
                          ? Icons.login
                          : Icons.logout,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    entry.type == HistoryEntryType.delivery
                        ? 'Equipamento Entregue'
                        : 'Equipamento Retirado',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data: ${DateFormat('dd/MM/yyyy').format(entry.date)}',
                      ),
                      Text(
                        'Responsu00e1vel: ${entry.responsiblePerson}',
                      ),
                      if (entry.notes != null && entry.notes!.isNotEmpty)
                        Text(
                          'Observau00e7u00f5es: ${entry.notes}',
                        ),
                    ],
                  ),
                  isThreeLine: entry.notes != null && entry.notes!.isNotEmpty,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}