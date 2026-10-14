/// Deterministic random numbers from a seed (Mulberry32), so the same seed
/// always gives the same problem in the app, in CI and in the playground.
class SeededRandom {
  int _state;

  SeededRandom(int seed) : _state = seed & 0xFFFFFFFF;

  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = _imul(t ^ (t >>> 15), t | 1);
    t ^= (t + _imul(t ^ (t >>> 7), t | 61)) & 0xFFFFFFFF;
    return (t ^ (t >>> 14)) & 0xFFFFFFFF;
  }

  static int _imul(int a, int b) => (a * b) & 0xFFFFFFFF;

  /// Uniform in [0, max).
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max, 'max');
    return nextUint32() % max;
  }

  /// Uniform in [min, max], both inclusive.
  int range(int min, int max) => min + nextInt(max - min + 1);

  T pick<T>(List<T> items) => items[nextInt(items.length)];

  bool chance(int percent) => nextInt(100) < percent;

  List<T> shuffled<T>(List<T> items) {
    final out = [...items];
    for (var i = out.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final t = out[i];
      out[i] = out[j];
      out[j] = t;
    }
    return out;
  }
}
