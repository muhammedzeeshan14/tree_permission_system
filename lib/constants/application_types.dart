class ApplicationTypes {
  ApplicationTypes._();

  static const privateLand = "PL";

  static const governmentLand = "GL";
static const stateGovernmentLand = "STGL";
static const centralGovernmentLand = "CGL";

  static const mcc = "MCC";

  static const sandal = "SANDAL";

static bool isGovernmentLand(String value) {
  final code = value.trim().toUpperCase();

  return code == governmentLand ||
      code == stateGovernmentLand ||
      code == centralGovernmentLand;
}

}