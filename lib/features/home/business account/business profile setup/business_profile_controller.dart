import 'package:bookify/app/custom_snackbar.dart';
import 'package:bookify/features/home/business%20account/business_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/user_service.dart';
import '../../Notifications screen/notifications_controller.dart';
import 'business_profile_screen2.dart';

class BusinessProfileController extends GetxController {
  // Form keys
  final formKey = GlobalKey<FormState>();

  // Loading state
  final isLoading = false.obs;
  final RxBool _isBranchManager = false.obs;
  final RxString _branchId = ''.obs;

  // Step 1 - Basic Information
  final businessName = TextEditingController();
  final businessCategory = RxString('');
  final businessDescription = TextEditingController();
  final businessEmail = TextEditingController();
  final phoneNumber = TextEditingController();
  final businessAddress = TextEditingController();
  final city = TextEditingController(); // New city field

  // City suggestions
  final citySuggestions = <String>[].obs;
  final showCitySuggestions = false.obs;

  // Pakistani cities list for suggestions
  final List<String> pakistaniCities = [
    'Karachi', 'Lahore', 'Islamabad', 'Rawalpindi', 'Faisalabad',
    'Multan', 'Peshawar', 'Quetta', 'Gujranwala', 'Sialkot',
    'Hyderabad', 'Bahawalpur', 'Abbottabad', 'Sargodha', 'Sukkur',
    'Mirpur', 'Muzaffarabad', 'Gilgit', 'Skardu', 'Gwadar'
  ];

  // Step 2 - Operating Hours
  final Map<String, RxBool> isOpen = {
    'Monday': true.obs,
    'Tuesday': true.obs,
    'Wednesday': true.obs,
    'Thursday': true.obs,
    'Friday': true.obs,
    'Saturday': true.obs,
    'Sunday': false.obs,
  };

  final Map<String, RxString> openTime = {
    'Monday': '09:00'.obs,
    'Tuesday': '09:00'.obs,
    'Wednesday': '09:00'.obs,
    'Thursday': '09:00'.obs,
    'Friday': '09:00'.obs,
    'Saturday': '10:00'.obs,
    'Sunday': '09:00'.obs,
  };

  final Map<String, RxString> closeTime = {
    'Monday': '18:00'.obs,
    'Tuesday': '18:00'.obs,
    'Wednesday': '18:00'.obs,
    'Thursday': '18:00'.obs,
    'Friday': '18:00'.obs,
    'Saturday': '16:00'.obs,
    'Sunday': '18:00'.obs,
  };

  // Categories list
  final List<String> categories = [
    'Beauty & Wellness',
    'Health & Fitness',
    'Food & Dining',
    'Automotive',
    'Home Services',
    'Professional Services',
    'Retail',
    'Education',
    'Entertainment',
    'Other'
  ];

  @override
  void onInit() {
    super.onInit();
    businessCategory.value = categories.first;

    // Add listener for city field to show suggestions
    city.addListener(_onCityTextChanged);
    _checkIfBranchManager();
  }

  Future<void> _checkIfBranchManager() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isBranch = await UserService.isBranchUser(user.uid);
    _isBranchManager.value = isBranch;
    if (isBranch) {
      // Fetch the branch document for this user
      final query = await FirebaseFirestore.instance
          .collection('branches')
          .where('branchManagerId', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        _branchId.value = query.docs.first.id;
        // Optionally pre-fill form fields from branch data
        final branchData = query.docs.first.data();
        businessName.text = branchData['name'] ?? '';
        businessAddress.text = branchData['location'] ?? '';
        // You could also prefill services if needed
      }
    }
  }

  void _onCityTextChanged() {
    final query = city.text.trim();
    if (query.isEmpty) {
      citySuggestions.clear();
      showCitySuggestions.value = false;
      return;
    }

    // Filter cities based on user input (case insensitive)
    final filtered = pakistaniCities.where((cityName) =>
        cityName.toLowerCase().startsWith(query.toLowerCase())
    ).take(2).toList(); // Only show 1-2 suggestions

    if (filtered.isNotEmpty) {
      citySuggestions.value = filtered;
      showCitySuggestions.value = true;
    } else {
      citySuggestions.clear();
      showCitySuggestions.value = false;
    }
  }

  void selectCitySuggestion(String selectedCity) {
    city.text = selectedCity;
    citySuggestions.clear();
    showCitySuggestions.value = false;
  }

  Future<void> selectTime(BuildContext context, String day, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(isStartTime ? openTime[day]!.value.split(':')[0] : closeTime[day]!.value.split(':')[0]),
        minute: int.parse(isStartTime ? openTime[day]!.value.split(':')[1] : closeTime[day]!.value.split(':')[1]),
      ),
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isStartTime) {
        openTime[day]!.value = timeString;
      } else {
        closeTime[day]!.value = timeString;
      }
    }
  }

  Future<void> onContinue() async {
    if (!validateStep1()) return;

    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    isLoading.value = false;

    Get.to(() => const BusinessProfileStep2());
  }

  String formatTime(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  void toggleOpen(String day) {
    isOpen[day]!.value = !isOpen[day]!.value;
  }

  // Phone number validation
  String? validatePhoneNumber(String phone) {
    if (phone.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces and special characters for validation
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check for Pakistani number patterns
    if (cleanPhone.startsWith('+92')) {
      // Format: +92XXXXXXXXXX (should be 13 characters including +92)
      if (cleanPhone.length != 13) {
        return 'Please enter a valid Pakistani number';
      }
      // Check if remaining 10 digits are all numbers
      final numberPart = cleanPhone.substring(3);
      if (!RegExp(r'^[0-9]{10}$').hasMatch(numberPart)) {
        return 'Please enter valid digits after +92';
      }
    }
    else if (cleanPhone.startsWith('0')) {
      // Format: 03XXXXXXXXX (11 digits total)
      if (cleanPhone.length != 11) {
        return 'Please enter a valid 11-digits number';
      }
      if (!RegExp(r'^[0-9]{11}$').hasMatch(cleanPhone)) {
        return 'Please enter valid digits';
      }
      if (!cleanPhone.startsWith('03')) {
        return 'Mobile number should start with 03';
      }
    }
    else if (cleanPhone.startsWith('3')) {
      // Format: 3XXXXXXXXX (10 digits)
      if (cleanPhone.length != 10) {
        return 'Please enter a valid 10-digit number';
      }
      if (!RegExp(r'^[0-9]{10}$').hasMatch(cleanPhone)) {
        return 'Please enter valid digits';
      }
    }
    else {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Email validation
  String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Business email is required';
    }

    // Regular expression for email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  bool validateStep1() {
    // Validate Business Name
    if (businessName.text.isEmpty) {
      AppSnackbar.error('Please enter business name');
      return false;
    }

    // Validate Business Category
    if (businessCategory.value.isEmpty) {
      AppSnackbar.error('Please select business category');
      return false;
    }

    // Validate Business Description
    if (businessDescription.text.isEmpty) {
      AppSnackbar.error('Please enter business description');
      return false;
    }

    // Validate Business Email
    final emailError = validateEmail(businessEmail.text.trim());
    if (emailError != null) {
      AppSnackbar.error(emailError);
      return false;
    }

    // Validate Phone Number
    final phoneError = validatePhoneNumber(phoneNumber.text.trim());
    if (phoneError != null) {
      AppSnackbar.error(phoneError);
      return false;
    }

    // Validate Business Address
    if (businessAddress.text.isEmpty) {
      AppSnackbar.error('Please enter business address');
      return false;
    }

    // Validate City
    if (city.text.isEmpty) {
      AppSnackbar.error('Please enter city name');
      return false;
    }

    return true;
  }

  Future<void> submitProfile() async {
    isLoading.value = true;

    try {
      // Prepare business profile data
      final Map<String, dynamic> operatingHours = {};

      // Save only open days with their timings
      isOpen.forEach((day, isOpenValue) {
        if (isOpenValue.value) {
          operatingHours[day] = {
            'isOpen': true,
            'openTime': openTime[day]!.value,
            'closeTime': closeTime[day]!.value,
          };
        } else {
          operatingHours[day] = {
            'isOpen': false,
          };
        }
      });

      final businessProfileData = {
        'basicInfo': {
          'businessName': businessName.text.trim(),
          'category': businessCategory.value,
          'description': businessDescription.text.trim(),
          'email': businessEmail.text.trim(),
          'phoneNumber': phoneNumber.text.trim(),
          'address': businessAddress.text.trim(),
          'city': city.text.trim(), // Add city to saved data
        },
        'operatingHours': operatingHours,
      };

      // Save to Firestore in 'businesses' collection
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await UserService.saveBusinessProfile(user.uid, businessProfileData);
      }

      await Future.delayed(const Duration(seconds: 1));

      isLoading.value = false;
      AppSnackbar.success("Business Profile Created Successfully", position: SnackPosition.BOTTOM);
      Get.offAll(
            () => BusinessHomeScreen(),
        binding: BindingsBuilder(() {
          Get.put(NotificationsController());
        }),
      );
    } catch (e) {
      isLoading.value = false;
      AppSnackbar.error("Failed to save business profile. Please try again.");
    }
  }

  @override
  void onClose() {
    businessName.dispose();
    businessDescription.dispose();
    businessEmail.dispose();
    phoneNumber.dispose();
    businessAddress.dispose();
    city.dispose();
    city.removeListener(_onCityTextChanged);
    super.onClose();
  }
}