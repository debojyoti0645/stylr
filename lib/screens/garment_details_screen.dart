import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stylr/constants/app_colors.dart';
import 'package:stylr/models/clothing_item.dart';
import 'package:stylr/services/wardrobe_storage.dart';

class GarmentDetailsScreen extends StatefulWidget {
  const GarmentDetailsScreen({required this.item, super.key});

  final ClothingItem item;

  @override
  State<GarmentDetailsScreen> createState() => _GarmentDetailsScreenState();
}

class _GarmentDetailsScreenState extends State<GarmentDetailsScreen> {
  static const _categories = [
    'Unclassified',
    'Topwear',
    'Bottomwear',
    'Footwear',
    'Ethnic wear',
    'Outerwear',
    'Accessories',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  late ClothingItem _item;
  late String _category;
  late String _measurementUnit;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _category = _item.category;
    _measurementUnit = _item.measurementUnit;
    _setInitialValues();
  }

  void _setInitialValues() {
    final values = <String, String>{
      'name': _item.name,
      'subtype': _item.subtype,
      'colors': _item.colors.join(', '),
      'pattern': _item.pattern,
      'style': _item.style,
      'neckline': _item.neckline,
      'sleeveLength': _item.sleeveLength,
      'garmentLength': _item.garmentLength,
      'fabric': _item.fabric,
      'fit': _item.fit,
      'occasions': _item.occasions.join(', '),
      'season': _item.season,
      'brand': _item.brand,
      'size': _item.size,
      'measurements': _item.measurements.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('\n'),
      'purchasePrice': _item.purchasePrice?.toString() ?? '',
      'purchaseDate': _item.purchaseDate == null
          ? ''
          : _dateOnly(_item.purchaseDate!),
      'notes': _item.notes,
    };
    for (final entry in values.entries) {
      final controller = _controllers.putIfAbsent(
        entry.key,
        () => TextEditingController(),
      );
      controller.text = entry.value;
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _value(String key) => _controllers[key]!.text.trim();

  List<String> _listValue(String key) => _value(key)
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();

  Map<String, String> _measurementValues() {
    final values = <String, String>{};
    for (final line in _value('measurements').split('\n')) {
      final separator = line.indexOf(':');
      if (separator <= 0) continue;
      final name = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      if (name.isNotEmpty && value.isNotEmpty) values[name] = value;
    }
    return values;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final priceText = _value('purchasePrice');
      final dateText = _value('purchaseDate');
      final updated = _item.copyWith(
        name: _value('name'),
        category: _category,
        subtype: _value('subtype'),
        colors: _listValue('colors'),
        pattern: _value('pattern'),
        style: _value('style'),
        neckline: _value('neckline'),
        sleeveLength: _value('sleeveLength'),
        garmentLength: _value('garmentLength'),
        fabric: _value('fabric'),
        fit: _value('fit'),
        occasions: _listValue('occasions'),
        season: _value('season'),
        brand: _value('brand'),
        size: _value('size'),
        measurements: _measurementValues(),
        measurementUnit: _measurementUnit,
        purchasePrice: priceText.isEmpty ? null : double.parse(priceText),
        clearPurchasePrice: priceText.isEmpty,
        purchaseDate: dateText.isEmpty ? null : DateTime.parse(dateText),
        clearPurchaseDate: dateText.isEmpty,
        notes: _value('notes'),
      );
      await WardrobeStorage.save(updated);
      if (!mounted) return;
      setState(() {
        _item = updated;
        _editing = false;
        _category = updated.category;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Garment details saved.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save garment details: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelEditing() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved garment edits will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      _setInitialValues();
      setState(() {
        _editing = false;
        _category = _item.category;
        _measurementUnit = _item.measurementUnit;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<ClothingItem>(
      canPop: !_editing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _editing) _cancelEditing();
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: Text(_editing ? 'Edit garment' : 'Garment details'),
          backgroundColor: AppColors.cream,
          leading: IconButton(
            tooltip: _editing ? 'Cancel editing' : 'Back',
            onPressed: () {
              if (_editing) {
                _cancelEditing();
              } else {
                Navigator.pop(context, _item);
              }
            },
            icon: Icon(_editing ? Icons.close : Icons.arrow_back),
          ),
          actions: [
            if (!_editing)
              IconButton(
                tooltip: 'Edit details',
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
        body: _editing ? _buildEditor() : _buildDetails(),
      ),
    );
  }

  Widget _buildDetails() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _buildImage(),
        const SizedBox(height: 16),
        Text(
          _item.name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          [
            _item.category,
            _item.subtype,
          ].where((value) => value.isNotEmpty).join(' · '),
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        _section('Appearance', [
          _detail(
            'Primary colour',
            _item.colors.isEmpty ? null : _item.colors.first,
          ),
          _detail(
            'Secondary colour',
            _item.colors.length < 2 ? null : _item.colors.skip(1).join(', '),
          ),
          _detail('Pattern', _item.pattern),
          _detail('Style', _item.style),
          _detail('Neckline', _item.neckline),
          _detail('Sleeve length', _item.sleeveLength),
          _detail('Length / silhouette', _item.garmentLength),
        ]),
        _section('Material and use', [
          _detail('Fabric', _item.fabric),
          _detail('Fit', _item.fit),
          _detail('Suitable occasions', _item.occasions.join(', ')),
          _detail('Season', _item.season),
          _detail('Brand', _item.brand),
        ]),
        _section('Size and purchase', [
          _detail('Label size', _item.size),
          _detail('Measurements', _formatMeasurements(_item)),
          _detail('Purchase price', _item.purchasePrice?.toStringAsFixed(2)),
          _detail('Purchase date', _nullableDateOnly(_item.purchaseDate)),
        ]),
        _section('Notes', [_detail('Personal notes', _item.notes)]),
      ],
    );
  }

  Widget _buildEditor() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildImage(),
          const SizedBox(height: 16),
          _editorSection('Basic information', [
            _field(
              'name',
              'Garment name',
              required: true,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Name is required'
                  : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items:
                  [
                        ..._categories,
                        if (!_categories.contains(_category)) _category,
                      ]
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            _field('subtype', 'Subcategory'),
          ]),
          _editorSection('Appearance', [
            _field(
              'colors',
              'Colours',
              helper: 'Separate multiple colours with commas.',
            ),
            _field('pattern', 'Pattern'),
            _field('style', 'Style'),
            _field('neckline', 'Neckline'),
            _field('sleeveLength', 'Sleeve length'),
            _field('garmentLength', 'Length / silhouette'),
          ]),
          _editorSection('Material and use', [
            _field('fabric', 'Fabric'),
            _field('fit', 'Fit'),
            _field(
              'occasions',
              'Suitable occasions',
              helper: 'Separate with commas.',
            ),
            _field('season', 'Season'),
            _field('brand', 'Brand'),
          ]),
          _editorSection('Size and measurements', [
            _field('size', 'Label size'),
            DropdownButtonFormField<String>(
              initialValue: _measurementUnit,
              decoration: const InputDecoration(labelText: 'Measurement unit'),
              items: const [
                DropdownMenuItem(value: 'cm', child: Text('Centimetres (cm)')),
                DropdownMenuItem(value: 'in', child: Text('Inches (in)')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _measurementUnit = value);
              },
            ),
            _field(
              'measurements',
              'Measurements',
              helper:
                  'One manual measurement per line, e.g. Chest: 52. '
                  'The selected unit applies to each value.',
              validator: _validateMeasurements,
              maxLines: 4,
            ),
          ]),
          _editorSection('Purchase and notes', [
            _field(
              'purchasePrice',
              'Purchase price',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final number = double.tryParse(value.trim());
                return number == null || number < 0
                    ? 'Enter a valid non-negative price'
                    : null;
              },
            ),
            _field(
              'purchaseDate',
              'Purchase date (YYYY-MM-DD)',
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final parsed = DateTime.tryParse(value.trim());
                return parsed == null || _dateOnly(parsed) != value.trim()
                    ? 'Enter a valid date as YYYY-MM-DD'
                    : null;
              },
            ),
            _field('notes', 'Personal notes', maxLines: 4),
          ]),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _cancelEditing,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final path = _item.cleanImagePath ?? _item.originalImagePath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 280,
        color: AppColors.white,
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String? value) {
    final shown = value == null || value.trim().isEmpty
        ? 'Not specified'
        : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(flex: 3, child: Text(shown)),
        ],
      ),
    );
  }

  Widget _editorSection(String title, List<Widget> fields) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...fields.map(
              (field) =>
                  Padding(padding: const EdgeInsets.only(top: 8), child: field),
            ),
          ],
        ),
      ),
    );
  }

  TextFormField _field(
    String key,
    String label, {
    String? helper,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: _controllers[key],
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        helperText: helper,
      ),
    );
  }

  String _formatMeasurements(ClothingItem item) {
    if (item.measurements.isEmpty) return '';
    return item.measurements.entries
        .map((entry) => '${entry.key}: ${entry.value} ${item.measurementUnit}')
        .join(', ');
  }

  String? _validateMeasurements(String? value) {
    final names = <String>{};
    for (final line in (value ?? '').split('\n')) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      final separator = trimmedLine.indexOf(':');
      if (separator <= 0 || separator == trimmedLine.length - 1) {
        return 'Use one "Name: value" measurement per line.';
      }

      final name = trimmedLine.substring(0, separator).trim();
      final measurement = double.tryParse(
        trimmedLine.substring(separator + 1).trim(),
      );
      if (name.isEmpty ||
          measurement == null ||
          !measurement.isFinite ||
          measurement <= 0) {
        return 'Enter a measurement name and a positive number.';
      }
      if (!names.add(name.toLowerCase())) {
        return 'Each measurement name must be unique.';
      }
    }
    return null;
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String? _nullableDateOnly(DateTime? date) =>
      date == null ? null : _dateOnly(date);
}
