import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:veil/src/features/native_player/repository/episode_repository.dart';

void main() {
  test(
    'catalog loads seasons and episode names, with numbered fallback',
    () async {
      final repository = EpisodeRepository(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/season/1')) {
            return http.Response(
              jsonEncode({
                'episodes': [
                  {
                    'episode_number': 1,
                    'name': 'Freedom Day',
                    'still_path': '/still.jpg',
                  },
                  {'episode_number': 2, 'name': ''},
                ],
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'seasons': [
                {'season_number': 0, 'episode_count': 1},
                {'season_number': 1, 'episode_count': 10},
              ],
            }),
            200,
          );
        }),
      );
      expect((await repository.seasons(125988)).single.episodeCount, 10);
      final episodes = await repository.episodes(125988, 1);
      expect(episodes.first.label, 'Freedom Day');
      expect(episodes.first.code, 'S01 - E01');
      expect(episodes.first.thumbnail, contains('still.jpg'));
      expect(episodes.last.label, 'Episode 2');
      repository.dispose();
    },
  );
}
