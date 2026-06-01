import 'package:flutter/material.dart';

import '../models/quick_site.dart';

/// A responsive grid of quick-access site shortcuts shown on the home page.
class QuickSiteGrid extends StatelessWidget {
  const QuickSiteGrid({
    super.key,
    required this.sites,
    required this.onTap,
  });

  final List<QuickSite> sites;
  final void Function(QuickSite site) onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt column count to the available width.
        final crossAxisCount = constraints.maxWidth ~/ 84;
        final count = crossAxisCount.clamp(3, 6);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: sites.length,
          itemBuilder: (context, index) {
            final site = sites[index];
            return _QuickSiteTile(site: site, onTap: () => onTap(site));
          },
        );
      },
    );
  }
}

class _QuickSiteTile extends StatelessWidget {
  const _QuickSiteTile({required this.site, required this.onTap});

  final QuickSite site;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(site.icon, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 6),
          Text(
            site.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
