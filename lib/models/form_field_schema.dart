class FormFieldSchema {
  final String key;
  final String label;
  final String type;
  final String section;
  final List<String>? options;

  FormFieldSchema({
    required this.key,
    required this.label,
    required this.type,
    required this.section,
    this.options,
  });
}
