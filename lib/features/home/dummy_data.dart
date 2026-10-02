import 'package:bookify/app/app_icons.dart';
import 'package:flutter/material.dart';

class CategoryData {
  final String id;
  final String name;
  final IconData icon;
  CategoryData({required this.id, required this.name, required this.icon});
}

class BusinessData {
  final String id;
  final String name;
  final String categoryId;
  final String description;
  final String location;
  final String rating;
  final String price;
  final String duration;
  final String imageUrl;
  final String businessPhone;
  BusinessData({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.description,
    required this.location,
    required this.rating,
    this.price = '',
    this.duration = '',
    this.imageUrl = '',
    this.businessPhone ='',
  });
}

// 🔹 Categories
final List<CategoryData> categories = [
  CategoryData(id: 'all', name: 'All', icon: AppIcons.app),
  CategoryData(id: 'salon', name: 'Salon', icon: AppIcons.cut),
  CategoryData(id: 'clinics', name: 'Clinics', icon: AppIcons.hospital),
  CategoryData(id: 'fitness', name: 'Fitness Centers', icon: AppIcons.fitness),
  CategoryData(id: 'beauty', name: 'Beauty & Wellness', icon: AppIcons.spa),
  CategoryData(id: 'health', name: 'Health & Wellness', icon: AppIcons.health),
  CategoryData(id: 'healthcare', name: 'Healthcare Services', icon: AppIcons.healthcare),
  CategoryData(id: 'automotive', name: 'Automotive Services', icon: AppIcons.car),
  CategoryData(id: 'tax', name: 'Tax Consultants', icon: AppIcons.balance),
  CategoryData(id: 'spa', name: 'Spa / Massage', icon: AppIcons.bubble),
  CategoryData(id: 'restaurants', name: 'Restaurants', icon: AppIcons.restaurant),
  CategoryData(id: 'events', name: 'Event Planners', icon: AppIcons.event),
  CategoryData(id: 'wedding', name: 'Wedding Services', icon: AppIcons.favorite),
  CategoryData(id: 'other', name: 'Other', icon: AppIcons.threedots),
];

// 🔹 Dummy Businesses with Pakistani Cities & Online Images
final List<BusinessData> dummyBusinesses = [
  // Salon
  BusinessData(
    id: 'b1',
    name: 'Elite Hair Studio',
    categoryId: 'salon',
    description: 'Premium cuts & coloring',
    location: 'DHA, Karachi',
    rating: '4.8',
    price: 'PKR 2,500',
    duration: '60 min',
    businessPhone: '+92 301 2436896',
    imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b2',
    name: 'Style Hub',
    categoryId: 'salon',
    description: 'Modern unisex salon',
    location: 'Gulberg, Lahore',
    rating: '4.5',
    price: 'PKR 1,800',
    duration: '45 min',
    businessPhone: '+92 300 6745342',
    imageUrl: 'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b3',
    name: 'Glamour Cuts',
    categoryId: 'salon',
    description: 'Bridal & party styling',
    location: 'F-7, Islamabad',
    rating: '4.9',
    price: 'PKR 3,200',
    duration: '90 min',
    businessPhone: '+92 330 1225697',
    imageUrl: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b4',
    name: 'Urban Barber',
    categoryId: 'salon',
    description: 'Classic & modern fades',
    location: 'Saddar, Rawalpindi',
    rating: '4.6',
    price: 'PKR 1,500',
    duration: '30 min',
    businessPhone: '+92 321 1094527',
    imageUrl: 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b5',
    name: 'Luxe Salon',
    categoryId: 'salon',
    description: 'Organic hair treatments',
    location: 'Clifton, Karachi',
    rating: '4.7',
    price: 'PKR 2,900',
    duration: '75 min',
    businessPhone: '+92 314 1910467',
    imageUrl: 'https://images.unsplash.com/photo-1633681926022-84c23e8cb2d6?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b6',
    name: 'Quick Trim',
    categoryId: 'salon',
    description: 'Express haircuts',
    location: 'Model Town, Lahore',
    rating: '4.2',
    price: 'PKR 900',
    duration: '20 min',
    businessPhone: '+92 320 2409954',
    imageUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400&h=300&fit=crop',
  ),

  // Clinics
  BusinessData(
    id: 'b7',
    name: 'City Dental Care',
    categoryId: 'clinics',
    description: 'General & cosmetic dentistry',
    location: 'Blue Area, Islamabad',
    rating: '4.9',
    price: 'PKR 3,000',
    duration: '45 min',
    businessPhone: '+92 303 4567890',
    imageUrl: 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b8',
    name: 'QuickHealth Clinic',
    categoryId: 'clinics',
    description: 'Walk-in consultations',
    location: 'Gulshan-e-Iqbal, Karachi',
    rating: '4.4',
    price: 'PKR 1,200',
    duration: '30 min',
    businessPhone: '+92 304 5678901',
    imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b9',
    name: 'DermaPlus',
    categoryId: 'clinics',
    description: 'Skin & laser treatments',
    location: 'DHA, Lahore',
    rating: '4.8',
    price: 'PKR 4,500',
    duration: '60 min',
    businessPhone: '+92 305 6789012',
    imageUrl: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b10',
    name: 'Family Care Center',
    categoryId: 'clinics',
    description: 'Pediatric & general',
    location: 'F-10, Islamabad',
    rating: '4.6',
    price: 'PKR 1,500',
    duration: '40 min',
    businessPhone: '+92 306 7890123',
    imageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b11',
    name: 'OptiVision Eye Clinic',
    categoryId: 'clinics',
    description: 'Eye exams & lenses',
    location: 'Saddar, Karachi',
    rating: '4.7',
    price: 'PKR 2,000',
    duration: '50 min',
    businessPhone: '+92 307 8901234',
    imageUrl: 'https://images.unsplash.com/photo-1579154204601-01588f351e67?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b12',
    name: 'MediQuick',
    categoryId: 'clinics',
    description: '24/7 urgent care',
    location: 'Johar Town, Lahore',
    rating: '4.3',
    price: 'PKR 1,800',
    duration: '35 min',
    businessPhone: '+92 308 9012345',
    imageUrl: 'https://img.freepik.com/premium-photo/photo-modern-medical-clinic-interior-high-quality-details-8k-full-ultra-hd-ar-169-v-52-job-id-3246525210e5405ab2cb52c0c7d7bfd8_1055425-17160.jpg',
  ),

  // Fitness Centers
  BusinessData(
    id: 'b13',
    name: 'IronPump Gym',
    categoryId: 'fitness',
    description: 'Heavy lifting & cardio',
    location: 'PECHS, Karachi',
    rating: '4.7',
    price: 'PKR 4,000',
    duration: '120 min',
    businessPhone: '+92 315 7788990',
    imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b14',
    name: 'YogaFlow Studio',
    categoryId: 'fitness',
    description: 'Meditation & flexibility',
    location: 'F-6, Islamabad',
    rating: '4.9',
    price: 'PKR 2,200',
    duration: '60 min',
    businessPhone: '+92 316 8899012',
    imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b15',
    name: 'CrossFit Zone',
    categoryId: 'fitness',
    description: 'High intensity training',
    location: 'DHA Phase 5, Lahore',
    rating: '4.6',
    price: 'PKR 3,500',
    duration: '90 min',
    businessPhone: '+92 317 9901234',
    imageUrl: 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b16',
    name: 'AquaFit Pool',
    categoryId: 'fitness',
    description: 'Swimming & aqua aerobics',
    location: 'Bahria Town, Islamabad',
    rating: '4.5',
    price: 'PKR 1,800',
    duration: '45 min',
    businessPhone: '+92 321 7788990',
    imageUrl: 'https://tse1.mm.bing.net/th/id/OIP.NENjeq3PVDQySJHeSOPnTwHaEK?rs=1&pid=ImgDetMain&o=7&rm=3',
  ),
  BusinessData(
    id: 'b17',
    name: 'Pilates Core',
    categoryId: 'fitness',
    description: 'Core strengthening',
    location: 'Gulistan-e-Jauhar, Karachi',
    rating: '4.8',
    price: 'PKR 2,800',
    duration: '50 min',
    businessPhone: '+92 322 8899012',
    imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b18',
    name: 'BoxFit Arena',
    categoryId: 'fitness',
    description: 'Boxing & conditioning',
    location: 'Iqbal Town, Lahore',
    rating: '4.4',
    price: 'PKR 2,500',
    duration: '75 min',
    businessPhone: '+92 331 7788990',
    imageUrl: 'https://tse4.mm.bing.net/th/id/OIP.VzciWzID07AbiKZj1CeAXwHaG8?rs=1&pid=ImgDetMain&o=7&rm=3',
  ),

  // Beauty & Wellness
  BusinessData(
    id: 'b19',
    name: 'Glow Skin Clinic',
    categoryId: 'beauty',
    description: 'Facials & peels',
    location: 'Defence, Karachi',
    rating: '4.8',
    price: 'PKR 3,200',
    duration: '60 min',
    businessPhone: '+92 333 7788990',
    imageUrl: 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b20',
    name: 'Nail Art Studio',
    categoryId: 'beauty',
    description: 'Manicure & pedicure',
    location: 'MM Alam Road, Lahore',
    rating: '4.6',
    price: 'PKR 1,500',
    duration: '40 min',
    businessPhone: '+92 334 8899012',
    imageUrl: 'https://images.unsplash.com/photo-1604654894610-df63bc536371?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b21',
    name: 'Lash & Brow Bar',
    categoryId: 'beauty',
    description: 'Extensions & tinting',
    location: 'E-7, Islamabad',
    rating: '4.9',
    price: 'PKR 2,800',
    duration: '90 min',
    businessPhone: '+92 335 9901234',
    imageUrl: 'https://tse1.mm.bing.net/th/id/OIP.GuTub-8KSmla-Sy4vEog5QHaHa?rs=1&pid=ImgDetMain&o=7&rm=3',
  ),
  BusinessData(
    id: 'b22',
    name: 'Aroma Therapy',
    categoryId: 'beauty',
    description: 'Relaxation & oils',
    location: 'North Nazimabad, Karachi',
    rating: '4.7',
    price: 'PKR 2,200',
    duration: '75 min',
    businessPhone: '+92 336 7788990',
    imageUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b23',
    name: 'Makeup by Sara',
    categoryId: 'beauty',
    description: 'Bridal & event makeup',
    location: 'Gulberg III, Lahore',
    rating: '4.9',
    price: 'PKR 5,000',
    duration: '120 min',
    businessPhone: '+92 312 7788340',
    imageUrl: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b24',
    name: 'Quick Glam',
    categoryId: 'beauty',
    description: 'Express beauty fixes',
    location: 'Korangi, Karachi',
    rating: '4.3',
    price: 'PKR 1,200',
    duration: '30 min',
    businessPhone: '+92 312 7788340',
    imageUrl: 'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=400&h=300&fit=crop',
  ),

  // Health & Wellness
  BusinessData(
    id: 'b25',
    name: 'MindBalance Therapy',
    categoryId: 'health',
    description: 'Counseling & mental health',
    location: 'F-8, Islamabad',
    rating: '4.9',
    price: 'PKR 3,500',
    duration: '60 min',
    businessPhone: '+92 345 7761290',
    imageUrl: 'https://th.bing.com/th?id=OIF.zDStBSTVSmh%2bYoZp0Gu9kQ&rs=1&pid=ImgDetMain&o=7&rm=3',
  ),
  BusinessData(
    id: 'b26',
    name: 'NutriLife Clinic',
    categoryId: 'health',
    description: 'Diet & nutrition plans',
    location: 'Shahrah-e-Faisal, Karachi',
    rating: '4.6',
    price: 'PKR 2,000',
    duration: '45 min',
    businessPhone: '+92 346 8899012',
    imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b27',
    name: 'SleepWell Center',
    categoryId: 'health',
    description: 'Insomnia & sleep therapy',
    location: 'Gulshan-e-Maymar, Karachi',
    rating: '4.8',
    price: 'PKR 2,800',
    duration: '50 min',
    businessPhone: '+92 347 9901234',
    imageUrl: 'https://tse4.mm.bing.net/th/id/OIP.ayycboAsnYdeFJ6cF0IMxAHaE8?rs=1&pid=ImgDetMain&o=7&rm=3',
  ),
  BusinessData(
    id: 'b28',
    name: 'Detox Hub',
    categoryId: 'health',
    description: 'Cleansing & rejuvenation',
    location: 'DHA Phase 6, Lahore',
    rating: '4.5',
    price: 'PKR 3,200',
    duration: '90 min',
    businessPhone: '+92 348 7788990',
    imageUrl: 'https://images.unsplash.com/photo-1545205597-3d9d02c29597?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b29',
    name: 'Vitality Clinic',
    categoryId: 'health',
    description: 'Holistic health checks',
    location: 'G-11, Islamabad',
    rating: '4.7',
    price: 'PKR 2,500',
    duration: '60 min',
    businessPhone: '+92 349 7876990',
    imageUrl: 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b30',
    name: 'Recovery Zone',
    categoryId: 'health',
    description: 'Post-op rehab',
    location: 'Malir, Karachi',
    rating: '4.8',
    price: 'PKR 4,000',
    duration: '75 min',
    businessPhone: '+92 342 7821012',
    imageUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=400&h=300&fit=crop',
  ),

  // Automotive Services
  BusinessData(
    id: 'b31',
    name: 'AutoFix Garage',
    categoryId: 'automotive',
    description: 'Full services & detailing',
    location: 'Korangi Industrial, Karachi',
    rating: '4.6',
    price: 'PKR 5,000',
    duration: '120 min',
    businessPhone: '+92 321 4344454',
    imageUrl: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b32',
    name: 'CarCare Pro',
    categoryId: 'automotive',
    description: 'Denting & painting',
    location: 'Faisalabad Road, Lahore',
    rating: '4.5',
    price: 'PKR 6,500',
    duration: '180 min',
    businessPhone: '+92 321 7683421',
    imageUrl: 'https://th.bing.com/th?id=OIF.fSfi%2bRwdFPaAJM4A2Rd%2fMQ&rs=1&pid=ImgDetMain&o=7&rm=3',
  ),

  // Tax Consultants
  BusinessData(
    id: 'b33',
    name: 'TaxPro Consultants',
    categoryId: 'tax',
    description: 'Filing & audit support',
    location: 'I.I. Chundrigar Road, Karachi',
    rating: '4.8',
    price: 'PKR 3,000',
    businessPhone: '+92 323 6566676',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b34',
    name: 'Finance Hub',
    categoryId: 'tax',
    description: 'Business tax planning',
    location: 'Blue Area, Islamabad',
    rating: '4.7',
    price: 'PKR 4,000',
    duration: '90 min',
    businessPhone: '+92 323 6891276',
    imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=400&h=300&fit=crop',
  ),

  // Spa / Massage
  BusinessData(
    id: 'b35',
    name: 'Zen Spa Retreat',
    categoryId: 'spa',
    description: 'Hot stone & Swedish',
    location: 'DHA Phase 2, Karachi',
    rating: '4.9',
    price: 'PKR 4,500',
    duration: '90 min',
    businessPhone: '+92 324 7677787',
    imageUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b36',
    name: 'Tranquil Massage',
    categoryId: 'spa',
    description: 'Deep tissue therapy',
    location: 'Gulberg, Lahore',
    rating: '4.8',
    price: 'PKR 3,800',
    duration: '75 min',
    businessPhone: '+92 324 7091287',
    imageUrl: 'https://th.bing.com/th/id/OIP.8GjBiaQqSfrV72mw1ghpuQHaEJ?w=303&h=180&c=7&r=0&o=7&dpr=1.1&pid=1.7&rm=3',
  ),

  // Restaurants
  BusinessData(
    id: 'b37',
    name: 'Bistro 52',
    categoryId: 'restaurants',
    description: 'Fine dining & cocktails',
    location: 'Clifton Block 5, Karachi',
    rating: '4.7',
    price: 'PKR 2,800',
    duration: '90 min',
    businessPhone: '+92 305 7677787',
    imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b38',
    name: 'Spice Garden',
    categoryId: 'restaurants',
    description: 'Pakistani & Continental',
    location: 'F-9, Islamabad',
    rating: '4.6',
    price: 'PKR 2,200',
    duration: '75 min',
    businessPhone: '+92 305 7783498',
    imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
  ),

  // Event Planners
  BusinessData(
    id: 'b39',
    name: 'DreamEvents Co',
    categoryId: 'events',
    description: 'Corporate & private',
    location: 'Gulshan-e-Iqbal, Karachi',
    rating: '4.8',
    price: 'PKR 8,000',
    duration: '240 min',
    businessPhone: '+92 323 8911337',
    imageUrl: 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b40',
    name: 'Perfect Occasions',
    categoryId: 'events',
    description: 'Birthday & anniversary',
    location: 'DHA, Lahore',
    rating: '4.7',
    price: 'PKR 6,500',
    duration: '180 min',
    businessPhone: '+92 323 8918937',
    imageUrl: 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=400&h=300&fit=crop',
  ),

  // Wedding Services
  BusinessData(
    id: 'b41',
    name: 'Wedding Bliss',
    categoryId: 'wedding',
    description: 'Full planning & decor',
    location: 'E-11, Islamabad',
    rating: '4.9',
    price: 'PKR 15,000',
    duration: '480 min',
    businessPhone: '+92 334 8908908',
    imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b42',
    name: 'Royal Weddings',
    categoryId: 'wedding',
    description: 'Mehndi & Walima setups',
    location: 'Bahria Town, Lahore',
    rating: '4.8',
    price: 'PKR 12,000',
    businessPhone: '+92 342 7787787',
    duration: '360 min',
    imageUrl: 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=400&h=300&fit=crop',
  ),

  // Other Services
  BusinessData(
    id: 'b43',
    name: 'QuickServe Hub',
    categoryId: 'other',
    description: 'General services',
    location: 'Saddar, Karachi',
    rating: '4.4',
    price: 'PKR 1,000',
    duration: '30 min',
    businessPhone: '+92 346 2121212',
    imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=400&h=300&fit=crop',
  ),
  BusinessData(
    id: 'b44',
    name: 'HomeFix Pro',
    categoryId: 'other',
    description: 'Plumbing & electrical',
    location: 'G-10, Islamabad',
    rating: '4.5',
    price: 'PKR 1,500',
    duration: '60 min',
    businessPhone: '+92 349 5454545',
    imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&h=300&fit=crop',
  ),
];

// 🔹 Dummy Appointments for Business Dashboard - Elite Hair Salon
// Dates updated to range: 2026-05-05 to 2026-05-09
final List<Map<String, dynamic>> dummyAppointments = [
  // === PAST APPOINTMENTS (May 05, 2026) ===
  {
    'id': '1',
    'services': 'Haircut & Styling',
    'customerName': 'Ahmed Khan',
    'email': 'ahmed@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-05',
    'time': '10:00',
    'duration': 60,
    'price': 2500,
    'advancePaid': 500,
    'paymentMethod': 'Credit Card',
    'status': 'completed',
  },
  {
    'id': '2',
    'services': 'Hair Coloring',
    'customerName': 'Sara Ali',
    'email': 'sara@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-05',
    'time': '14:30',
    'duration': 90,
    'price': 3500,
    'advancePaid': 700,
    'paymentMethod': 'Cash',
    'status': 'cancelled',
    'refunded': true, // ✅ Refunded
  },

  // === PAST APPOINTMENTS (May 06, 2026) ===
  {
    'id': '3',
    'services': 'Hair Treatment',
    'customerName': 'Fatima Hassan',
    'email': 'fatima@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-06',
    'time': '11:00',
    'duration': 45,
    'price': 2000,
    'advancePaid': 400,
    'paymentMethod': 'EasyPaisa',
    'status': 'completed',
  },
  {
    'id': '4',
    'services': 'Blow Dry',
    'customerName': 'Zainab Malik',
    'email': 'zainab@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-06',
    'time': '16:00',
    'duration': 30,
    'price': 1500,
    'advancePaid': 300,
    'paymentMethod': 'Credit Card',
    'status': 'cancelled',
    'refunded': false, // ❌ Not refunded yet
  },

  // === PAST APPOINTMENTS (May 07, 2026) ===
  {
    'id': '5',
    'services': 'Bridal Styling',
    'customerName': 'Ayesha Siddiqui',
    'email': 'ayesha@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-07',
    'time': '09:00',
    'duration': 180,
    'price': 5000,
    'advancePaid': 2500,
    'paymentMethod': 'Bank Transfer',
    'status': 'completed',
  },
  {
    'id': '6',
    'services': 'Beard Trim',
    'customerName': 'Usman Tariq',
    'email': 'usman@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-07',
    'time': '13:00',
    'duration': 30,
    'price': 800,
    'advancePaid': 200,
    'paymentMethod': 'Cash',
    'status': 'completed',
  },
  {
    'id': '7',
    'services': 'Hair Spa',
    'customerName': 'Hina Raza',
    'email': 'hina@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-07',
    'time': '15:30',
    'duration': 60,
    'price': 3000,
    'advancePaid': 600,
    'paymentMethod': 'Credit Card',
    'status': 'completed',
  },

  // === TODAY'S APPOINTMENTS (May 08, 2026) ===
  {
    'id': '8',
    'services': 'Keratin Treatment',
    'customerName': 'Maria Ahmed',
    'email': 'maria@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-08',
    'time': '10:30',
    'duration': 120,
    'price': 4500,
    'advancePaid': 1000,
    'paymentMethod': 'EasyPaisa',
    'status': 'completed', // Already passed morning slot
  },
  {
    'id': '9',
    'services': 'Haircut & Styling',
    'customerName': 'Ali Raza',
    'email': 'ali@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-08',
    'time': '14:00',
    'duration': 60,
    'price': 2500,
    'advancePaid': 500,
    'paymentMethod': 'Credit Card',
    'status': 'confirmed', // Upcoming today
  },
  {
    'id': '10',
    'services': 'Hair Coloring',
    'customerName': 'Nida Khan',
    'email': 'nida@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-08',
    'time': '17:00',
    'duration': 90,
    'price': 3500,
    'advancePaid': 700,
    'paymentMethod': 'Cash',
    'status': 'pending', // Pending approval
  },

  // === TOMORROW'S APPOINTMENTS (May 09, 2026) ===
  {
    'id': '11',
    'services': 'Hair Treatment',
    'customerName': 'Sana Malik',
    'email': 'sana@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-09',
    'time': '09:00',
    'duration': 45,
    'price': 2000,
    'advancePaid': 400,
    'paymentMethod': 'Credit Card',
    'status': 'confirmed',
  },
  {
    'id': '12',
    'services': 'Blow Dry',
    'customerName': 'Rabia Shah',
    'email': 'rabia@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-09',
    'time': '11:30',
    'duration': 30,
    'price': 1500,
    'advancePaid': 300,
    'paymentMethod': 'EasyPaisa',
    'status': 'confirmed',
  },
  {
    'id': '13',
    'services': 'Haircut & Styling',
    'customerName': 'Imran Sheikh',
    'email': 'imran@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-09',
    'time': '14:00',
    'duration': 60,
    'price': 2500,
    'advancePaid': 500,
    'paymentMethod': 'Credit Card',
    'status': 'pending',
  },
  {
    'id': '14',
    'services': 'Bridal Styling',
    'customerName': 'Kiran Fatima',
    'email': 'kiran@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-09',
    'time': '16:00',
    'duration': 180,
    'price': 5000,
    'advancePaid': 2500,
    'paymentMethod': 'Bank Transfer',
    'status': 'confirmed',
  },

  // === FUTURE APPOINTMENTS (May 09, 2026 - Extended List) ===
  {
    'id': '15',
    'services': 'Hair Coloring',
    'customerName': 'Amina Butt',
    'email': 'amina@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-09',
    'time': '10:00',
    'duration': 90,
    'price': 3500,
    'advancePaid': 700,
    'paymentMethod': 'Cash',
    'status': 'confirmed',
  },
  {
    'id': '16',
    'services': 'Hair Spa',
    'customerName': 'Tayyaba Hussain',
    'email': 'tayyaba@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-09',
    'time': '13:00',
    'duration': 60,
    'price': 3000,
    'advancePaid': 600,
    'paymentMethod': 'Credit Card',
    'status': 'pending',
  },
  {
    'id': '17',
    'services': 'Keratin Treatment',
    'customerName': 'Bushra Akram',
    'email': 'bushra@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-09',
    'time': '15:30',
    'duration': 120,
    'price': 4500,
    'advancePaid': 1000,
    'paymentMethod': 'EasyPaisa',
    'status': 'confirmed',
  },

  // === ADDITIONAL APPOINTMENTS (May 05 - May 09 Range) ===
  {
    'id': '18',
    'services': 'Beard Trim',
    'customerName': 'Kamran Ali',
    'email': 'kamran@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-05',
    'time': '11:00',
    'duration': 30,
    'price': 800,
    'advancePaid': 200,
    'paymentMethod': 'Cash',
    'status': 'completed',
  },
  {
    'id': '19',
    'services': 'Haircut & Styling',
    'customerName': 'Sadaf Iqbal',
    'email': 'sadaf@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-06',
    'time': '14:00',
    'duration': 60,
    'price': 2500,
    'advancePaid': 500,
    'paymentMethod': 'Credit Card',
    'status': 'completed',
  },
  {
    'id': '20',
    'services': 'Hair Treatment',
    'customerName': 'Rimsha Nawaz',
    'email': 'rimsha@example.com',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'businessEmail': 'contact@elitehairsalon.com',
    'date': '2026-05-07',
    'time': '16:30',
    'duration': 45,
    'price': 2000,
    'advancePaid': 400,
    'paymentMethod': 'Bank Transfer',
    'status': 'completed',
  },
];

// 🔹 Customer/User Appointments (For My Appointments Screen)
// These are appointments from a customer's perspective
// Dates updated to range: 2026-05-05 to 2026-05-09
final List<Map<String, dynamic>> customerAppointments = [
  // === UPCOMING APPOINTMENTS ===

  // Pending
  {
    'id': 'c1',
    'services': 'Haircut & Styling',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'date': '2026-05-09',
    'time': '14:00',
    'duration': 60,
    'price': 2500,
    'status': 'pending',
  },

  // Confirmed
  {
    'id': 'c2',
    'services': 'Hair Coloring',
    'businessName': 'Style Hub',
    'businessPhone': '+92 301 2345678',
    'date': '2026-05-08',
    'time': '10:30',
    'duration': 90,
    'price': 3500,
    'status': 'confirmed',
  },
  {
    'id': 'c3',
    'services': 'Dental Checkup',
    'businessName': 'City Dental Care',
    'businessPhone': '+92 302 3456789',
    'date': '2026-05-09',
    'time': '11:00',
    'duration': 45,
    'price': 3000,
    'status': 'confirmed',
  },

  // === PAST APPOINTMENTS ===

  // Completed
  {
    'id': 'c4',
    'services': 'Beard Trim',
    'businessName': 'Urban Barber',
    'businessPhone': '+92 303 4567890',
    'date': '2026-05-05',
    'time': '16:00',
    'duration': 30,
    'price': 1500,
    'status': 'completed',
  },
  {
    'id': 'c5',
    'services': 'Hair Treatment',
    'businessName': 'Elite Hair Salon',
    'businessPhone': '+92 300 1234567',
    'date': '2026-05-06',
    'time': '13:00',
    'duration': 45,
    'price': 2000,
    'status': 'completed',
  },
  {
    'id': 'c6',
    'services': 'Gym Session',
    'businessName': 'IronPump Gym',
    'businessPhone': '+92 304 5678901',
    'date': '2026-05-07',
    'time': '09:00',
    'duration': 120,
    'price': 4000,
    'status': 'completed',
  },

  // Cancelled
  {
    'id': 'c7',
    'services': 'Bridal Styling',
    'businessName': 'Glamour Cuts',
    'businessPhone': '+92 305 6789012',
    'date': '2026-05-05',
    'time': '10:00',
    'duration': 180,
    'price': 5000,
    'status': 'cancelled',
  },
  {
    'id': 'c8',
    'services': 'Massage Therapy',
    'businessName': 'Zen Spa Retreat',
    'businessPhone': '+92 306 7890123',
    'date': '2026-05-06',
    'time': '15:00',
    'duration': 90,
    'price': 4500,
    'status': 'cancelled',
  },
];


// ════════════════════════════════════════════════════════════
// SERVICE MODEL
// ════════════════════════════════════════════════════════════

class ServiceData {
  final String id;
  final String businessId;
  final String name;
  final String description;
  final String price;
  final String duration;
  final String imageUrl;
  final String category;

  ServiceData({
    required this.id,
    required this.businessId,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.imageUrl,
    required this.category,
  });
}

// ════════════════════════════════════════════════════════════
// ALL SERVICES FOR ALL BUSINESSES
// ════════════════════════════════════════════════════════════

final List<ServiceData> dummyServices = [
  // ════════════════════════════════════════════════════════════
  // ELITE HAIR STUDIO (b1) - 6 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's1',
    businessId: 'b1',
    name: 'Haircut & Styling',
    description: 'Professional cut with styling consultation',
    price: 'PKR 2,500',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&h=300&fit=crop',
    category: 'Hair',
  ),
  ServiceData(
    id: 's2',
    businessId: 'b1',
    name: 'Hair Coloring',
    description: 'Full or partial coloring with premium dyes',
    price: 'PKR 3,500',
    duration: '90 min',
    imageUrl: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&h=300&fit=crop',
    category: 'Color',
  ),
  ServiceData(
    id: 's3',
    businessId: 'b1',
    name: 'Keratin Treatment',
    description: 'Smooth, frizz-free hair for up to 3 months',
    price: 'PKR 4,500',
    duration: '120 min',
    imageUrl: 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=400&h=300&fit=crop',
    category: 'Treatment',
  ),
  ServiceData(
    id: 's4',
    businessId: 'b1',
    name: 'Bridal Styling',
    description: 'Complete bridal hair package with trial',
    price: 'PKR 5,000',
    duration: '180 min',
    imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=400&h=300&fit=crop',
    category: 'Bridal',
  ),
  ServiceData(
    id: 's5',
    businessId: 'b1',
    name: 'Hair Spa',
    description: 'Deep conditioning and nourishment',
    price: 'PKR 3,000',
    duration: '75 min',
    imageUrl: 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=400&h=300&fit=crop',
    category: 'Treatment',
  ),
  ServiceData(
    id: 's6',
    businessId: 'b1',
    name: 'Beard Grooming',
    description: 'Precision beard trim and styling',
    price: 'PKR 1,500',
    duration: '45 min',
    imageUrl: 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400&h=300&fit=crop',
    category: 'Grooming',
  ),

  // ════════════════════════════════════════════════════════════
  // STYLE HUB (b2) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's7',
    businessId: 'b2',
    name: 'Express Cut',
    description: 'Quick trim and style',
    price: 'PKR 1,800',
    duration: '45 min',
    imageUrl: 'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=400&h=300&fit=crop',
    category: 'Hair',
  ),
  ServiceData(
    id: 's8',
    businessId: 'b2',
    name: 'Hair Spa',
    description: 'Deep conditioning treatment',
    price: 'PKR 2,200',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=400&h=300&fit=crop',
    category: 'Treatment',
  ),

  // ════════════════════════════════════════════════════════════
  // GLAMOUR CUTS (b3) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's9',
    businessId: 'b3',
    name: 'Bridal Package',
    description: 'Complete bridal hair and makeup',
    price: 'PKR 8,000',
    duration: '240 min',
    imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=400&h=300&fit=crop',
    category: 'Bridal',
  ),
  ServiceData(
    id: 's10',
    businessId: 'b3',
    name: 'Party Styling',
    description: 'Special occasion hair styling',
    price: 'PKR 3,500',
    duration: '90 min',
    imageUrl: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&h=300&fit=crop',
    category: 'Styling',
  ),

  // ════════════════════════════════════════════════════════════
  // URBAN BARBER (b4) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's11',
    businessId: 'b4',
    name: 'Classic Haircut',
    description: 'Traditional fade and cut',
    price: 'PKR 1,500',
    duration: '30 min',
    imageUrl: 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400&h=300&fit=crop',
    category: 'Hair',
  ),
  ServiceData(
    id: 's12',
    businessId: 'b4',
    name: 'Beard Trim',
    description: 'Precision beard shaping',
    price: 'PKR 1,200',
    duration: '30 min',
    imageUrl: 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400&h=300&fit=crop',
    category: 'Grooming',
  ),

  // ════════════════════════════════════════════════════════════
  // LUXE SALON (b5) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's13',
    businessId: 'b5',
    name: 'Organic Hair Treatment',
    description: 'Natural hair care and conditioning',
    price: 'PKR 2,900',
    duration: '75 min',
    imageUrl: 'https://images.unsplash.com/photo-1633681926022-84c23e8cb2d6?w=400&h=300&fit=crop',
    category: 'Treatment',
  ),
  ServiceData(
    id: 's14',
    businessId: 'b5',
    name: 'Hair Coloring',
    description: 'Premium organic dyes',
    price: 'PKR 3,200',
    duration: '90 min',
    imageUrl: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&h=300&fit=crop',
    category: 'Color',
  ),

  // ════════════════════════════════════════════════════════════
  // QUICK TRIM (b6) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's15',
    businessId: 'b6',
    name: 'Express Haircut',
    description: 'Quick trim services',
    price: 'PKR 900',
    duration: '20 min',
    imageUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400&h=300&fit=crop',
    category: 'Hair',
  ),
  ServiceData(
    id: 's16',
    businessId: 'b6',
    name: 'Kids Haircut',
    description: 'Gentle haircut for children',
    price: 'PKR 700',
    duration: '25 min',
    imageUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400&h=300&fit=crop',
    category: 'Hair',
  ),

  // ════════════════════════════════════════════════════════════
  // CITY DENTAL CARE (b7) - 6 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's17',
    businessId: 'b7',
    name: 'Dental Checkup',
    description: 'Comprehensive oral examination',
    price: 'PKR 3,000',
    duration: '45 min',
    imageUrl: 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=400&h=300&fit=crop',
    category: 'Checkup',
  ),
  ServiceData(
    id: 's18',
    businessId: 'b7',
    name: 'Teeth Whitening',
    description: 'Professional whitening treatment',
    price: 'PKR 5,500',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1606811846408-f84e1424f58d?w=400&h=300&fit=crop',
    category: 'Cosmetic',
  ),
  ServiceData(
    id: 's19',
    businessId: 'b7',
    name: 'Root Canal',
    description: 'Pain-free root canal therapy',
    price: 'PKR 8,000',
    duration: '90 min',
    imageUrl: 'https://images.unsplash.com/photo-1588776814546-daab14f72b0e?w=400&h=300&fit=crop',
    category: 'Treatment',
  ),
  ServiceData(
    id: 's20',
    businessId: 'b7',
    name: 'Dental Cleaning',
    description: 'Professional scaling and polishing',
    price: 'PKR 4,000',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=400&h=300&fit=crop',
    category: 'Cleaning',
  ),
  ServiceData(
    id: 's21',
    businessId: 'b7',
    name: 'Tooth Extraction',
    description: 'Safe and painless extraction',
    price: 'PKR 3,500',
    duration: '45 min',
    imageUrl: 'https://images.unsplash.com/photo-1588776814546-daab14f72b0e?w=400&h=300&fit=crop',
    category: 'Surgery',
  ),
  ServiceData(
    id: 's22',
    businessId: 'b7',
    name: 'Dental Implants',
    description: 'Permanent tooth replacement',
    price: 'PKR 25,000',
    duration: '120 min',
    imageUrl: 'https://images.unsplash.com/photo-1606811846408-f84e1424f58d?w=400&h=300&fit=crop',
    category: 'Implants',
  ),

  // ════════════════════════════════════════════════════════════
  // QUICKHEALTH CLINIC (b8) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's23',
    businessId: 'b8',
    name: 'General Consultation',
    description: 'Walk-in medical consultation',
    price: 'PKR 1,200',
    duration: '30 min',
    imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=400&h=300&fit=crop',
    category: 'Consultation',
  ),
  ServiceData(
    id: 's24',
    businessId: 'b8',
    name: 'Health Checkup',
    description: 'Basic health screening',
    price: 'PKR 2,500',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=400&h=300&fit=crop',
    category: 'Checkup',
  ),

  // ════════════════════════════════════════════════════════════
  // DERMAPLUS (b9) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's25',
    businessId: 'b9',
    name: 'Skin Consultation',
    description: 'Expert skin analysis',
    price: 'PKR 2,000',
    duration: '45 min',
    imageUrl: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=400&h=300&fit=crop',
    category: 'Consultation',
  ),
  ServiceData(
    id: 's26',
    businessId: 'b9',
    name: 'Laser Treatment',
    description: 'Advanced laser skin therapy',
    price: 'PKR 6,000',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=400&h=300&fit=crop',
    category: 'Treatment',
  ),

  // ════════════════════════════════════════════════════════════
  // FAMILY CARE CENTER (b10) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's27',
    businessId: 'b10',
    name: 'Pediatric Checkup',
    description: 'Child health examination',
    price: 'PKR 1,500',
    duration: '40 min',
    imageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=400&h=300&fit=crop',
    category: 'Pediatric',
  ),
  ServiceData(
    id: 's28',
    businessId: 'b10',
    name: 'Vaccination',
    description: 'Immunization services',
    price: 'PKR 2,000',
    duration: '30 min',
    imageUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=400&h=300&fit=crop',
    category: 'Vaccination',
  ),

  // ════════════════════════════════════════════════════════════
  // OPTIVISION EYE CLINIC (b11) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's29',
    businessId: 'b11',
    name: 'Eye Exam',
    description: 'Comprehensive vision test',
    price: 'PKR 2,000',
    duration: '50 min',
    imageUrl: 'https://images.unsplash.com/photo-1579154204601-01588f351e67?w=400&h=300&fit=crop',
    category: 'Examination',
  ),
  ServiceData(
    id: 's30',
    businessId: 'b11',
    name: 'Contact Lens Fitting',
    description: 'Professional lens fitting',
    price: 'PKR 1,500',
    duration: '45 min',
    imageUrl: 'https://images.unsplash.com/photo-1579154204601-01588f351e67?w=400&h=300&fit=crop',
    category: 'Optical',
  ),

  // ════════════════════════════════════════════════════════════
  // MEDIQUICK (b12) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's31',
    businessId: 'b12',
    name: 'Emergency Care',
    description: '24/7 urgent medical care',
    price: 'PKR 1,800',
    duration: '35 min',
    imageUrl: 'https://img.freepik.com/premium-photo/photo-modern-medical-clinic-interior-high-quality-details-8k-full-ultra-hd-ar-169-v-52-job-id-3246525210e5405ab2cb52c0c7d7bfd8_1055425-17160.jpg',
    category: 'Emergency',
  ),
  ServiceData(
    id: 's32',
    businessId: 'b12',
    name: 'Minor Surgery',
    description: 'Outpatient surgical procedures',
    price: 'PKR 5,000',
    duration: '90 min',
    imageUrl: 'https://img.freepik.com/premium-photo/photo-modern-medical-clinic-interior-high-quality-details-8k-full-ultra-hd-ar-169-v-52-job-id-3246525210e5405ab2cb52c0c7d7bfd8_1055425-17160.jpg',
    category: 'Surgery',
  ),

  // ════════════════════════════════════════════════════════════
  // IRONPUMP GYM (b13) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's33',
    businessId: 'b13',
    name: 'Day Pass',
    description: 'Full gym access for one day',
    price: 'PKR 1,500',
    duration: '120 min',
    imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&h=300&fit=crop',
    category: 'Access',
  ),
  ServiceData(
    id: 's34',
    businessId: 'b13',
    name: 'Personal Training',
    description: 'One-on-one fitness coaching',
    price: 'PKR 3,000',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop',
    category: 'Training',
  ),

  // ════════════════════════════════════════════════════════════
  // YOGAFLOW STUDIO (b14) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's35',
    businessId: 'b14',
    name: 'Yoga Class',
    description: 'Meditation and flexibility',
    price: 'PKR 2,200',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&h=300&fit=crop',
    category: 'Yoga',
  ),
  ServiceData(
    id: 's36',
    businessId: 'b14',
    name: 'Private Session',
    description: 'Personalized yoga instruction',
    price: 'PKR 3,500',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&h=300&fit=crop',
    category: 'Private',
  ),

  // ════════════════════════════════════════════════════════════
  // CROSSFIT ZONE (b15) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's37',
    businessId: 'b15',
    name: 'CrossFit Class',
    description: 'High intensity training',
    price: 'PKR 3,500',
    duration: '90 min',
    imageUrl: 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=400&h=300&fit=crop',
    category: 'CrossFit',
  ),
  ServiceData(
    id: 's38',
    businessId: 'b15',
    name: 'Nutrition Plan',
    description: 'Custom diet planning',
    price: 'PKR 2,500',
    duration: '45 min',
    imageUrl: 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=400&h=300&fit=crop',
    category: 'Nutrition',
  ),

  // ════════════════════════════════════════════════════════════
  // AQUAFIT POOL (b16) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's39',
    businessId: 'b16',
    name: 'Swimming Session',
    description: 'Pool access and swimming',
    price: 'PKR 1,800',
    duration: '45 min',
    imageUrl: 'https://tse1.mm.bing.net/th/id/OIP.NENjeq3PVDQySJHeSOPnTwHaEK?rs=1&pid=ImgDetMain&o=7&rm=3',
    category: 'Swimming',
  ),
  ServiceData(
    id: 's40',
    businessId: 'b16',
    name: 'Aqua Aerobics',
    description: 'Water-based fitness class',
    price: 'PKR 2,000',
    duration: '60 min',
    imageUrl: 'https://tse1.mm.bing.net/th/id/OIP.NENjeq3PVDQySJHeSOPnTwHaEK?rs=1&pid=ImgDetMain&o=7&rm=3',
    category: 'Aerobics',
  ),

  // ════════════════════════════════════════════════════════════
  // PILATES CORE (b17) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's41',
    businessId: 'b17',
    name: 'Pilates Class',
    description: 'Core strengthening exercises',
    price: 'PKR 2,800',
    duration: '50 min',
    imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&h=300&fit=crop',
    category: 'Pilates',
  ),
  ServiceData(
    id: 's42',
    businessId: 'b17',
    name: 'Reformer Session',
    description: 'Equipment-based pilates',
    price: 'PKR 3,500',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&h=300&fit=crop',
    category: 'Reformer',
  ),

  // ════════════════════════════════════════════════════════════
  // BOXFIT ARENA (b18) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's43',
    businessId: 'b18',
    name: 'Boxing Class',
    description: 'Boxing and conditioning',
    price: 'PKR 2,500',
    duration: '75 min',
    imageUrl: 'https://tse4.mm.bing.net/th/id/OIP.VzciWzID07AbiKZj1CeAXwHaG8?rs=1&pid=ImgDetMain&o=7&rm=3',
    category: 'Boxing',
  ),
  ServiceData(
    id: 's44',
    businessId: 'b18',
    name: 'Bag Work',
    description: 'Heavy bag training',
    price: 'PKR 2,000',
    duration: '60 min',
    imageUrl: 'https://tse4.mm.bing.net/th/id/OIP.VzciWzID07AbiKZj1CeAXwHaG8?rs=1&pid=ImgDetMain&o=7&rm=3',
    category: 'Training',
  ),

  // ════════════════════════════════════════════════════════════
  // GLOW SKIN CLINIC (b19) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's45',
    businessId: 'b19',
    name: 'Facial Treatment',
    description: 'Deep cleansing and hydration',
    price: 'PKR 3,200',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=400&h=300&fit=crop',
    category: 'Facial',
  ),
  ServiceData(
    id: 's46',
    businessId: 'b19',
    name: 'Chemical Peel',
    description: 'Skin rejuvenation treatment',
    price: 'PKR 4,500',
    duration: '45 min',
    imageUrl: 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=400&h=300&fit=crop',
    category: 'Treatment',
  ),

  // ════════════════════════════════════════════════════════════
  // NAIL ART STUDIO (b20) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's47',
    businessId: 'b20',
    name: 'Manicure',
    description: 'Hand and nail care',
    price: 'PKR 1,500',
    duration: '40 min',
    imageUrl: 'https://images.unsplash.com/photo-1604654894610-df63bc536371?w=400&h=300&fit=crop',
    category: 'Nails',
  ),
  ServiceData(
    id: 's48',
    businessId: 'b20',
    name: 'Pedicure',
    description: 'Foot and toenail care',
    price: 'PKR 1,800',
    duration: '50 min',
    imageUrl: 'https://images.unsplash.com/photo-1604654894610-df63bc536371?w=400&h=300&fit=crop',
    category: 'Nails',
  ),

  // ════════════════════════════════════════════════════════════
  // LASH & BROW BAR (b21) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's49',
    businessId: 'b21',
    name: 'Eyelash Extensions',
    description: 'Full lash extension services',
    price: 'PKR 2,800',
    duration: '90 min',
    imageUrl: 'https://tse1.mm.bing.net/th/id/OIP.GuTub-8KSmla-Sy4vEog5QHaHa?rs=1&pid=ImgDetMain&o=7&rm=3',
    category: 'Lashes',
  ),
  ServiceData(
    id: 's50',
    businessId: 'b21',
    name: 'Brow Tinting',
    description: 'Eyebrow shaping and tinting',
    price: 'PKR 1,500',
    duration: '45 min',
    imageUrl: 'https://tse1.mm.bing.net/th/id/OIP.GuTub-8KSmla-Sy4vEog5QHaHa?rs=1&pid=ImgDetMain&o=7&rm=3',
    category: 'Brows',
  ),

  // ════════════════════════════════════════════════════════════
  // AROMA THERAPY (b22) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's51',
    businessId: 'b22',
    name: 'Aromatherapy Massage',
    description: 'Relaxation with essential oils',
    price: 'PKR 2,200',
    duration: '75 min',
    imageUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=400&h=300&fit=crop',
    category: 'Massage',
  ),
  ServiceData(
    id: 's52',
    businessId: 'b22',
    name: 'Hot Stone Therapy',
    description: 'Heated stone massage',
    price: 'PKR 3,000',
    duration: '90 min',
    imageUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=400&h=300&fit=crop',
    category: 'Massage',
  ),

  // ════════════════════════════════════════════════════════════
  // MAKEUP BY SARA (b23) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's53',
    businessId: 'b23',
    name: 'Bridal Makeup',
    description: 'Complete bridal makeup package',
    price: 'PKR 5,000',
    duration: '120 min',
    imageUrl: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&h=300&fit=crop',
    category: 'Bridal',
  ),
  ServiceData(
    id: 's54',
    businessId: 'b23',
    name: 'Party Makeup',
    description: 'Special occasion makeup',
    price: 'PKR 3,000',
    duration: '90 min',
    imageUrl: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&h=300&fit=crop',
    category: 'Makeup',
  ),

  // ════════════════════════════════════════════════════════════
  // QUICK GLAM (b24) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's55',
    businessId: 'b24',
    name: 'Express Makeup',
    description: 'Quick beauty fixes',
    price: 'PKR 1,200',
    duration: '30 min',
    imageUrl: 'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=400&h=300&fit=crop',
    category: 'Makeup',
  ),
  ServiceData(
    id: 's56',
    businessId: 'b24',
    name: 'Hair Styling',
    description: 'Quick hair styling',
    price: 'PKR 1,500',
    duration: '40 min',
    imageUrl: 'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=400&h=300&fit=crop',
    category: 'Hair',
  ),

  // ════════════════════════════════════════════════════════════
  // MINDBALANCE THERAPY (b25) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's57',
    businessId: 'b25',
    name: 'Counseling Session',
    description: 'Mental health counseling',
    price: 'PKR 3,500',
    duration: '60 min',
    imageUrl: 'https://th.bing.com/th?id=OIF.zDStBSTVSmh%2bYoZp0Gu9kQ&rs=1&pid=ImgDetMain&o=7&rm=3',
    category: 'Therapy',
  ),
  ServiceData(
    id: 's58',
    businessId: 'b25',
    name: 'Stress Management',
    description: 'Stress relief techniques',
    price: 'PKR 3,000',
    duration: '60 min',
    imageUrl: 'https://th.bing.com/th?id=OIF.zDStBSTVSmh%2bYoZp0Gu9kQ&rs=1&pid=ImgDetMain&o=7&rm=3',
    category: 'Therapy',
  ),

  // ════════════════════════════════════════════════════════════
  // NUTRILIFE CLINIC (b26) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's59',
    businessId: 'b26',
    name: 'Nutrition Consultation',
    description: 'Diet and nutrition planning',
    price: 'PKR 2,000',
    duration: '45 min',
    imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400&h=300&fit=crop',
    category: 'Nutrition',
  ),
  ServiceData(
    id: 's60',
    businessId: 'b26',
    name: 'Weight Management',
    description: 'Weight loss program',
    price: 'PKR 3,500',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400&h=300&fit=crop',
    category: 'Nutrition',
  ),

  // ════════════════════════════════════════════════════════════
  // SLEEPWELL CENTER (b27) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's61',
    businessId: 'b27',
    name: 'Sleep Consultation',
    description: 'Insomnia and sleep therapy',
    price: 'PKR 2,800',
    duration: '50 min',
    imageUrl: 'https://tse4.mm.bing.net/th/id/OIP.ayycboAsnYdeFJ6cF0IMxAHaE8?rs=1&pid=ImgDetMain&o=7&rm=3',
    category: 'Therapy',
  ),
  ServiceData(
    id: 's62',
    businessId: 'b27',
    name: 'Sleep Study',
    description: 'Comprehensive sleep analysis',
    price: 'PKR 5,000',
    duration: '120 min',
    imageUrl: 'https://tse4.mm.bing.net/th/id/OIP.ayycboAsnYdeFJ6cF0IMxAHaE8?rs=1&pid=ImgDetMain&o=7&rm=3',
    category: 'Diagnosis',
  ),

  // ════════════════════════════════════════════════════════════
  // DETOX HUB (b28) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's63',
    businessId: 'b28',
    name: 'Body Detox',
    description: 'Cleansing and rejuvenation',
    price: 'PKR 3,200',
    duration: '90 min',
    imageUrl: 'https://images.unsplash.com/photo-1545205597-3d9d02c29597?w=400&h=300&fit=crop',
    category: 'Detox',
  ),
  ServiceData(
    id: 's64',
    businessId: 'b28',
    name: 'Colon Cleanse',
    description: 'Digestive system cleansing',
    price: 'PKR 4,000',
    duration: '90 min',
    imageUrl: 'https://images.unsplash.com/photo-1545205597-3d9d02c29597?w=400&h=300&fit=crop',
    category: 'Detox',
  ),

  // ════════════════════════════════════════════════════════════
  // VITALITY CLINIC (b29) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's65',
    businessId: 'b29',
    name: 'Health Screening',
    description: 'Holistic health checkup',
    price: 'PKR 2,500',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=400&h=300&fit=crop',
    category: 'Checkup',
  ),
  ServiceData(
    id: 's66',
    businessId: 'b29',
    name: 'Wellness Consultation',
    description: 'Overall wellness planning',
    price: 'PKR 3,000',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=400&h=300&fit=crop',
    category: 'Consultation',
  ),

  // ════════════════════════════════════════════════════════════
  // RECOVERY ZONE (b30) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's67',
    businessId: 'b30',
    name: 'Post-Op Rehab',
    description: 'Post-surgery rehabilitation',
    price: 'PKR 4,000',
    duration: '75 min',
    imageUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=400&h=300&fit=crop',
    category: 'Rehab',
  ),
  ServiceData(
    id: 's68',
    businessId: 'b30',
    name: 'Physical Therapy',
    description: 'Injury recovery therapy',
    price: 'PKR 3,500',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=400&h=300&fit=crop',
    category: 'Therapy',
  ),

  // ════════════════════════════════════════════════════════════
  // AUTOFIX GARAGE (b31) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's69',
    businessId: 'b31',
    name: 'Full Service',
    description: 'Complete car servicing',
    price: 'PKR 5,000',
    duration: '120 min',
    imageUrl: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=400&h=300&fit=crop',
    category: 'Service',
  ),
  ServiceData(
    id: 's70',
    businessId: 'b31',
    name: 'Car Detailing',
    description: 'Interior and exterior detailing',
    price: 'PKR 3,500',
    duration: '180 min',
    imageUrl: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=400&h=300&fit=crop',
    category: 'Detailing',
  ),

  // ════════════════════════════════════════════════════════════
  // CARCARE PRO (b32) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's71',
    businessId: 'b32',
    name: 'Denting & Painting',
    description: 'Body repair and painting',
    price: 'PKR 6,500',
    duration: '180 min',
    imageUrl: 'https://th.bing.com/th?id=OIF.fSfi%2bRwdFPaAJM4A2Rd%2fMQ&rs=1&pid=ImgDetMain&o=7&rm=3',
    category: 'Repair',
  ),
  ServiceData(
    id: 's72',
    businessId: 'b32',
    name: 'Engine Repair',
    description: 'Engine diagnostics and repair',
    price: 'PKR 8,000',
    duration: '240 min',
    imageUrl: 'https://th.bing.com/th?id=OIF.fSfi%2bRwdFPaAJM4A2Rd%2fMQ&rs=1&pid=ImgDetMain&o=7&rm=3',
    category: 'Repair',
  ),

  // ════════════════════════════════════════════════════════════
  // TAXPRO CONSULTANTS (b33) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's73',
    businessId: 'b33',
    name: 'Tax Filing',
    description: 'Income tax filing services',
    price: 'PKR 3,000',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=400&h=300&fit=crop',
    category: 'Tax',
  ),
  ServiceData(
    id: 's74',
    businessId: 'b33',
    name: 'Audit Support',
    description: 'Tax audit assistance',
    price: 'PKR 5,000',
    duration: '90 min',
    imageUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=400&h=300&fit=crop',
    category: 'Audit',
  ),

  // ════════════════════════════════════════════════════════════
  // FINANCE HUB (b34) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's75',
    businessId: 'b34',
    name: 'Business Tax Planning',
    description: 'Corporate tax strategy',
    price: 'PKR 4,000',
    duration: '90 min',
    imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=400&h=300&fit=crop',
    category: 'Tax',
  ),
  ServiceData(
    id: 's76',
    businessId: 'b34',
    name: 'Financial Consultation',
    description: 'Financial planning advice',
    price: 'PKR 3,500',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=400&h=300&fit=crop',
    category: 'Consultation',
  ),

  // ════════════════════════════════════════════════════════════
  // ZEN SPA RETREAT (b35) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's77',
    businessId: 'b35',
    name: 'Hot Stone Massage',
    description: 'Hot stone & Swedish massage',
    price: 'PKR 4,500',
    duration: '90 min',
    imageUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=400&h=300&fit=crop',
    category: 'Massage',
  ),
  ServiceData(
    id: 's78',
    businessId: 'b35',
    name: 'Couples Spa',
    description: 'Couples massage package',
    price: 'PKR 7,000',
    duration: '120 min',
    imageUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=400&h=300&fit=crop',
    category: 'Spa',
  ),

  // ════════════════════════════════════════════════════════════
  // TRANQUIL MASSAGE (b36) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's79',
    businessId: 'b36',
    name: 'Deep Tissue Massage',
    description: 'Therapeutic deep tissue',
    price: 'PKR 3,800',
    duration: '75 min',
    imageUrl: 'https://th.bing.com/th/id/OIP.8GjBiaQqSfrV72mw1ghpuQHaEJ?w=303&h=180&c=7&r=0&o=7&dpr=1.1&pid=1.7&rm=3',
    category: 'Massage',
  ),
  ServiceData(
    id: 's80',
    businessId: 'b36',
    name: 'Thai Massage',
    description: 'Traditional Thai massage',
    price: 'PKR 3,500',
    duration: '90 min',
    imageUrl: 'https://th.bing.com/th/id/OIP.8GjBiaQqSfrV72mw1ghpuQHaEJ?w=303&h=180&c=7&r=0&o=7&dpr=1.1&pid=1.7&rm=3',
    category: 'Massage',
  ),

  // ════════════════════════════════════════════════════════════
  // BISTRO 52 (b37) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's81',
    businessId: 'b37',
    name: 'Fine Dining',
    description: 'Premium dining experience',
    price: 'PKR 2,800',
    duration: '90 min',
    imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=300&fit=crop',
    category: 'Dining',
  ),
  ServiceData(
    id: 's82',
    businessId: 'b37',
    name: 'Private Dining',
    description: 'Private room dining',
    price: 'PKR 4,500',
    duration: '120 min',
    imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=300&fit=crop',
    category: 'Dining',
  ),

  // ════════════════════════════════════════════════════════════
  // SPICE GARDEN (b38) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's83',
    businessId: 'b38',
    name: 'Buffet Dinner',
    description: 'Pakistani & Continental buffet',
    price: 'PKR 2,200',
    duration: '75 min',
    imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
    category: 'Dining',
  ),
  ServiceData(
    id: 's84',
    businessId: 'b38',
    name: 'Catering Service',
    description: 'Event catering',
    price: 'PKR 5,000',
    duration: '180 min',
    imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
    category: 'Catering',
  ),

  // ════════════════════════════════════════════════════════════
  // DREAMEVENTS CO (b39) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's85',
    businessId: 'b39',
    name: 'Corporate Event',
    description: 'Corporate event planning',
    price: 'PKR 8,000',
    duration: '240 min',
    imageUrl: 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=400&h=300&fit=crop',
    category: 'Events',
  ),
  ServiceData(
    id: 's86',
    businessId: 'b39',
    name: 'Private Party',
    description: 'Private party planning',
    price: 'PKR 6,000',
    duration: '180 min',
    imageUrl: 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=400&h=300&fit=crop',
    category: 'Events',
  ),

  // ════════════════════════════════════════════════════════════
  // PERFECT OCCASIONS (b40) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's87',
    businessId: 'b40',
    name: 'Birthday Party',
    description: 'Birthday celebration planning',
    price: 'PKR 6,500',
    duration: '180 min',
    imageUrl: 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=400&h=300&fit=crop',
    category: 'Events',
  ),
  ServiceData(
    id: 's88',
    businessId: 'b40',
    name: 'Anniversary Event',
    description: 'Anniversary celebration',
    price: 'PKR 7,000',
    duration: '240 min',
    imageUrl: 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=400&h=300&fit=crop',
    category: 'Events',
  ),

  // ════════════════════════════════════════════════════════════
  // WEDDING BLISS (b41) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's89',
    businessId: 'b41',
    name: 'Wedding Planning',
    description: 'Full wedding planning & decor',
    price: 'PKR 15,000',
    duration: '480 min',
    imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=400&h=300&fit=crop',
    category: 'Wedding',
  ),
  ServiceData(
    id: 's90',
    businessId: 'b41',
    name: 'Mehndi Setup',
    description: 'Mehndi ceremony decoration',
    price: 'PKR 10,000',
    duration: '360 min',
    imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=400&h=300&fit=crop',
    category: 'Wedding',
  ),

  // ════════════════════════════════════════════════════════════
  // ROYAL WEDDINGS (b42) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's91',
    businessId: 'b42',
    name: 'Walima Setup',
    description: 'Walima reception decoration',
    price: 'PKR 12,000',
    duration: '360 min',
    imageUrl: 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=400&h=300&fit=crop',
    category: 'Wedding',
  ),
  ServiceData(
    id: 's92',
    businessId: 'b42',
    name: 'Bridal Entrance',
    description: 'Bridal entrance decoration',
    price: 'PKR 8,000',
    duration: '240 min',
    imageUrl: 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=400&h=300&fit=crop',
    category: 'Wedding',
  ),

  // ════════════════════════════════════════════════════════════
  // QUICKSERVE HUB (b43) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's93',
    businessId: 'b43',
    name: 'General Services',
    description: 'Various general services',
    price: 'PKR 1,000',
    duration: '30 min',
    imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=400&h=300&fit=crop',
    category: 'General',
  ),
  ServiceData(
    id: 's94',
    businessId: 'b43',
    name: 'Errand Service',
    description: 'Personal errand running',
    price: 'PKR 1,500',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=400&h=300&fit=crop',
    category: 'General',
  ),

  // ════════════════════════════════════════════════════════════
  // HOMEFIX PRO (b44) - 2 Services
  // ════════════════════════════════════════════════════════════
  ServiceData(
    id: 's95',
    businessId: 'b44',
    name: 'Plumbing Service',
    description: 'Professional plumbing repair',
    price: 'PKR 1,500',
    duration: '60 min',
    imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&h=300&fit=crop',
    category: 'Plumbing',
  ),
  ServiceData(
    id: 's96',
    businessId: 'b44',
    name: 'Electrical Work',
    description: 'Electrical repair and installation',
    price: 'PKR 2,000',
    duration: '90 min',
    imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&h=300&fit=crop',
    category: 'Electrical',
  ),
];