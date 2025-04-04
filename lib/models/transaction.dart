import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String category;

  @HiveField(4)
  bool isIncome;

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.isIncome,
  });
}
