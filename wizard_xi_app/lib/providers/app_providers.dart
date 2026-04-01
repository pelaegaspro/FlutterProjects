import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_bootstrap.dart';

final appBootstrapProvider = Provider<AppBootstrapState>(
  (ref) => throw UnimplementedError('Bootstrap state is injected from main().'),
);
