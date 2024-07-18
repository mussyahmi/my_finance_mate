import 'package:flutter/material.dart';

class CustomDraggableScrollableSheet extends StatefulWidget {
  final double initialSize;
  final Widget title;
  final Widget contents;

  const CustomDraggableScrollableSheet({
    super.key,
    required this.initialSize,
    required this.title,
    required this.contents,
  });

  @override
  State<CustomDraggableScrollableSheet> createState() =>
      _CustomDraggableScrollableSheetState();
}

class _CustomDraggableScrollableSheetState
    extends State<CustomDraggableScrollableSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: widget.initialSize,
      minChildSize: 0.3,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              widget.title,
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      widget.contents,
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
