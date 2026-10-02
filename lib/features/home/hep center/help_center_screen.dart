import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'help_center_controller.dart';
import '../../../../app/app_colors.dart'; // Adjust path

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HelpCenterController());
    final TextEditingController searchController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help Center',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textHeadline,
              ),
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: searchController,
                onChanged: controller.updateSearch,
                decoration: InputDecoration(
                  hintText: 'Search for help...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // 2. Topic Filter Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Obx(() => _buildTopicDropdown(controller)),
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 24),

            // 3. FAQ Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeadline,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 4. FAQ List (Limited to 12)
            Obx(() {
              final faqs = controller.visibleFaqs;
              if (faqs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No questions found.')),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: faqs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildFaqCard(faqs[index], controller);
                },
              );
            }),

            // Load More Indicator (if applicable)
            Obx(() {
              if (controller.hasMoreItems) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Showing top 12 results. Refine search for more.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            const SizedBox(height: 24),

            // 5. Contact Card (Updated: White background, Purple border, No Chat)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, // Changed to white
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryPurple, // Added purple border
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need More Help?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeadline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Our support team is here to assist you',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Removed Chat option - keeping only Email and Call
                      _buildContactButton(Icons.email_outlined, 'Email'),
                      _buildContactButton(Icons.phone_outlined, 'Call'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 6. Contact Info & Support Hours
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildInfoCard(
                    title: 'Contact Information',
                    children: [
                      _buildContactRow(Icons.email_outlined, 'Email', 'support@bookify.com', Colors.blue),
                      _buildContactRow(Icons.phone_outlined, 'Phone', '+92 300 1234567', Colors.green),
                      // Removed Live Chat row
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    title: 'Support Hours',
                    isOrange: true,
                    children: [
                      const Text('Our support team is available:', style: TextStyle(fontSize: 13, color: Colors.orange)),
                      const SizedBox(height: 8),
                      _buildBulletPoint('Monday - Friday: 9:00 AM - 9:00 PM'),
                      _buildBulletPoint('Saturday - Sunday: 10:00 AM - 6:00 PM'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildTopicDropdown(HelpCenterController controller) {
    final categories = ['All Topics', 'Bookings', 'Payments', 'Business', 'Account', 'General'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedCategory.value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: category == 'All Topics' ? AppColors.primaryPurple : Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) controller.updateCategory(newValue);
          },
        ),
      ),
    );
  }

  Widget _buildContactButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryPurple, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: AppColors.textHeadline, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFaqCard(FaqItem faq, HelpCenterController controller) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      maintainState: true,
      iconColor: AppColors.primaryPurple,
      collapsedIconColor: Colors.grey,
      title: Text(
        faq.question,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textHeadline,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          faq.category,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.primaryPurple,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      children: [
        Text(
          faq.answer,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textBody,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),

        // Feedback Section
        Row(
          children: [
            Text('Was this helpful?', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const Spacer(),
            Obx(() {
              final feedback = controller.feedbackMap[faq.id] ?? 0;
              return Row(
                children: [
                  GestureDetector(
                    onTap: () => controller.submitFeedback(faq.id, 1),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: feedback == 1 ? Colors.green.shade50 : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 18,
                        color: feedback == 1 ? Colors.green : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.submitFeedback(faq.id, -1),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: feedback == -1 ? Colors.red.shade50 : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.thumb_down_alt_outlined,
                        size: 18,
                        color: feedback == -1 ? Colors.red : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              );
            })
          ],
        )
      ],
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children, bool isOrange = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOrange ? const Color(0xFFFFF3E0) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOrange ? const Color(0xFFFFE0B2) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isOrange ? Colors.orange.shade800 : AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textHeadline)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.orange.shade800, fontSize: 14)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.orange.shade900))),
        ],
      ),
    );
  }
}