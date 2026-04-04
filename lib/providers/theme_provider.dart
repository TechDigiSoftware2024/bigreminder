
import 'package:bigreminder/utils/enum_classes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../theme/app_theme.dart';
import '../theme/theme_mapper.dart';

final appTypeProvider = StateProvider<AppType>((ref) => AppType.gym);

final themeProvider = Provider<ThemeData>((ref) {
  final type = ref.watch(appTypeProvider);
  final colors = getColors(type);
  return AppTheme.light(colors);
});

