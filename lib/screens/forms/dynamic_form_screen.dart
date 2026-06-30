import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import '../../services/sync_service.dart';
import '../../services/metadata_service.dart';
import '../../models/form_field_schema.dart';
import '../../schemas/bank_schemas.dart';
import '../../utils/bank_themes.dart';

class DynamicFormScreen extends StatefulWidget {
  final String jobId;
  final String bankName;

  const DynamicFormScreen({
    super.key,
    required this.jobId,
    required this.bankName,
  });

  @override
  _DynamicFormScreenState createState() => _DynamicFormScreenState();
}

class _DynamicFormScreenState extends State<DynamicFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  late TabController _tabController;
  int _currentPage = 0;

  final Map<String, dynamic> _formData = {};
  late List<FormFieldSchema> _schema;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _schema =
        BankSchemas.schemas[widget.bankName] ?? BankSchemas.schemas['OTHERS']!;

    for (var field in _schema) {
      _formData[field.key] = null;
    }
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final box = Hive.box('surveyQueue');
    final savedData = box.get(widget.jobId);
    if (savedData != null) {
      setState(() {
        final payload = Map<String, dynamic>.from(savedData['payload']);
        for (var key in payload.keys) {
          _formData[key] = payload[key];
        }
      });
    }
  }

  void _autoSave() {
    final syncService = Provider.of<SyncService>(context, listen: false);
    syncService.saveSurvey(widget.jobId, widget.bankName, _formData);
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final syncService = Provider.of<SyncService>(context, listen: false);
      syncService.saveSurvey(widget.jobId, widget.bankName, _formData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Survey Saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _nextPage(int totalSections) {
    if (_currentPage < totalSections - 1) {
      _pageController.jumpToPage(_currentPage + 1);
    } else {
      _saveForm();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.jumpToPage(_currentPage - 1);
    }
  }

  Widget _buildField(FormFieldSchema field) {
    final metadata = Provider.of<MetadataService>(context, listen: false);
    switch (field.type) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
            ),
            initialValue: _formData[field.key]?.toString(),
            onChanged: (value) {
              _formData[field.key] = value;
              _autoSave();
            },
          ),
        );
      case 'number':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            initialValue: _formData[field.key]?.toString(),
            onChanged: (value) {
              _formData[field.key] = value;
              _autoSave();
            },
          ),
        );
      case 'date':
      case 'time':
        // Display a text field with a tap handler to open a picker (simplified text entry for now)
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: '${field.label} (${field.type})',
              border: const OutlineInputBorder(),
              suffixIcon: Icon(
                field.type == 'date' ? Icons.calendar_today : Icons.access_time,
              ),
            ),
            initialValue: _formData[field.key]?.toString(),
            onChanged: (value) {
              _formData[field.key] = value;
              _autoSave();
            },
          ),
        );
      case 'checkbox':
        bool isChecked =
            _formData[field.key] == true ||
            _formData[field.key] == 'true' ||
            _formData[field.key] == 1;
        return CheckboxListTile(
          title: Text(field.label),
          value: isChecked,
          onChanged: (bool? value) {
            setState(() {
              _formData[field.key] = value;
              _autoSave();
            });
          },
        );
      case 'dropdown':
        List<String> options = field.options ?? [];
        if (options.isEmpty) {
          options = metadata.getCachedOptions(field.key, [
            'Option 1',
            'Option 2',
          ]);
        }

        String? currentValue = _formData[field.key]?.toString();
        if (currentValue != null && !options.contains(currentValue)) {
          // If the cached API hasn't loaded or it's a new free-text value, fall back to null
          // or we could allow free-text input if needed.
          if (!options.contains(currentValue)) {
            options.add(currentValue);
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
            ),
            value: currentValue,
            items: options.map((option) {
              return DropdownMenuItem(value: option, child: Text(option));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _formData[field.key] = value;
                _autoSave();
              });
            },
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<FormFieldSchema>> groupedFields = {};
    for (var field in _schema) {
      if (!groupedFields.containsKey(field.section)) {
        groupedFields[field.section] = [];
      }
      groupedFields[field.section]!.add(field);
    }

    final sections = groupedFields.keys.toList();
    final totalSections = sections.length;
    final theme = BankTheme.getTheme(widget.bankName);

    return DefaultTabController(
      length: 2,
      child: Theme(
        data: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: theme.primaryColor),
          primaryColor: theme.primaryColor,
          appBarTheme: AppBarTheme(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: Text('${widget.bankName} - Job ${widget.jobId}'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Form', icon: Icon(Icons.assignment)),
                Tab(text: 'Images', icon: Icon(Icons.camera_alt)),
              ],
              indicatorColor: theme.secondaryColor,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: totalSections == 0
                          ? 0
                          : (_currentPage + 1) / totalSections,
                      backgroundColor: theme.primaryColor.withValues(
                        alpha: 0.2,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.primaryColor,
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) =>
                            setState(() => _currentPage = index),
                        itemCount: totalSections,
                        itemBuilder: (context, index) {
                          String sectionName = sections[index];
                          List<FormFieldSchema> fields =
                              groupedFields[sectionName]!;
                          String stepText =
                              'Step ${index + 1} of $totalSections: $sectionName';
                          return ListView(
                            padding: const EdgeInsets.all(16.0),
                            children: [
                              Text(
                                stepText,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                              const Divider(thickness: 2),
                              const SizedBox(height: 16),
                              ...fields.map((field) => _buildField(field)),
                            ],
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade400,
                                foregroundColor: Colors.black87,
                              ),
                              onPressed: _currentPage == 0 ? null : _prevPage,
                              child: const Text('Back'),
                            ),
                            ElevatedButton(
                              onPressed: () => _nextPage(totalSections),
                              child: Text(
                                _currentPage == totalSections - 1
                                    ? 'Finish'
                                    : 'Next',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ImagePickerTab(jobId: widget.jobId),
            ],
          ),
        ),
      ),
    );
  }
}

class ImagePickerTab extends StatefulWidget {
  final String jobId;
  const ImagePickerTab({super.key, required this.jobId});

  @override
  _ImagePickerTabState createState() => _ImagePickerTabState();
}

class _ImagePickerTabState extends State<ImagePickerTab> {
  final ImagePicker _picker = ImagePicker();
  List<String> _imageTypes = [];
  String? _selectedType;
  List<Map<String, dynamic>> _queuedImages = [];

  @override
  void initState() {
    super.initState();
    _loadQueuedImages();
  }

  void _loadQueuedImages() {
    final metadata = Provider.of<MetadataService>(context, listen: false);
    _imageTypes = metadata.getCachedOptions('image_types', [
      'Front Side',
      'Back Side',
      'Right Side',
      'Left Side',
      'Engine',
      'Chassis Number',
      'Dashboard',
      'Interior',
      'Other',
    ]);

    final box = Hive.box('imageQueue');
    final images = box.values
        .where((item) => item['jobId'] == widget.jobId)
        .toList();
    setState(() {
      _queuedImages = images.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Future<void> _pickImage() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image type first!')),
      );
      return;
    }

    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      if (!mounted) return;
      final syncService = Provider.of<SyncService>(context, listen: false);

      await syncService.queueImage(
        jobId: widget.jobId,
        imagePath: photo.path,
        imageType: _selectedType!,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image queued for upload!')));

      _loadQueuedImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Image Type / Reference',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedType,
                  items: _imageTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedType = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const Text(
            'Queued Images for this Job',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _queuedImages.isEmpty
                ? const Center(child: Text('No images queued yet.'))
                : ListView.builder(
                    itemCount: _queuedImages.length,
                    itemBuilder: (context, index) {
                      final item = _queuedImages[index];
                      return Card(
                        child: ListTile(
                          leading: Image.file(
                            File(item['imagePath']),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(item['imageType']),
                          subtitle: Text(
                            'Status: ${item['synced'] == true ? "Synced" : "Pending Sync"}',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
