import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class GuideDetailScreen extends StatelessWidget {
  final String title;
  final List<dynamic> content;

  const GuideDetailScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    // Process content to group spans together for tighter vertical rhythm
    final processedContent = <dynamic>[];
    List<TextSpan>? currentSpanGroup;

    for (final item in content) {
      if (item is TextSpan) {
        currentSpanGroup ??= [];
        currentSpanGroup.add(item);
      } else if (item is String) {
        currentSpanGroup ??= [];
        currentSpanGroup.add(TextSpan(text: item));
      } else {
        if (currentSpanGroup != null) {
          processedContent.add(TextSpan(children: currentSpanGroup));
          currentSpanGroup = null;
        }
        processedContent.add(item);
      }
    }
    if (currentSpanGroup != null) {
      processedContent.add(TextSpan(children: currentSpanGroup));
    }

    return Scaffold(
      backgroundColor: AppConstants.bgDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLG,
              vertical: AppConstants.paddingMD,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = processedContent[index];
                  
                  if (item is TextSpan) {
                    return SelectableText.rich(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.55,
                        color: AppConstants.textSecondary,
                      ),
                    );
                  } else if (item is Widget) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: item,
                    );
                  }
                  return const SizedBox.shrink();
                },
                childCount: processedContent.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 48),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppConstants.bgDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppConstants.textPrimary,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Divider(color: AppConstants.border, thickness: 1),
      ),
    );
  }
}
