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
  
  bool _isLoading = false;
  bool _isSaving = false;
  bool _showSuccessOverlay = false;

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
    
    _tabController = TabController(length: 2, vsync: this);
    
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final box = Hive.box('surveyQueue');
    final savedData = box.get(widget.jobId);
    
    if (savedData != null && savedData['synced'] == false) {
      setState(() {
        final payload = Map<String, dynamic>.from(savedData['payload']);
        for (var key in payload.keys) {
          _formData[key] = payload[key];
        }
      });
      return;
    }

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
                  _formData[key] = item[key]?.toString();
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
        _showSuccessOverlay = true;
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildSectionPills() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEAECF0))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final isSelected = _currentSectionIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentSectionIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEFF8FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? const Color(0xFFB2DDFF) : Colors.transparent,
                ),
              ),
              child: Text(
                _sections[index],
                style: TextStyle(
                  color: isSelected ? const Color(0xFF175CD3) : const Color(0xFF475467),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentSection() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAECF0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _sections[_currentSectionIndex],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 24),
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
        const SizedBox(height: 100), // padding for bottom bar
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF101828)),
        title: Hero(
          tag: 'job_title_${widget.jobId}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              '${widget.bankName} - Job ${widget.jobId}',
              style: const TextStyle(
                color: Color(0xFF101828),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1570EF),
          indicatorWeight: 3,
          labelColor: const Color(0xFF1570EF),
          unselectedLabelColor: const Color(0xFF475467),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          dividerColor: const Color(0xFFEAECF0),
          tabs: const [
            Tab(text: 'Vehicle Information'),
            Tab(text: 'Images & Media'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              // FORM TAB
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSectionPills(),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeIn,
                        switchOutCurve: Curves.easeOut,
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: Container(
                          key: ValueKey<int>(_currentSectionIndex),
                          child: _buildCurrentSection(),
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
          // Success Overlay
          if (_showSuccessOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.95),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFECFDF3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF12B76A), size: 64),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Survey Saved Successfully',
                        style: TextStyle(
                          color: Color(0xFF101828),
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFEAECF0))),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFD0D5DD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(color: Color(0xFF344054), fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              if (_currentSectionIndex > 0) const SizedBox(width: 12),
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
                    backgroundColor: const Color(0xFF1570EF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          (_currentSectionIndex < _sections.length - 1) ? 'Next Section' : 'Save & Finish',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                ),
              ),
            ],
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

    final box = Hive.box('imageQueue');
    final images = box.values
        .where((item) => item['jobId'] == widget.jobId)
        .toList();
    setState(() {
      _queuedImages = images.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Future<void> _pickImage(String type) async {
    final isVideo = type == 'Video';
    final XFile? media = isVideo 
        ? await _picker.pickVideo(source: ImageSource.camera)
        : await _picker.pickImage(source: ImageSource.camera);
        
    if (media != null) {
      if (!mounted) return;
      final syncService = Provider.of<SyncService>(context, listen: false);

      await syncService.queueImage(
        jobId: widget.jobId,
        imagePath: media.path,
        imageType: type,
        dbId: widget.dbId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isVideo ? 'Video' : 'Image'} queued for $type!', style: const TextStyle(fontWeight: FontWeight.w500)),
          backgroundColor: const Color(0xFF101828),
          behavior: SnackBarBehavior.floating,
        )
      );

      _loadQueuedImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Capture Evidence',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF101828)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap a card below to take a photo or video.',
          style: TextStyle(fontSize: 14, color: Color(0xFF475467)),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _imageTypes.length,
          itemBuilder: (context, index) {
            final type = _imageTypes[index];
            final existingItem = _queuedImages.where((img) => img['imageType'] == type).lastOrNull;

            if (existingItem != null) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEAECF0)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF101828).withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: existingItem['imageType'] == 'Video'
                            ? Container(
                                color: const Color(0xFFF2F4F7),
                                child: const Center(
                                  child: Icon(Icons.play_circle_fill_rounded, size: 32, color: Color(0xFF98A2B3)),
                                ),
                              )
                            : Image.file(
                                File(existingItem['imagePath']),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF101828)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    existingItem['synced'] == true ? Icons.check_circle : Icons.cloud_upload,
                                    size: 14,
                                    color: existingItem['synced'] == true ? const Color(0xFF12B76A) : const Color(0xFFF79009),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    existingItem['synced'] == true ? "Synced" : "Pending",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF667085), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () => _pickImage(type),
                                child: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF1570EF)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return InkWell(
              onTap: () => _pickImage(type),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEAECF0), style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        type == 'Video' ? Icons.videocam_rounded : Icons.camera_alt_rounded,
                        color: const Color(0xFF667085),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        type,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF344054)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 100), // padding for FAB
      ],
    );
  }
}
