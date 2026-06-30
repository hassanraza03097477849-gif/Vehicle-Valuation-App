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
import '../../widgets/glass_card.dart';
import '../../widgets/modern_form_field.dart';

class DynamicFormScreen extends StatefulWidget {
  final String jobId;
  final String bankName;

  const DynamicFormScreen({
    super.key,
    required this.jobId,
    required this.bankName,
  });

  @override
  State<DynamicFormScreen> createState() => _DynamicFormScreenState();
}

class _DynamicFormScreenState extends State<DynamicFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  late TabController _tabController;
  int _currentPage = 0;
  bool _isSaving = false;

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

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isSaving = true;
      });
      
      final syncService = Provider.of<SyncService>(context, listen: false);
      syncService.saveSurvey(widget.jobId, widget.bankName, _formData);
      
      // Artificial delay for premium feel
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
      });

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
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveForm();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Hero(
              tag: 'job_title_${widget.jobId}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  '${widget.bankName} - Job ${widget.jobId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Form', icon: Icon(Icons.assignment_rounded)),
                Tab(text: 'Images', icon: Icon(Icons.camera_alt_rounded)),
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
                      value: totalSections == 0 ? 0 : (_currentPage + 1) / totalSections,
                      backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                      minHeight: 6,
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) => setState(() => _currentPage = index),
                        itemCount: totalSections,
                        itemBuilder: (context, index) {
                          String sectionName = sections[index];
                          List<FormFieldSchema> fields = groupedFields[sectionName]!;
                          String stepText = 'Step ${index + 1} of $totalSections: $sectionName';
                          return ListView(
                            padding: const EdgeInsets.all(24.0),
                            children: [
                              GlassCard(
                                borderRadius: 32.0,
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      stepText,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    ...fields.map((field) => ModernFormField(
                                      field: field,
                                      initialValue: _formData[field.key],
                                      onChanged: (value) {
                                        setState(() {
                                          _formData[field.key] = value;
                                        });
                                        _autoSave();
                                      },
                                    )),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                  foregroundColor: Colors.grey.shade800,
                                  elevation: 0,
                                ),
                                onPressed: _currentPage == 0 || _isSaving ? null : _prevPage,
                                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : () => _nextPage(totalSections),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        _currentPage == totalSections - 1 ? 'Save & Finish' : 'Next Step',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
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
  State<ImagePickerTab> createState() => _ImagePickerTabState();
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
      'Front Side', 'Back Side', 'Right Side', 'Left Side',
      'Engine', 'Chassis Number', 'Dashboard', 'Interior', 'Other',
    ]);
    if (_imageTypes.isNotEmpty && _selectedType == null) {
      _selectedType = _imageTypes.first;
    }

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

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image queued for upload!')));

      _loadQueuedImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        GlassCard(
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Capture Evidence',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Image Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                initialValue: _selectedType,
                items: _imageTypes.map((type) {
                  return DropdownMenuItem<String>(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedType = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Open Camera', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Queued Images',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        _queuedImages.isEmpty
            ? const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No images queued yet.', style: TextStyle(color: Colors.grey)),
              ))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _queuedImages.length,
                itemBuilder: (context, index) {
                  final item = _queuedImages[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(
                          File(item['imagePath']),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        item['imageType'],
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            item['synced'] == true ? Icons.cloud_done : Icons.cloud_upload,
                            size: 14,
                            color: item['synced'] == true ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(item['synced'] == true ? "Synced" : "Pending Sync"),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
