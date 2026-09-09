String formatKoreanTime(DateTime dt) {
  final period = dt.hour < 12 ? '오전' : '오후';
  var hour = dt.hour % 12;
  if (hour == 0) hour = 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$period $hour:$minute';
}

String formatKoreanDate(DateTime dt) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${dt.month}월 ${dt.day}일 ${weekdays[dt.weekday - 1]}요일';
}

String formatDistanceMeters(int meters) {
  if (meters < 1000) return '${meters}m';
  final km = meters / 1000;
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)}km';
}
