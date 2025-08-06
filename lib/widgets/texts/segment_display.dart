import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SegmentDisplay extends StatelessWidget {
  final String displayText;

  const SegmentDisplay({
    Key? key,
    required this.displayText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (displayText.isEmpty) {
      return Center(
        child: Text(
          'Appuyez sur "Segment suivant" pour commencer',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textGrey,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: SelectableText(
        displayText,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textDark,
          height: 1.6,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
