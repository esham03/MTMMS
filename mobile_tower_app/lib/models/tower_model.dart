// ============================================================
// OFFICIAL DATA MODELS FOR MTMMS (GOVERNMENT OF GOA)
// ============================================================

class TowerModel {
  final String id; // e.g. "TWR-0001"
  final String dbId;
  final String owner;
  final String district;
  final String constituency;
  final String taluka;
  final String area;
  final String land; // "Government" or "Private"
  final String height;
  final String width;
  final String frequency;
  final String operator;
  final String operatorsCount;
  final String status; // "active" or "inactive"
  final String rent; // "Paid", "Due", "Overdue"
  final String monthlyRent;
  final String yearlyRent;
  final String rentDueDate;
  final String address;
  final String remarks;
  final Map<String, dynamic>? raw;

  TowerModel({
    required this.id,
    required this.dbId,
    required this.owner,
    required this.district,
    required this.constituency,
    required this.taluka,
    required this.area,
    required this.land,
    required this.height,
    required this.width,
    required this.frequency,
    required this.operator,
    required this.operatorsCount,
    required this.status,
    required this.rent,
    required this.monthlyRent,
    required this.yearlyRent,
    required this.rentDueDate,
    required this.address,
    required this.remarks,
    this.raw,
  });

  factory TowerModel.fromMap(Map<String, dynamic> map) {
    return TowerModel(
      id: map['id']?.toString() ?? '',
      dbId: map['dbId']?.toString() ?? '',
      owner: map['owner']?.toString() ?? 'Government',
      district: map['district']?.toString() ?? 'North Goa',
      constituency: map['constituency']?.toString() ?? 'Panaji',
      taluka: map['taluka']?.toString() ?? 'Tiswadi',
      area: map['area']?.toString() ?? 'Panaji',
      land: map['land']?.toString() ?? 'Government',
      height: map['height']?.toString() ?? '30m',
      width: map['width']?.toString() ?? '2.5m',
      frequency: map['frequency']?.toString() ?? '1800 MHz',
      operator: map['operator']?.toString() ?? 'None',
      operatorsCount: map['operators']?.toString() ?? '0 operators',
      status: map['status']?.toString() ?? 'active',
      rent: map['rent']?.toString() ?? 'Paid',
      monthlyRent: map['monthly_rent']?.toString() ?? map['monthlyRent']?.toString() ?? '0',
      yearlyRent: map['yearly_rent']?.toString() ?? map['yearlyRent']?.toString() ?? '0',
      rentDueDate: map['rent_due_date']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      remarks: map['remarks']?.toString() ?? '',
      raw: map['_raw'] is Map<String, dynamic> ? map['_raw'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dbId': dbId,
      'owner': owner,
      'district': district,
      'constituency': constituency,
      'taluka': taluka,
      'area': area,
      'land': land,
      'height': height,
      'width': width,
      'frequency': frequency,
      'operator': operator,
      'operators': operatorsCount,
      'status': status,
      'rent': rent,
      'monthly_rent': monthlyRent,
      'yearly_rent': yearlyRent,
      'rent_due_date': rentDueDate,
      'address': address,
      'remarks': remarks,
    };
  }
}

class OperatorModel {
  final String id;
  final String name;
  final String shortName;
  final String contact;
  final String email;
  final int towers;
  final String status;
  final String frequency;
  final String type;
  final String license;
  final String since;
  final Map<String, dynamic>? raw;

  OperatorModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.contact,
    required this.email,
    required this.towers,
    required this.status,
    required this.frequency,
    required this.type,
    required this.license,
    required this.since,
    this.raw,
  });

  factory OperatorModel.fromMap(Map<String, dynamic> map) {
    return OperatorModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      shortName: map['shortName']?.toString() ?? map['short_name']?.toString() ?? '',
      contact: map['contact']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      towers: (map['towers'] as num?)?.toInt() ?? 0,
      status: map['status']?.toString() ?? 'Active',
      frequency: map['frequency']?.toString() ?? 'N/A',
      type: map['type']?.toString() ?? 'Telecom Operator',
      license: map['license']?.toString() ?? 'N/A',
      since: map['since']?.toString() ?? '',
      raw: map['_raw'] is Map<String, dynamic> ? map['_raw'] : null,
    );
  }
}

class OwnerModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final int towersCount;
  final List<dynamic> towers;

  OwnerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.towersCount,
    required this.towers,
  });

  factory OwnerModel.fromMap(Map<String, dynamic> map) {
    final towersList = map['towers'] is List ? (map['towers'] as List) : [];
    return OwnerModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '—',
      email: map['email']?.toString() ?? '—',
      address: map['address']?.toString() ?? 'Goa',
      towersCount: (map['towers_count'] as num?)?.toInt() ?? towersList.length,
      towers: towersList,
    );
  }
}

class RentPaymentModel {
  final String id;
  final String receiptNo;
  final String towerId;
  final String owner;
  final String district;
  final String operator;
  final String amount;
  final int rawAmount;
  final String date;
  final String period;
  final String mode;
  final String status;
  final String remarks;
  final Map<String, dynamic>? raw;

  RentPaymentModel({
    required this.id,
    required this.receiptNo,
    required this.towerId,
    required this.owner,
    required this.district,
    required this.operator,
    required this.amount,
    required this.rawAmount,
    required this.date,
    required this.period,
    required this.mode,
    required this.status,
    required this.remarks,
    this.raw,
  });

  factory RentPaymentModel.fromMap(Map<String, dynamic> map) {
    return RentPaymentModel(
      id: map['id']?.toString() ?? '',
      receiptNo: map['receiptNo']?.toString() ?? map['payment_reference']?.toString() ?? 'RCP-000',
      towerId: map['towerId']?.toString() ?? map['tower_id']?.toString() ?? 'TWR-0001',
      owner: map['owner']?.toString() ?? 'Government of Goa',
      district: map['district']?.toString() ?? 'North Goa',
      operator: map['operator']?.toString() ?? 'Airtel',
      amount: map['amount']?.toString() ?? '₹0',
      rawAmount: (map['rawAmount'] as num?)?.toInt() ?? 0,
      date: map['date']?.toString() ?? map['payment_date']?.toString() ?? '',
      period: map['period']?.toString() ?? '',
      mode: map['mode']?.toString() ?? map['payment_method']?.toString() ?? 'NEFT / RTGS',
      status: map['status']?.toString() ?? 'Paid',
      remarks: map['remarks']?.toString() ?? '',
      raw: map['_raw'] is Map<String, dynamic> ? map['_raw'] : null,
    );
  }
}
