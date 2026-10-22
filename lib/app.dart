
import 'package:flutter/widgets.dart';

import 'screens/report_form_screen.dart';

Map<String, WidgetBuilder> buildAppRoutes() {
  return {
    '/report': (_) => const ReportFormScreen(),
  };
}
