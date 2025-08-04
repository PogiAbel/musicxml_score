extension StringExtension on String {
  String capitalize() {
    switch (length) {
      case 0:
        return '';
      case 1:
        return toUpperCase();
      default:
        return "${this[0].toUpperCase()}${substring(1)}";
    }
  }

  String remove(String toRemove) {
    return replaceAll(toRemove, '');
  }
}