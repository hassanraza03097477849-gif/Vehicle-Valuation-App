import 'package:flutter/material.dart';
import '../models/form_field_schema.dart';
import '../services/metadata_service.dart';
import 'package:provider/provider.dart';

class ModernFormField extends StatefulWidget {
  final FormFieldSchema field;
  final dynamic initialValue;
  final Function(dynamic) onChanged;

  const ModernFormField({
    super.key,
    required this.field,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<ModernFormField> createState() => _ModernFormFieldState();
}

class _ModernFormFieldState extends State<ModernFormField> {
  late dynamic currentValue;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
    _focusNode.addListener(() {
      setState(() {});
    });
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metadata = context.watch<MetadataService>();
    final theme = Theme.of(context);
    
    Widget content;
    
    switch (widget.field.type) {
      case 'text':
      case 'number':
        content = TextFormField(
          focusNode: _focusNode,
          decoration: _buildDecoration(),
          style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
          keyboardType: widget.field.type == 'number' ? TextInputType.number : TextInputType.text,
          initialValue: widget.initialValue?.toString(),
          onChanged: widget.onChanged,
        );
        break;
      case 'date':
      case 'time':
        final isDate = widget.field.type == 'date';
        content = TextFormField(
          focusNode: _focusNode,
          readOnly: true,
          onTap: () async {
            if (isDate) {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: theme.copyWith(
                      colorScheme: theme.colorScheme.copyWith(
                        primary: theme.colorScheme.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                final dateStr = "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
                widget.onChanged(dateStr);
              }
            } else {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: theme.copyWith(
                      colorScheme: theme.colorScheme.copyWith(
                        primary: theme.colorScheme.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (time != null) {
                if (!context.mounted) return;
                final hourStr = time.hour > 12 ? (time.hour - 12).toString().padLeft(2, '0') : (time.hour == 0 ? '12' : time.hour.toString().padLeft(2, '0'));
                final minStr = time.minute.toString().padLeft(2, '0');
                final period = time.hour >= 12 ? 'PM' : 'AM';
                final timeStr = "$hourStr:$minStr $period";
                widget.onChanged(timeStr);
              }
            }
          },
          decoration: _buildDecoration().copyWith(
            suffixIcon: Icon(
              isDate ? Icons.calendar_today_rounded : Icons.access_time_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
          controller: TextEditingController(text: widget.initialValue?.toString() ?? ''),
        );
        break;
      case 'checkbox':
        bool isChecked = widget.initialValue == true || widget.initialValue == 'true' || widget.initialValue == 1;
        content = Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: CheckboxListTile(
            title: Text(widget.field.label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF191B23))),
            value: isChecked,
            activeColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (bool? value) => widget.onChanged(value),
          ),
        );
        break;
      case 'dropdown':
        List<String> options = widget.field.options ?? [];
        if (options.isEmpty) {
          options = metadata.getCachedOptions(widget.field.key, ['Option 1', 'Option 2']);
        }
        String? currentValue = widget.initialValue?.toString();
        if (currentValue != null && !options.contains(currentValue)) {
          options.add(currentValue);
        }
        
        content = DropdownButtonFormField<String>(
          focusNode: _focusNode,
          decoration: _buildDecoration(),
          style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
          initialValue: currentValue,
          icon: Icon(Icons.expand_more_rounded, color: theme.colorScheme.primary),
          items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
          onChanged: (value) => widget.onChanged(value),
        );
        break;
      default:
        content = const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: content,
    );
  }
  
  InputDecoration _buildDecoration() {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: widget.field.label,
      labelStyle: TextStyle(
        color: _focusNode.hasFocus ? theme.colorScheme.primary : Colors.grey.shade600,
        fontWeight: _focusNode.hasFocus ? FontWeight.bold : FontWeight.normal,
      ),
      filled: true,
      fillColor: _focusNode.hasFocus ? Colors.white : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}
