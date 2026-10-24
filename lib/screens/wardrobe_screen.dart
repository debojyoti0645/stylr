import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylr/constants/app_colors.dart';
import 'package:stylr/models/clothing_item.dart';
import 'package:stylr/screens/garment_details_screen.dart';
import 'package:stylr/services/background_removal_service.dart';
import 'package:stylr/services/garment_image_analysis.dart';
import 'package:stylr/services/wardrobe_image_storage.dart';
import 'package:stylr/services/wardrobe_storage.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final ImagePicker _picker = ImagePicker();

  List<ClothingItem> _items = [];
  bool _loading = true;
  bool _adding = false;
  bool _processingImage = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _items = WardrobeStorage.getAll();
      _loading = false;
    });
  }

  Future<void> _addClothing(ImageSource source) async {
    if (_adding) return;
    setState(() => _adding = true);

    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final photo = await _picker.pickImage(source: source, imageQuality: 90);

      if (photo == null || !mounted) return;

      String? processedImagePath;
      Object? processingFailure;
      GarmentImageAnalysis? analysis;
      setState(() => _processingImage = true);

      try {
        final processedFile = await BackgroundRemovalService().processImageFile(
          File(photo.path),
        );
        processedImagePath = processedFile.path;
        try {
          analysis = await const GarmentImageAnalysisService().analyzeFile(
            processedFile,
          );
        } catch (error) {
          debugPrint('[GarmentAnalysis] Local colour analysis failed: $error');
        }
      } catch (error) {
        processedImagePath = null;
        processingFailure = error;
        debugPrint(
          '[BackgroundRemoval] Failed; keeping the original photo: $error',
        );
      } finally {
        if (mounted) setState(() => _processingImage = false);
      }

      if (!mounted) return;
      final details = await showDialog<Map<String, String>>(
        context: context,
        builder: (_) => _AddClothingDialog(
          imagePath: processedImagePath ?? photo.path,
          analysis: analysis,
          processingFailed: processingFailure != null,
        ),
      );

      if (details == null || !mounted) {
        await WardrobeImageStorage.deleteImage(processedImagePath);
        return;
      }
      final id = DateTime.now().microsecondsSinceEpoch.toString();

      String? savedPath;
      late final ClothingItem item;
      try {
        savedPath = await WardrobeImageStorage.saveImage(File(photo.path), id);

        item = ClothingItem(
          id: id,
          name: details['name']!,
          category: details['category']!,
          subtype: details['subtype'] ?? '',
          colors: _splitCommaSeparated(details['colors'] ?? ''),
          pattern: details['pattern'] ?? '',
          style: details['style'] ?? '',
          neckline: details['neckline'] ?? '',
          sleeveLength: details['sleeveLength'] ?? '',
          garmentLength: details['garmentLength'] ?? '',
          fabric: details['fabric'] ?? '',
          fit: details['fit'] ?? '',
          occasions: _splitCommaSeparated(details['occasions'] ?? ''),
          season: details['season'] ?? '',
          originalImagePath: savedPath,
          cleanImagePath: processedImagePath,
          dateAdded: DateTime.now(),
        );

        await WardrobeStorage.save(item);
      } catch (error) {
        try {
          await WardrobeImageStorage.deleteImage(savedPath);
          await WardrobeImageStorage.deleteImage(processedImagePath);
        } catch (cleanupError) {
          debugPrint(
            '[Wardrobe] Could not remove an image after save failed: '
            '$cleanupError',
          );
        }
        rethrow;
      }

      if (!mounted) return;

      _loadItems();

      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            processingFailure != null
                ? 'Background removal failed. The original photo was saved.'
                : processedImagePath == null
                ? 'Clothing item saved with the original image.'
                : 'Clothing item saved with a background-cleaned preview.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      messenger?.showSnackBar(
        SnackBar(content: Text('Could not add item: $error')),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  List<String> _splitCommaSeparated(String value) => value
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();

  Future<void> _openDetails(ClothingItem item) async {
    final updated = await Navigator.of(context).push<ClothingItem>(
      MaterialPageRoute(builder: (_) => GarmentDetailsScreen(item: item)),
    );
    if (updated != null && mounted) _loadItems();
  }

  Future<void> _deleteItem(ClothingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete clothing item?'),
        content: Text('Remove "${item.name}" from your wardrobe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await WardrobeStorage.delete(item.id);
      await WardrobeImageStorage.deleteImage(item.originalImagePath);

      if (item.cleanImagePath != null &&
          item.cleanImagePath != item.originalImagePath) {
        await WardrobeImageStorage.deleteImage(item.cleanImagePath);
      }

      if (!mounted) return;

      _loadItems();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete item: $error')));
    }
  }

  void _showAddOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _addClothing(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _addClothing(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('My Wardrobe'),
        backgroundColor: AppColors.cream,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adding ? null : _showAddOptions,
        backgroundColor: AppColors.deepRose,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add clothing'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.checkroom_rounded,
                            size: 76,
                            color: AppColors.mutedRose,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your wardrobe starts here',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add a clothing photo to start organising '
                            'your personal wardrobe.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _showAddOptions,
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: const Text('Add your first item'),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        color: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: AppColors.border),
                        ),
                        child: InkWell(
                          onTap: () => _openDetails(item),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      File(
                                        item.cleanImagePath ??
                                            item.originalImagePath,
                                      ),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              size: 40,
                                            ),
                                          ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      left: 10,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: AppColors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 5,
                                          ),
                                          child: Text(
                                            item.cleanImagePath == null
                                                ? 'Original photo'
                                                : 'Processed cutout',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: IconButton(
                                        tooltip: 'Delete item',
                                        onPressed: () => _deleteItem(item),
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppColors.white,
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.deepRose,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
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
          ),
          if (_processingImage)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black38,
                child: Center(
                  child: Card(
                    color: AppColors.cream,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 14),
                          Text(
                            'Preparing garment locally...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddClothingDialog extends StatefulWidget {
  const _AddClothingDialog({
    required this.imagePath,
    required this.analysis,
    required this.processingFailed,
  });

  final String imagePath;
  final GarmentImageAnalysis? analysis;
  final bool processingFailed;

  @override
  State<_AddClothingDialog> createState() => _AddClothingDialogState();
}

class _AddClothingDialogState extends State<_AddClothingDialog> {
  final _nameController = TextEditingController();
  final _subtypeController = TextEditingController();
  final _colorsController = TextEditingController();
  final _patternController = TextEditingController();
  final _styleController = TextEditingController();
  final _necklineController = TextEditingController();
  final _sleeveController = TextEditingController();
  final _lengthController = TextEditingController();
  final _fabricController = TextEditingController();
  final _fitController = TextEditingController();
  final _occasionsController = TextEditingController();
  final _seasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _category = 'Unclassified';

  @override
  void initState() {
    super.initState();
    final analysis = widget.analysis;
    _nameController.text = analysis?.suggestedName ?? '';
    _colorsController.text = analysis?.colors.join(', ') ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtypeController.dispose();
    _colorsController.dispose();
    _patternController.dispose();
    _styleController.dispose();
    _necklineController.dispose();
    _sleeveController.dispose();
    _lengthController.dispose();
    _fabricController.dispose();
    _fitController.dispose();
    _occasionsController.dispose();
    _seasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm garment details'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(widget.imagePath),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.processingFailed
                      ? 'Background removal failed. This is the original photo.'
                      : widget.analysis == null
                      ? 'Local colour analysis unavailable. Add details manually.'
                      : 'Colour estimate is calculated locally. Other details are not automatically identified.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    hintText: 'Enter a garment name',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Unclassified',
                      child: Text('Unclassified'),
                    ),
                    DropdownMenuItem(value: 'Topwear', child: Text('Topwear')),
                    DropdownMenuItem(
                      value: 'Bottomwear',
                      child: Text('Bottomwear'),
                    ),
                    DropdownMenuItem(
                      value: 'Footwear',
                      child: Text('Footwear'),
                    ),
                    DropdownMenuItem(
                      value: 'Ethnic wear',
                      child: Text('Ethnic wear'),
                    ),
                    DropdownMenuItem(
                      value: 'Outerwear',
                      child: Text('Outerwear'),
                    ),
                    DropdownMenuItem(
                      value: 'Accessories',
                      child: Text('Accessories'),
                    ),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 12),
                _textField(_subtypeController, 'Subcategory'),
                _textField(
                  _colorsController,
                  'Colours (comma separated)',
                  helperText: 'A local estimate; review before saving.',
                ),
                _textField(_patternController, 'Pattern'),
                _textField(_styleController, 'Style'),
                _textField(_necklineController, 'Neckline'),
                _textField(_sleeveController, 'Sleeve length'),
                _textField(_lengthController, 'Garment length / silhouette'),
                _textField(_fabricController, 'Fabric (manual only)'),
                _textField(_fitController, 'Fit (manual only)'),
                _textField(_occasionsController, 'Occasions (comma separated)'),
                _textField(_seasonController, 'Season'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'category': _category,
              'subtype': _subtypeController.text.trim(),
              'colors': _colorsController.text.trim(),
              'pattern': _patternController.text.trim(),
              'style': _styleController.text.trim(),
              'neckline': _necklineController.text.trim(),
              'sleeveLength': _sleeveController.text.trim(),
              'garmentLength': _lengthController.text.trim(),
              'fabric': _fabricController.text.trim(),
              'fit': _fitController.text.trim(),
              'occasions': _occasionsController.text.trim(),
              'season': _seasonController.text.trim(),
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, helperText: helperText),
      ),
    );
  }
}
