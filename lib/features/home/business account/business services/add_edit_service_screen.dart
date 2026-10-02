import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import '../../../../services/supabase_storage_service.dart';
import 'business_service_controller.dart';

class AddEditServiceScreen extends StatefulWidget {
  final Service? service;

  const AddEditServiceScreen({super.key, this.service});

  @override
  State<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _categoryController;

  final _isLoading = false.obs;
  final _isImageUploading = false.obs;
  final _imageUrls = <String>[].obs;
  final _suggestions = <String>[].obs;
  final _showSuggestions = false.obs;

  List<File> _selectedImageFiles = [];
  List<String> _existingImageUrls = [];

  final ImagePicker _picker = ImagePicker();
  late BusinessServiceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<BusinessServiceController>();
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _descriptionController = TextEditingController(text: widget.service?.description ?? '');
    _priceController = TextEditingController(text: widget.service?.price.toString() ?? '');
    _durationController = TextEditingController(text: widget.service?.duration.toString() ?? '');
    _categoryController = TextEditingController(text: widget.service?.category ?? '');

    if (widget.service?.imageUrls != null && widget.service!.imageUrls!.isNotEmpty) {
      _imageUrls.assignAll(widget.service!.imageUrls!);
      _existingImageUrls = List.from(widget.service!.imageUrls!);
    } else if (widget.service?.imageUrl != null && widget.service!.imageUrl!.isNotEmpty) {
      _imageUrls.add(widget.service!.imageUrl!);
      _existingImageUrls.add(widget.service!.imageUrl!);
    }

    _categoryController.addListener(_onCategoryTextChanged);
  }

  void _onCategoryTextChanged() {
    final query = _categoryController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _suggestions.clear();
      _showSuggestions.value = false;
      return;
    }

    final filtered = _controller.businessCategories
        .where((cat) => cat.toLowerCase().contains(query))
        .take(5)
        .toList();

    if (filtered.isNotEmpty) {
      _suggestions.value = filtered;
      _showSuggestions.value = true;
    } else {
      _suggestions.clear();
      _showSuggestions.value = false;
    }
  }

  void _selectSuggestion(String suggestion) {
    _categoryController.text = suggestion;
    _suggestions.clear();
    _showSuggestions.value = false;
  }

  Future<void> _pickImages() async {
    try {
      final int remainingSlots = 5 - _selectedImageFiles.length - _imageUrls.length;
      if (remainingSlots <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 5 images allowed'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        limit: remainingSlots,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          for (final file in pickedFiles) {
            _selectedImageFiles.add(File(file.path));
            _imageUrls.add(file.path);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${pickedFiles.length} image(s) selected successfully'),
              backgroundColor: AppColors.primaryPurple,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick images'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _selectedImageFiles.length) {
        _selectedImageFiles.removeAt(index);
        _imageUrls.removeAt(index);
      } else {
        final urlIndex = index - _selectedImageFiles.length;
        if (urlIndex >= 0 && urlIndex < _existingImageUrls.length) {
          _existingImageUrls.removeAt(urlIndex);
          _imageUrls.removeAt(index);
        }
      }
    });
  }

  Future<List<String>> _uploadAllImages() async {
    List<String> uploadedUrls = [];

    for (int i = 0; i < _selectedImageFiles.length; i++) {
      final file = _selectedImageFiles[i];
      try {
        final uploadedUrl = await SupabaseStorageService().uploadServiceImage(file);
        if (uploadedUrl != null) {
          uploadedUrls.add(uploadedUrl);
        }
      } catch (e) {
        print('Error uploading image $i: $e');
      }
    }

    return uploadedUrls;
  }

  Future<void> _deleteOldImages() async {
    for (final oldUrl in _existingImageUrls) {
      if (oldUrl.contains('supabase.co')) {
        await SupabaseStorageService().deleteOldProfileImage(oldUrl);
      }
    }
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all required fields'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (_selectedImageFiles.isEmpty && _existingImageUrls.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one service image'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    _isLoading.value = true;

    try {
      List<String> finalImageUrls = [];
      String? uploadError;

      if (_selectedImageFiles.isNotEmpty) {
        _isImageUploading.value = true;
        final uploadedUrls = await _uploadAllImages();
        _isImageUploading.value = false;

        if (uploadedUrls.isNotEmpty) {
          finalImageUrls.addAll(uploadedUrls);
        } else {
          uploadError = 'Some images failed to upload but service will be saved.';
        }
      }

      finalImageUrls.addAll(_existingImageUrls);

      await _deleteOldImages();

      final serviceId = widget.service?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      final newService = Service(
        id: serviceId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        price: int.parse(_priceController.text.trim()),
        duration: int.parse(_durationController.text.trim()),
        imageUrls: finalImageUrls,
      );

      if (widget.service == null) {
        await _controller.addService(newService);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service added successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await _controller.updateService(widget.service!.id, newService);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      if (uploadError != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uploadError),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      print('Error saving service: $e');
      String errorMessage = 'Failed to save service';

      if (e.toString().contains('Firestore')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.arrowLeft, color: AppColors.textHeadline),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.service == null ? 'Add New Service' : 'Edit Service',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        actions: [
          Obx(() => TextButton(
            onPressed: _isLoading.value ? null : _saveService,
            child: _isLoading.value
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              ),
            )
                : Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPurple,
              ),
            ),
          )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: 'Service Name *',
                hint: 'e.g., Haircut & Styling',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Service name is required';
                  if (v.length < 2) return 'Name must be at least 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildCategoryField(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description *',
                hint: 'Describe what\'s included in this service...',
                maxLines: 3,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Description is required';
                  if (v.length < 10) return 'Please provide a more detailed description';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Price (PKR) *',
                      hint: '2500',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Price is required';
                        final price = int.tryParse(v);
                        if (price == null) return 'Invalid price';
                        if (price <= 0) return 'Price must be greater than 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _durationController,
                      label: 'Duration (min) *',
                      hint: '60',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Duration is required';
                        final duration = int.tryParse(v);
                        if (duration == null) return 'Invalid duration';
                        if (duration <= 0) return 'Duration must be greater than 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Obx(() {
      final hasImages = _imageUrls.isNotEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Images (Max 5)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeadline,
                ),
              ),
              Text(
                '${_imageUrls.length}/5',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textBody,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: _imageUrls.length + 1,
            itemBuilder: (context, index) {
              if (index == _imageUrls.length) {
                return _buildAddImageButton();
              }
              return _buildImageItem(index);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to add up to 5 images (JPG, PNG)',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textPlaceholder,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: AppColors.primaryPurple,
            ),
            const SizedBox(height: 8),
            Text(
              'Add Image',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    final imageUrl = _imageUrls[index];
    final isNetworkImage = imageUrl.startsWith('http');
    final isLocalFile = !isNetworkImage;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isNetworkImage
                ? Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primaryPurple.withOpacity(0.1),
                child: Icon(
                  Icons.broken_image,
                  size: 30,
                  color: AppColors.textPlaceholder,
                ),
              ),
            )
                : Image.file(
              File(imageUrl),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (_isImageUploading.value && !isNetworkImage)
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Uploading...',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeadline,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _categoryController,
            decoration: InputDecoration(
              hintText: 'e.g., Haircut, Massage',
              hintStyle: TextStyle(color: AppColors.textPlaceholder),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (_showSuggestions.value && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _suggestions.map((suggestion) {
                return InkWell(
                  onTap: () => _selectSuggestion(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primaryPurple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textHeadline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    ));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeadline,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textPlaceholder),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}