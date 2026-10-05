class Tower {
  final String id;
  final String owner;
  final String district;
  final String constituency;
  final String taluka;
  final String area;
  final String land;
  final String height;
  final String width;
  final String frequency;
  final int operators;
  final String rent;
  final String monthlyRent;
  final String yearlyRent;

  Tower({
    required this.id,
    required this.owner,
    required this.district,
    required this.constituency,
    required this.taluka,
    required this.area,
    required this.land,
    required this.height,
    required this.width,
    required this.frequency,
    required this.operators,
    required this.rent,
    required this.monthlyRent,
    required this.yearlyRent,
  });

  // Convert Tower object to JSON.
  // We will use this when sending tower data to Laravel/MySQL.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner': owner,
      'district': district,
      'constituency': constituency,
      'taluka': taluka,
      'area': area,
      'land': land,
      'height': height,
      'width': width,
      'frequency': frequency,
      'operators': operators,
      'rent': rent,
      'monthlyRent': monthlyRent,
      'yearlyRent': yearlyRent,
    };
  }

  // Create Tower object from JSON.
  // We will use this when receiving tower data from Laravel.
  factory Tower.fromJson(Map<String, dynamic> json) {
    return Tower(
      id: json['id']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      constituency: json['constituency']?.toString() ?? '',
      taluka: json['taluka']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      land: json['land']?.toString() ?? '',
      height: json['height']?.toString() ?? '',
      width: json['width']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      operators: int.tryParse(json['operators']?.toString() ?? '0') ?? 0,
      rent: json['rent']?.toString() ?? '',
      monthlyRent: json['monthlyRent']?.toString() ?? '',
      yearlyRent: json['yearlyRent']?.toString() ?? '',
    );
  }
}
