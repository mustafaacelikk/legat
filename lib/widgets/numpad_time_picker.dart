import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class NumpadTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  const NumpadTimePicker({super.key, required this.initialTime});

  static Future<TimeOfDay?> show(BuildContext context, {required TimeOfDay initialTime}) {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (_) => NumpadTimePicker(initialTime: initialTime),
    );
  }

  @override
  State<NumpadTimePicker> createState() => _NumpadTimePickerState();
}

class _NumpadTimePickerState extends State<NumpadTimePicker> {
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  final FocusNode _hourFocus = FocusNode();
  final FocusNode _minuteFocus = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _hourController = TextEditingController(text: widget.initialTime.hour.toString().padLeft(2, '0'));
    _minuteController = TextEditingController(text: widget.initialTime.minute.toString().padLeft(2, '0'));
    _hourFocus.addListener(() {
      if (_hourFocus.hasFocus) {
        _hourController.selection = TextSelection(baseOffset: 0, extentOffset: _hourController.text.length);
      }
    });
    _minuteFocus.addListener(() {
      if (_minuteFocus.hasFocus) {
        _minuteController.selection = TextSelection(baseOffset: 0, extentOffset: _minuteController.text.length);
      }
    });
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  void _confirm() {
    final h = int.tryParse(_hourController.text);
    final m = int.tryParse(_minuteController.text);
    if (h == null || m == null || h > 23 || m > 59) {
      setState(() => _errorText = 'Geçerli bir saat girin (00:00 - 23:59)');
      return;
    }
    Navigator.pop(context, TimeOfDay(hour: h, minute: m));
  }

  Widget _buildBox(TextEditingController controller, FocusNode focusNode, {VoidCallback? onComplete}) {
    return SizedBox(
      width: 76,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: focusNode == _hourFocus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 2,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.brand, width: 1.5)),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
        onChanged: (v) {
          setState(() => _errorText = null);
          if (v.length == 2) onComplete?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Saat Seç'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBox(_hourController, _hourFocus, onComplete: () => _minuteFocus.requestFocus()),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
              ),
              _buildBox(_minuteController, _minuteFocus),
            ],
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(_errorText!, style: const TextStyle(color: AppColors.dangerText, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(onPressed: _confirm, child: const Text('Tamam')),
      ],
    );
  }
}
