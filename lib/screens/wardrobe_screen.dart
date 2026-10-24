import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylr/constants/app_colors.dart';
import 'package:stylr/models/clothing_item.dart';
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
    try {
      final photo = await _picker.pickImage(source: source, imageQuality: 90);

      if (photo == null || !mounted) return;

      final details = await showDialog<Map<String, String>>(
        context: context,
        builder: (_) => const _AddClothingDialog(),
      );

      if (details == null || !mounted) return;
      final id = DateTime.now().microsecondsSinceEpoch.toString();

      final savedPath = await WardrobeImageStorage.saveImage(
        File(photo.path),
        id,
      );

      final item = ClothingItem(
        id: id,
        name: details['name']!,
        category: details['category']!,
        originalImagePath: savedPath,
        dateAdded: DateTime.now(),
      );

      await WardrobeStorage.save(item);

      if (!mounted) return;

      _loadItems();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clothing item saved!')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add item: $error')));
    }
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
        onPressed: _showAddOptions,
        backgroundColor: AppColors.deepRose,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add clothing'),
      ),
      body: _loading
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(
                                item.cleanImagePath ?? item.originalImagePath,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 40,
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
                );
              },
            ),
    );
  }
}

class _AddClothingDialog extends StatefulWidget {
  const _AddClothingDialog();

  @override
  State<_AddClothingDialog> createState() => _AddClothingDialogState();
}

class _AddClothingDialogState extends State<_AddClothingDialog> {
  final _nameController = TextEditingController();
  String _category = 'Topwear';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add clothing item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Item name',
                hintText: 'e.g. Blue casual shirt',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'Topwear', child: Text('Topwear')),
                DropdownMenuItem(
                  value: 'Bottomwear',
                  child: Text('Bottomwear'),
                ),
                DropdownMenuItem(value: 'Footwear', child: Text('Footwear')),
                DropdownMenuItem(
                  value: 'Ethnic wear',
                  child: Text('Ethnic wear'),
                ),
                DropdownMenuItem(value: 'Outerwear', child: Text('Outerwear')),
                DropdownMenuItem(
                  value: 'Accessories',
                  child: Text('Accessories'),
                ),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            Navigator.pop(context, {'name': name, 'category': _category});
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
