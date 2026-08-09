import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/auth/view_model/auth_view_model/auth_view_model.dart';
import 'package:veil/src/features/catalog/models/tmdb_watch_provider.dart';
import 'package:veil/src/features/catalog/view_model/provider_catalog_providers.dart';
import 'package:veil/src/shared/components/skeleton.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';

class WatchProviderSection extends ConsumerWidget {
  const WatchProviderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref
        .watch(authViewModelProvider)
        .user
        ?.email
        ?.trim()
        .toLowerCase();
    if (email == 'tester@vexellab.com') return const SizedBox.shrink();

    final providers = ref.watch(watchProvidersProvider);
    return providers.when(
      data: (items) {
        final visible = items.take(12).toList(growable: false);
        if (visible.isEmpty) return const SizedBox.shrink();
        return _ProviderRail(providers: visible);
      },
      loading: () => const _ProviderRailLoading(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ProviderRail extends StatelessWidget {
  const _ProviderRail({required this.providers});

  final List<TmdbWatchProvider> providers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: SizedBox(
        height: 90,
        child: ListView.separated(
          key: const ValueKey('watch-provider-list'),
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: VeilLayout.pageGutter(context),
          ),
          itemCount: providers.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final provider = providers[index];
            return _ProviderCard(
              provider: provider,
              onTap: () => ProviderRoute(
                id: provider.id,
                name: provider.name,
                logoPath: provider.logoPath,
              ).push(context),
            );
          },
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.onTap});

  final TmdbWatchProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedName = provider.name.trim();
    final fallback = ColoredBox(
      color: VeilColors.bg3,
      child: Center(
        child: Text(
          normalizedName.isEmpty
              ? '?'
              : normalizedName.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
    return InkWell(
      key: ValueKey('watch-provider-${provider.id}'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              key: ValueKey('watch-provider-image-${provider.id}'),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VeilColors.hairlineStrong),
              ),
              clipBehavior: Clip.antiAlias,
              child: provider.logoUrl == null
                  ? fallback
                  : CachedNetworkImage(
                      imageUrl: provider.logoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => fallback,
                      errorWidget: (_, _, _) => fallback,
                    ),
            ),
            const SizedBox(height: 5),
            Text(
              provider.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: VeilColors.text2,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderRailLoading extends StatelessWidget {
  const _ProviderRailLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: SizedBox(
        height: 58,
        child: ListView.separated(
          key: const ValueKey('watch-provider-loading-list'),
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: VeilLayout.pageGutter(context),
          ),
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, index) => SkeletonBox(
            key: ValueKey('watch-provider-loading-$index'),
            width: 58,
            height: 58,
            radius: 12,
          ),
        ),
      ),
    );
  }
}
