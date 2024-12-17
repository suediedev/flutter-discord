import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_colors.dart';

class PlatformTheme {
  static bool isIOS(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS;
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static ThemeData getMaterialTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: isDark ? ColorScheme.dark(
        background: AppColors.backgroundColor,
        surface: AppColors.channelBarColor,
        primary: AppColors.primaryPurple,
      ) : const ColorScheme.light(
        primary: Color(0xFF007AFF),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.messageInputBackground : Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(color: isDark ? AppColors.secondaryTextColor : Colors.grey[600]),
      ),
      cardTheme: CardTheme(
        color: isDark ? AppColors.cardBackground : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  static CupertinoThemeData getCupertinoTheme(bool isDark) {
    return CupertinoThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: const Color(0xFF007AFF),
      scaffoldBackgroundColor: isDark ? AppColors.backgroundColor : CupertinoColors.systemBackground,
      barBackgroundColor: isDark ? AppColors.channelBarColor : CupertinoColors.systemBackground,
    );
  }

  static Widget adaptiveProgressIndicator({Color? color}) {
    return Builder(
      builder: (context) {
        return isIOS(context)
            ? const CupertinoActivityIndicator()
            : CircularProgressIndicator(color: color);
      },
    );
  }

  static Widget adaptiveButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required Widget child,
    Color? backgroundColor,
  }) {
    if (isIOS(context)) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        child: child,
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: child,
    );
  }

  static Widget adaptiveTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String placeholder,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    if (isIOS(context)) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        obscureText: obscureText,
        keyboardType: keyboardType,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.systemGrey6,
            context,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: placeholder,
        border: const OutlineInputBorder(),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
