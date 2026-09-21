import 'package:flutter/foundation.dart';

/// True while the API answers 503 with `meta.maintenance` (System Settings →
/// System → Maintenance mode). The maintenance gate covers the app until the
/// platform endpoint says it is over.
class MaintenanceState {
  MaintenanceState._();

  static final ValueNotifier<bool> active = ValueNotifier(false);
}
