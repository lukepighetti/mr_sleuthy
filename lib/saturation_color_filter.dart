import 'package:flutter/rendering.dart' show ColorFilter;

ColorFilter saturationColorFilter(double saturation) {
  const double r = 0.2126;
  const double g = 0.7152;
  const double b = 0.0722;

  final double invSat = 1 - saturation;

  return ColorFilter.matrix(<double>[
    invSat * r + saturation, invSat * g,             invSat * b,             0, 0,
    invSat * r,             invSat * g + saturation, invSat * b,             0, 0,
    invSat * r,             invSat * g,             invSat * b + saturation, 0, 0,
    0,                     0,                      0,                      1, 0,
  ]);
}