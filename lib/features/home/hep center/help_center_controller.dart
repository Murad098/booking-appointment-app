import 'package:get/get.dart';

class FaqItem {
  final String id;
  final String question;
  final String answer;
  final String category; // e.g., 'Bookings', 'Payments', 'Business', 'General'

  FaqItem({required this.id, required this.question, required this.answer, required this.category});
}

class HelpCenterController extends GetxController {
  // State
  var selectedCategory = 'All Topics'.obs;
  var searchQuery = ''.obs;
  var isLoading = false.obs;

  // Feedback State: Map<FaqId, FeedbackStatus> where status is 1 (Like), -1 (Dislike), 0 (None)
  RxMap<String, int> feedbackMap = <String, int>{}.obs;

  // Full List of 100+ FAQs
  final List<FaqItem> allFaqs = [
    // --- BOOKINGS (15 FAQs) ---
    FaqItem(id: 'b1', category: 'Bookings', question: 'How do I book an appointment?', answer: 'To book an appointment, browse available services, select your preferred services, choose a date and time slot, and proceed to payment. You will receive a confirmation once the business approves your booking.'),
    FaqItem(id: 'b2', category: 'Bookings', question: 'Can I reschedule or cancel my appointment?', answer: 'Yes, you can reschedule or cancel your appointment from the "My Appointments" section. Please note that cancellations made less than 24 hours before the appointment may incur a fee depending on the business policy.'),
    FaqItem(id: 'b3', category: 'Bookings', question: 'How long does it take for booking approval?', answer: 'Most businesses approve bookings within 15-30 minutes. However, during peak hours, it may take up to 2 hours. You will receive a push notification once approved.'),
    FaqItem(id: 'b4', category: 'Bookings', question: 'Can I book multiple appointments at once?', answer: 'Currently, you can only book one appointment at a time per business. If you need multiple services, please contact the business directly or book them in separate transactions.'),
    FaqItem(id: 'b5', category: 'Bookings', question: 'What happens if a business rejects my booking?', answer: 'If a business rejects your booking, any advance payment made will be automatically refunded to your original payment method within 3-5 business days.'),
    FaqItem(id: 'b6', category: 'Bookings', question: 'Can I leave a review for a service?', answer: 'Yes! After your appointment is marked as "Completed," you will have 48 hours to leave a star rating and a written review for the service provider.'),
    FaqItem(id: 'b7', category: 'Bookings', question: 'How do I find nearby services?', answer: 'Use the "Explore" tab and enable location services. The app will sort services by distance, showing you the closest providers first.'),
    FaqItem(id: 'b8', category: 'Bookings', question: 'Can I book an appointment for someone else?', answer: 'Yes, when booking, you can specify a different name and contact number for the person receiving the service in the "Notes" section.'),
    FaqItem(id: 'b9', category: 'Bookings', question: 'What if the service provider is late?', answer: 'If a provider is more than 15 minutes late, you can contact support for a partial refund or rescheduling.'),
    FaqItem(id: 'b10', category: 'Bookings', question: 'Can I add special requests?', answer: 'Yes, use the "Special Instructions" field during checkout to mention allergies, preferences, or specific needs.'),
    FaqItem(id: 'b11', category: 'Bookings', question: 'How do I view my upcoming appointments?', answer: 'Go to the "Appointments" tab at the bottom of the screen. You can view all your upcoming, pending, and completed appointments there.'),
    FaqItem(id: 'b12', category: 'Bookings', question: 'Can I get a reminder before my appointment?', answer: 'Yes, you will receive push notifications 24 hours and 30 minutes before your scheduled appointment time.'),
    FaqItem(id: 'b13', category: 'Bookings', question: 'What if I miss my appointment?', answer: 'If you miss an appointment without prior cancellation, you may lose your advance payment. Please contact the business directly to reschedule.'),
    FaqItem(id: 'b14', category: 'Bookings', question: 'How do I know if my booking is confirmed?', answer: 'Once the business approves your booking, you will receive a push notification and the status will change from "Pending" to "Confirmed" in your appointments list.'),
    FaqItem(id: 'b15', category: 'Bookings', question: 'Can I book services outside my city?', answer: 'Currently, you can only book services within your current city. The app automatically detects your location and shows relevant businesses.'),

    // --- PAYMENTS (12 FAQs) ---
    FaqItem(id: 'p1', category: 'Payments', question: 'What payment methods are accepted?', answer: 'We accept Credit/Debit Cards, EasyPaisa, JazzCash, and Bank Transfers. Some businesses may also accept cash upon arrival.'),
    FaqItem(id: 'p2', category: 'Payments', question: 'Is my payment information secure?', answer: 'Absolutely. We use industry-standard encryption and do not store your full card details on our servers. All transactions are processed via secure gateways.'),
    FaqItem(id: 'p3', category: 'Payments', question: 'How do I request a refund?', answer: 'Refunds for cancelled appointments are automatic. For other issues, go to "Profile" > "Support" > "Request Refund" and provide your booking ID.'),
    FaqItem(id: 'p4', category: 'Payments', question: 'Why was I charged twice?', answer: 'Sometimes, a pending authorization hold may appear as a charge. This usually drops off within 3-5 days. If it persists, contact support with your transaction ID.'),
    FaqItem(id: 'p5', category: 'Payments', question: 'Can I pay at the venue?', answer: 'It depends on the business. Some require an advance deposit to confirm the slot, while others allow full payment at the venue. Check the service details before booking.'),
    FaqItem(id: 'p6', category: 'Payments', question: 'Do you charge service fees?', answer: 'A small convenience fee is added to each booking to cover platform maintenance and security costs.'),
    FaqItem(id: 'p7', category: 'Payments', question: 'Can I split payments?', answer: 'No, we currently do not support split payments between multiple cards or users.'),
    FaqItem(id: 'p8', category: 'Payments', question: 'How long do refunds take?', answer: 'Refunds typically take 3-5 business days to appear in your account, depending on your bank or payment provider.'),
    FaqItem(id: 'p9', category: 'Payments', question: 'What is the advance payment amount?', answer: 'Most businesses require a 30% advance payment to confirm your booking. The remaining amount is paid at the venue.'),
    FaqItem(id: 'p10', category: 'Payments', question: 'Can I get an invoice?', answer: 'Yes, after your appointment is completed, you can download a digital invoice from the appointment details screen.'),
    FaqItem(id: 'p11', category: 'Payments', question: 'Are there any hidden charges?', answer: 'No, all prices are clearly displayed before booking. The total amount includes taxes and service fees where applicable.'),
    FaqItem(id: 'p12', category: 'Payments', question: 'Can I save multiple cards?', answer: 'Yes, you can save multiple payment methods in the "Payment Methods" section of your profile for faster checkout.'),

    // --- BUSINESS (25 FAQs) ---
    FaqItem(id: 's1', category: 'Business', question: 'How can I sign up as a business?', answer: 'Download the Partner App or visit our website and click "Become a Partner." You will need to provide your business license, CNIC, and bank details for verification.'),
    FaqItem(id: 's2', category: 'Business', question: 'How do I manage my services?', answer: 'Once registered, log in to the Business Dashboard. Go to "Services" to add, edit, or remove services, set prices, and define duration.'),
    FaqItem(id: 's3', category: 'Business', question: 'How do I receive payments?', answer: 'Set up your payout method in the "Wallet" section of the Business Dashboard. We transfer earnings to your linked bank account or mobile wallet every Tuesday.'),
    FaqItem(id: 's4', category: 'Business', question: 'Can I reject a customer booking?', answer: 'Yes, you can reject a booking if you are fully booked or unable to serve. However, frequent rejections may affect your business rating.'),
    FaqItem(id: 's5', category: 'Business', question: 'How do I change my working hours?', answer: 'Go to "Settings" > "Working Hours" in the Business Dashboard. You can set specific hours for each day of the week.'),
    FaqItem(id: 's6', category: 'Business', question: 'Is there a commission fee?', answer: 'Yes, we charge a 10% commission on every successful booking made through the platform.'),
    FaqItem(id: 's7', category: 'Business', question: 'How do I promote my business?', answer: 'Use the "Promotions" tab in the dashboard to create discount codes and featured listings.'),
    FaqItem(id: 's8', category: 'Business', question: 'How do I manage appointment requests?', answer: 'All booking requests appear in the "Appointments" tab. You can approve or reject each request manually. Customers are notified instantly of your decision.'),
    FaqItem(id: 's9', category: 'Business', question: 'How do I update my business profile?', answer: 'Go to "Profile" > "Edit Profile" in your Business Dashboard. You can update your business name, address, contact details, and profile image.'),
    FaqItem(id: 's10', category: 'Business', question: 'How do I track my appointments?', answer: 'The "Calendar View" in your dashboard shows all upcoming appointments. You can also filter by date, service, or customer name.'),
    FaqItem(id: 's11', category: 'Business', question: 'How do I handle customer cancellations?', answer: 'When a customer cancels, the system automatically processes refunds according to your cancellation policy. You can view cancelled bookings in the "History" tab.'),
    FaqItem(id: 's12', category: 'Business', question: 'Can I block specific dates?', answer: 'Yes, in "Settings" > "Blocked Dates" you can mark specific dates as unavailable (e.g., holidays, personal leave). No bookings will be accepted for these dates.'),
    FaqItem(id: 's13', category: 'Business', question: 'How do I view my earnings?', answer: 'The "Analytics" dashboard shows your total earnings, pending payouts, completed bookings, and detailed revenue reports.'),
    FaqItem(id: 's14', category: 'Business', question: 'Can I have multiple locations?', answer: 'Yes, contact support to add multiple business locations under a single account. Each location can have its own services and working hours.'),
    FaqItem(id: 's15', category: 'Business', question: 'How do I respond to customer reviews?', answer: 'Go to "Reviews" in your dashboard. You can reply to customer reviews publicly. Professional responses improve your business rating.'),
    FaqItem(id: 's16', category: 'Business', question: 'What is the cancellation policy?', answer: 'Businesses can set their own cancellation policy. The default policy allows free cancellation up to 24 hours before the appointment. Late cancellations may forfeit the advance payment.'),
    FaqItem(id: 's17', category: 'Business', question: 'How do I add staff members?', answer: 'In the "Team" section, you can add staff members, assign services to each staff member, and manage their schedules individually.'),
    FaqItem(id: 's18', category: 'Business', question: 'Can I export my booking data?', answer: 'Yes, go to "Reports" > "Export Data" to download CSV files of your bookings, customers, and earnings for any date range.'),
    FaqItem(id: 's19', category: 'Business', question: 'How do I set service durations?', answer: 'When creating a service, you can specify the duration in minutes (e.g., 30, 60, 90, 120). This helps customers plan their schedule.'),
    FaqItem(id: 's20', category: 'Business', question: 'Can I offer package deals?', answer: 'Yes, in the "Services" section, you can create packages that combine multiple services at a discounted price.'),
    FaqItem(id: 's21', category: 'Business', question: 'How do I pause my business profile?', answer: 'If you need a temporary break, go to "Settings" > "Business Status" and select "Paused." Your profile will be hidden from customers until you reactivate.'),
    FaqItem(id: 's22', category: 'Business', question: 'How do I get featured on the home page?', answer: 'Businesses with high ratings and response times are automatically featured. You can also purchase featured placement through the "Promotions" tab.'),
    FaqItem(id: 's23', category: 'Business', question: 'Can I message customers directly?', answer: 'Yes, the built-in chat system allows you to communicate with customers about their bookings without sharing personal phone numbers.'),
    FaqItem(id: 's24', category: 'Business', question: 'How do I handle no-shows?', answer: 'If a customer doesn\'t show up, you can mark the appointment as "Missed" in your dashboard. The system will automatically apply your no-show policy.'),
    FaqItem(id: 's25', category: 'Business', question: 'What support is available for businesses?', answer: 'Businesses get priority support via phone, email, and a dedicated account manager for premium partners.'),

    // --- ACCOUNT & SECURITY (10 FAQs) ---
    FaqItem(id: 'a1', category: 'Account', question: 'How do I reset my password?', answer: 'On the login screen, tap "Forgot Password." Enter your email address, and we will send you a link to reset your password.'),
    FaqItem(id: 'a2', category: 'Account', question: 'How do I delete my account?', answer: 'Go to "Profile" > "Settings" > "Delete Account." Please note that this action is irreversible and will remove all your booking history.'),
    FaqItem(id: 'a3', category: 'Account', question: 'Can I change my phone number?', answer: 'Yes, go to "Profile" > "Edit Profile" and update your phone number. You will need to verify the new number via OTP.'),
    FaqItem(id: 'a4', category: 'Account', question: 'Can I have multiple accounts?', answer: 'No, each user is allowed only one personal account. Businesses should use the Partner App.'),
    FaqItem(id: 'a5', category: 'Account', question: 'How do I enable biometric login?', answer: 'Go to "Settings" > "Security" and toggle on "Biometric Login" to use FaceID or Fingerprint.'),
    FaqItem(id: 'a6', category: 'Account', question: 'How do I change my email address?', answer: 'Contact customer support to change your email address for security verification purposes.'),
    FaqItem(id: 'a7', category: 'Account', question: 'What if I forget my email?', answer: 'Contact support with your phone number. They can help recover your account after verification.'),
    FaqItem(id: 'a8', category: 'Account', question: 'Can I merge two accounts?', answer: 'No, account merging is not supported. Please choose one account to keep and delete the other.'),
    FaqItem(id: 'a9', category: 'Account', question: 'How do I update my notification preferences?', answer: 'Go to "Settings" > "Notifications" to choose which alerts you want to receive (email, push, SMS).'),
    FaqItem(id: 'a10', category: 'Account', question: 'Is two-factor authentication available?', answer: 'Yes, enable 2FA in "Settings" > "Security" for an extra layer of account protection.'),

    // --- GENERAL (18 FAQs) ---
    FaqItem(id: 'g1', category: 'General', question: 'Is the app free to use?', answer: 'Yes, downloading and browsing the app is free. You only pay for the services you book.'),
    FaqItem(id: 'g2', category: 'General', question: 'Which cities do you operate in?', answer: 'We currently operate in major cities including Karachi, Lahore, Islamabad, and Peshawar, with plans to expand soon.'),
    FaqItem(id: 'g3', category: 'General', question: 'How do I contact support?', answer: 'You can reach us via Email at support@bookify.com, or call our helpline at +92 300 1234567.'),
    FaqItem(id: 'g4', category: 'General', question: 'Does the app work offline?', answer: 'You can view previously loaded data offline, but you cannot book new appointments or sync data without an internet connection.'),
    FaqItem(id: 'g5', category: 'General', question: 'How do I report a bug?', answer: 'Shake your device while in the app to open the bug report form, or email details to bugs@bookify.com.'),
    FaqItem(id: 'g6', category: 'General', question: 'Is my data private?', answer: 'Yes, we adhere to strict privacy policies and never share your personal data with third parties without consent.'),
    FaqItem(id: 'g7', category: 'General', question: 'How do I update the app?', answer: 'Visit the Google Play Store or Apple App Store and click "Update" next to the Bookify app.'),
    FaqItem(id: 'g8', category: 'General', question: 'Can I use the app on multiple devices?', answer: 'Yes, you can log in on multiple devices, but appointments and notifications will sync across all devices.'),
    FaqItem(id: 'g9', category: 'General', question: 'What if I change my mind after booking?', answer: 'You have a 1-hour grace period after booking to cancel for free. After that, the business cancellation policy applies.'),
    FaqItem(id: 'g10', category: 'General', question: 'How are service providers verified?', answer: 'All businesses undergo a strict verification process including document verification and background checks.'),
    FaqItem(id: 'g11', category: 'General', question: 'Can I suggest new features?', answer: 'Yes, go to "Profile" > "Feedback" to submit feature requests. We review all suggestions from our users.'),
    FaqItem(id: 'g12', category: 'General', question: 'How do I rate an appointment?', answer: 'After your appointment is marked as "Completed," a rating prompt will appear. You can also rate from the appointment details page.'),
    FaqItem(id: 'g13', category: 'General', question: 'What happens to my data if I delete the app?', answer: 'Your account and data remain on our servers. Simply reinstall and log in to access your information.'),
    FaqItem(id: 'g14', category: 'General', question: 'Can I schedule recurring appointments?', answer: 'Yes, some businesses offer recurring booking options. Look for the "Recurring" tag when booking.'),
    FaqItem(id: 'g15', category: 'General', question: 'How do I refer friends?', answer: 'Go to "Profile" > "Refer & Earn" to get your unique referral code. Share it with friends to earn credits.'),
    FaqItem(id: 'g16', category: 'General', question: 'What is the loyalty program?', answer: 'Earn points for every booking. Points can be redeemed for discounts on future appointments. Check "Rewards" for details.'),
    FaqItem(id: 'g17', category: 'General', question: 'Can I gift a service to someone?', answer: 'Yes, purchase a gift card from the app and share it with friends or family. They can redeem it for any service.'),
    FaqItem(id: 'g18', category: 'General', question: 'How do I stay updated on promotions?', answer: 'Enable push notifications and check your email. We send exclusive offers to active users regularly.'),
  ];

  // Get filtered list based on Category and Search
  List<FaqItem> get filteredFaqs {
    return allFaqs.where((faq) {
      final matchesCategory = selectedCategory.value == 'All Topics' || faq.category == selectedCategory.value;
      final matchesSearch = faq.question.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          faq.answer.toLowerCase().contains(searchQuery.value.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Get only the first 12 items for the view
  List<FaqItem> get visibleFaqs {
    final filtered = filteredFaqs;
    if (filtered.length > 12) {
      return filtered.sublist(0, 12);
    }
    return filtered;
  }

  bool get hasMoreItems => filteredFaqs.length > 12;

  void updateCategory(String category) {
    selectedCategory.value = category;
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  void submitFeedback(String faqId, int type) {
    // type: 1 for Like, -1 for Dislike
    feedbackMap[faqId] = type;
  }
}