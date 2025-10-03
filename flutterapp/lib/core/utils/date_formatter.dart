import 'package:intl/intl.dart';

import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter();

  String formatDate(DateTime date) => DateFormat.yMMMMd().format(date);
  String formatDateTime(DateTime dateTime) => DateFormat.yMMMd().add_jm().format(dateTime);
}
