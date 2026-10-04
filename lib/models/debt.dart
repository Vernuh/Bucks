import '../utils/formatters.dart';

/// Which direction the money flows.
enum DebtType {
  iOwe('i_owe'),
  owedToMe('owed_to_me');

  final String value;
  const DebtType(this.value);

  /// Parses the database value; throws on anything unsupported.
  static DebtType fromValue(String value) =>
      DebtType.values.firstWhere((t) => t.value == value,
          orElse: () => throw FormatException('Unknown debt type: $value'));
}

/// `active` until the debt is fully paid, then `paid`.
enum DebtStatus {
  active('active'),
  paid('paid');

  final String value;
  const DebtStatus(this.value);

  static DebtStatus fromValue(String value) =>
      DebtStatus.values.firstWhere((s) => s.value == value,
          orElse: () => throw FormatException('Unknown debt status: $value'));
}

/// Rounds a peso amount to whole centavos so sums never drift
/// (0.1 + 0.2 style errors).
double roundMoney(double v) => (v * 100).round() / 100;

int _cents(double v) => (v * 100).round();

/// One debt: money the user owes, or money owed to the user.

class Debt {
  final String id;
  final String userId;
  final DebtType type;
  final String title;
  final String? personName;
  final double originalAmount;
  final double amountPaid;
  final DateTime? dueDate; // date only
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Debt({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.personName,
    required this.originalAmount,
    this.amountPaid = 0,
    this.dueDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// originalAmount - amountPaid, never below zero.
  double get remaining {
    final left = _cents(originalAmount) - _cents(amountPaid);
    return left <= 0 ? 0 : left / 100;
  }

  bool get isFullyPaid => _cents(amountPaid) >= _cents(originalAmount);

  /// Derived: `paid` exactly when nothing remains.
  DebtStatus get status => isFullyPaid ? DebtStatus.paid : DebtStatus.active;

  bool get isActive => status == DebtStatus.active;

  /// 0.0 – 1.0 for progress bars.
  double get progress => originalAmount <= 0
      ? 0
      : (amountPaid / originalAmount).clamp(0.0, 1.0).toDouble();

  /// Active, has a due date, and that day is before [today].
  bool isOverdue(DateTime today) {
    final due = dueDate;
    if (due == null || !isActive) return false;
    final d = DateTime(due.year, due.month, due.day);
    final t = DateTime(today.year, today.month, today.day);
    return d.isBefore(t);
  }

  Debt copyWith({
    DebtType? type,
    String? title,
    String? personName,
    bool clearPersonName = false,
    double? originalAmount,
    double? amountPaid,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? notes,
    bool clearNotes = false,
    DateTime? updatedAt,
  }) =>
      Debt(
        id: id,
        userId: userId,
        type: type ?? this.type,
        title: title ?? this.title,
        personName: clearPersonName ? null : (personName ?? this.personName),
        originalAmount: originalAmount ?? this.originalAmount,
        amountPaid: amountPaid ?? this.amountPaid,
        dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
        notes: clearNotes ? null : (notes ?? this.notes),
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Same snake_case keys as the `debts` table columns.
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type.value,
        'title': title,
        'person_name': personName,
        'original_amount': originalAmount,
        'amount_paid': amountPaid,
        'due_date': dueDate == null ? null : dateKey(dueDate!),
        'notes': notes,
        'status': status.value,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory Debt.fromJson(Map<String, dynamic> json) {
    double num_(Object? v) => v is num ? v.toDouble() : double.parse('$v');
    final due = json['due_date'];
    final created = json['created_at'];
    final updated = json['updated_at'];
    final createdAt = created == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(created as String).toLocal();
    return Debt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: DebtType.fromValue(json['type'] as String),
      title: json['title'] as String,
      personName: json['person_name'] as String?,
      originalAmount: num_(json['original_amount']),
      amountPaid: num_(json['amount_paid'] ?? 0),
      dueDate: due == null ? null : _parseDate(due as String),
      notes: json['notes'] as String?,
      createdAt: createdAt,
      updatedAt: updated == null
          ? createdAt
          : DateTime.parse(updated as String).toLocal(),
    );
  }

  /// "2026-11-30" (or a full timestamp) -> local calendar date.
  static DateTime _parseDate(String s) {
    final d = DateTime.parse(s);
    return DateTime(d.year, d.month, d.day);
  }
}
