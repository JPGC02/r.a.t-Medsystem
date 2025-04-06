import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';

import '../models/rat.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../utils/signature_helper.dart';
import './equipment_form_screen.dart';

class RATFormScreen extends StatefulWidget {
  const RATFormScreen({super.key});

  @override
  State<RATFormScreen> createState() => _RATFormScreenState();
}

class _RATFormScreenState extends State<RATFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _responsiblePersonController = TextEditingController();
  
  String? _signature;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _clientNameController.dispose();
    _responsiblePersonController.dispose();
    super.dispose();
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
      _isLoading = true;
    });
    
    try {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      
      final rat = await provider.createRAT(
        clientName: _clientNameController.text.trim(),
        responsiblePerson: _responsiblePersonController.text.trim(),
        signature: _signature!,
      );
      
      if (!mounted) return;
      
      // Navigate to equipment form
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EquipmentFormScreen(ratId: rat.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar RAT: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova RAT'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informau00e7u00f5es da RAT',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildClientField(),
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

  Widget _buildClientField() {
    return TextFormField(
      controller: _clientNameController,
      decoration: const InputDecoration(
        labelText: 'Cliente',
        hintText: 'Nome do cliente',
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, informe o nome do cliente';
        }
        return null;
      },
    );
  }

  Widget _buildResponsiblePersonField() {
    return TextFormField(
      controller: _responsiblePersonController,
      decoration: const InputDecoration(
        labelText: 'Responsu00e1vel pela Retirada',
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
              color: _signature == null ? Colors.grey : AppTheme.primaryColor,
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
                          color: AppTheme.primaryColor,
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
        label: const Text('Criar RAT e Adicionar Equipamentos'),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}