import 'package:flutter/widgets.dart';
import 'app_strings.dart';

extension LocalizationBuildContext on BuildContext {
  AppStrings get l10n => AppStrings.current;
}
