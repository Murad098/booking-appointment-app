// lib/features/home/business account/branch management/branch_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/app_icons.dart';
import '../../../../app/custom_snackbar.dart';
import 'branch analytics/branch_analytics_screen.dart';
import 'branch_controller.dart';
import 'branch_model.dart';

class BranchListScreen extends StatefulWidget {
  const BranchListScreen({super.key});

  @override
  State<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen> {
  final controller = Get.put(BranchController());

  // Cache for business profiles keyed by branchManagerId
  Map<String, Map<String, dynamic>> _businessProfiles = {};
  bool _isLoadingProfiles = true;

  @override
  void initState() {
    super.initState();
    ever(controller.branches, (_) {
      _fetchBusinessProfiles();
    });
  }

  Future<void> _fetchBusinessProfiles() async {
    final branches = controller.branches;
    if (branches.isEmpty) {
      setState(() {
        _businessProfiles = {};
        _isLoadingProfiles = false;
      });
      return;
    }

    setState(() => _isLoadingProfiles = true);

    final Map<String, Map<String, dynamic>> profiles = {};
    for (var branch in branches) {
      final managerId = branch.branchManagerId;
      if (managerId.isEmpty) continue;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('businesses')
            .doc(managerId)
            .get();
        if (doc.exists) {
          profiles[managerId] = doc.data() as Map<String, dynamic>;
        }
      } catch (e) {
        print('Error fetching business profile for $managerId: $e');
      }
    }

    setState(() {
      _businessProfiles = profiles;
      _isLoadingProfiles = false;
    });
  }

  Map<String, dynamic> _getBranchDisplayData(Branch branch) {
    final profile = _businessProfiles[branch.branchManagerId];
    if (profile != null) {
      return {
        'imageUrl': profile['profileImage'] ?? branch.imageUrl,
        'name': profile['businessName'] ?? branch.name,
        'location': profile['address'] ?? branch.location,
      };
    } else {
      return {
        'imageUrl': branch.imageUrl,
        'name': branch.name,
        'location': branch.location,
      };
    }
  }

  String _extractCity(String location) {
    if (location.isEmpty) return '';
    final parts = location.split(',');
    if (parts.isNotEmpty) {
      return parts.last.trim();
    }
    return location;
  }

  Future<Map<String, dynamic>> _fetchBranchMetrics(Branch branch) async {
    final managerId = branch.branchManagerId;
    if (managerId.isEmpty) {
      return {'bookings': 0, 'revenue': 0};
    }

    final bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('businessId', isEqualTo: managerId)
        .get();

    int totalBookings = 0;
    double totalRevenue = 0;
    for (var doc in bookingsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] ?? 'pending';
      final autoCancelled = data['autoCancelled'] ?? false;
      if (autoCancelled) continue;
      if (status == 'completed' || status == 'confirmed') {
        totalBookings++;
        final price = double.tryParse(data['servicePrice']?.toString() ?? '0') ?? 0;
        final advancePaid = (data['advanceAmount'] ?? 0).toDouble();
        if (status == 'completed') {
          totalRevenue += price;
        } else {
          totalRevenue += advancePaid;
        }
      }
    }
    return {
      'bookings': totalBookings,
      'revenue': totalRevenue.toInt(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(AppIcons.arrowLeft, color: AppColors.textHeadline),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Branch Management',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.scaffoldBackground,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: AppColors.textHeadline),
            onPressed: () {},
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.branches.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.branches.isEmpty) {
          return _buildEmptyState();
        }
        return FutureBuilder<Map<String, dynamic>>(
          future: _computeTotals(controller.branches),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final totals = snapshot.data ?? {'bookings': 0, 'revenue': 0};

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.9,
                      children: [
                        _buildMetricCard(
                          title: 'Total Branches',
                          value: '${controller.branches.length}',
                          icon: Icons.store_mall_directory,
                          color: AppColors.primaryPurple,
                        ),
                        _buildMetricCard(
                          title: 'Active Branches',
                          value: '${controller.branches.length}',
                          icon: Icons.check_circle_outline,
                          color: Colors.green.shade600,
                        ),
                        _buildMetricCard(
                          title: 'Total Bookings',
                          value: '${totals['bookings']}',
                          icon: Icons.calendar_today,
                          color: Colors.blue.shade600,
                        ),
                        _buildMetricCard(
                          title: 'Total Revenue',
                          value: 'PKR ${totals['revenue']}',
                          icon: Icons.attach_money,
                          color: Colors.amber.shade700,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Locations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textHeadline,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text('View All', style: TextStyle(color: AppColors.primaryPurple)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: controller.branches.length,
                    itemBuilder: (context, index) {
                      final branch = controller.branches[index];
                      return _buildCleanBranchCard(branch);
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/branch-create'),
        backgroundColor: AppColors.primaryPurple,
        icon: const Icon(Icons.add_business_outlined, color: Colors.white),
        label: const Text(
          'Add Branch',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<Map<String, dynamic>> _computeTotals(List<Branch> branches) async {
    int totalBookings = 0;
    int totalRevenue = 0;
    for (var branch in branches) {
      final metrics = await _fetchBranchMetrics(branch);
      totalBookings += metrics['bookings'] as int;
      totalRevenue += metrics['revenue'] as int;
    }
    return {'bookings': totalBookings, 'revenue': totalRevenue};
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textPlaceholder,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textHeadline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanBranchCard(Branch branch) {
    final displayData = _getBranchDisplayData(branch);
    final imageUrl = displayData['imageUrl'] as String;
    final name = displayData['name'] as String;
    final location = displayData['location'] as String;

    return GestureDetector(
      onTap: () { Get.to(() => BranchAnalyticsScreen(branchId: branch.id)); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.store, color: Colors.grey.shade400),
                ),
              )
                  : Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade200,
                child: Icon(Icons.store, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textHeadline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Replace right arrow with PopupMenuButton
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                        onSelected: (value) async {
                          if (value == 'analytics') {
                            // Navigate to branch analytics
                            Get.to(() => BranchAnalyticsScreen(branchId: branch.id));
                          } else if (value == 'delete') {
                            // Show delete confirmation dialog
                            _showDeleteConfirmation(branch);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'analytics',
                            child: Row(
                              children: [
                                Icon(Icons.analytics, size: 18, color: AppColors.primaryPurple),
                                SizedBox(width: 8),
                                Text('View Analytics'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: AppColors.deleteColor),
                                SizedBox(width: 8),
                                Text('Delete Branch'),
                              ],
                            ),
                          ),
                        ],
                        offset: const Offset(0, -20),
                        elevation: 2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _extractCity(location),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: branch.services.take(2).map((s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 9)),
                      backgroundColor: AppColors.backgroundLightPurple,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: Use Get.close(1) to close only the loading dialog
  void _showDeleteConfirmation(Branch branch) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Branch',
          style: TextStyle(color: AppColors.textHeadline),
        ),
        content: Text(
          'Do you want to delete this branch?',
          style: TextStyle(color: AppColors.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textBody)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close confirmation dialog first
              Get.back();

              // Show loading overlay
              Get.dialog(
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryPurple),
                ),
                barrierDismissible: false,
              );

              try {
                await controller.deleteBranch(branch.id);
              } finally {
                // Close ONLY the loading dialog – Get.close(1) does NOT touch snackbars
                if (Get.isDialogOpen ?? false) {
                  Get.close(1);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deleteColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store_mall_directory_outlined,
                size: 64,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Branches Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textHeadline,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You haven’t added any branches yet. Create your first branch to manage multiple locations efficiently.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textBody,
                height: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/branch-create'),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text('Create First Branch', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}