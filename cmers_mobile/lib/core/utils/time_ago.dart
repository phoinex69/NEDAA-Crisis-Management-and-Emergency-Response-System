/// يحوّل وقتاً إلى نص عربي نسبي ("الآن"، "منذ 5 دقائق"، "أمس"...).
String timeAgoFrom(DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final difference = current.difference(time);

  if (difference.inSeconds < 60) return 'الآن';

  if (difference.inMinutes < 60) {
    final m = difference.inMinutes;
    return m == 1 ? 'منذ دقيقة' : 'منذ $m دقائق';
  }

  if (difference.inHours < 24) {
    final h = difference.inHours;
    return h == 1 ? 'منذ ساعة' : 'منذ $h ساعات';
  }

  if (difference.inDays < 2) return 'أمس';

  if (difference.inDays < 7) {
    final d = difference.inDays;
    return d == 2 ? 'منذ يومين' : 'منذ $d أيام';
  }

  final day = time.day.toString().padLeft(2, '0');
  final month = time.month.toString().padLeft(2, '0');
  return '$day/$month/${time.year}';
}
