import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';

import '../models/equipment.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../utils/signature_helper.dart';

class EquipmentDeliveryScreen extends StatefulWidget {
  final String equipmentId;

  const EquipmentDeliveryScreen({super.key, required this.equipmentId});

  @override
  State<EquipmentDeliveryScreen> createState() => _EquipmentDeliveryScreenState();
}

class _EquipmentDeliveryScreenState extends State<EquipmentDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _responsiblePersonController = TextEditingController();
  
  Equipment? _equipment;
  String? _clientName;
  String? _signature;
  bool _isLoading = true;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _responsiblePersonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<AppStateProvider>(context, listen: false);
    await provider.refreshData();

    try {
      final equipment = provider.equipment.firstWhere((e) => e.id == widget.equipmentId);
      
      if (equipment.status == EquipmentStatus.delivered) {
        // Equipment already delivered
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este equipamento ju00e1 foi entregue'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      final rat = provider.rats.firstWhere((r) => r.id == equipment.ratId);

      setState(() {
        _equipment = equipment;
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

  Future<void> _captureSignature() async {
    final signature = await SignatureHelper.showSignaturePad(context);
    if (signature != null) {
      setState(() {
        _signature = signature;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    if (_signature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, capture a assinatura'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      
      await provider.markEquipmentAsDelivered(
        equipmentId: widget.equipmentId,
        responsiblePerson: _responsiblePersonController.text.trim(),
        signature: _signature!,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipamento entregue com sucesso!'),
          backgroundColor: AppTheme.deliveredColor,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registrar entrega: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
        appBar: AppBar(title: const Text('Registrar Entrega')),
        body: const Center(child: Text('Equipamento nu00e3o encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Entrega'),
        backgroundColor: AppTheme.deliveredColor,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEquipmentInfoCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Informau00e7u00f5es de Entrega',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildResponsiblePersonField(),
                    const SizedBox(height: 24),
                    _buildSignatureSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEquipmentInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_equipment!.brand} ${_equipment!.model}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Su00e9rie: ${_equipment!.serialNumber}',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            if (_equipment!.assetId.isNotEmpty) ...[  
              const SizedBox(height: 4),
              Text(
                'Patrimu00f4nio: ${_equipment!.assetId}',
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Cliente: $_clientName',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiblePersonField() {
    return TextFormField(
      controller: _responsiblePersonController,
      decoration: const InputDecoration(
        labelText: 'Responsu00e1vel pela Entrega',
        hintText: 'Nome do responsu00e1vel',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, informe o nome do responsu00e1vel';
        }
        return null;
      },
    );
  }

  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assinatura do Responsu00e1vel',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _signature == null ? Colors.grey : AppTheme.deliveredColor,
              width: _signature == null ? 1 : 2,
            ),
          ),
          child: _signature == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.draw,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nenhuma assinatura capturada',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _captureSignature,
                        icon: const Icon(Icons.edit),
                        label: const Text('Capturar Assinatura'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.deliveredColor,
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    SignatureHelper.displaySignature(_signature!),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 16,
                        child: IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          color: AppTheme.deliveredColor,
                          onPressed: _captureSignature,
                          tooltip: 'Editar assinatura',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _submitForm,
        icon: const Icon(Icons.check),
        label: const Text('Confirmar Entrega'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.deliveredColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}