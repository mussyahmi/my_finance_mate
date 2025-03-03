import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';

class NoteInputPage extends StatefulWidget {
  final String note;

  const NoteInputPage({
    super.key,
    required this.note,
  });

  @override
  State<NoteInputPage> createState() => _NoteInputPageState();
}

class _NoteInputPageState extends State<NoteInputPage> {
  @override
  Widget build(BuildContext context) {
    final controller = FleatherController(
      document: ParchmentDocument.fromJson(
        widget.note.contains('insert')
            ? jsonDecode(widget.note)
            : [
                {"insert": "${widget.note}\n"}
              ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Note'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              if (jsonEncode(controller.document.toJson()) ==
                  '[{"insert":"\\n"}]') {
                Navigator.of(context).pop('');
                return;
              }

              Navigator.of(context)
                  .pop(jsonEncode(controller.document.toJson()));
            },
            child: Text('DONE'),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FleatherEditor(
              controller: controller,
              padding: const EdgeInsets.all(16),
              autofocus: true,
            ),
          ),
          FleatherToolbar.basic(controller: controller),
        ],
      ),
    );
  }
}
