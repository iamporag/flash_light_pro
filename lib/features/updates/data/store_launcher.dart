import 'package:url_launcher/url_launcher.dart';

abstract interface class StoreLauncher {
  Future<bool> open(Uri uri);
}

class UrlStoreLauncher implements StoreLauncher {
  const UrlStoreLauncher();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
