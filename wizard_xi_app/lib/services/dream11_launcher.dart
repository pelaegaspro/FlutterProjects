import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';

class Dream11Launcher {
  Future<void> openDream11() async {
    final appUri = Uri.parse(AppConstants.dream11Scheme);
    final webUri = Uri.parse(AppConstants.dream11WebUrl);

    try {
      final launched = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return;
      }
    } catch (_) {
      // Fall back to the public site when the app is not installed.
    }

    await launchUrl(
      webUri,
      mode: LaunchMode.externalApplication,
    );
  }
}
