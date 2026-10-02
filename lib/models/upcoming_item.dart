/// An expected future income or expense shown on Home.
class UpcomingItem {
  final String id;
  final String name;
  final double amount;
  final bool isExpense;
  final DateTime date;

  UpcomingItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.isExpense,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'isExpense': isExpense,
        'date': date.toIso8601String(),
      };

  factory UpcomingItem.fromJson(Map<String, dynamic> json) => UpcomingItem(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        isExpense: json['isExpense'] as bool,
        date: DateTime.parse(json['date'] as String),
      );
}
