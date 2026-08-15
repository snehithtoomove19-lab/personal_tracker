import 'package:intl/intl.dart';

String formatMoney(double amount, String currency) {
  final f = NumberFormat('#,##0.00');
  return '$currency${f.format(amount)}';
}

String formatDate(DateTime d) => DateFormat('d MMM yyyy').format(d);
String formatDateShort(DateTime d) => DateFormat('d MMM').format(d);
String formatDayName(DateTime d) => DateFormat('EEEE').format(d);
String formatMonthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
