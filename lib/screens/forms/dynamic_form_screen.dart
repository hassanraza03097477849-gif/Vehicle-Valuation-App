import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import '../../services/auth_service.dart';
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
  final String dbId;

  const DynamicFormScreen({
    super.key,
    required this.jobId,
    required this.bankName,
    required this.dbId,
  });

  @override
  State<DynamicFormScreen> createState() => _DynamicFormScreenState();
}

class _DynamicFormScreenState extends State<DynamicFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _isSaving = false;

  final Map<String, dynamic> _formData = {};
  late List<FormFieldSchema> _schema;
  
  final Map<String, List<FormFieldSchema>> _groupedFields = {};
  List<String> _sections = [];
  int _currentSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _schema = BankSchemas.schemas[widget.bankName] ?? BankSchemas.schemas['OTHERS']!;

    for (var field in _schema) {
      _formData[field.key] = null;
      if (!_groupedFields.containsKey(field.section)) {
        _groupedFields[field.section] = [];
      }
      _groupedFields[field.section]!.add(field);
    }
    _sections = _groupedFields.keys.toList();
    
    // 2 main tabs: Form and Images
    _tabController = TabController(length: 2, vsync: this);
    
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final box = Hive.box('surveyQueue');
    final savedData = box.get(widget.jobId);
    
    // Prioritize unsynced local changes
    if (savedData != null && savedData['synced'] == false) {
      setState(() {
        final payload = Map<String, dynamic>.from(savedData['payload']);
        for (var key in payload.keys) {
          _formData[key] = payload[key];
        }
      });
      return;
    }

    // Fetch from ERP API
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.token != null) {
        final response = await http.get(
          Uri.parse('${authService.baseUrl}/getReportDetails${widget.bankName}/${widget.dbId}'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${authService.token}',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data != null && data.isNotEmpty) {
            setState(() {
              final item = data is List ? data.first : data;
              for (var key in item.keys) {
                if (_formData.containsKey(key)) {
                  _formData[key] = item[key]?.toString(); // Safely cast to string
                }
              }
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching ERP data: $e');
    }

    // Fallback to synced local data if API fails or returns empty
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
    syncService.saveSurvey(widget.jobId, widget.bankName, _formData, widget.dbId);
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isSaving = true;
      });
      
      final syncService = Provider.of<SyncService>(context, listen: false);
      syncService.saveSurvey(widget.jobId, widget.bankName, _formData, widget.dbId);
      
      await Future.delayed(const Duration(milliseconds: 1000));
      
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
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildSectionPills(ThemeData theme) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final isSelected = _currentSectionIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentSectionIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                border: isSelected ? null : Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Text(
                  _sections[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bankTheme = BankTheme.getTheme(widget.bankName);
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: bankTheme.primaryColor),
      primaryColor: bankTheme.primaryColor,
      appBarTheme: AppBarTheme(
        backgroundColor: bankTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );

    return Theme(
      data: theme,
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
            indicatorColor: bankTheme.secondaryColor,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            tabs: const [
              Tab(text: 'Vehicle Information', icon: Icon(Icons.assignment_rounded, size: 24)),
              Tab(text: 'Images', icon: Icon(Icons.camera_alt_rounded, size: 24)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // FORM TAB
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildSectionPills(theme),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.1),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: ListView(
                        key: ValueKey<int>(_currentSectionIndex),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        children: [
                          GlassCard(
                            borderRadius: 32.0,
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _sections[_currentSectionIndex],
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                ..._groupedFields[_sections[_currentSectionIndex]]!.map(
                                  (field) => ModernFormField(
                                    field: field,
                                    initialValue: _formData[field.key],
                                    onChanged: (value) {
                                      setState(() {
                                        _formData[field.key] = value;
                                      });
                                      _autoSave();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 100), // padding for FAB
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // IMAGES TAB
            ImagePickerTab(jobId: widget.jobId, dbId: widget.dbId),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (_currentSectionIndex > 0)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentSectionIndex--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                if (_currentSectionIndex > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving 
                        ? null 
                        : (_currentSectionIndex < _sections.length - 1)
                            ? () {
                                setState(() {
                                  _currentSectionIndex++;
                                });
                              }
                            : _saveForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            (_currentSectionIndex < _sections.length - 1) ? 'Next' : 'Save & Finish',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ImagePickerTab extends StatefulWidget {
  final String jobId;
  final String dbId;
  const ImagePickerTab({super.key, required this.jobId, required this.dbId});

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
      'Back Seat View', 'Back Number Plate View', 'Back View', 
      'Bonnet Inside View', 'Chassis No', 'Engine Number', 
      'Engine View', 'Front Elevation', 'Front Number Plate View', 
      'Front Seat View', 'Front View', 'Interior View', 'Key', 
      'Left Side View', 'Odometer', 'Original Number Plates View', 
      'Right Side View', 'Tickly', 'Trunk', 'Video'
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

    final isVideo = _selectedType == 'Video';
    final XFile? media = isVideo 
        ? await _picker.pickVideo(source: ImageSource.camera)
        : await _picker.pickImage(source: ImageSource.camera);
        
    if (media != null) {
      if (!mounted) return;
      final syncService = Provider.of<SyncService>(context, listen: false);

      await syncService.queueImage(
        jobId: widget.jobId,
        imagePath: media.path,
        imageType: _selectedType!,
        dbId: widget.dbId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${isVideo ? 'Video' : 'Image'} queued for upload!'))
      );

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
                icon: Icon(_selectedType == 'Video' ? Icons.videocam_rounded : Icons.camera_alt_rounded),
                label: Text(_selectedType == 'Video' ? 'Record Video' : 'Open Camera', style: const TextStyle(fontWeight: FontWeight.bold)),
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
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        _queuedImages.isEmpty
            ? const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No images queued yet.', style: TextStyle(color: Colors.grey)),
              ))
            : SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _queuedImages.length,
                  itemBuilder: (context, index) {
                    final item = _queuedImages[index];
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Hero(
                                tag: 'image_${item['imagePath']}',
                              child: item['imageType'] == 'Video'
                                  ? Container(
                                      color: Colors.black12,
                                      child: const Center(
                                        child: Icon(Icons.play_circle_fill_rounded, size: 48, color: Colors.black54),
                                      ),
                                    )
                                  : Image.file(
                                      File(item['imagePath']),
                                      fit: BoxFit.cover,
                                    ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['imageType'],
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      item['synced'] == true ? Icons.check_circle : Icons.cloud_upload,
                                      size: 14,
                                      color: item['synced'] == true ? Colors.green : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item['synced'] == true ? "Synced" : "Pending",
                                      style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        const SizedBox(height: 100), // padding for FAB
      ],
    );
  }
}
