import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureHelper {
  // Create the signature controller
  static SignatureController createSignatureController() {
    return SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  // Convert the signature to a base64 string
  static Future<String?> signatureToBase64(SignatureController controller) async {
    if (controller.isEmpty) {
      return null;
    }
    
    final exportedImage = await controller.toPngBytes();
    if (exportedImage == null) {
      return null;
    }
    
    return base64Encode(exportedImage);
  }

  // Display a signature from a base64 string
  static Widget displaySignature(String base64Signature, {double height = 150}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(base64Signature),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // Show signature pad dialog
  static Future<String?> showSignaturePad(BuildContext context) async {
    final controller = createSignatureController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assinatura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Por favor, assine abaixo:'),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Signature(
                  controller: controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clear();
            },
            child: const Text('Limpar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.isNotEmpty) {
                final signature = await signatureToBase64(controller);
                Navigator.pop(context, signature);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, faça sua assinatura')),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}