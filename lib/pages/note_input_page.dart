import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/foundation.dart';
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
  final FocusNode _focusNode = FocusNode();

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
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                title: Text('Enter Note'),
                centerTitle: true,
                scrolledUnderElevation: 9999,
                floating: true,
                snap: true,
                actions: [
                  TextButton(
                    onPressed: () {
                      if (jsonEncode(controller.document.toJson()) ==
                          '[{"insert":"\\n"}]') {
                        Navigator.of(context).pop('empty');
                        return;
                      }

                      Navigator.of(context)
                          .pop(jsonEncode(controller.document.toJson()));
                    },
                    child: Text('DONE'),
                  )
                ],
              ),
            ],
            body: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (kIsWeb) _focusNode.requestFocus();
                    },
                    child: FleatherEditor(
                      controller: controller,
                      focusNode: _focusNode,
                      padding: const EdgeInsets.all(16),
                      autofocus: true,
                    ),
                  ),
                ),
                FleatherToolbar.basic(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
