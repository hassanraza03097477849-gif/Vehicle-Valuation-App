import 'package:flutter/material.dart';
import '../models/form_field_schema.dart';
import '../services/metadata_service.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'bouncing_widget.dart';

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
          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
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
                        primary: const Color(0xFF1570EF),
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
                        primary: const Color(0xFF1570EF),
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
          decoration: const InputDecoration().copyWith(
            suffixIcon: Icon(
              isDate ? Icons.calendar_today_rounded : Icons.access_time_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
          ),
          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
          controller: TextEditingController(text: displayValue),
        );
        break;
      case 'checkbox':
        bool isChecked = widget.initialValue == true || widget.initialValue == 'true' || widget.initialValue == 1 || widget.initialValue == '1';
        content = InkWell(
          onTap: () => widget.onChanged(!isChecked),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isChecked ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(
                color: isChecked ? theme.colorScheme.primary : theme.colorScheme.outline,
                width: isChecked ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isChecked ? theme.colorScheme.primary : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isChecked ? theme.colorScheme.primary : theme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: isChecked
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.field.label,
                    style: TextStyle(
                      fontWeight: isChecked ? FontWeight.w800 : FontWeight.w600,
                      color: isChecked ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      fontSize: 14,
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
        content = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: options.map((option) {
              final isSelected = currentValue == option;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: BouncingWidget(
                  onTap: () {
                    widget.onChanged(option);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? theme.colorScheme.primary.withOpacity(0.1) 
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
        break;
      default:
        content = const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.field.type != 'checkbox') ...[
            Text(
              widget.field.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
          ],
          content,
        ],
      ),
    );
  }
}
