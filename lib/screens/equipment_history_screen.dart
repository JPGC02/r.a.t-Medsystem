import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/equipment.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import './equipment_details_screen.dart';

class EquipmentHistoryScreen extends StatefulWidget {
  const EquipmentHistoryScreen({super.key});

  @override
  State<EquipmentHistoryScreen> createState() => _EquipmentHistoryScreenState();
}

class _EquipmentHistoryScreenState extends State<EquipmentHistoryScreen> {
  String? _nameFilter;
  String? _serialNumberFilter;
  String? _assetIdFilter;
  String? _clientFilter;
  EquipmentStatus? _statusFilter;
  
  List<Equipment> _filteredEquipment = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Histu00f3rico de Equipamentos',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildSearchFilters(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros de Busca',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nome/Modelo',
                      hintText: 'Marca ou modelo',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => _nameFilter = value.isNotEmpty ? value : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nu00famero de Su00e9rie',
                      hintText: 'Nu00famero de su00e9rie',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    onChanged: (value) => _serialNumberFilter = value.isNotEmpty ? value : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Patrimu00f4nio',
                      hintText: 'Nu00famero de patrimu00f4nio',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    onChanged: (value) => _assetIdFilter = value.isNotEmpty ? value : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Cliente',
                      hintText: 'Nome do cliente',
                      prefixIcon: Icon(Icons.business),
                    ),
                    onChanged: (value) => _clientFilter = value.isNotEmpty ? value : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Status:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _statusFilter == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _statusFilter = null);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Retirados'),
                  selected: _statusFilter == EquipmentStatus.withdrawn,
                  selectedColor: AppTheme.withdrawnColor.withOpacity(0.2),
                  onSelected: (selected) {
                    setState(() => _statusFilter = selected ? EquipmentStatus.withdrawn : null);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Entregues'),
                  selected: _statusFilter == EquipmentStatus.delivered,
                  selectedColor: AppTheme.deliveredColor.withOpacity(0.2),
                  onSelected: (selected) {
                    setState(() => _statusFilter = selected ? EquipmentStatus.delivered : null);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _searchEquipment,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Use os filtros acima para buscar equipamentos',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_filteredEquipment.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum equipamento encontrado com os filtros atuais',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _filteredEquipment.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildEquipmentCard(_filteredEquipment[index]);
      },
    );
  }

  Widget _buildEquipmentCard(Equipment equipment) {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final rat = provider.rats.firstWhere((r) => r.id == equipment.ratId);

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
          ).then((_) => _searchEquipment());
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
                        Row(
                          children: [
                            const Icon(
                              Icons.business,
                              size: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                rat.clientName,
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nu00famero de Su00e9rie',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        Text(
                          equipment.serialNumber,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (equipment.assetId.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Patrimu00f4nio',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          Text(
                            equipment.assetId,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Retirada',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(equipment.withdrawalDate),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (equipment.status == EquipmentStatus.delivered && equipment.deliveryDate != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Entrega',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(equipment.deliveryDate!),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
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

  void _clearFilters() {
    setState(() {
      _nameFilter = null;
      _serialNumberFilter = null;
      _assetIdFilter = null;
      _clientFilter = null;
      _statusFilter = null;
      _filteredEquipment = [];
      _hasSearched = false;
    });
  }

  Future<void> _searchEquipment() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      
      final equipment = await provider.searchEquipment(
        name: _nameFilter,
        serialNumber: _serialNumberFilter,
        assetId: _assetIdFilter,
        client: _clientFilter,
        status: _statusFilter,
      );

      setState(() {
        _filteredEquipment = equipment;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _filteredEquipment = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar equipamentos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}