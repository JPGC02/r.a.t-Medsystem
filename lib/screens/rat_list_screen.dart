import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../models/rat.dart';
import '../models/equipment.dart';
import '../theme/app_theme.dart';
import './rat_details_screen.dart';
import './rat_form_screen.dart';

class RATListScreen extends StatefulWidget {
  const RATListScreen({super.key});

  @override
  State<RATListScreen> createState() => _RATListScreenState();
}

class _RATListScreenState extends State<RATListScreen> {
  String _searchQuery = '';
  bool _showClosedRATs = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatu00f3rios de Atendimento Tu00e9cnico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Buscar',
          ),
          IconButton(
            icon: Icon(_showClosedRATs ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showClosedRATs = !_showClosedRATs;
              });
            },
            tooltip: _showClosedRATs ? 'Ocultar RATs fechadas' : 'Mostrar RATs fechadas',
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter RATs based on search query and closed status
          List<RAT> filteredRATs = provider.rats;
          
          if (!_showClosedRATs) {
            filteredRATs = filteredRATs.where((rat) => !rat.isClosed).toList();
          }
          
          if (_searchQuery.isNotEmpty) {
            filteredRATs = filteredRATs.where((rat) {
              final query = _searchQuery.toLowerCase();
              return rat.clientName.toLowerCase().contains(query) ||
                  rat.responsiblePerson.toLowerCase().contains(query);
            }).toList();
          }
          
          // Sort RATs with most recent first
          filteredRATs.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

          if (filteredRATs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Nenhuma RAT encontrada para "$_searchQuery"'
                        : 'Nenhuma RAT disponu00edvel',
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RATFormScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Criar Nova RAT'),
                  ),
                ],
              ),
            );
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: ListView.separated(
              key: ValueKey<String>('rat_list_${filteredRATs.length}_$_showClosedRATs'),
              padding: const EdgeInsets.all(16),
              itemCount: filteredRATs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildRATCard(filteredRATs[index], provider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RATFormScreen(),
            ),
          ).then((_) => setState(() {}));
        },
        child: const Icon(Icons.add),
        tooltip: 'Nova RAT',
      ),
    );
  }

  Widget _buildRATCard(RAT rat, AppStateProvider provider) {
    final equipmentList = provider.getEquipmentForRAT(rat.id);
    final deliveredCount = equipmentList
        .where((e) => e.status == EquipmentStatus.delivered)
        .length;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RATDetailsScreen(ratId: rat.id),
            ),
          ).then((_) => setState(() {}));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rat.clientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(rat.dateCreated),
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                rat.responsiblePerson,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: rat.isClosed ? AppTheme.deliveredColor : AppTheme.withdrawnColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          rat.isClosed ? 'Fechada' : 'Aberta',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$deliveredCount/${equipmentList.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'equipamentos',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (equipmentList.isNotEmpty) ...[  
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: equipmentList.take(3).map((equipment) {
                    return Chip(
                      backgroundColor: equipment.status == EquipmentStatus.delivered
                          ? AppTheme.deliveredColor.withOpacity(0.1)
                          : AppTheme.withdrawnColor.withOpacity(0.1),
                      side: BorderSide(
                        color: equipment.status == EquipmentStatus.delivered
                            ? AppTheme.deliveredColor
                            : AppTheme.withdrawnColor,
                      ),
                      label: Text(
                        '${equipment.brand} ${equipment.model}',
                        style: TextStyle(
                          color: equipment.status == EquipmentStatus.delivered
                              ? AppTheme.deliveredColor
                              : AppTheme.withdrawnColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      avatar: Icon(
                        Icons.memory,
                        size: 16,
                        color: equipment.status == EquipmentStatus.delivered
                            ? AppTheme.deliveredColor
                            : AppTheme.withdrawnColor,
                      ),
                    );
                  }).toList(),
                ),
                if (equipmentList.length > 3) ...[  
                  const SizedBox(height: 8),
                  Text(
                    '+ ${equipmentList.length - 3} outros equipamentos',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempQuery = _searchQuery;
        final controller = TextEditingController(text: _searchQuery);
        
        return AlertDialog(
          title: const Text('Buscar RAT'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Cliente ou responsável',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => tempQuery = value,
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = '');
                Navigator.pop(context);
              },
              child: const Text('Limpar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _searchQuery = tempQuery);
                Navigator.pop(context);
              },
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );
  }
}