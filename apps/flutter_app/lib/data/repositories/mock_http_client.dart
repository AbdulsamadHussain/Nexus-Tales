import 'package:dio/dio.dart';
import '../services/http_client_interface.dart';

/// Mock HTTP client for testing Phase 2 Riverpod wiring without backend
/// Simulates real API responses during development
/// Swap with HttpClientService when backend auth is ready
class MockHttpClientService implements HttpClientServiceInterface {
  static const String _fakeToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3LWFiY2QtdGVzdC1wbGF5ZXIiLCJpYXQiOjE2NDM2NDQ0MDB9.abcd1234';

  /// Mock POST request
  @override
  Future<T> post<T>(
    String path, {
    required dynamic data,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock responses by endpoint
    if (path.contains('/v1/turns')) {
      return _mockTurnResponse(data) as T;
    }
    if (path.contains('/v1/saves/manual')) {
      return _mockCreateSaveResponse(data) as T;
    }
    if (path.contains('/v1/rollback')) {
      return _mockRollbackResponse(data) as T;
    }

    throw DioException(
      requestOptions: RequestOptions(path: path),
      message: 'Unmocked endpoint: $path',
      type: DioExceptionType.unknown,
    );
  }

  /// Mock GET request
  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock responses by endpoint
    if (path.contains('/v1/saves')) {
      return _mockFetchSavesResponse() as T;
    }
    if (path.contains('/v1/character')) {
      return _mockFetchCharacterResponse() as T;
    }
    if (path.contains('/health')) {
      return {'status': 'ok'} as T;
    }

    throw DioException(
      requestOptions: RequestOptions(path: path),
      message: 'Unmocked endpoint: $path',
      type: DioExceptionType.unknown,
    );
  }

  /// Mock PUT request
  @override
  Future<T> put<T>(
    String path, {
    required dynamic data,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw DioException(
      requestOptions: RequestOptions(path: path),
      message: 'PUT not mocked for: $path',
      type: DioExceptionType.unknown,
    );
  }

  /// Mock DELETE request
  @override
  Future<T> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    throw DioException(
      requestOptions: RequestOptions(path: path),
      message: 'DELETE not mocked for: $path',
      type: DioExceptionType.unknown,
    );
  }

  /// Mock turn submission response
  dynamic _mockTurnResponse(dynamic data) {
    return {
      'status': 'ACCEPTED',
      'revision_id': 'rev-mock-001',
      'request_hash': 'hash-abc123',
      'simulation_result': {
        'action_outcome': 'SUCCESS',
        'roll_result': {
          'dice': [4, 5],
          'total': 9,
          'targetDC': 10,
        },
        'consequences': [
          'You take a step forward, the shadows parting before you.',
        ],
        'canonical_events': [
          {
            'eventId': 'evt-mock-001',
            'eventType': 'ACTION_OUTCOME',
            'description': 'You attempted an action and it succeeded!',
            'rollSum': 9,
            'targetDC': 10,
          },
        ],
      },
      'character_state_delta': {
        'hpDelta': -5,
        'staminaDelta': -10,
        'manaDelta': 0,
      },
      'autosave_eligible': true,
    };
  }

  /// Mock save creation response
  dynamic _mockCreateSaveResponse(dynamic data) {
    return {
      'save_id': 'save-mock-001',
      'timestamp': DateTime.now().toIso8601String(),
      'location': 'Forest Clearing',
      'chapter_number': 1,
      'quest_milestone': 'The Journey Begins',
    };
  }

  /// Mock fetch saves response
  dynamic _mockFetchSavesResponse() {
    return {
      'manual_saves': [
        {
          'save_id': 'save-mock-001',
          'timestamp': '2026-04-01T10:00:00Z',
          'location': 'Forest Clearing',
          'chapter_number': 1,
          'quest_milestone': 'The Journey Begins',
        },
      ],
      'autosaves': [
        {
          'save_id': 'save-mock-auto-001',
          'timestamp': '2026-04-01T10:15:00Z',
          'location': 'Village Square',
          'chapter_number': 1,
          'quest_milestone': 'Meeting the Elder',
        },
      ],
      'checkpoints': [],
    };
  }

  /// Mock character fetch response
  dynamic _mockFetchCharacterResponse() {
    return {
      'character_id': 'char-mock-001',
      'name': 'Mock Hero',
      'class_name': 'Adventurer',
      'class_description': 'A brave wanderer',
      'level': 1,
      'experience': 0,
      'experience_max': 100,
      'hp': 50,
      'hp_max': 100,
      'stamina': 80,
      'stamina_max': 100,
      'mana': 30,
      'mana_max': 50,
      'strength': 10,
      'dexterity': 10,
      'constitution': 10,
      'intelligence': 10,
      'wisdom': 10,
      'charisma': 10,
      'gold': 50,
      'resources': 10,
      'current_location': 'The Raven\'s Threshold',
      'inventory': [
        {
          'item_id': 'item-mock-001',
          'name': 'Iron Sword',
          'item_type': 'WEAPON',
          'quantity': 1,
          'rarity': 'COMMON',
        },
        {
          'item_id': 'item-mock-002',
          'name': 'Health Potion',
          'item_type': 'CONSUMABLE',
          'quantity': 5,
          'rarity': 'COMMON',
        },
      ],
      'quests': [
        {
          'quest_id': 'quest-mock-001',
          'title': 'The Journey Begins',
          'description': 'Start your adventure in the forest',
          'quest_stage': 'IN_PROGRESS',
          'progress': 0,
          'progress_max': 5,
          'reward_preview': 'Experience and gold',
        },
      ],
      'factions': [
        {
          'faction_id': 'faction-mock-001',
          'name': 'The Watchers',
          'standing': 50,
          'standing_level': 'NEUTRAL',
        },
      ],
      'relationships': [
        {
          'npc_id': 'npc-mock-001',
          'npc_name': 'The Hooded Figure',
          'affinity': 10,
          'affinity_level': 'ACQUAINTANCE',
          'last_interaction': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        },
      ],
      'codex': [
        {
          'entry_id': 'codex-mock-001',
          'title': 'The Raven\'s Threshold',
          'entry_type': 'LOCATION',
          'description': 'A tavern in the heart of the city',
          'discovered_at': DateTime.now().toIso8601String(),
        },
      ],
    };
  }

  /// Mock rollback response
  dynamic _mockRollbackResponse(dynamic data) {
    return {
      'character_state': _mockFetchCharacterResponse(),
      'game_state': {
        'current_location': 'Forest Clearing',
        'time_of_day': 'morning',
      },
    };
  }

  /// Returns mock auth token
  static String getMockAuthToken() => _fakeToken;

  /// Update auth token (no-op in mock)
  @override
  void setAuthToken(String token) {
    // Mock doesn't validate tokens
  }
}
