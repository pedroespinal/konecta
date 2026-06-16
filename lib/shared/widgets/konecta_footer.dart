import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_version.dart';
import '../../core/theme/app_colors.dart';

class KonectaFooter extends StatelessWidget {
  final bool showVersion;

  const KonectaFooter({super.key, this.showVersion = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? KonectaColors.darkTextTertiary
        : KonectaColors.lightTextTertiary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showVersion)
            Text(
              AppVersion.displayVersion,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            AppConstants.copyright,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
