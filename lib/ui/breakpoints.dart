class AppBreakpoints {
  static const xs = 600.0;
  static const sm = 900.0;
  static const md = 1200.0;
  static const lg = 1536.0;

  static double aspectFor(double w) {
    if (w >= lg) return 16 / 6;   // hero mais “achatado”
    if (w >= md) return 16 / 7;
    if (w >= sm) return 16 / 8;
    if (w >= xs) return 16 / 9;   // padrão widescreen
    return 4 / 3;                 // mobile estreito
  }

  static int gridCols(double w) {
    if (w >= lg) return 5;
    if (w >= md) return 4;
    if (w >= sm) return 3;
    return 2;
  }
}
