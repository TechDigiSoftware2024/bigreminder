import 'package:bigreminder/theme/role_colors.dart';

import '../models/app_color_scheme.dart';
import '../utils/enum_classes.dart';
final Map<AppType, AppColorScheme> _colorMap = {
  AppType.gym: gymColors,
  AppType.shop: shopColors,
  AppType.institute: instituteColors,
  AppType.salon: salonColors,
  AppType.hospital: hospitalColors,
  AppType.restaurant: restaurantColors,
  AppType.finance: financeColors,
  AppType.realEstate: realEstateColors,
};

AppColorScheme getColors(AppType type) {
  return _colorMap[type] ?? gymColors; // fallback safe
}