import '../dto/save_dto.dart';
import '../mappers/save_mapper.dart';
import '../services/http_client_service.dart';
import '../services/network_config.dart';
import '../services/network_exception.dart';
import '../../domain/models/game_models.dart';
import 'save_repository.dart';

/// Implementation of SaveRepository using HTTP client
class SaveRepositoryImpl implements SaveRepository {
  final HttpClientService _httpClient;

  SaveRepositoryImpl({required HttpClientService httpClient})
      : _httpClient = httpClient;

  @override
  Future<SaveSlot> createManualSave(SaveRequestDto request) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        NetworkConfig.manualSavesEndpoint,
        data: request.toJson(),
      );

      final responseDto = CreateSaveResponseDto.fromJson(response);

      // Create a SaveSlot from the response
      final saveSlot = SaveSlot(
        id: responseDto.manualSaveId,
        campaignTitle: 'Current Campaign',
        characterName: 'Unknown',
        location: 'Unknown',
        currentChapter: 'Chapter 1',
        lastSavedAt: responseDto.timestamp,
        isAutosave: false,
        isCheckpoint: false,
        revisionNumber: 0,
        playtimeMinutes: 0,
      );

      return saveSlot;
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error creating save: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<SaveSlot>> fetchSaves(String runId, String saveSlotId) async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        '${NetworkConfig.savesEndpoint}/$runId',
        queryParameters: {'save_slot_id': saveSlotId},
      );

      final saveSlotsDto = SaveSlotsDto.fromJson(response);

      // Combine all save types and convert to domain models
      final allSaves = <SaveSlot>[
        ...saveSlotsDto.manualSaves.map(SaveMapper.toSaveSlot),
        ...saveSlotsDto.autosaves.map(SaveMapper.toSaveSlot),
        ...saveSlotsDto.checkpoints.map(SaveMapper.toSaveSlot),
      ];

      // Sort by timestamp descending (most recent first)
      allSaves.sort((a, b) => b.lastSavedAt.compareTo(a.lastSavedAt));

      return allSaves;
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error fetching saves: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> loadSave(String saveSlotId) async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        '${NetworkConfig.savesEndpoint}/$saveSlotId/load',
      );

      // Parse as SaveSnapshotDto
      final snapshotDto = SaveSnapshotDto.fromJson(response);

      // Convert to game state map
      return SaveMapper.toGameStateMap(snapshotDto);
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error loading save: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteManualSave(String saveId) async {
    try {
      await _httpClient.delete<void>(
        '${NetworkConfig.manualSavesEndpoint}/$saveId',
      );
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error deleting save: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<SaveSlotsDto> fetchSaveMetadata(String runId) async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        '${NetworkConfig.savesEndpoint}/$runId/metadata',
      );

      return SaveSlotsDto.fromJson(response);
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error fetching save metadata: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
