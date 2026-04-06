/// Maps backend `icon_name` keys to local Flutter SVG asset paths.
/// Add new entries here when new service categories are created in Django Admin.
class IconAssets {
  IconAssets._();

  static const _basePath = 'assets/icons';

  static String path(String? iconName) {
    if (iconName == null || iconName.isEmpty) return '$_basePath/default.svg';
    return '$_basePath/$iconName.svg';
  }
}
