import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';

class Dream11Launcher {
  Future<void> openDream11() async {
    final appUri = Uri.parse(AppConstants.dream11Scheme);
    final webUri = Uri.parse(AppConstants.dream11WebUrl);

    try {
      final launchedApp = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );
      if (launchedApp) {
        return;
      }
    } catch (_) {
      // Fallback to the public web URL below.
    }

    await launchUrl(
      webUri,
      mode: LaunchMode.externalApplication,
    );
  }
}
