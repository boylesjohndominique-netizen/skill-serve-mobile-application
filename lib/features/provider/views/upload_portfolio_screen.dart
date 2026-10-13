import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../controllers/portfolio_controller.dart';
import '../models/portfolio_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/section_card.dart';
import '../../../core/widgets/feedback/app_notice.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/misc/app_icon.dart';

/// Add a piece of work to the portfolio, or edit one ([itemId] set): up to
/// [PortfolioModel.maxPhotos] photos (the first is the cover), a title and a
/// description. Nothing changes on the server until Save.
class PortfolioFormScreen extends StatefulWidget {
  final String? itemId;
  const PortfolioFormScreen({super.key, this.itemId});

  bool get isEditing => itemId != null;

  @override
  State<PortfolioFormScreen> createState() => _PortfolioFormScreenState();
}

/// A photo in the form: one already saved, or one picked from the phone.
class _Photo {
  final PortfolioPhoto? saved;
  final String? path;
  const _Photo.saved(PortfolioPhoto this.saved) : path = null;
  const _Photo.picked(String this.path) : saved = null;
}

class _PortfolioFormScreenState extends State<PortfolioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final List<_Photo> _photos = [];
  final List<String> _removedPhotoIds = [];
  PortfolioModel? _item;
  bool _loading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadItem());
    }
  }

  Future<void> _loadItem() async {
    final portfolio = context.read<PortfolioController>();
    if (portfolio.find(widget.itemId!) == null) await portfolio.loadMine();
    final item = portfolio.find(widget.itemId!);
    if (!mounted) return;
    setState(() {
      _item = item;
      _loading = false;
      if (item != null) {
        _title.text = item.title;
        _description.text = item.description;
        _photos
          ..clear()
          ..addAll(item.images.isNotEmpty
              ? item.images.map(_Photo.saved)
              : [if (item.image.isNotEmpty) _Photo.saved(PortfolioPhoto(id: '', url: item.image))]);
      }
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  int get _room => PortfolioModel.maxPhotos - _photos.length;

  Future<void> _pickPhotos() async {
    if (_room <= 0) return;
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85, limit: _room > 1 ? _room : null);
    if (picked.isEmpty || !mounted) return;
    final kept = picked.take(_room).toList();
    setState(() => _photos.addAll(kept.map((file) => _Photo.picked(file.path))));
    if (picked.length > kept.length) {
      AppSnackbar.error(context, 'Only ${PortfolioModel.maxPhotos} photos fit in one item — the rest were left out.');
    }
  }

  void _removePhoto(int index) {
    final photo = _photos[index];
    setState(() {
      _photos.removeAt(index);
      final id = photo.saved?.id;
      if (id != null && id.isNotEmpty) _removedPhotoIds.add(id);
    });
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      AppSnackbar.error(context, 'Add at least one photo.');
      return;
    }

    final portfolio = context.read<PortfolioController>();
    final title = _title.text.trim();
    final description = _description.text.trim();
    final pickedPaths = [for (final photo in _photos) if (photo.path != null) photo.path!];

    setState(() => _submitting = true);
    final saved = widget.isEditing
        ? await portfolio.saveChanges(
            _item!,
            title: title,
            description: description,
            addedPaths: pickedPaths,
            removedPhotoIds: _removedPhotoIds,
          )
        : await portfolio.add(title: title, description: description, imagePaths: pickedPaths);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (saved) {
      AppSnackbar.success(context, widget.isEditing ? 'Changes saved.' : 'Added to your portfolio.');
      context.pop();
    } else {
      AppSnackbar.error(context, portfolio.errorMessage ?? 'We could not save this item.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final heading = widget.isEditing ? 'Edit work' : 'Add work';
    if (_loading) return const Scaffold(body: LoadingState());
    if (widget.isEditing && _item == null) {
      return Scaffold(
        appBar: AppBar(title: Text(heading)),
        body: const Center(child: Text('This item is no longer in your portfolio.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(heading)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.pageHPad),
            children: [
              const AppNotice(
                message: 'Customers see this on your public profile as soon as you save it.',
              ),
              const SizedBox(height: AppSizes.lg),
              SectionCard(
                title: 'Photos',
                subtitle: '${_photos.length} of ${PortfolioModel.maxPhotos} · the first one is the cover',
                child: _PhotoGrid(
                  photos: _photos,
                  canAdd: _room > 0,
                  onAdd: _pickPhotos,
                  onRemove: _removePhoto,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Title',
                hint: 'e.g. Bathroom repipe',
                controller: _title,
                validator: Validators.required,
              ),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Description (optional)',
                hint: 'What was the job, and what did you do?',
                controller: _description,
                maxLines: 4,
                maxLength: 2000,
              ),
              const SizedBox(height: AppSizes.xl),
              PrimaryButton(
                label: widget.isEditing ? 'Save changes' : 'Add to portfolio',
                isLoading: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSizes.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<_Photo> photos;
  final bool canAdd;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _PhotoGrid({required this.photos, required this.canAdd, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSizes.sm,
      crossAxisSpacing: AppSizes.sm,
      children: [
        for (var i = 0; i < photos.length; i++)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Stack(
              fit: StackFit.expand,
              children: [
                photos[i].path != null
                    ? Image.file(File(photos[i].path!), fit: BoxFit.cover)
                    : CachedNetworkImage(imageUrl: photos[i].saved!.url, fit: BoxFit.cover),
                if (i == 0)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
                      child: Text('Cover', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Semantics(
                    button: true,
                    label: 'Remove photo ${i + 1}',
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                        child: const AppIcon(AppIcons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (canAdd)
          Semantics(
            button: true,
            label: 'Add photos',
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Container(
                decoration: BoxDecoration(
                  color: context.accentSoftColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(AppIcons.add_photo_alternate_outlined, color: context.onAccentSoftColor, size: 26),
                    const SizedBox(height: 4),
                    Text('Add photos', style: AppTextStyles.caption.copyWith(color: context.onAccentSoftColor, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
