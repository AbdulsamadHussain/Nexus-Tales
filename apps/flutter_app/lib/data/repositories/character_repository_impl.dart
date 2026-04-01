import '../dto/character_state_dto.dart';
import '../mappers/character_mapper.dart';
import '../services/http_client_service.dart';
import '../services/network_config.dart';
import '../services/network_exception.dart';
import '../../domain/models/game_models.dart';
import 'character_repository.dart';

/// Implementation of CharacterRepository using HTTP client
class CharacterRepositoryImpl implements CharacterRepository {
  final HttpClientService _httpClient;

  CharacterRepositoryImpl({required HttpClientService httpClient})
      : _httpClient = httpClient;

  @override
  Future<PlayerCharacter> fetchCharacter(
      String runId, String saveSlotId) async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        NetworkConfig.characterEndpoint,
        queryParameters: {
          'run_id': runId,
          'save_slot_id': saveSlotId,
        },
      );

      final characterDto = CharacterStateDto.fromJson(response);
      return CharacterMapper.toPlayerCharacter(characterDto);
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error fetching character: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Quest>> fetchQuests(String runId) async {
    try {
      final response = await _httpClient.get<List<dynamic>>(
        '${NetworkConfig.characterEndpoint}/$runId/quests',
      );

      final questDtos = (response as List)
          .cast<Map<String, dynamic>>()
          .map((json) => QuestDto.fromJson(json))
          .toList();

      return questDtos.map(CharacterMapper.toQuest).toList();
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error fetching quests: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<InventoryItem>> fetchInventory(String runId) async {
    try {
      final response = await _httpClient.get<List<dynamic>>(
        '${NetworkConfig.characterEndpoint}/$runId/inventory',
      );

      final itemDtos = (response as List)
          .cast<Map<String, dynamic>>()
          .map((json) => InventoryItemDto.fromJson(json))
          .toList();

      return itemDtos.map(CharacterMapper.toInventoryItem).toList();
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error fetching inventory: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<CodexEntry>> fetchCodexEntries(String runId) async {
    try {
      final response = await _httpClient.get<List<dynamic>>(
        '${NetworkConfig.characterEndpoint}/$runId/codex',
      );

      final codexDtos = (response as List)
          .cast<Map<String, dynamic>>()
          .map((json) => CodexEntryDto.fromJson(json))
          .toList();

      return codexDtos
          .where((dto) => dto.discovered)
          .map(CharacterMapper.toCodexEntry)
          .toList();
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error fetching codex entries: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Faction>> fetchFactions(String runId) async {
    try {
      final response = await _httpClient.get<List<dynamic>>(
        '${NetworkConfig.characterEndpoint}/$runId/factions',
      );

      final factionDtos = (response as List)
          .cast<Map<String, dynamic>>()
          .map((json) => FactionDto.fromJson(json))
          .toList();

      return factionDtos.map(CharacterMapper.toFaction).toList();
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error fetching factions: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Relationship>> fetchRelationships(String runId) async {
    try {
      final response = await _httpClient.get<List<dynamic>>(
        '${NetworkConfig.characterEndpoint}/$runId/relationships',
      );

      final relationshipDtos = (response as List)
          .cast<Map<String, dynamic>>()
          .map((json) => RelationshipDto.fromJson(json))
          .toList();

      return relationshipDtos.map(CharacterMapper.toRelationship).toList();
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error fetching relationships: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> hydrateCompleteState(
    String runId,
    String saveSlotId,
  ) async {
    try {
      // Fetch all state in parallel
      final results = await Future.wait([
        fetchCharacter(runId, saveSlotId),
        fetchQuests(runId),
        fetchInventory(runId),
        fetchCodexEntries(runId),
        fetchFactions(runId),
        fetchRelationships(runId),
      ]);

      final character = results[0] as PlayerCharacter;
      final quests = results[1] as List<Quest>;
      final inventory = results[2] as List<InventoryItem>;
      final codex = results[3] as List<CodexEntry>;
      final factions = results[4] as List<Faction>;
      final relationships = results[5] as List<Relationship>;

      return {
        'character': character,
        'quests': quests,
        'inventory': inventory,
        'codex': codex,
        'factions': factions,
        'relationships': relationships,
        'hydration_time': DateTime.now().toIso8601String(),
      };
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error hydrating complete state: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
