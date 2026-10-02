import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../app/app_colors.dart';
import '../../../../services/stripe_connect_service.dart';
import '../../../../services/user_service.dart';
import '../../../../app/custom_snackbar.dart';
import '../stripe/stripe_account_model.dart';
import '../stripe/stripe_webview_screen.dart';

class PaymentMethod {
  final String id;
  final String name;
  final String iconPath;
  final Color bgColor;
  final Color iconColor;
  final bool isStripe;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.bgColor,
    required this.iconColor,
    this.isStripe = false,
  });
}

class PaymentMethodsController extends GetxController {
  var isEditMode = false.obs;
  var editingIndex = (-1).obs;
  var isLoading = false.obs;
  var isSaving = false.obs;

  var stripeAccountId = ''.obs;
  var stripeAccountStatus = ''.obs;
  var stripeChargesEnabled = false.obs; // ✅ New: Track actual charges_enabled
  var stripePayoutsEnabled = false.obs; // ✅ New: Track actual payouts_enabled
  var stripeDetailsSubmitted = false.obs; // ✅ New: Track details_submitted
  var isConnectingStripe = false.obs;
  var stripeConnectionUrl = ''.obs;

  Rx<PaymentMethod?> selectedMethod = Rx<PaymentMethod?>(null);
  var savedPaymentMethods = <Map<String, dynamic>>[].obs;

  final accountTitleController = TextEditingController();
  final accountNumberController = TextEditingController();
  final ibanController = TextEditingController();
  final bankNameController = TextEditingController();

  // ✅ FIXED: Country should be dynamic, default PK for Pakistan
  var businessCountry = 'PK'.obs;

  final List<PaymentMethod> methods = [
    PaymentMethod(
      id: 'stripe',
      name: 'Credit/Debit Card (Stripe)',
      iconPath: 'assets/png/stripe.png',
      bgColor: const Color(0xFF635BFF),
      iconColor: Colors.white,
      isStripe: true,
    ),
    PaymentMethod(
      id: 'easypaisa',
      name: 'EasyPaisa',
      iconPath: 'assets/png/easypaisa.png',
      bgColor: const Color(0xFFE8F5E9),
      iconColor: const Color(0xFF4CAF50),
    ),
    PaymentMethod(
      id: 'jazzcash',
      name: 'JazzCash',
      iconPath: 'assets/png/jazzcash.png',
      bgColor: const Color(0xFFFFEBEE),
      iconColor: const Color(0xFFD32F2F),
    ),
    PaymentMethod(
      id: 'bank',
      name: 'Bank Transfer',
      iconPath: 'assets/png/bank.png',
      bgColor: const Color(0xFFE3F2FD),
      iconColor: const Color(0xFF1976D2),
    ),
  ];

  List<PaymentMethod> get availableMethods {
    final addedMethodIds = savedPaymentMethods.map((m) => m['id'] as String).toSet();
    return methods.where((method) => !addedMethodIds.contains(method.id)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _initializePaymentMethods();
  }

  Future<void> _initializePaymentMethods() async {
    await loadPaymentMethods();
    await loadStripeAccountStatus();
    await _loadBusinessCountry();
  }

  // ✅ New: Load business country
  Future<void> _loadBusinessCountry() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final businessProfile = await UserService.getBusinessProfile(user.uid);
      if (businessProfile != null) {
        businessCountry.value = businessProfile['country'] ?? 'PK';
      }
    } catch (e) {
      print('Error loading business country: $e');
    }
  }

  Future<void> loadStripeAccountStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final businessProfile = await UserService.getBusinessProfile(user.uid);
      if (businessProfile != null) {
        stripeAccountId.value = businessProfile['stripeAccountId'] ?? '';
        stripeAccountStatus.value = businessProfile['stripeAccountStatus'] ?? 'disabled';
        // ✅ FIXED: Load actual boolean values
        stripeChargesEnabled.value = businessProfile['stripeChargesEnabled'] ?? false;
        stripePayoutsEnabled.value = businessProfile['stripePayoutsEnabled'] ?? false;
        stripeDetailsSubmitted.value = businessProfile['stripeDetailsSubmitted'] ?? false;

        // ✅ FIXED: Check if Stripe payment method should be auto-added
        final shouldAddStripe = stripeChargesEnabled.value &&
            stripePayoutsEnabled.value &&
            stripeAccountId.value.isNotEmpty &&
            !savedPaymentMethods.any((m) => m['id'] == 'stripe');

        if (shouldAddStripe) {
          await _ensureStripePaymentMethod(user.uid);
        }
      }
    } catch (e) {
      print('Error loading Stripe account status: $e');
    }
  }

  // ✅ NEW: Single method to ensure Stripe payment method exists (fixes Issue 9)
  Future<void> _ensureStripePaymentMethod(String businessId) async {
    try {
      final currentMethods = await _fetchPaymentMethodsFromFirestore(businessId);
      final alreadyAdded = currentMethods.any((m) => m['id'] == 'stripe');

      if (!alreadyAdded) {
        currentMethods.add({
          'id': 'stripe',
          'name': 'Credit/Debit Card (Stripe)',
          'accountTitle': 'Stripe Connected',
          'accountNumber': 'Connected via Stripe Connect',
          'stripeAccountId': stripeAccountId.value,
          'addedAt': DateTime.now().toIso8601String(),
        });
        await UserService.updateBusinessPaymentMethods(businessId, currentMethods);
        await loadPaymentMethods();
        print('✅ Stripe payment method added successfully.');
      }
    } catch (e) {
      print('Error ensuring Stripe payment method: $e');
    }
  }

  // lib/features/home/business account/payment method/payment_methods_controller.dart

// Only the connectStripeAccount method needs to be updated with better error handling
// Keep everything else the same

  // In PaymentMethodsController, update the connectStripeAccount method

  Future<void> connectStripeAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar.error('Please login to continue');
      return;
    }

    isConnectingStripe.value = true;

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
      barrierDismissible: false,
    );

    try {
      final businessProfile = await UserService.getBusinessProfile(user.uid);
      final email = businessProfile?['email'] ?? user.email;

      // ✅ Use US for Stripe (card payments require US or EU countries)
      // Store the business's actual country separately for display purposes
      final stripeCountry = 'US'; // Stripe requires US for card payments
      final businessDisplayCountry = businessProfile?['country'] ?? 'PK';

      if (email == null) {
        AppSnackbar.error('Business email not found');
        Get.back();
        return;
      }

      print('🔗 Connecting Stripe for business: ${user.uid}, email: $email, country: $stripeCountry');

      final accountId = await StripeConnectService().createConnectedAccount(
        businessId: user.uid,
        email: email,
        country: stripeCountry, // ✅ Use US for Stripe
      );

      if (accountId == null) {
        AppSnackbar.error('Failed to create Stripe account. Please try again.');
        Get.back();
        return;
      }

      print('✅ Stripe account created: $accountId');

      await UserService.updateBusinessStripeAccount(user.uid, accountId);
      // ✅ Store both the Stripe country and the business's actual country
      await UserService.updateBusinessStripeCountry(user.uid, stripeCountry);
      await UserService.updateBusinessCountry(user.uid, businessDisplayCountry);
      stripeAccountId.value = accountId;

      final returnUrl = 'https://bookify.app/stripe-return';
      final refreshUrl = 'https://bookify.app/stripe-refresh';

      final accountLinkUrl =
      await StripeConnectService().createAccountLink(
        accountId: accountId,
        returnUrl: returnUrl,
        refreshUrl: refreshUrl,
      );

      if (accountLinkUrl == null) {
        AppSnackbar.error('Failed to create account link');
        Get.back();
        return;
      }

      stripeConnectionUrl.value = accountLinkUrl;
      Get.back();

      final result = await Get.to<bool>(() => StripeWebViewScreen(
        url: accountLinkUrl,
        businessId: user.uid,
      ));

      if (result == true) {
        await loadPaymentMethods();
        await loadStripeAccountStatus();
        if (stripeChargesEnabled.value && stripePayoutsEnabled.value) {
          AppSnackbar.success('Stripe connected successfully!');
        } else {
          AppSnackbar.warning('Stripe setup requires additional verification.');
        }
      } else {
        AppSnackbar.info('Stripe setup was not completed.');
      }
    } catch (e) {
      print('[PaymentMethodsController] Error connecting Stripe: $e');
      AppSnackbar.error('Error connecting Stripe: $e');
      if (Get.isDialogOpen ?? false) Get.back();
    } finally {
      isConnectingStripe.value = false;
    }
  }

  var pendingRequirements = <String>[].obs;

  Future<void> finalizeFromWebView(String businessId) async {
    try {
      final stripeService = StripeConnectService();
      final accountId = stripeAccountId.value;

      if (accountId.isEmpty) {
        print('No Stripe account ID found');
        return;
      }

      final accountStatus = await stripeService
          .retrieveAccountStatus(accountId: accountId, businessId: businessId)
          .timeout(const Duration(seconds: 8));

      if (accountStatus == null) {
        print('Could not retrieve Stripe account status');
        return;
      }

      // ✅ FIXED: Save actual Stripe flags (Issue 2)
      final chargesEnabled = accountStatus.chargesEnabled ?? false;
      final payoutsEnabled = accountStatus.payoutsEnabled ?? false;
      final detailsSubmitted = accountStatus.detailsSubmitted ?? false;

      // Determine status based on actual flags
      String status;
      if (chargesEnabled && payoutsEnabled) {
        status = 'enabled';
      } else if (chargesEnabled || payoutsEnabled) {
        status = 'restricted';
      } else {
        status = 'pending';
      }

      await UserService.updateBusinessStripeAccountStatus(businessId, status);
      await UserService.updateBusinessStripeChargesEnabled(businessId, chargesEnabled);
      await UserService.updateBusinessStripePayoutsEnabled(businessId, payoutsEnabled);
      await UserService.updateBusinessStripeDetailsSubmitted(businessId, detailsSubmitted);

      stripeAccountStatus.value = status;
      stripeChargesEnabled.value = chargesEnabled;
      stripePayoutsEnabled.value = payoutsEnabled;
      stripeDetailsSubmitted.value = detailsSubmitted;

      final currentlyDue = accountStatus.requirements?['currently_due'];
      if (currentlyDue is List) {
        pendingRequirements.value = currentlyDue.cast<String>();
      } else {
        pendingRequirements.value = [];
      }

      // ✅ FIXED: Only add Stripe payment method if fully enabled (Issue 9)
      if (chargesEnabled && payoutsEnabled) {
        await _ensureStripePaymentMethod(businessId);
        AppSnackbar.success('Stripe payment method added successfully!');
      } else {
        final msg = pendingRequirements.isNotEmpty
            ? 'Please complete the following requirements: ${pendingRequirements.join(', ')}'
            : 'Stripe account setup is incomplete. Please click "Complete Setup" to continue.';
        AppSnackbar.warning(msg);
      }
    } catch (e) {
      print('Error finalizing Stripe connection: $e');
      rethrow;
    }
  }

  Future<void> resumeStripeOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final accountId = stripeAccountId.value;
    if (accountId.isEmpty) {
      AppSnackbar.error('No Stripe account found. Please reconnect.');
      return;
    }

    isConnectingStripe.value = true;
    Get.dialog(const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)));

    try {
      // ✅ FIXED: Use proper deep link URL
      final returnUrl = 'https://bookify.app/stripe-return';
      final refreshUrl = 'https://bookify.app/stripe-refresh';

      final accountLinkUrl =
      await StripeConnectService().createAccountLink(
        accountId: accountId,
        returnUrl: returnUrl,
        refreshUrl: refreshUrl,
      );

      if (accountLinkUrl == null) {
        AppSnackbar.error('Failed to create account link');
        Get.back();
        return;
      }

      stripeConnectionUrl.value = accountLinkUrl;
      Get.back();

      final result = await Get.to<bool>(() => StripeWebViewScreen(
        url: accountLinkUrl,
        businessId: user.uid,
      ));

      if (result == true) {
        await loadPaymentMethods();
        await loadStripeAccountStatus();
        if (stripeChargesEnabled.value && stripePayoutsEnabled.value) {
          AppSnackbar.success('Stripe setup completed!');
        } else {
          AppSnackbar.warning('Still incomplete. Please complete all steps.');
        }
      }
    } catch (e) {
      print('Error resuming Stripe onboarding: $e');
      AppSnackbar.error('Error: $e');
      if (Get.isDialogOpen ?? false) Get.back();
    } finally {
      isConnectingStripe.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPaymentMethodsFromFirestore(String businessId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('businesses').doc(businessId).get();
      if (doc.exists && doc.data() != null) {
        final methods = doc.data()?['paymentMethods'];
        if (methods != null && methods is List) {
          return List<Map<String, dynamic>>.from(methods);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching payment methods from Firestore: $e');
      return [];
    }
  }

  Future<void> loadPaymentMethods() async {
    isLoading.value = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final businessProfile = await UserService.getBusinessProfile(user.uid);
        if (businessProfile != null && businessProfile['paymentMethods'] != null) {
          savedPaymentMethods.value = List<Map<String, dynamic>>.from(businessProfile['paymentMethods']);
        } else {
          savedPaymentMethods.clear();
        }
      }
    } catch (e) {
      print('Error loading payment methods: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> savePaymentMethodsToFirestore() async {
    if (isSaving.value) return;
    isSaving.value = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await UserService.updateBusinessPaymentMethods(user.uid, savedPaymentMethods.toList());
      }
    } catch (e) {
      print('Error saving payment methods: $e');
      rethrow;
    } finally {
      isSaving.value = false;
    }
  }

  void openSelectMethodModal() {
    Get.bottomSheet(
      _buildSelectMethodModal(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      enableDrag: true,
    );
  }

  void openAddDetailsModal() {
    Get.bottomSheet(
      _buildAddDetailsModal(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      enableDrag: true,
    );
  }

  void closeAllModals() {
    if (Get.isBottomSheetOpen ?? false) Get.back();
  }

  void selectMethod(PaymentMethod method) {
    if (method.isStripe) {
      closeAllModals();
      connectStripeAccount();
      return;
    }
    selectedMethod.value = method;
    isEditMode.value = false;
    editingIndex.value = -1;
    closeAllModals();
    openAddDetailsModal();
  }

  void editPaymentMethod(int index) {
    final method = savedPaymentMethods[index];
    if (method['id'] == 'stripe') {
      AppSnackbar.info('Stripe payment method cannot be edited. Delete and reconnect if needed.');
      return;
    }
    selectedMethod.value = methods.firstWhere(
          (m) => m.id == method['id'],
      orElse: () => methods.first,
    );
    isEditMode.value = true;
    editingIndex.value = index;

    accountTitleController.text = method['accountTitle'] ?? '';
    accountNumberController.text = method['accountNumber'] ?? '';

    if (selectedMethod.value!.id == 'bank') {
      bankNameController.text = method['bankName'] ?? '';
      ibanController.text = method['iban'] ?? '';
    }

    openAddDetailsModal();
  }

  Future<void> addPaymentMethod() async {
    if (selectedMethod.value == null) return;
    if (isSaving.value) return;

    if (!validateForm()) return;

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
      barrierDismissible: false,
    );

    try {
      final paymentMethodData = {
        'id': selectedMethod.value!.id,
        'name': selectedMethod.value!.name,
        'accountTitle': accountTitleController.text.trim(),
        'accountNumber': accountNumberController.text.trim(),
        'addedAt': DateTime.now().toIso8601String(),
      };

      if (selectedMethod.value!.id == 'bank') {
        paymentMethodData['bankName'] = bankNameController.text.trim();
        paymentMethodData['iban'] = ibanController.text.trim();
      }

      if (isEditMode.value && editingIndex.value >= 0) {
        savedPaymentMethods[editingIndex.value] = paymentMethodData;
      } else {
        savedPaymentMethods.add(paymentMethodData);
      }

      await savePaymentMethodsToFirestore();
      await loadPaymentMethods();

      Get.back();
      closeAllModals();
      _clearForms();

      AppSnackbar.success(isEditMode.value ? 'Payment method updated successfully!' : 'Payment method added successfully!');
    } catch (e) {
      Get.back();
      AppSnackbar.error('Error saving payment method: $e');
    }
  }

  Future<void> deletePaymentMethod(int index, {bool isStripe = false}) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
      barrierDismissible: false,
    );

    try {
      if (isStripe) {
        await _deleteStripePaymentMethod();
      } else {
        savedPaymentMethods.removeAt(index);
        await savePaymentMethodsToFirestore();
        await loadPaymentMethods();
      }
      Get.back();
      AppSnackbar.success('Payment method deleted successfully');
    } catch (e) {
      Get.back();
      AppSnackbar.error('Error deleting payment method: $e');
    }
  }

  Future<void> _deleteStripePaymentMethod() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final currentMethods = await _fetchPaymentMethodsFromFirestore(user.uid);
    currentMethods.removeWhere((m) => m['id'] == 'stripe');
    await UserService.updateBusinessPaymentMethods(user.uid, currentMethods);

    // ✅ FIXED: Don't erase account ID - mark as disabled instead (Issue 7)
    // Store deletion flag instead of erasing history
    await UserService.updateBusinessStripeAccountStatus(user.uid, 'disabled');
    await UserService.updateBusinessStripeChargesEnabled(user.uid, false);
    await UserService.updateBusinessStripePayoutsEnabled(user.uid, false);
    // ✅ Keep account ID for reference
    // await UserService.updateBusinessStripeAccount(user.uid, ''); // ❌ Don't erase

    stripeAccountStatus.value = 'disabled';
    stripeChargesEnabled.value = false;
    stripePayoutsEnabled.value = false;
    await loadPaymentMethods();
  }

  void _clearForms() {
    accountTitleController.clear();
    accountNumberController.clear();
    ibanController.clear();
    bankNameController.clear();
    selectedMethod.value = null;
    isEditMode.value = false;
    editingIndex.value = -1;
  }

  String? validateAccountNumber(String value, String methodId) {
    if (value.isEmpty) return 'Account number is required';
    if (methodId == 'easypaisa' || methodId == 'jazzcash') {
      if (value.length != 11) return 'Account number must be exactly 11 digits';
      if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Account number must contain only digits';
    }
    return null;
  }

  String? validateIBAN(String value) {
    if (value.isEmpty) return 'IBAN is required';
    final cleanIBAN = value.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (cleanIBAN.length != 24) return 'Pakistani IBAN must be exactly 24 characters';
    if (!cleanIBAN.startsWith('PK')) return 'IBAN must start with PK';
    final remaining = cleanIBAN.substring(2);
    if (!RegExp(r'^[A-Z0-9]{22}$').hasMatch(remaining)) return 'Invalid IBAN format';
    return null;
  }

  String? validateBankName(String value) {
    if (value.isEmpty) return 'Bank name is required';
    if (value.length < 2) return 'Please enter a valid bank name';
    return null;
  }

  String? validateAccountTitle(String value) {
    if (value.isEmpty) return 'Account title is required';
    if (value.length < 2) return 'Please enter a valid account title';
    return null;
  }

  bool validateForm() {
    final accountTitleError = validateAccountTitle(accountTitleController.text.trim());
    if (accountTitleError != null) {
      AppSnackbar.error(accountTitleError);
      return false;
    }

    final accountNumberError = validateAccountNumber(
        accountNumberController.text.trim(), selectedMethod.value!.id);
    if (accountNumberError != null) {
      AppSnackbar.error(accountNumberError);
      return false;
    }

    if (selectedMethod.value!.id == 'bank') {
      final bankNameError = validateBankName(bankNameController.text.trim());
      if (bankNameError != null) {
        AppSnackbar.error(bankNameError);
        return false;
      }

      final ibanError = validateIBAN(ibanController.text.trim());
      if (ibanError != null) {
        AppSnackbar.error(ibanError);
        return false;
      }
    }

    return true;
  }

  Widget _buildSelectMethodModal() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: Get.height * 0.5,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadline,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: closeAllModals,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: availableMethods.length,
              itemBuilder: (context, index) {
                final method = availableMethods[index];
                return GestureDetector(
                  onTap: () => selectMethod(method),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: method.bgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Image.asset(
                              method.iconPath,
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  method.id == 'easypaisa'
                                      ? Icons.account_balance_wallet
                                      : method.id == 'jazzcash'
                                      ? Icons.phone_android
                                      : Icons.account_balance,
                                  size: 24,
                                  color: method.iconColor,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          method.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHeadline,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDetailsModal() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (selectedMethod.value != null) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: selectedMethod.value!.bgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Image.asset(
                            selectedMethod.value!.iconPath,
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                selectedMethod.value!.id == 'easypaisa'
                                    ? Icons.account_balance_wallet
                                    : selectedMethod.value!.id == 'jazzcash'
                                    ? Icons.phone_android
                                    : Icons.account_balance,
                                size: 20,
                                color: selectedMethod.value!.iconColor,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEditMode.value ? 'Edit ${selectedMethod.value!.name}' : 'Add ${selectedMethod.value!.name}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textHeadline,
                        ),
                      ),
                    ] else ...[
                      Text('Add Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                    ]
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    closeAllModals();
                    _clearForms();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryPurple.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: AppColors.primaryPurple),
                        const SizedBox(width: 6),
                        Text(
                          'Enter details for ${selectedMethod.value?.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    label: 'Account Title *',
                    hint: 'e.g., John Doe',
                    controller: accountTitleController,
                  ),
                  const SizedBox(height: 12),

                  if (selectedMethod.value?.id == 'bank') ...[
                    _buildTextField(
                      label: 'Bank Name *',
                      hint: 'e.g., HBL, UBL, Allied Bank',
                      controller: bankNameController,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'IBAN *',
                      hint: 'PK36HBL...',
                      controller: ibanController,
                      helperText: 'Pakistani IBAN must be 24 characters starting with PK',
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildTextField(
                    label: 'Account Number *',
                    hint: selectedMethod.value?.id == 'easypaisa' || selectedMethod.value?.id == 'jazzcash'
                        ? '11-digit number'
                        : 'Account number',
                    controller: accountNumberController,
                    keyboardType: TextInputType.number,
                    helperText: selectedMethod.value?.id == 'easypaisa' || selectedMethod.value?.id == 'jazzcash'
                        ? 'Must be exactly 11 digits'
                        : null,
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      closeAllModals();
                      _clearForms();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Back', style: TextStyle(color: Colors.black87, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: addPaymentMethod,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isEditMode.value ? 'Update Method' : 'Add Method',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeadline,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            helperText: helperText,
            helperStyle: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primaryPurple, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  void onClose() {
    accountTitleController.dispose();
    accountNumberController.dispose();
    ibanController.dispose();
    bankNameController.dispose();
    super.onClose();
  }
}