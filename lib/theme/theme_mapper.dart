import 'package:bigreminder/theme/role_colors.dart';

import '../models/app_color_scheme.dart';
import '../utils/enum_classes.dart';

AppColorScheme getColors(AppType type) {
  switch (type) {
    case AppType.gym:
      return gymColors;
    case AppType.shop:
      return shopColors;
    case AppType.institute:
      return instituteColors;
  }
}