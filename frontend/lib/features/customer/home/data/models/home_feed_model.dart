// lib/features/customer/home/data/models/home_feed_model.dart
import '../../domain/entities/home_feed_entity.dart';

class CategoryModel {
  final int id;
  final String name;
  final String iconName;

  const CategoryModel({required this.id, required this.name, required this.iconName});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'],
        name: json['name'],
        iconName: json['icon_name'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon_name': iconName,
      };

  CategoryEntity toEntity() => CategoryEntity(id: id, name: name, iconName: iconName);
}

class PromotionModel {
  final int id;
  final String title;
  final String bannerImageUrl;
  final String promoDescription;
  final String buttonText;

  const PromotionModel({
    required this.id,
    required this.title,
    required this.bannerImageUrl,
    required this.promoDescription,
    required this.buttonText,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) => PromotionModel(
        id: json['id'],
        title: json['title'],
        bannerImageUrl: json['banner_image_url'],
        promoDescription: json['promo_description'],
        buttonText: json['button_text'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'banner_image_url': bannerImageUrl,
        'promo_description': promoDescription,
        'button_text': buttonText,
      };

  PromotionEntity toEntity() => PromotionEntity(
        id: id,
        title: title,
        bannerImageUrl: bannerImageUrl,
        promoDescription: promoDescription,
        buttonText: buttonText,
      );
}

class FixedGigModel {
  final int id;
  final String name;
  final String basePrice;
  final String parentCategory;
  final String imageUrl;

  const FixedGigModel({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.parentCategory,
    required this.imageUrl,
  });

  factory FixedGigModel.fromJson(Map<String, dynamic> json) => FixedGigModel(
        id: json['id'],
        name: json['name'],
        basePrice: json['base_price'].toString(),
        parentCategory: json['parent_category'],
        imageUrl: json['image_url'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'base_price': basePrice,
        'parent_category': parentCategory,
        'image_url': imageUrl,
      };

  FixedGigEntity toEntity() => FixedGigEntity(
        id: id,
        name: name,
        basePrice: basePrice,
        parentCategory: parentCategory,
        imageUrl: imageUrl,
      );
}

class TechnicianFeedModel {
  final int id;
  final String fullName;
  final String primaryCategory;
  final String city;
  final String profilePicture;
  final double ratingAverage;
  final int reviewCount;
  final double? distanceKm;
  final double bayesianScore;
  final bool isActive;

  const TechnicianFeedModel({
    required this.id,
    required this.fullName,
    required this.primaryCategory,
    required this.city,
    required this.profilePicture,
    required this.ratingAverage,
    required this.reviewCount,
    this.distanceKm,
    required this.bayesianScore,
    required this.isActive,
  });

  factory TechnicianFeedModel.fromJson(Map<String, dynamic> json) => TechnicianFeedModel(
        id: json['id'],
        fullName: json['full_name'],
        primaryCategory: json['primary_category'],
        city: json['city'],
        profilePicture: json['profile_picture'],
        ratingAverage: _parseDouble(json['rating_average']),
        reviewCount: json['review_count'],
        distanceKm: json['distance_km'] != null ? _parseDouble(json['distance_km']) : null,
        bayesianScore: _parseDouble(json['bayesian_score']),
        isActive: json['is_active'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'primary_category': primaryCategory,
        'city': city,
        'profile_picture': profilePicture,
        'rating_average': ratingAverage,
        'review_count': reviewCount,
        'distance_km': distanceKm,
        'bayesian_score': bayesianScore,
        'is_active': isActive,
      };

  TechnicianFeedEntity toEntity() => TechnicianFeedEntity(
        id: id,
        fullName: fullName,
        primaryCategory: primaryCategory,
        city: city,
        profilePicture: profilePicture,
        ratingAverage: ratingAverage,
        reviewCount: reviewCount,
        distanceKm: distanceKm,
        bayesianScore: bayesianScore,
        isActive: isActive,
      );
}

class HomeFeedModel {
  final List<CategoryModel> categories;
  final List<PromotionModel> promotions;
  final List<FixedGigModel> fixedGigs;
  final List<TechnicianFeedModel> topTechnicians;

  const HomeFeedModel({
    required this.categories,
    required this.promotions,
    required this.fixedGigs,
    required this.topTechnicians,
  });

  factory HomeFeedModel.fromJson(Map<String, dynamic> json) => HomeFeedModel(
        categories: (json['categories'] as List).map((i) => CategoryModel.fromJson(i)).toList(),
        promotions: (json['promotions'] as List).map((i) => PromotionModel.fromJson(i)).toList(),
        fixedGigs: (json['fixed_gigs'] as List).map((i) => FixedGigModel.fromJson(i)).toList(),
        topTechnicians: (json['top_technicians'] as List).map((i) => TechnicianFeedModel.fromJson(i)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'categories': categories.map((c) => c.toJson()).toList(),
        'promotions': promotions.map((p) => p.toJson()).toList(),
        'fixed_gigs': fixedGigs.map((f) => f.toJson()).toList(),
        'top_technicians': topTechnicians.map((t) => t.toJson()).toList(),
      };

  HomeFeedEntity toEntity() => HomeFeedEntity(
        categories: categories.map((m) => m.toEntity()).toList(),
        promotions: promotions.map((m) => m.toEntity()).toList(),
        fixedGigs: fixedGigs.map((m) => m.toEntity()).toList(),
        topTechnicians: topTechnicians.map((m) => m.toEntity()).toList(),
      );
}

double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

