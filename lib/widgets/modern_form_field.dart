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
        String displayValue = widget.initialValue?.toString() ?? '';
        if (isDate && displayValue.isNotEmpty) {
          try {
            final parsed = DateTime.parse(displayValue);
            displayValue = "${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year}";
          } catch (_) {}
        } else if (!isDate && displayValue.isNotEmpty) {
           // For time, if it's HH:mm:ss, parse and convert to hh:mm AM/PM
           try {
             if (displayValue.length >= 5) {
               final parts = displayValue.split(':');
               int h = int.parse(parts[0]);
               int m = int.parse(parts[1]);
               final hourStr = h > 12 ? (h - 12).toString().padLeft(2, '0') : (h == 0 ? '12' : h.toString().padLeft(2, '0'));
               final period = h >= 12 ? 'PM' : 'AM';
               displayValue = "$hourStr:${m.toString().padLeft(2, '0')} $period";
             }
           } catch (_) {}
        }

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
          controller: TextEditingController(text: displayValue),
        );
        break;
      case 'checkbox':
        bool isChecked = widget.initialValue == true || widget.initialValue == 'true' || widget.initialValue == 1 || widget.initialValue == '1';
        content = InkWell(
          onTap: () => widget.onChanged(!isChecked),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isChecked ? theme.colorScheme.primary.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isChecked ? theme.colorScheme.primary : Colors.grey.shade200,
                width: isChecked ? 2 : 1,
              ),
              boxShadow: isChecked
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isChecked ? theme.colorScheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isChecked ? theme.colorScheme.primary : Colors.grey.shade400,
                      width: 2,
                    ),
                    boxShadow: isChecked
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: isChecked
                      ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.field.label,
                    style: TextStyle(
                      fontWeight: isChecked ? FontWeight.bold : FontWeight.w600,
                      color: isChecked ? theme.colorScheme.primary : const Color(0xFF191B23),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _focusNode.hasFocus && widget.field.type != 'checkbox'
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: content,
      ),
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
