import 'package:cloud_firestore/cloud_firestore.dart';

enum DonationStatus {
  success('success', 'Success'),
  failed('failed', 'Failed');

  final String value;
  final String label;
  const DonationStatus(this.value, this.label);

  static DonationStatus fromString(String? raw) {
    return DonationStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => DonationStatus.success,
    );
  }
}

/// Domain model for `projects/{projectId}/donations/{donationId}`.
class Donation {
  final String id;
  final String projectId;
  final String donorId;
  final String donorName;
  final bool isAnonymous;
  final num amount;
  final String paymentGatewayRef;
  final String? receiptUrl;
  final String? panOrTaxId;
  final DateTime timestamp;
  final DonationStatus status;

  const Donation({
    required this.id,
    required this.projectId,
    required this.donorId,
    required this.donorName,
    required this.isAnonymous,
    required this.amount,
    required this.paymentGatewayRef,
    this.receiptUrl,
    this.panOrTaxId,
    required this.timestamp,
    required this.status,
  });

  String get publicDonorName => isAnonymous ? 'Anonymous Well-Wisher' : donorName;

  factory Donation.fromJson(
    Map<String, dynamic> json, {
    String? id,
    String? projectId,
  }) {
    return Donation(
      id: id ?? (json['id'] as String? ?? ''),
      projectId: projectId ?? (json['projectId'] as String? ?? ''),
      donorId: json['donorId'] as String? ?? '',
      donorName: json['donorName'] as String? ?? 'Supporter',
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      amount: json['amount'] as num? ?? 0,
      paymentGatewayRef: json['paymentGatewayRef'] as String? ?? '',
      receiptUrl: json['receiptUrl'] as String?,
      panOrTaxId: json['pan_or_tax_id'] as String?,
      timestamp: _parseDateTime(json['timestamp']),
      status: DonationStatus.fromString(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'donorId': donorId,
      'donorName': donorName,
      'isAnonymous': isAnonymous,
      'amount': amount,
      'paymentGatewayRef': paymentGatewayRef,
      'receiptUrl': receiptUrl,
      'pan_or_tax_id': panOrTaxId,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.value,
    };
  }

  Donation copyWith({
    String? id,
    String? projectId,
    String? donorId,
    String? donorName,
    bool? isAnonymous,
    num? amount,
    String? paymentGatewayRef,
    String? receiptUrl,
    String? panOrTaxId,
    DateTime? timestamp,
    DonationStatus? status,
  }) {
    return Donation(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      amount: amount ?? this.amount,
      paymentGatewayRef: paymentGatewayRef ?? this.paymentGatewayRef,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      panOrTaxId: panOrTaxId ?? this.panOrTaxId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  static DateTime _parseDateTime(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    if (raw is DateTime) return raw;
    return DateTime.now();
  }
}
