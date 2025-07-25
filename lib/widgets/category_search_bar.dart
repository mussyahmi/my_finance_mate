import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CategorySearchBar extends StatefulWidget {
  const CategorySearchBar({
    super.key,
    required this.searchController,
    required this.searchQueryNotifier,
  });

  final TextEditingController searchController;
  final ValueNotifier<String> searchQueryNotifier;

  @override
  State<CategorySearchBar> createState() => _CategorySearchBarState();
}

class _CategorySearchBarState extends State<CategorySearchBar> {
  late String _currentText;

  @override
  void initState() {
    super.initState();
    _currentText = widget.searchController.text;
    widget.searchController.addListener(_updateText);
  }

  void _updateText() {
    setState(() {
      _currentText = widget.searchController.text;
    });
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_updateText);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(left: 16, top: 16, right: 90, bottom: 16),
      child: TextField(
        controller: widget.searchController,
        decoration: InputDecoration(
          hintText: 'Search categories...',
          border: InputBorder.none,
          suffixIcon: _currentText.isNotEmpty
              ? IconButton(
                  icon: const Icon(CupertinoIcons.clear_circled),
                  onPressed: () {
                    widget.searchController.clear();
                    widget.searchQueryNotifier.value = '';
                  },
                )
              : null,
        ),
        style: const TextStyle(fontSize: 16),
        textAlignVertical: TextAlignVertical.center,
        textAlign: TextAlign.start,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          widget.searchQueryNotifier.value = value;
        },
      ),
    );
  }
}
