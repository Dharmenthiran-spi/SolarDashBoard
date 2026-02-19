import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Config/Themes/app_text_styles.dart';

class GenericDropdownProvider<T> extends ChangeNotifier {
  final TextEditingController controller;
  List<T> items;
  final String Function(T) itemLabel;
  final Function(T)? onSelected;
  final LayerLink _layerLink = LayerLink();
  final FocusNode textFieldFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  List<T> filteredItems = [];
  bool showDropdown = false;

  final double? width;

  GenericDropdownProvider({
    required this.controller,
    required this.items,
    required this.itemLabel,
    this.onSelected,
    this.width,
  }) {
    textFieldFocusNode.addListener(_handleFocusChange);
    filteredItems = List.from(items);
  }

  @override
  void dispose() {
    textFieldFocusNode.removeListener(_handleFocusChange);
    // Remove dropdown without notifying to avoid "locked widget tree" error
    _overlayEntry?.remove();
    _overlayEntry = null;
    showDropdown = false;
    textFieldFocusNode.dispose();
    super.dispose();
  }

  void updateItems(List<T> newItems) {
    items = List.from(newItems);
    filteredItems = List.from(newItems);
    if (showDropdown) {
      notifyListeners();
    }
  }

  void _handleFocusChange() {
    if (textFieldFocusNode.hasFocus) {
      _showDropdown();
    } else {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!textFieldFocusNode.hasFocus && _overlayEntry != null) {
          _removeDropdown();
        }
      });
    }
  }

  void _showDropdown() {
    if (textFieldFocusNode.context == null) return;
    _removeDropdown();
    showDropdown = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(textFieldFocusNode.context!).insert(_overlayEntry!);
    notifyListeners();
  }

  void _removeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    showDropdown = false;
    notifyListeners();
  }

  void filterItems(String query) {
    if (query.isEmpty) {
      filteredItems = List.from(items);
    } else {
      filteredItems = items
          .where((item) => itemLabel(item).toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    if (showDropdown) {
      notifyListeners();
    } else {
      _showDropdown();
    }
  }

  void selectItem(T item) {
    final label = itemLabel(item);
    controller.value = TextEditingValue(
      text: label,
      selection: TextSelection.collapsed(offset: label.length),
    );

    onSelected?.call(item);

    Future.delayed(const Duration(milliseconds: 200), () {
      _removeDropdown();
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox =
        textFieldFocusNode.context!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        width: width ?? size.width,
        left: offset.dx,
        top: offset.dy + size.height + 15,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(14, size.height + 30),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8.0),
            color: Theme.of(context).cardColor,
            child: ChangeNotifierProvider<GenericDropdownProvider<T>>.value(
              value: this,
              child: Consumer<GenericDropdownProvider<T>>(
                builder: (context, provider, _) {
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: provider.filteredItems.isNotEmpty
                        ? ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: provider.filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = provider.filteredItems[index];
                              final label = provider.itemLabel(item);
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                child: TextButton(
                                  onPressed: () =>
                                      provider.selectItem(item),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    backgroundColor: Colors.white54,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      label,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No results found',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DropdownField<T> extends StatefulWidget {
  final TextEditingController controller;
  final List<T> items;
  final String Function(T) itemLabel;
  final Function(T)? onSelected;
  final String? hintText;
  final Color? textColor;
  final double? width;

  const DropdownField({
    Key? key,
    required this.controller,
    required this.items,
    required this.itemLabel,
    this.onSelected,
    this.hintText,
    this.textColor,
    this.width,
  }) : super(key: key);

  @override
  State<DropdownField<T>> createState() => _DropdownFieldState<T>();
}

class _DropdownFieldState<T> extends State<DropdownField<T>> {
  late GenericDropdownProvider<T> _provider;

  @override
  void initState() {
    super.initState();
    _provider = GenericDropdownProvider<T>(
      controller: widget.controller,
      items: widget.items,
      itemLabel: widget.itemLabel,
      onSelected: widget.onSelected,
      width: widget.width,
    );
  }

  @override
  void didUpdateWidget(covariant DropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _provider.updateItems(widget.items);
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GenericDropdownProvider<T>>.value(
      value: _provider,
      child: Consumer<GenericDropdownProvider<T>>(
        builder: (context, provider, child) {
          return CompositedTransformTarget(
            link: provider._layerLink,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextField(
                controller: provider.controller,
                focusNode: provider.textFieldFocusNode,
                onChanged: (value) => provider.filterItems(value),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyText(Colors.black),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
