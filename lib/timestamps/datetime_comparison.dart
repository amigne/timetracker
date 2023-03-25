extension DateTimeComparison on DateTime {
  bool operator <(DateTime other) => compareTo(other) < 0;

  bool operator <=(DateTime other) => compareTo(other) <= 0;

  bool operator >(DateTime other) => compareTo(other) > 0;

  bool operator >=(DateTime other) => compareTo(other) >= 0;
}
