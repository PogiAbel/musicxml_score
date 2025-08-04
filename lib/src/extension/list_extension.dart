
extension LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
  T? firstWhereOrNull(test) { 
    try {
    return firstWhere(test);
    } catch (e) {
      return null;
    }
    }
}

extension LastOfType<E> on List<E> {
  T? lastOfType<T>() {
    for (var i = length - 1; i >= 0; i--) {
      if (this[i] is T) {
        return this[i] as T;
      }
    }
    return null;
  }
}

extension IterableExtension on Iterable<double> {
  /// Returns the sum of all elements in the iterable.
  double get sum => fold(0, (sum, element) => sum + element);

  /// Returns the maximum value in the iterable. Throws a [StateError] if the iterable is empty.
  double get max =>
      fold(first, (max, element) => element > max ? element : max);

  /// Returns the minimum value in the iterable. Throws a [StateError] if the iterable is empty.
  double get min =>
      fold(first, (min, element) => element < min ? element : min);
}

extension RoundUp on double{
  double roundUpTo(double number) => (this / number).ceil() * number;
}