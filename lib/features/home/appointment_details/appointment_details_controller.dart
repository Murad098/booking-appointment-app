import 'package:bookify/app/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/custom_snackbar.dart';
import '../../../services/email_service.dart';
import '../chat system/chat/chat_screen.dart';
import '../../../../app/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/user_service.dart';
import '../../../services/notification_service.dart';

class AppointmentDetailsController extends GetxController {
  final appointmentStatus = ''.obs;
  final statusMessage = ''.obs;
  final isPending = false.obs;
  final isUpcoming = false.obs;
  final isCompleted = false.obs;
  final isAutoCancelled = false.obs;
  final isRescheduling = false.obs;
  final paymentScreenshotUrl = ''.obs;
  final userRole = ''.obs;
  final isRefunded = false.obs;

  // Add loading state
  final isLoading = true.obs;
  final isRoleLoaded = false.obs;

  // Button loading states
  final isApproveLoading = false.obs;
  final isConfirmRescheduleLoading = false.obs;
  final isMarkCompletedLoading = false.obs;
  final isRejectLoading = false.obs;
  final isMarkRefundedLoading = false.obs;
  final isCancelLoading = false.obs;
  final isRescheduleRequestLoading = false.obs;
  final isDirectRescheduleLoading = false.obs;

  var localStatus = ''.obs;
  Map<String, dynamic>? currentAppointment;
  final pendingNewDate = ''.obs;
  final pendingNewTime = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    // First fetch user role
    await fetchUserRole();

    // Then load appointment based on arguments
    await _loadAppointmentFromArguments();
  }

  Future<void> fetchUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await UserService.getUserRole(user.uid);
        if (role != null && role.isNotEmpty) {
          userRole.value = role;
          isRoleLoaded.value = true;
          print('[AppointmentDetails] User role fetched: ${userRole.value}');
        } else {
          print('[AppointmentDetails] No role found for user: ${user.uid}');
          AppSnackbar.error('User role not found. Please logout and login again.');
          Get.back();
          return;
        }
      } else {
        print('[AppointmentDetails] No user logged in');
        AppSnackbar.error('Please login to view appointment details');
        Get.back();
        return;
      }
    } catch (e) {
      print('Error fetching user role: $e');
      AppSnackbar.error('Failed to load user role');
      Get.back();
    }
  }

  Future<void> _loadAppointmentFromArguments() async {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      if (args.containsKey('id') && !args.containsKey('services') && !args.containsKey('serviceName')) {
        // Only ID provided - load from Firestore
        final id = args['id'];
        final isBusinessView = args['isBusinessView'] ?? false;
        await loadAppointmentFromId(id, isBusinessView: isBusinessView);
      } else if (args.containsKey('services') || args.containsKey('serviceName')) {
        // Full appointment data provided
        loadAppointment(args);
      } else {
        isLoading.value = false;
        AppSnackbar.error('Invalid appointment data');
        Get.back();
      }
    } else {
      isLoading.value = false;
      AppSnackbar.error('Invalid appointment data');
      Get.back();
    }
  }

  void loadAppointment(Map<String, dynamic> appointment) {
    currentAppointment = appointment;
    final status = appointment['status'] ?? 'pending';
    appointmentStatus.value = status;
    localStatus.value = status;

    isRefunded.value = appointment['refunded'] ?? false;
    isAutoCancelled.value = appointment['autoCancelled'] ?? false;
    isRescheduling.value = appointment['isRescheduling'] ?? false;

    if (appointment['pendingNewDate'] != null) {
      pendingNewDate.value = appointment['pendingNewDate'];
    }
    if (appointment['pendingNewTime'] != null) {
      pendingNewTime.value = appointment['pendingNewTime'];
    }

    isPending.value = status == 'pending';
    isCompleted.value = status == 'completed';

    final isUpcomingValue = _isAppointmentUpcoming(appointment);
    isUpcoming.value = isUpcomingValue;

    // NOTE: Auto-cancellation only applies to pending appointments, not confirmed ones
    // Confirmed appointments will NEVER be auto-cancelled or auto-completed
    if (status == 'pending' && !isUpcomingValue && !isRescheduling.value) {
      _autoCancelAppointment(appointment['id']);
    }

    _updateStatusMessage(status);
    _fetchBookingDetails(appointment['id']);

    // Data loaded, hide loading indicator
    isLoading.value = false;
  }

  Future<void> _fetchBookingDetails(String id) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(id)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        paymentScreenshotUrl.value = data['paymentScreenshotUrl'] ?? '';

        final autoCancelled = data['autoCancelled'] ?? false;
        if (autoCancelled != isAutoCancelled.value) {
          isAutoCancelled.value = autoCancelled;
        }

        final status = data['status'] ?? 'pending';
        if (status != appointmentStatus.value) {
          appointmentStatus.value = status;
          localStatus.value = status;
          _updateStatusMessage(status);
        }

        final refunded = data['refunded'] ?? false;
        if (refunded != isRefunded.value) {
          isRefunded.value = refunded;
        }

        final isReschedulingFlag = data['isRescheduling'] ?? false;
        if (isReschedulingFlag != isRescheduling.value) {
          isRescheduling.value = isReschedulingFlag;
          _updateStatusMessage(status);
        }


        if (data['pendingNewDate'] != null) {
          pendingNewDate.value = data['pendingNewDate'];
        }
        if (data['pendingNewTime'] != null) {
          pendingNewTime.value = data['pendingNewTime'];
        }

        // Update current appointment with latest data
        if (currentAppointment != null) {
          currentAppointment!['paymentScreenshotUrl'] = paymentScreenshotUrl.value;
          currentAppointment!['status'] = appointmentStatus.value;
          currentAppointment!['refunded'] = isRefunded.value;
          currentAppointment!['autoCancelled'] = isAutoCancelled.value;
          currentAppointment!['isRescheduling'] = isRescheduling.value;
        }


        // IMPORTANT: No auto-completion logic here
        // Confirmed appointments will NEVER be automatically completed
        // Only business users can manually mark appointments as completed
      }
    } catch (e) {
      print('[AppointmentDetails] Error fetching booking: $e');
    }
  }

  // ===========================================================================
  // OPEN CHAT WITH PERSON (Business or Customer) - FIXED to use UIDs only
  // ===========================================================================
  Future<void> openChatWithPerson() async {
    if (currentAppointment == null) {
      AppSnackbar.error('Unable to start chat');
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      AppSnackbar.error('Please login to chat');
      return;
    }

    final isBusinessUser = userRole.value == 'business';
    String otherUserId;

    if (isBusinessUser) {
      // Business user -> chat with customer (use customer UID from appointment)
      otherUserId = currentAppointment!['customerId'] ?? '';
    } else {
      // Customer user -> chat with business (use business UID from appointment)
      otherUserId = currentAppointment!['businessId'] ?? '';
    }

    if (otherUserId.isEmpty) {
      AppSnackbar.error('Unable to identify chat recipient');
      return;
    }

    // Show loading indicator
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      String otherUserName = 'User';
      String otherUserEmail = '';
      String? otherUserProfileImage;

      // First, get the user's role from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();

      String userRole = userDoc.exists ? (userDoc.data()?['role'] as String? ?? '') : '';

      // If the user is a business, fetch from businesses collection for the name
      if (userRole == 'business') {
        final businessDoc = await FirebaseFirestore.instance
            .collection('businesses')
            .doc(otherUserId)
            .get();

        if (businessDoc.exists) {
          final businessData = businessDoc.data();
          if (businessData != null) {
            otherUserName = businessData['businessName'] ?? 'Business';
            otherUserEmail = businessData['email'] ?? '';
            otherUserProfileImage = businessData['profileImage'];
          }
        } else {
          // Fallback to users collection
          if (userDoc.exists) {
            final data = userDoc.data();
            if (data != null) {
              otherUserName = data['name'] ?? 'Business';
              otherUserEmail = data['email'] ?? '';
              otherUserProfileImage = data['profileImage'];
            }
          }
        }
      } else {
        // Regular user/customer - fetch from users collection
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null) {
            otherUserName = data['name'] ?? 'User';
            otherUserEmail = data['email'] ?? '';
            otherUserProfileImage = data['profileImage'];
          }
        }
      }

      // Close loading dialog before navigation
      Get.back();

      // Navigate to chat or create new chat room
      await _navigateToChat(otherUserId, otherUserName, otherUserEmail, otherUserProfileImage);
    } catch (e) {
      Get.back(); // Close loading dialog
      print('[AppointmentDetails] Error opening chat: $e');
      AppSnackbar.error('Failed to start chat: $e');
    }
  }

  Future<void> _navigateToChat(String otherUserId, String otherUserName, String otherUserEmail, String? profileImage) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Check if chat room already exists between these two users
      final existingChatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      String? existingChatId;

      for (var doc in existingChatSnapshot.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(otherUserId) && participants.length == 2) {
          existingChatId = doc.id;
          break;
        }
      }

      if (existingChatId != null) {
        // Open existing chat - use Get.to() instead of Get.toNamed() for reliability
        Get.to(
              () => ChatScreen(),
          arguments: {
            'chatId': existingChatId,
            'userId': otherUserId,
            'userName': otherUserName,
            'userProfileImage': profileImage,
          },
          transition: Transition.rightToLeft,
        );
      } else {
        // Create new chat room
        final chatId = DateTime.now().millisecondsSinceEpoch.toString();

        // Fetch current user details
        final currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();
        final currentUserData = currentUserDoc.data() ?? {};
        final currentUserName = currentUserData['name'] ?? 'User';
        final currentUserEmail = currentUserData['email'] ?? '';
        final currentUserProfileImage = currentUserData['profileImage'] ?? '';

        final chatData = {
          'id': chatId,
          'participants': [currentUserId, otherUserId],
          'participantDetails': {
            currentUserId: {
              'name': currentUserName,
              'email': currentUserEmail,
              'profileImage': currentUserProfileImage,
            },
            otherUserId: {
              'name': otherUserName,
              'email': otherUserEmail,
              'profileImage': profileImage,
            },
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .set(chatData);

        // Open new chat - use Get.to() instead of Get.toNamed() for reliability
        Get.to(
              () => ChatScreen(),
          arguments: {
            'chatId': chatId,
            'userId': otherUserId,
            'userName': otherUserName,
            'userProfileImage': profileImage,
          },
          transition: Transition.rightToLeft,
        );
      }
    } catch (e) {
      print('[AppointmentDetails] Error opening chat: $e');
      throw e;
    }
  }


  Future<void> _saveNotificationToFirestore({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String bookingId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'bookingId': bookingId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('[AppointmentDetails] Notification saved to Firestore for user: $userId');
    } catch (e) {
      print('[AppointmentDetails] Error saving notification to Firestore: $e');
    }
  }

  String _formatTimeForNotification(String timeStr) {
    try {
      String cleanTimeStr = timeStr;
      if (timeStr.contains(' - ')) {
        cleanTimeStr = timeStr.split(' - ')[0].trim();
      }

      final timeParts = cleanTimeStr.split(':');
      if (timeParts.length >= 2) {
        int hour = int.parse(timeParts[0]);
        final minute = timeParts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        if (hour == 0) hour = 12;
        return '$hour:$minute $period';
      }
      return timeStr;
    } catch (e) {
      return timeStr;
    }
  }

  String _formatDateForNotification(String dateStr) {
    try {
      String cleanDateStr = dateStr;
      if (dateStr.contains('T')) {
        cleanDateStr = dateStr.split('T')[0];
      }
      final date = DateTime.parse(cleanDateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // ===========================================================================
  // AUTO-CANCEL — fires when a pending appointment's time has passed
  // Notifies the business owner as well.
  // NOTE: This only applies to PENDING appointments, NOT confirmed ones
  // ===========================================================================
  Future<void> _autoCancelAppointment(String id) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(id)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final currentStatus = data['status'] ?? 'pending';

      // Only auto-cancel if status is pending
      // Confirmed appointments will NEVER be auto-cancelled
      if (currentStatus != 'pending') return;

      final appointmentDate =
          data['selectedDate']?.toString() ?? data['date'] ?? '';
      final appointmentTime =
          data['selectedTime']?.toString() ?? data['time'] ?? '';

      if (appointmentDate.isEmpty || appointmentTime.isEmpty) return;

      if (!_isDateTimePassed(appointmentDate, appointmentTime)) return;

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(id)
          .update({
        'status': 'cancelled',
        'autoCancelled': true,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'refunded': false,
        'isRescheduling': false,
      });

      appointmentStatus.value = 'cancelled';
      localStatus.value = 'cancelled';
      isAutoCancelled.value = true;
      isPending.value = false;
      isUpcoming.value = false;
      isRefunded.value = false;
      isRescheduling.value = false;
      _updateStatusMessage('cancelled');

      if (currentAppointment != null) {
        currentAppointment!['status'] = 'cancelled';
        currentAppointment!['autoCancelled'] = true;
        currentAppointment!['refunded'] = false;
        currentAppointment!['isRescheduling'] = false;
      }

      update();

      // Notify business owner of auto-cancellation
      await NotificationService().sendPushNotification(
        userId: currentAppointment?['businessId'] ?? '',
        title: 'Appointment Auto-Cancelled',
        body:
        'Appointment with ${currentAppointment?['customerName'] ?? 'a customer'} has been auto-cancelled as the scheduled time has passed.',
        data: {
          'type': 'auto_cancelled',
          'bookingId': id,
        },
      );

      // Notify customer of auto-cancellation
      await NotificationService().sendPushNotification(
        userId: currentAppointment?['customerId'] ?? '',
        title: 'Appointment Auto-Cancelled',
        body:
        'Your appointment with ${currentAppointment?['businessName'] ?? 'the business'} has been auto-cancelled as the scheduled time has passed.',
        data: {
          'type': 'auto_cancelled',
          'bookingId': id,
        },
      );

      // Send email to customer about auto-cancellation
      await _sendAppointmentCancelledByBusinessEmail();

      AppSnackbar.error(
        'Appointment #$id has been auto-cancelled as the scheduled time has passed',
        position: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('[AppointmentDetails] Error auto-cancelling: $e');
    }
  }

  bool _isDateTimePassed(String dateStr, String timeStr) {
    try {
      if (dateStr.isEmpty || timeStr.isEmpty) return false;

      String cleanDateStr = dateStr;
      if (dateStr.contains('T')) {
        cleanDateStr = dateStr.split('T')[0];
      }

      final dateParts = cleanDateStr.split('-');
      if (dateParts.length != 3) return false;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      String cleanTimeStr = timeStr;
      if (timeStr.contains(' - ')) {
        cleanTimeStr = timeStr.split(' - ')[0].trim();
      }

      final timeParts = cleanTimeStr.split(':');
      if (timeParts.length < 2) return false;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final appointmentDateTime = DateTime(year, month, day, hour, minute);
      return appointmentDateTime.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  void _updateStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        if (isRescheduling.value) {
          statusMessage.value =
          'Reschedule request pending. Waiting for business confirmation.';
        } else if (!isUpcoming.value) {
          statusMessage.value =
          'This appointment has expired and will be auto-cancelled.';
        } else {
          statusMessage.value =
          'Waiting for approval from the business. You\'ll be notified within 15-20 minutes.';
        }
        break;
      case 'confirmed':
        statusMessage.value =
        'Your appointment has been confirmed. We look forward to serving you!';
        break;
      case 'completed':
        statusMessage.value =
        'This appointment has been completed. Please rate your experience.';
        break;
      case 'cancelled':
        final refunded = isRefunded.value;
        final autoCancelled = isAutoCancelled.value;
        if (autoCancelled) {
          statusMessage.value = refunded
              ? 'This appointment was automatically cancelled and fully refunded.'
              : 'This appointment was automatically cancelled. Refund is being processed.';
        } else {
          statusMessage.value = refunded
              ? 'This appointment was cancelled and fully refunded.'
              : 'This appointment has been cancelled. Refund is being processed.';
        }
        break;
      default:
        statusMessage.value = 'Appointment status: $status';
    }
  }

  bool _isAppointmentUpcoming(Map<String, dynamic> appointment) {
    try {
      final dateStr =
          appointment['date'] as String? ?? appointment['selectedDate'] as String? ?? '';
      final timeStr =
          appointment['time'] as String? ?? appointment['selectedTime'] as String? ?? '';

      if (dateStr.isEmpty || timeStr.isEmpty) return true;

      String cleanDateStr = dateStr;
      if (dateStr.contains('T')) {
        cleanDateStr = dateStr.split('T')[0];
      }

      final dateParts = cleanDateStr.split('-');
      if (dateParts.length != 3) return true;

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      String cleanTimeStr = timeStr;
      if (timeStr.contains(' - ')) {
        cleanTimeStr = timeStr.split(' - ')[0].trim();
      }

      final timeParts = cleanTimeStr.split(':');
      if (timeParts.length < 2) return true;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final appointmentDateTime = DateTime(year, month, day, hour, minute);
      return appointmentDateTime.isAfter(DateTime.now());
    } catch (e) {
      return true;
    }
  }

  // ===========================================================================
  // APPROVE — business approves a pending booking → notifies customer
  // ===========================================================================
  Future<void> approveAppointment(String id) async {
    if (currentAppointment != null &&
        !_isAppointmentUpcoming(currentAppointment!)) {
      Get.back();
      AppSnackbar.error('Cannot approve an expired appointment');
      return;
    }

    Get.dialog(
      AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Approve Appointment',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
        const Text('Are you sure you want to approve this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              isApproveLoading.value = true;
              try {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(id)
                    .update({
                  'status': 'confirmed',
                  'approvedAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                  'isRescheduling': false,
                });

                appointmentStatus.value = 'confirmed';
                localStatus.value = 'confirmed';
                isPending.value = false;
                isRescheduling.value = false;
                _updateStatusMessage('confirmed');

                if (currentAppointment != null) {
                  currentAppointment!['status'] = 'confirmed';
                  currentAppointment!['isRescheduling'] = false;
                }

                // ── Push notification to CUSTOMER ──────────────────────
                await NotificationService().sendPushNotification(
                  userId: currentAppointment?['customerId'] ?? '',
                  title: 'Appointment Approved! ✅',
                  body:
                  'Your appointment for ${currentAppointment?['serviceName'] ?? 'the service'} at ${currentAppointment?['businessName'] ?? 'the business'} has been confirmed.',
                  data: {
                    'type': 'appointment_approved',
                    'bookingId': id,
                  },
                );

                // ── NEW: Send confirmation emails to both customer and business ──
                await _sendAppointmentConfirmedEmails();

                Get.back();
                AppSnackbar.success(
                  'Appointment approved successfully',
                  position: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.back();
                AppSnackbar.error('Failed to approve appointment');
              } finally {
                isApproveLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Obx(() => isApproveLoading.value
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text('Approve')),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CONFIRM RESCHEDULE — business confirms a customer's reschedule request
  // Notifies customer of confirmed new schedule.
  // ===========================================================================
  Future<void> confirmReschedule(String id) async {
    if (pendingNewDate.value.isEmpty || pendingNewTime.value.isEmpty) {
      AppSnackbar.error('No pending reschedule data found');
      return;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Reschedule',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Confirm reschedule to ${pendingNewDate.value} at ${pendingNewTime.value}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              isConfirmRescheduleLoading.value = true;
              try {
                // Capture old values BEFORE update
                final String oldDate = currentAppointment?['date'] ?? currentAppointment?['selectedDate'] ?? '';
                final String oldTime = currentAppointment?['time'] ?? currentAppointment?['selectedTime'] ?? '';
                final String newDate = pendingNewDate.value;
                final String newTime = pendingNewTime.value;

                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(id)
                    .update({
                  'selectedDate': newDate,
                  'selectedTime': newTime,
                  'date': newDate,
                  'time': newTime,
                  'status': 'confirmed',
                  'isRescheduling': false,
                  'rescheduleConfirmedAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (currentAppointment != null) {
                  currentAppointment!['date'] = newDate;
                  currentAppointment!['time'] = newTime;
                  currentAppointment!['selectedDate'] = newDate;
                  currentAppointment!['selectedTime'] = newTime;
                  currentAppointment!['status'] = 'confirmed';
                  currentAppointment!['isRescheduling'] = false;
                }

                appointmentStatus.value = 'confirmed';
                localStatus.value = 'confirmed';
                isRescheduling.value = false;
                isPending.value = false;
                pendingNewDate.value = '';
                pendingNewTime.value = '';
                _updateStatusMessage('confirmed');

                // Push notification to CUSTOMER
                await NotificationService().sendPushNotification(
                  userId: currentAppointment?['customerId'] ?? '',
                  title: 'Reschedule Confirmed ✅',
                  body:
                  'Your reschedule request has been confirmed. New appointment: $newDate at $newTime.',
                  data: {
                    'type': 'reschedule_confirmed',
                    'bookingId': id,
                  },
                );

                // Send email to customer about reschedule confirmation
                _sendRescheduleConfirmedEmail(oldDate, oldTime, newDate, newTime);

                Get.back();
                AppSnackbar.success(
                  'Reschedule confirmed successfully',
                  position: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.back();
                AppSnackbar.error('Failed to confirm reschedule');
              } finally {
                isConfirmRescheduleLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Obx(() => isConfirmRescheduleLoading.value
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text('Confirm')),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MARK AS COMPLETED — business marks appointment done (MANUAL ONLY)
  // Sends rating request push notification to customer.
  // ONLY business users can call this method
  // ===========================================================================
  Future<void> markAsCompleted(String id) async {
    // Security check: Only business users can mark appointments as completed
    if (userRole.value != 'business') {
      AppSnackbar.error('Only business users can mark appointments as completed');
      return;
    }

    Get.dialog(
      AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Mark as Completed',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Has this appointment been completed successfully?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              isMarkCompletedLoading.value = true;
              try {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(id)
                    .update({
                  'status': 'completed',
                  'completedAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                appointmentStatus.value = 'completed';
                localStatus.value = 'completed';
                isCompleted.value = true;
                _updateStatusMessage('completed');

                if (currentAppointment != null) {
                  currentAppointment!['status'] = 'completed';
                }

                // ── Push notification to CUSTOMER — rating request ──────
                await NotificationService().sendPushNotification(
                  userId: currentAppointment?['customerId'] ?? '',
                  title: 'Rate Your Experience ⭐',
                  body:
                  'Your appointment at ${currentAppointment?['businessName'] ?? 'the business'} is complete! Tap to leave a review.',
                  data: {
                    'type': 'rating_request',
                    'bookingId': id,
                  },
                );

                // Send email to customer only (no email to business for completion)
                await _sendAppointmentCompletedEmail();

                Get.back();
                AppSnackbar.success(
                  'Appointment marked as completed. Rating request sent to customer.',
                  position: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.back();
                AppSnackbar.error('Failed to update status');
              } finally {
                isMarkCompletedLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Obx(() => isMarkCompletedLoading.value
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text('Yes, Complete')),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REJECT / CANCEL (by business) → notifies customer
  // ===========================================================================
  Future<void> rejectAppointment(String id) async {
    Get.dialog(
      AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Cancel Appointment',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('No', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              isRejectLoading.value = true;
              try {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(id)
                    .update({
                  'status': 'cancelled',
                  'cancelledAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                  'refunded': false,
                  'autoCancelled': false,
                  'isRescheduling': false,
                });

                appointmentStatus.value = 'cancelled';
                localStatus.value = 'cancelled';
                isPending.value = false;
                isUpcoming.value = false;
                isRescheduling.value = false;
                _updateStatusMessage('cancelled');

                if (currentAppointment != null) {
                  currentAppointment!['status'] = 'cancelled';
                  currentAppointment!['isRescheduling'] = false;
                }

                // ── Push notification to CUSTOMER ──────────────────────
                await NotificationService().sendPushNotification(
                  userId: currentAppointment?['customerId'] ?? '',
                  title: 'Appointment Cancelled',
                  body:
                  'Your appointment at ${currentAppointment?['businessName'] ?? 'the business'} has been cancelled. A refund will be processed shortly.',
                  data: {
                    'type': 'appointment_cancelled',
                    'bookingId': id,
                  },
                );

                // ── NEW: Send email to BOTH customer and business about cancellation ──
               await _sendAppointmentCancelledByBusinessEmail();

                // Also send email to business about their own cancellation action
                _sendBusinessCancellationConfirmationEmail();

                Get.back();
                AppSnackbar.error(
                  'Appointment has been cancelled',
                  position: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.back();
                AppSnackbar.error('Failed to cancel appointment');
              } finally {
                isRejectLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Obx(() => isRejectLoading.value
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text('Yes, Cancel')),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MARK AS REFUNDED — business confirms refund processed
  // ===========================================================================
  Future<void> markAsRefunded(String id) async {
    Get.dialog(
      AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Mark as Refunded',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Has the refund been processed for this cancelled appointment?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              isMarkRefundedLoading.value = true;
              try {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(id)
                    .update({
                  'refunded': true,
                  'refundedAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                isRefunded.value = true;
                _updateStatusMessage('cancelled');

                if (currentAppointment != null) {
                  currentAppointment!['refunded'] = true;
                }

                // ── Push notification to CUSTOMER ──────────────────────
                await NotificationService().sendPushNotification(
                  userId: currentAppointment?['customerId'] ?? '',
                  title: 'Refund Processed 💸',
                  body:
                  'Your refund for the cancelled appointment at ${currentAppointment?['businessName'] ?? 'the business'} has been processed.',
                  data: {
                    'type': 'refund_processed',
                    'bookingId': id,
                  },
                );

                Get.back();
                AppSnackbar.success(
                  'Refund status updated successfully',
                  position: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.back();
                AppSnackbar.error('Failed to update refund status');
              } finally {
                isMarkRefundedLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Obx(() => isMarkRefundedLoading.value
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text('Yes, Mark Refunded')),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CANCEL (by customer) → notifies business
  // ===========================================================================
  Future<void> cancelAppointment(String id) async {
    if (currentAppointment != null &&
        !_isAppointmentUpcoming(currentAppointment!)) {
      Get.back();
      AppSnackbar.error('Cannot cancel an expired appointment');
      return;
    }

    Get.dialog(
      AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Cancel Appointment',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure you want to cancel this upcoming appointment?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('No', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              isCancelLoading.value = true;
              try {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(id)
                    .update({
                  'status': 'cancelled',
                  'cancelledAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                  'refunded': false,
                  'autoCancelled': false,
                  'isRescheduling': false,
                });

                appointmentStatus.value = 'cancelled';
                localStatus.value = 'cancelled';
                isPending.value = false;
                isUpcoming.value = false;
                isRescheduling.value = false;
                _updateStatusMessage('cancelled');

                if (currentAppointment != null) {
                  currentAppointment!['status'] = 'cancelled';
                  currentAppointment!['isRescheduling'] = false;
                }

                // ── Push notification to BUSINESS ──────────────────────
                await NotificationService().sendPushNotification(
                  userId: currentAppointment?['businessId'] ?? '',
                  title: 'Appointment Cancelled',
                  body:
                  '${currentAppointment?['customerName'] ?? 'A customer'} has cancelled their appointment for ${currentAppointment?['serviceName'] ?? 'your service'}.',
                  data: {
                    'type': 'appointment_cancelled',
                    'bookingId': id,
                  },
                );

                // ── NEW: Send email to BOTH customer and business about customer cancellation ──
                await _sendAppointmentCancelledByCustomerEmail();

                Get.back();
                AppSnackbar.error(
                  'Appointment cancelled successfully',
                  position: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.back();
                AppSnackbar.error('Failed to cancel appointment');
              } finally {
                isCancelLoading.value = false;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Obx(() => isCancelLoading.value
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text('Yes, Cancel')),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REQUEST RESCHEDULE (by customer) → notifies business
  // ===========================================================================
  void requestReschedule(Map<String, dynamic> appointment) {
    if (!_isAppointmentUpcoming(appointment)) {
      AppSnackbar.error('Cannot reschedule an expired appointment');
      return;
    }

    Get.dialog(
      AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Request Reschedule',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Would you like to request a reschedule? The business will need to approve it.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('No', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Future.delayed(const Duration(milliseconds: 350), () {
                _showRescheduleBottomSheet(appointment, isRequest: true);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Request Reschedule'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DIRECT RESCHEDULE (by business) → confirms immediately, notifies customer
  // ===========================================================================
  void directReschedule(Map<String, dynamic> appointment) {
    if (!_isAppointmentUpcoming(appointment)) {
      AppSnackbar.error('Cannot reschedule an expired appointment');
      return;
    }

    Get.dialog(
      AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Reschedule Appointment',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure you want to reschedule this appointment? It will be confirmed immediately.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('No', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Future.delayed(const Duration(milliseconds: 350), () {
                _showRescheduleBottomSheet(appointment, isRequest: false);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Reschedule'),
          ),
        ],
      ),
    );
  }

  Future<void> loadAppointmentFromId(String id, {bool isBusinessView = false}) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(id)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final appointment = {
          'id': doc.id,
          'services': data['serviceName'] ?? '',
          'serviceName': data['serviceName'] ?? '',
          'customerName': data['customerName'] ?? '',
          'customerEmail': data['customerEmail'] ?? '',
          'customerPhone': data['customerPhone'] ?? '',
          'businessId': data['businessId'] ?? '',
          'businessName': data['businessName'] ?? '',
          'businessEmail': data['businessEmail'] ?? '',
          'serviceId': data['serviceId'] ?? '',
          'servicePrice': data['servicePrice'] ?? '0',
          'serviceDuration': data['serviceDuration'] ?? '0',
          'selectedDate': data['selectedDate'] ?? '',
          'selectedTime': data['selectedTime'] ?? '',
          'date': data['selectedDate']?.toString().split('T')[0] ?? '',
          'time': data['selectedTime'] ?? '',
          'duration': data['serviceDuration'] ?? '0',
          'price': double.tryParse(data['servicePrice']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0') ?? 0,
          'advancePaid': (data['advanceAmount'] ?? 0).toDouble(),
          'paymentMethod': data['paymentMethod'] ?? '',
          'paymentScreenshotUrl': data['paymentScreenshotUrl'] ?? '',
          'status': data['status'] ?? 'pending',
          'createdAt': data['createdAt'],
          'customerId': data['customerId'] ?? '',
          'refunded': data['refunded'] ?? false,
          'autoCancelled': data['autoCancelled'] ?? false,
          'isRescheduling': data['isRescheduling'] ?? false,
          'hasSentThirtyMinReminder': data['hasSentThirtyMinReminder'] ?? false,
          'isBusinessView': isBusinessView,
        };
        loadAppointment(appointment);
      } else {
        isLoading.value = false;
        AppSnackbar.error('Appointment not found');
        Get.back();
      }
    } catch (e) {
      isLoading.value = false;
      print('[AppointmentDetails] Error loading appointment: $e');
      AppSnackbar.error('Failed to load appointment details');
      Get.back();
    }
  }

  void _showRescheduleBottomSheet(
      Map<String, dynamic> appointment, {
        required bool isRequest,
      }) {
    final RxString selectedDate =
    RxString(appointment['date'] ?? appointment['selectedDate'] ?? '');
    final RxString selectedTime =
    RxString(appointment['time'] ?? appointment['selectedTime'] ?? '');

    Get.bottomSheet(
      Container(
        padding:
        const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              isRequest
                  ? 'Request Reschedule'
                  : 'Reschedule Appointment',
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
              'New Schedule: ${_formatDate(selectedDate.value)} at ${selectedTime.value}',
              style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            )),
            const SizedBox(height: 24),

            // Date picker
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                FocusManager.instance.primaryFocus?.unfocus();

                DateTime? initialDate;
                try {
                  final parts = selectedDate.value.split('-');
                  if (parts.length == 3) {
                    initialDate = DateTime(int.parse(parts[0]),
                        int.parse(parts[1]), int.parse(parts[2]));
                  }
                } catch (e) {
                  initialDate = DateTime.now();
                }

                await Future.delayed(const Duration(milliseconds: 100));

                final picked = await showDatePicker(
                  context: Get.overlayContext!,
                  initialDate: initialDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate:
                  DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primaryPurple,
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (picked != null) {
                  selectedDate.value =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                }
              },
              child: Obx(() => _buildSelectionCard(
                icon: Icons.calendar_today,
                label: 'Select Date',
                value: _formatDate(selectedDate.value),
              )),
            ),
            const SizedBox(height: 12),

            // Time picker
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                FocusManager.instance.primaryFocus?.unfocus();

                TimeOfDay? initialTime;
                try {
                  final parts = selectedTime.value.split(':');
                  if (parts.length >= 2) {
                    initialTime = TimeOfDay(
                        hour: int.parse(parts[0]),
                        minute: int.parse(parts[1]));
                  }
                } catch (e) {
                  initialTime = TimeOfDay.now();
                }

                await Future.delayed(const Duration(milliseconds: 100));

                final picked = await showTimePicker(
                  context: Get.context!,
                  initialTime: initialTime ?? TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primaryPurple,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (picked != null) {
                  selectedTime.value =
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                }
              },
              child: Obx(() => _buildSelectionCard(
                icon: Icons.access_time,
                label: 'Select Time',
                value: selectedTime.value,
              )),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(() => ElevatedButton(
                onPressed: isRescheduleRequestLoading.value || isDirectRescheduleLoading.value
                    ? null
                    : () async {
                  try {
                    if (isRequest) {
                      isRescheduleRequestLoading.value = true;
                    } else {
                      isDirectRescheduleLoading.value = true;
                    }

                    final bookingId = appointment['id'];
                    // Capture old date/time BEFORE any update
                    final String oldDate = appointment['date'] ?? appointment['selectedDate'] ?? '';
                    final String oldTime = appointment['time'] ?? appointment['selectedTime'] ?? '';

                    if (isRequest) {
                      // Customer requesting reschedule → status pending + notify business
                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(bookingId)
                          .update({
                        'pendingNewDate': selectedDate.value,
                        'pendingNewTime': selectedTime.value,
                        'isRescheduling': true,
                        'status': 'pending',
                        'rescheduleRequestedAt': FieldValue.serverTimestamp(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      // Push notification to BUSINESS
                      await NotificationService().sendPushNotification(
                        userId: appointment['businessId'] ?? '',
                        title: 'Reschedule Request 🔄',
                        body:
                        '${appointment['customerName'] ?? 'A customer'} has requested to reschedule their appointment to ${selectedDate.value} at ${selectedTime.value}.',
                        data: {
                          'type': 'reschedule_request',
                          'bookingId': bookingId,
                        },
                      );
                      // No email for reschedule request (only when confirmed)
                    } else {
                      // Business doing a direct reschedule → confirmed + notify customer
                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(bookingId)
                          .update({
                        'selectedDate': selectedDate.value,
                        'selectedTime': selectedTime.value,
                        'date': selectedDate.value,
                        'time': selectedTime.value,
                        'status': 'confirmed',
                        'isRescheduling': false,
                        'rescheduledAt': FieldValue.serverTimestamp(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      // Push notification to CUSTOMER
                      await NotificationService().sendPushNotification(
                        userId: appointment['customerId'] ?? '',
                        title: 'Appointment Rescheduled 📅',
                        body:
                        'Your appointment has been rescheduled to ${selectedDate.value} at ${selectedTime.value} by ${appointment['businessName'] ?? 'the business'}.',
                        data: {
                          'type': 'reschedule_confirmed',
                          'bookingId': bookingId,
                        },
                      );

                      // Send email to customer about reschedule (using old and new values)
                      await _sendAppointmentRescheduledByBusinessEmail(oldDate, oldTime, selectedDate.value, selectedTime.value);
                    }

                    // Update local appointment data
                    if (currentAppointment != null) {
                      currentAppointment!['date'] = selectedDate.value;
                      currentAppointment!['time'] = selectedTime.value;
                      currentAppointment!['selectedDate'] = selectedDate.value;
                      currentAppointment!['selectedTime'] = selectedTime.value;

                      if (isRequest) {
                        currentAppointment!['isRescheduling'] = true;
                        currentAppointment!['pendingNewDate'] = selectedDate.value;
                        currentAppointment!['pendingNewTime'] = selectedTime.value;
                        appointmentStatus.value = 'pending';
                        localStatus.value = 'pending';
                        isRescheduling.value = true;
                      } else {
                        currentAppointment!['status'] = 'confirmed';
                        currentAppointment!['isRescheduling'] = false;
                        appointmentStatus.value = 'confirmed';
                        localStatus.value = 'confirmed';
                        isRescheduling.value = false;
                      }
                    }

                    if (isRequest) {
                      appointmentStatus.value = 'pending';
                      localStatus.value = 'pending';
                      isRescheduling.value = true;
                      _updateStatusMessage('pending');
                    } else {
                      appointmentStatus.value = 'confirmed';
                      localStatus.value = 'confirmed';
                      isRescheduling.value = false;
                      _updateStatusMessage('confirmed');
                    }

                    loadAppointment(appointment);
                    Get.back();

                    AppSnackbar.success(
                      isRequest
                          ? 'Reschedule request sent to business'
                          : 'Rescheduled Successfully',
                      position: SnackPosition.BOTTOM,
                    );
                  } catch (e) {
                    AppSnackbar.error('Failed to reschedule appointment');
                  } finally {
                    isRescheduleRequestLoading.value = false;
                    isDirectRescheduleLoading.value = false;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: isRescheduleRequestLoading.value || isDirectRescheduleLoading.value
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  isRequest ? 'Send Request' : 'Confirm Reschedule',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
              )),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.edit, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      String cleanDateStr = dateStr;
      if (dateStr.contains('T')) {
        cleanDateStr = dateStr.split('T')[0];
      }
      final date = DateTime.parse(cleanDateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _sendAppointmentConfirmedEmails() async {
    final appointment = currentAppointment;
    if (appointment == null) return;

    final customerEmail = appointment['customerEmail'] ?? '';
    final customerName = appointment['customerName'] ?? 'Customer';
    final businessId = appointment['businessId'] ?? '';
    final businessName = appointment['businessName'] ?? 'Business';
    final serviceName = appointment['serviceName'] ?? 'service';
    final date = _formatDate(appointment['date'] ?? appointment['selectedDate'] ?? '');
    final time = appointment['time'] ?? appointment['selectedTime'] ?? '';

    // Fetch business email from businesses collection (not just from appointment map)
    final businessEmail = await _getBusinessEmail(businessId);

    print('[AppointmentDetails] Sending confirmed emails → customer: $customerEmail, business: $businessEmail');

    if (customerEmail.isNotEmpty) {
      await EmailService.queueAppointmentConfirmed(
        customerEmail: customerEmail,
        customerName: customerName,
        businessEmail: businessEmail.isNotEmpty ? businessEmail : null,
        businessName: businessName,
        serviceName: serviceName,
        date: date,
        time: time,
      );
    }
  }

  // In AppointmentDetailsController
  Future<String> _getBusinessEmail(String businessId) async {
    if (businessId.isEmpty) return '';

    // First check currentAppointment cache
    final cached = currentAppointment?['businessEmail'] ?? '';
    if (cached.isNotEmpty) return cached;

    // Fetch from businesses collection (where UserService stores it)
    try {
      final doc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .get();
      if (doc.exists) {
        return doc.data()?['email'] ?? '';
      }
    } catch (e) {
      print('[AppointmentDetails] Error fetching business email: $e');
    }
    return '';
  }

  Future<void> _sendAppointmentCancelledByBusinessEmail() async {
    final appointment = currentAppointment;
    if (appointment == null) return;

    final customerEmail = appointment['customerEmail'] ?? '';
    final customerName = appointment['customerName'] ?? 'Customer';
    final businessName = appointment['businessName'] ?? 'Business';
    final serviceName = appointment['serviceName'] ?? 'service';
    final date = _formatDate(appointment['date'] ?? appointment['selectedDate'] ?? '');
    final time = appointment['time'] ?? appointment['selectedTime'] ?? '';

    if (customerEmail.isNotEmpty) {
      await EmailService.queueAppointmentCancelledByBusiness(
        customerEmail: customerEmail,
        customerName: customerName,
        businessName: businessName,
        serviceName: serviceName,
        date: date,
        time: time,
      );
    }
  }

  Future<void> _sendBusinessCancellationConfirmationEmail() async {
    final appointment = currentAppointment;
    if (appointment == null) return;

    final businessId = appointment['businessId'] ?? '';
    final businessEmail = await _getBusinessEmail(businessId);  // fetch properly
    final businessName = appointment['businessName'] ?? 'Business';
    final customerName = appointment['customerName'] ?? 'Customer';
    final serviceName = appointment['serviceName'] ?? 'service';
    final date = _formatDate(appointment['date'] ?? appointment['selectedDate'] ?? '');
    final time = appointment['time'] ?? appointment['selectedTime'] ?? '';

    if (businessEmail.isNotEmpty) {
      // Business cancelled their own appointment — confirm to them
      await EmailService.queueAppointmentCancelledByBusiness(
        customerEmail: businessEmail,   // sending to business as confirmation
        customerName: businessName,
        businessName: customerName,     // flip context for the message
        serviceName: serviceName,
        date: date,
        time: time,
      );
    }
  }

  Future<void> _sendAppointmentCancelledByCustomerEmail() async {
    final appointment = currentAppointment;
    if (appointment == null) return;

    final businessId = appointment['businessId'] ?? '';
    final businessEmail = await _getBusinessEmail(businessId);  // fetch properly
    final businessName = appointment['businessName'] ?? 'Business';
    final customerName = appointment['customerName'] ?? 'Customer';
    final customerEmail = appointment['customerEmail'] ?? '';
    final serviceName = appointment['serviceName'] ?? 'service';
    final date = _formatDate(appointment['date'] ?? appointment['selectedDate'] ?? '');
    final time = appointment['time'] ?? appointment['selectedTime'] ?? '';

    // Notify business
    if (businessEmail.isNotEmpty) {
      await EmailService.queueAppointmentCancelledByCustomer(
        businessEmail: businessEmail,
        businessName: businessName,
        customerName: customerName,
        serviceName: serviceName,
        date: date,
        time: time,
      );
    }

    // Confirm to customer too
    if (customerEmail.isNotEmpty) {
      await EmailService.queueAppointmentCancelledByBusiness(
        customerEmail: customerEmail,
        customerName: customerName,
        businessName: businessName,
        serviceName: serviceName,
        date: date,
        time: time,
      );
    }
  }

  Future<void> _sendAppointmentRescheduledByBusinessEmail(
      String oldDate, String oldTime, String newDate, String newTime) async {
    final appointment = currentAppointment;
    if (appointment == null) return;

    final customerEmail = appointment['customerEmail'] ?? '';
    final customerName = appointment['customerName'] ?? 'Customer';
    final businessName = appointment['businessName'] ?? 'Business';
    final serviceName = appointment['serviceName'] ?? 'service';

    if (customerEmail.isNotEmpty) {
      await EmailService.queueAppointmentRescheduledByBusiness(
        customerEmail: customerEmail,
        customerName: customerName,
        businessName: businessName,
        serviceName: serviceName,
        oldDate: _formatDate(oldDate),
        oldTime: oldTime,
        newDate: _formatDate(newDate),
        newTime: newTime,
      );
    }
  }

  Future<void> _sendRescheduleConfirmedEmail(
      String oldDate, String oldTime, String newDate, String newTime) async {
    final appointment = currentAppointment;
    if (appointment == null) return;

    final customerEmail = appointment['customerEmail'] ?? '';
    final customerName = appointment['customerName'] ?? 'Customer';
    final businessName = appointment['businessName'] ?? 'Business';
    final serviceName = appointment['serviceName'] ?? 'service';

    if (customerEmail.isNotEmpty) {
      await EmailService.queueAppointmentRescheduledByBusiness(
        customerEmail: customerEmail,
        customerName: customerName,
        businessName: businessName,
        serviceName: serviceName,
        oldDate: _formatDate(oldDate),
        oldTime: oldTime,
        newDate: _formatDate(newDate),
        newTime: newTime,
      );
    }
  }


  Future<void> _sendAppointmentCompletedEmail() async{
    final appointment = currentAppointment;
    if (appointment == null) return;

    final customerEmail = appointment['customerEmail'] ?? '';
    final customerName = appointment['customerName'] ?? 'Customer';
    final businessName = appointment['businessName'] ?? 'Business';
    final serviceName = appointment['serviceName'] ?? 'service';

    if (customerEmail.isNotEmpty) {
      await EmailService.queueAppointmentCompleted(
        customerEmail: customerEmail,
        customerName: customerName,
        businessName: businessName,
        serviceName: serviceName,
      );
    }
  }
}