import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../models/rat.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../image_upload.dart';
import './rat_details_screen.dart';

class EquipmentFormScreen extends StatefulWidget {
  final String ratId;

  const EquipmentFormScreen({super.key, required this.ratId});

  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _assetIdController = TextEditingController();
  final _serviceDescriptionController = TextEditingController();
  final _accessoriesController = TextEditingController();
  
  final List<String> _photos = [];
  bool _isLoading = false;
  RAT? _rat;
  
  @override
  void initState() {
    super.initState();
    _loadRAT();
  }
  
  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _assetIdController.dispose();
    _serviceDescriptionController.dispose();
    _accessoriesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRAT() async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final rat = provider.rats.firstWhere((r) => r.id == widget.ratId);
    setState(() {
      _rat = rat;
    });
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mu00e1ximo de 5 fotos por equipamento'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da galeria'),
              onTap: () async {
                Navigator.pop(context);
                final imageBytes = await ImageUploadHelper.pickImageFromGallery();
                if (imageBytes != null && mounted) {
                  setState(() {
                    _photos.add(base64Encode(imageBytes));
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar foto'),
              onTap: () async {
                Navigator.pop(context);
                final imageBytes = await ImageUploadHelper.captureImage();
                if (imageBytes != null && mounted) {
                  setState(() {
                    _photos.add(base64Encode(imageBytes));
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      
      // Parse accessories
      final accessoriesText = _accessoriesController.text.trim();
      final accessories = accessoriesText.isEmpty
          ? <String>[]
          : accessoriesText.split(',').map((e) => e.trim()).toList();
      
      await provider.addEquipment(
        ratId: widget.ratId,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        serialNumber: _serialNumberController.text.trim(),
        assetId: _assetIdController.text.trim(),
        photos: _photos,
        serviceDescription: _serviceDescriptionController.text.trim(),
        accessories: accessories,
      );
      
      if (!mounted) return;
      
      // Clear form for next equipment or navigate away
      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar equipamento: $e'),
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppTheme.deliveredColor,
            ),
            const SizedBox(width: 8),
            const Text('Equipamento Adicionado'),
          ],
        ),
        content: const Text(
          'Equipamento adicionado com sucesso!u000ADeseja adicionar mais equipamentos a esta RAT?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to RAT details
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RATDetailsScreen(ratId: widget.ratId),
                ),
              );
            },
            child: const Text('Concluir'),
          ),
          ElevatedButton(
            onPressed: () {
              // Clear form for next equipment
              Navigator.pop(context);
              _clearForm();
            },
            child: const Text('Adicionar Mais'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _brandController.clear();
    _modelController.clear();
    _serialNumberController.clear();
    _assetIdController.clear();
    _serviceDescriptionController.clear();
    _accessoriesController.clear();
    setState(() {
      _photos.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_rat == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Equipamento'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Concluir',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RATDetailsScreen(ratId: widget.ratId),
                ),
              );
            },
          ),
        ],
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
                    _buildRatInfoCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Informau00e7u00f5es do Equipamento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBrandField(),
                    const SizedBox(height: 16),
                    _buildModelField(),
                    const SizedBox(height: 16),
                    _buildSerialNumberField(),
                    const SizedBox(height: 16),
                    _buildAssetIdField(),
                    const SizedBox(height: 24),
                    _buildPhotosSection(),
                    const SizedBox(height: 24),
                    _buildServiceDescriptionField(),
                    const SizedBox(height: 16),
                    _buildAccessoriesField(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRatInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.description,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'RAT: ${_rat!.clientName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Responsu00e1vel: ${_rat!.responsiblePerson}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandField() {
    return TextFormField(
      controller: _brandController,
      decoration: const InputDecoration(
        labelText: 'Marca',
        hintText: 'Marca do equipamento',
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, informe a marca';
        }
        return null;
      },
    );
  }

  Widget _buildModelField() {
    return TextFormField(
      controller: _modelController,
      decoration: const InputDecoration(
        labelText: 'Modelo',
        hintText: 'Modelo do equipamento',
        prefixIcon: Icon(Icons.devices),
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, informe o modelo';
        }
        return null;
      },
    );
  }

  Widget _buildSerialNumberField() {
    return TextFormField(
      controller: _serialNumberController,
      decoration: const InputDecoration(
        labelText: 'Nu00famero de Su00e9rie',
        hintText: 'Nu00famero de su00e9rie do equipamento',
        prefixIcon: Icon(Icons.numbers),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, informe o nu00famero de su00e9rie';
        }
        return null;
      },
    );
  }

  Widget _buildAssetIdField() {
    return TextFormField(
      controller: _assetIdController,
      decoration: const InputDecoration(
        labelText: 'Patrimu00f4nio',
        hintText: 'Nu00famero de patrimu00f4nio (opcional)',
        prefixIcon: Icon(Icons.tag),
        border: OutlineInputBorder(),
      ),
      // This field is optional
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fotos do Equipamento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_photos.length}/5',
              style: TextStyle(
                color: _photos.length >= 5 ? AppTheme.warningColor : AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: _photos.isEmpty
              ? Center(
                  child: TextButton.icon(
                    onPressed: _addPhoto,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Adicionar Foto'),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length + (_photos.length < 5 ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _photos.length) {
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add_a_photo),
                          onPressed: _addPhoto,
                        ),
                      );
                    }
                    
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: MemoryImage(base64Decode(_photos[index])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              onPressed: () => _removePhoto(index),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildServiceDescriptionField() {
    return TextFormField(
      controller: _serviceDescriptionController,
      decoration: const InputDecoration(
        labelText: 'Serviu00e7o a ser Realizado',
        hintText: 'Descriu00e7u00e3o do serviu00e7o necessário',
        prefixIcon: Icon(Icons.engineering),
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, descreva o serviu00e7o a ser realizado';
        }
        return null;
      },
    );
  }

  Widget _buildAccessoriesField() {
    return TextFormField(
      controller: _accessoriesController,
      decoration: const InputDecoration(
        labelText: 'Acessu00f3rios',
        hintText: 'Ex: cabo de alimentau00e7u00e3o, mouse, teclado (separados por vu00edrgula)',
        prefixIcon: Icon(Icons.cable),
        border: OutlineInputBorder(),
      ),
      // This field is optional
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _submitForm,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Equipamento'),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}