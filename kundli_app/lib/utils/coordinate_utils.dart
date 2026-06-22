class CoordinateUtils {
  static double toDecimal({
    required int degree,
    required int minute,
    required bool negative,
  }) {
    final value = degree + (minute / 60);

    return negative ? -value : value;
  }
}