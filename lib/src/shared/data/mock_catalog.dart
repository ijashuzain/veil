import 'package:flutter/material.dart';
import 'package:veil/src/shared/models/content_item.dart';

class VeilCatalog {
  static const items = <ContentItem>[
    ContentItem(
      id: 'wakanda',
      title: 'Wakanda Forever',
      subtitle: 'Black Panther',
      year: 2022,
      genre: 'Action / Adventure',
      type: 'Movie',
      rating: 8.2,
      palette: [Color(0xFF1A0D2E), Color(0xFF4A1A5E), Color(0xFF7C2D12)],
      glyph: Icons.shield_rounded,
      runtime: '2h 41m',
      description:
          'After the death of his father, T\'Challa returns home to Wakanda to take his rightful place as king while a hidden power rises from the deep.',
    ),
    ContentItem(
      id: 'oppenheimer',
      title: 'Oppenheimer',
      subtitle: 'A Christopher Nolan film',
      year: 2023,
      genre: 'Drama / Biography',
      type: 'Movie',
      rating: 8.4,
      palette: [Color(0xFF3A1A04), Color(0xFF8B3A0B), Color(0xFFD97706)],
      glyph: Icons.blur_circular_rounded,
      runtime: '3h 0m',
      description:
          'A theoretical physicist leads a world-changing project and faces the cost of genius, ambition, and power.',
    ),
    ContentItem(
      id: 'dune',
      title: 'Dune: Part Two',
      subtitle: 'Long live the fighters',
      year: 2024,
      genre: 'Sci-Fi / Adventure',
      type: 'Movie',
      rating: 8.7,
      palette: [Color(0xFF3D2914), Color(0xFF8B6F3A), Color(0xFFD4A574)],
      glyph: Icons.public_rounded,
      runtime: '2h 46m',
      description:
          'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family.',
    ),
    ContentItem(
      id: 'peaky',
      title: 'Peaky Blinders',
      subtitle: 'S6 - final order',
      year: 2022,
      genre: 'Crime / Drama',
      type: 'TV Show',
      rating: 8.8,
      palette: [Color(0xFF1A1A1A), Color(0xFF3A2A1A), Color(0xFF6B4423)],
      glyph: Icons.theater_comedy_rounded,
      progress: 0.62,
      progressLabel: '42 min left',
      description:
          'A notorious family builds an empire in postwar Birmingham while old enemies close in.',
    ),
    ContentItem(
      id: 'transformers',
      title: 'Transformers',
      subtitle: 'Rise of the Beasts',
      year: 2023,
      genre: 'Action / Sci-Fi',
      type: 'Movie',
      rating: 7.4,
      palette: [Color(0xFF0A1A2E), Color(0xFF1E3A5F), Color(0xFF3A5A8A)],
      glyph: Icons.settings_rounded,
      progress: 0.28,
      progressLabel: '1h 32m left',
      description:
          'A new faction of Transformers joins the battle for Earth in a globe-spanning adventure.',
    ),
    ContentItem(
      id: 'tanhaji',
      title: 'Tanhaji',
      subtitle: 'The Unsung Warrior',
      year: 2020,
      genre: 'Action / History',
      type: 'Movie',
      rating: 7.5,
      palette: [Color(0xFF2E0A0A), Color(0xFF7A1F1F), Color(0xFFC2410C)],
      glyph: Icons.local_fire_department_rounded,
      description:
          'A legendary warrior risks everything to reclaim a fortress and defend his people.',
    ),
    ContentItem(
      id: 'spiderverse',
      title: 'Across the Spider-Verse',
      subtitle: 'Every universe has a story',
      year: 2023,
      genre: 'Animation / Action',
      type: 'Movie',
      rating: 8.6,
      palette: [Color(0xFF3A0A5E), Color(0xFFC2185B), Color(0xFFFBBF24)],
      glyph: Icons.hub_rounded,
      description:
          'Miles Morales races across worlds and discovers what it means to write his own story.',
    ),
    ContentItem(
      id: 'arcane',
      title: 'Arcane',
      subtitle: 'Season 2',
      year: 2024,
      genre: 'Animation / Drama',
      type: 'TV Show',
      rating: 9.0,
      palette: [Color(0xFF0A3A5E), Color(0xFF1E6F8A), Color(0xFF34D399)],
      glyph: Icons.diamond_rounded,
      progress: 0.85,
      progressLabel: '8 min left',
      description:
          'Two sisters stand on opposite sides of a divided city shaped by magic, invention, and grief.',
    ),
    ContentItem(
      id: 'joker',
      title: 'Joker: Folie a Deux',
      subtitle: 'Madness finds harmony',
      year: 2024,
      genre: 'Crime / Musical',
      type: 'Movie',
      rating: 7.1,
      palette: [Color(0xFF1A2A1A), Color(0xFF3A5A3A), Color(0xFFF59E0B)],
      glyph: Icons.masks_rounded,
      description:
          'A criminal mind turns spectacle into confession in a city addicted to chaos.',
    ),
    ContentItem(
      id: 'furiosa',
      title: 'Furiosa',
      subtitle: 'A Mad Max Saga',
      year: 2024,
      genre: 'Action / Sci-Fi',
      type: 'Movie',
      rating: 7.8,
      palette: [Color(0xFF3A1A04), Color(0xFFA83A08), Color(0xFFF97316)],
      glyph: Icons.radio_button_unchecked_rounded,
      description:
          'A young warrior crosses a brutal wasteland and becomes the legend she was forced to become.',
    ),
    ContentItem(
      id: 'godzilla',
      title: 'Godzilla x Kong',
      subtitle: 'The New Empire',
      year: 2024,
      genre: 'Action / Sci-Fi',
      type: 'Movie',
      rating: 7.2,
      palette: [Color(0xFF0A2A3A), Color(0xFF1E5A7A), Color(0xFFEF4444)],
      glyph: Icons.bolt_rounded,
      description:
          'Two titans collide with a threat buried beneath the world they rule.',
    ),
    ContentItem(
      id: 'past',
      title: 'Past Lives',
      subtitle: 'What if then became now',
      year: 2023,
      genre: 'Drama / Romance',
      type: 'Movie',
      rating: 8.0,
      palette: [Color(0xFF1A2A3A), Color(0xFF3A5A7A), Color(0xFFFDA4AF)],
      glyph: Icons.nights_stay_rounded,
      description:
          'Two childhood friends reconnect across time, distance, and the choices that made them adults.',
    ),
    ContentItem(
      id: 'fallguy',
      title: 'The Fall Guy',
      subtitle: 'Stunts, sparks, second chances',
      year: 2024,
      genre: 'Action / Comedy',
      type: 'Movie',
      rating: 7.0,
      palette: [Color(0xFF3A0A1A), Color(0xFFA8082E), Color(0xFFF97316)],
      glyph: Icons.local_fire_department_rounded,
      description:
          'A stunt performer returns to the job and lands in the middle of a very real mystery.',
    ),
    ContentItem(
      id: 'monkeyman',
      title: 'Monkey Man',
      subtitle: 'Revenge has a rhythm',
      year: 2024,
      genre: 'Action / Thriller',
      type: 'Movie',
      rating: 7.3,
      palette: [Color(0xFF2E0A14), Color(0xFF7A1F3A), Color(0xFFDC2626)],
      glyph: Icons.front_hand_rounded,
      description:
          'A fighter claws his way through a city of corruption to settle a debt written in blood.',
    ),
    ContentItem(
      id: 'challengers',
      title: 'Challengers',
      subtitle: 'Love means nothing',
      year: 2024,
      genre: 'Drama / Sport',
      type: 'Movie',
      rating: 7.4,
      palette: [Color(0xFF0A3A3A), Color(0xFF0E7A7A), Color(0xFFFDE047)],
      glyph: Icons.sports_tennis_rounded,
      description:
          'Three players turn a tennis match into a reckoning over ambition, desire, and control.',
    ),
  ];

  static ContentItem get featured => byId('dune');

  static List<ContentItem> get continueWatching => [
    byId('peaky'),
    byId('transformers'),
    byId('arcane'),
  ];

  static List<ContentItem> get globalTrending => [
    byId('wakanda'),
    byId('oppenheimer'),
    byId('spiderverse'),
    byId('furiosa'),
    byId('joker'),
    byId('godzilla'),
  ];

  static List<ContentItem> get newThisWeek => [
    byId('challengers'),
    byId('past'),
    byId('monkeyman'),
    byId('fallguy'),
    byId('tanhaji'),
  ];

  static List<ContentItem> get watchlist => [
    byId('challengers'),
    byId('past'),
    byId('arcane'),
    byId('monkeyman'),
    byId('fallguy'),
  ];

  static List<ContentItem> get recentlyWatched => [
    byId('wakanda'),
    byId('peaky'),
    byId('dune'),
  ];

  static List<String> get genres => [
    'Action',
    'Drama',
    'Sci-Fi',
    'Anime',
    'Thriller',
    'Comedy',
  ];

  static ContentItem byId(String id) =>
      items.firstWhere((item) => item.id == id, orElse: () => items.first);

  static List<ContentItem> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return items.take(8).toList();

    return items.where((item) {
      final haystack = [
        item.title,
        item.subtitle,
        item.genre,
        item.type,
        item.year.toString(),
      ].join(' ').toLowerCase();
      return haystack.contains(normalized);
    }).toList();
  }
}
