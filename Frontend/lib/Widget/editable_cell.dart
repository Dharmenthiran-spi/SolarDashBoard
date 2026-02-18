import 'package:flutter/material.dart';
import '../Config/Themes/app_text_styles.dart';
import 'simple_map_picker.dart';

class EditableCell extends StatefulWidget {
  final String value;
  final Function(String) onChanged;
  final double height;
  final double width;
  final bool isLocation;
  final bool obscureText;
  final Function(Map<String, dynamic>)? onMapResult;

  const EditableCell({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.height,
    required this.width,
    this.isLocation = false,
    this.obscureText = false,
    this.onMapResult,
  }) : super(key: key);

  @override
  State<EditableCell> createState() => _EditableCellState();
}

class _EditableCellState extends State<EditableCell> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant EditableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.8),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _controller,
              style: AppTextStyles.editableBody1(),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.text,
              obscureText: widget.obscureText,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: widget.onChanged,
            ),
          ),
          if (widget.isLocation)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.location_on,
                color: Colors.blueAccent,
                size: 16,
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SimpleMapPicker(onLocationSelected: (_) {}),
                  ),
                );

                if (result != null && result is Map) {
                  final Map<String, dynamic> typedResult =
                      Map<String, dynamic>.from(result);

                  if (widget.onMapResult != null) {
                    widget.onMapResult!(typedResult);
                  } else {
                    final lat = result['latitude'];
                    final lng = result['longitude'];
                    widget.onChanged("$lat, $lng");
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}
