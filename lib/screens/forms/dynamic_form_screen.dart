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
import '../../theme/app_theme.dart';
import '../../services/theme_service.dart';
import '../../widgets/animated_corporate_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/bouncing_widget.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUnsavedChangesDialog(savedData);
      });
      return;
    }

    setState(() { _isLoading = true; });
    await _fetchFromERP(savedData);
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  void _showUnsavedChangesDialog(dynamic savedData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unsaved Changes Found', style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text('You have offline changes that have not been synced to the ERP. Do you want to resume editing your offline changes, or wipe them and fetch the latest data from the ERP?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final box = Hive.box('surveyQueue');
                await box.delete(widget.jobId);
                await _fetchFromERP(null);
              },
              child: const Text('Wipe & Fetch from ERP', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  final payload = Map<String, dynamic>.from(savedData['payload']);
                  for (var key in payload.keys) {
                    _formData[key] = payload[key];
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Resume Offline Changes', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchFromERP(dynamic savedData) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.token != null) {
        String apiBankName = widget.bankName == 'OTHERS' ? 'Others' : widget.bankName;
        final response = await http.get(
          Uri.parse('${authService.baseUrl}/getReportDetails$apiBankName/${widget.dbId}'),
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
              
              final Map<String, String> dbToSchemaAlias = {
                'acq_is_reconditioned': 'reconditioned',
                'acq_is_repossesed': 'repossesed',
                'document_seen_is_push_start': 'is_push_start',
                'document_seen_is_key_start': 'is_key_start',
                'air_conditionar_avalibility': 'air_conditionar_available',
                'heater_avalibility': 'heater_available',
                'bluetooth_avalibility': 'cd_player_available',
                'cameras_avalibility': 'cameras_available',
                'inspected_on_time': 'inspected_time',
                'car_toolkit': 'tool_kit',
              };

              for (var key in item.keys) {
                String schemaKey = dbToSchemaAlias[key] ?? key;
                if (_formData.containsKey(schemaKey)) {
                  var val = item[key]?.toString();
                  if (val == 'null') val = null;
                  _formData[schemaKey] = val;
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

  Future<void> _submitSurvey() async {
    // Show confirmation dialog first
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to submit this survey? Please ensure all required images and fields are completed.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Submit Survey'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;

    // If we are on the images tab, we MUST switch back to the form tab 
    // so the Form widget mounts and we can validate it safely.
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    // Safety check just in case
    if (_formKey.currentState == null) return;

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isSaving = true;
      });
      
      final syncService = Provider.of<SyncService>(context, listen: false);
      syncService.saveSurvey(widget.jobId, widget.bankName, _formData, widget.dbId);
      await syncService.submitSurvey(widget.jobId);
      
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
        _showSuccessOverlay = true;
      });
      
      // Wait for a bit so user can see the "Survey Saved Successfully" overlay
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;
      
      Navigator.pop(context, true); // Pass true to indicate we submitted
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    final theme = Theme.of(context);
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5))),
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
                color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                ),
              ),
              child: Text(
                _sections[index],
                style: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: theme.colorScheme.outline, width: 1),
            boxShadow: Provider.of<ThemeService>(context).isDarkMode 
                ? AppTheme.darkShadow 
                : AppTheme.lightShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _sections[_currentSectionIndex],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Hero(
          tag: 'job_title_${widget.jobId}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              '${widget.bankName} - Job ${widget.jobId}',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          dividerColor: theme.colorScheme.outline.withOpacity(0.3),
          tabs: const [
            Tab(text: 'Vehicle Information'),
            Tab(text: 'Images & Media'),
          ],
        ),
      ),
      body: AnimatedCorporateBackground(
        child: Stack(
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
          if (_showSuccessOverlay)
            Positioned.fill(
              child: Container(
                color: theme.colorScheme.surface.withOpacity(0.95),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Survey Saved Successfully',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: theme.colorScheme.surface.withOpacity(0.6),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Fetching from ERP...',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitSurvey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2),
                        )
                      : const Text(
                          'Submit Survey',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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
    final theme = Theme.of(context);
    
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isVideo ? 'Select Video Source' : 'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isVideo ? Icons.videocam_rounded : Icons.camera_alt_rounded, color: theme.colorScheme.primary),
                ),
                title: Text(isVideo ? 'Record a Video' : 'Take a Photo', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_rounded, color: theme.colorScheme.primary),
                ),
                title: Text('Choose from Library', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final XFile? media = isVideo 
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source, imageQuality: 50);
        
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

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Front View':
      case 'Front Elevation':
        return Icons.directions_car_rounded;
      case 'Back View':
        return Icons.time_to_leave_rounded;
      case 'Left Side View':
      case 'Right Side View':
        return Icons.view_sidebar_rounded;
      case 'Front Seat View':
      case 'Back Seat View':
      case 'Interior View':
        return Icons.airline_seat_recline_normal_rounded;
      case 'Front Number Plate View':
      case 'Back Number Plate View':
      case 'Original Number Plates View':
        return Icons.branding_watermark_rounded;
      case 'Engine View':
      case 'Bonnet Inside View':
        return Icons.engineering_rounded;
      case 'Engine Number':
      case 'Chassis No':
        return Icons.pin_rounded;
      case 'Odometer':
        return Icons.speed_rounded;
      case 'Key':
        return Icons.vpn_key_rounded;
      case 'Trunk':
        return Icons.luggage_rounded;
      case 'Tickly':
        return Icons.label_rounded;
      case 'Video':
        return Icons.videocam_rounded;
      default:
        return Icons.camera_alt_rounded;
    }
  }

  String? _getAssetPathForType(String type) {
    switch (type) {
      case 'Back Seat View': return 'assets/images/BACK SEAT VIEW.webp';
      case 'Back Number Plate View': return 'assets/images/BACK NUMBER PLATE VIEW.webp';
      case 'Back View': return 'assets/images/BACK VIEW.webp';
      case 'Bonnet Inside View': return 'assets/images/BONET INSIDE VIEW.webp';
      case 'Chassis No': return 'assets/images/CHASSIS NO.webp';
      case 'Engine Number': return 'assets/images/ENGINE NO.webp';
      case 'Engine View': return 'assets/images/ENGINE VIEW.webp';
      case 'Front Elevation': return 'assets/images/FRONT ELEVATION.webp';
      case 'Front Number Plate View': return 'assets/images/FRONT NO PLATE VIEW.webp';
      case 'Front Seat View': return 'assets/images/FRONT SEAT VIEW.webp';
      case 'Front View': return 'assets/images/FRONT VIEW.webp';
      case 'Interior View': return 'assets/images/INTERIOR VIEW.webp';
      case 'Key': return 'assets/images/KEY.webp';
      case 'Left Side View': return 'assets/images/LEFT SIDE VIEW.webp';
      case 'Odometer': return 'assets/images/ODOMETER VIEW.webp';
      case 'Original Number Plates View': return 'assets/images/ORIGNAL NO PLATE VIEW.webp';
      case 'Right Side View': return 'assets/images/RIGHT SIDE VIEW.webp';
      case 'Tickly': return 'assets/images/TICKLY.webp';
      case 'Trunk': return 'assets/images/TRUNK.webp';
      case 'Video': return 'assets/images/VIDEO.webp';
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Capture Evidence',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap a card below to take a photo or video.',
          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.8), fontWeight: FontWeight.w500),
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
              return BouncingWidget(
                onTap: () => _pickImage(type), // Tap to replace/retake
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: existingItem['imageType'] == 'Video'
                            ? Container(
                                color: Colors.black12,
                                child: const Center(
                                  child: Icon(Icons.play_circle_fill_rounded, size: 48, color: Colors.white70),
                                ),
                              )
                            : Image.file(
                                File(existingItem['imagePath']),
                                fit: BoxFit.cover,
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.6),
                          border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              type,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: theme.colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: existingItem['synced'] == true 
                                      ? const Color(0xFF12B76A).withOpacity(0.2) 
                                      : const Color(0xFFF79009).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        existingItem['synced'] == true ? Icons.check_circle : Icons.cloud_upload,
                                        size: 12,
                                        color: existingItem['synced'] == true ? const Color(0xFF12B76A) : const Color(0xFFF79009),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        existingItem['synced'] == true ? "Synced" : "Pending",
                                        style: TextStyle(
                                          fontSize: 10, 
                                          color: existingItem['synced'] == true ? const Color(0xFF12B76A) : const Color(0xFFF79009), 
                                          fontWeight: FontWeight.w800
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.cameraswitch_rounded, size: 16, color: Color(0xFF1570EF)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return BouncingWidget(
              onTap: () => _pickImage(type),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _getAssetPathForType(type) != null
                          ? Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Image.asset(
                                _getAssetPathForType(type)!,
                                fit: BoxFit.contain,
                                color: theme.brightness == Brightness.dark ? Colors.white : null,
                              ),
                            )
                          : Center(
                              child: Icon(
                                _getIconForType(type),
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                                size: 48,
                              ),
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.4),
                        border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              type,
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: theme.colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_a_photo_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
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
