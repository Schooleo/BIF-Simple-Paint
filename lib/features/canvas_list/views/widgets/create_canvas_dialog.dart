import 'package:flutter/material.dart';

class CreateCanvasDialog extends StatelessWidget {
  const CreateCanvasDialog({
    super.key,
    this.nameController,
    this.onCancel,
    this.onConfirm,
  });

  final TextEditingController? nameController;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Canvas'),
      content: TextField(controller: nameController),
      actions: <Widget>[
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        TextButton(onPressed: onConfirm, child: const Text('Create')),
      ],
    );
  }
}
