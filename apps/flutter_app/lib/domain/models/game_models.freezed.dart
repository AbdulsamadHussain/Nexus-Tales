// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlayerCharacter _$PlayerCharacterFromJson(Map<String, dynamic> json) {
  return _PlayerCharacter.fromJson(json);
}

/// @nodoc
mixin _$PlayerCharacter {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get archetype => throw _privateConstructorUsedError;
  String get background => throw _privateConstructorUsedError;
  String get pronouns => throw _privateConstructorUsedError;
  int get healthPoints => throw _privateConstructorUsedError;
  int get maxHealthPoints => throw _privateConstructorUsedError;
  int get stamina => throw _privateConstructorUsedError;
  int get maxStamina => throw _privateConstructorUsedError;
  int get mana => throw _privateConstructorUsedError;
  int get maxMana => throw _privateConstructorUsedError;
  Map<String, int> get stats =>
      throw _privateConstructorUsedError; // str, agi, willpower, presence, intellect
  int get gold => throw _privateConstructorUsedError;
  List<String> get equippedItems => throw _privateConstructorUsedError;
  List<String> get wounds => throw _privateConstructorUsedError;
  List<String> get activeConditions => throw _privateConstructorUsedError;
  Map<String, int> get skillLevels => throw _privateConstructorUsedError;
  int get experience => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;
  List<String> get passiveTraits => throw _privateConstructorUsedError;

  /// Serializes this PlayerCharacter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerCharacter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerCharacterCopyWith<PlayerCharacter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerCharacterCopyWith<$Res> {
  factory $PlayerCharacterCopyWith(
          PlayerCharacter value, $Res Function(PlayerCharacter) then) =
      _$PlayerCharacterCopyWithImpl<$Res, PlayerCharacter>;
  @useResult
  $Res call(
      {String id,
      String name,
      String archetype,
      String background,
      String pronouns,
      int healthPoints,
      int maxHealthPoints,
      int stamina,
      int maxStamina,
      int mana,
      int maxMana,
      Map<String, int> stats,
      int gold,
      List<String> equippedItems,
      List<String> wounds,
      List<String> activeConditions,
      Map<String, int> skillLevels,
      int experience,
      int level,
      List<String> passiveTraits});
}

/// @nodoc
class _$PlayerCharacterCopyWithImpl<$Res, $Val extends PlayerCharacter>
    implements $PlayerCharacterCopyWith<$Res> {
  _$PlayerCharacterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerCharacter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? archetype = null,
    Object? background = null,
    Object? pronouns = null,
    Object? healthPoints = null,
    Object? maxHealthPoints = null,
    Object? stamina = null,
    Object? maxStamina = null,
    Object? mana = null,
    Object? maxMana = null,
    Object? stats = null,
    Object? gold = null,
    Object? equippedItems = null,
    Object? wounds = null,
    Object? activeConditions = null,
    Object? skillLevels = null,
    Object? experience = null,
    Object? level = null,
    Object? passiveTraits = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      archetype: null == archetype
          ? _value.archetype
          : archetype // ignore: cast_nullable_to_non_nullable
              as String,
      background: null == background
          ? _value.background
          : background // ignore: cast_nullable_to_non_nullable
              as String,
      pronouns: null == pronouns
          ? _value.pronouns
          : pronouns // ignore: cast_nullable_to_non_nullable
              as String,
      healthPoints: null == healthPoints
          ? _value.healthPoints
          : healthPoints // ignore: cast_nullable_to_non_nullable
              as int,
      maxHealthPoints: null == maxHealthPoints
          ? _value.maxHealthPoints
          : maxHealthPoints // ignore: cast_nullable_to_non_nullable
              as int,
      stamina: null == stamina
          ? _value.stamina
          : stamina // ignore: cast_nullable_to_non_nullable
              as int,
      maxStamina: null == maxStamina
          ? _value.maxStamina
          : maxStamina // ignore: cast_nullable_to_non_nullable
              as int,
      mana: null == mana
          ? _value.mana
          : mana // ignore: cast_nullable_to_non_nullable
              as int,
      maxMana: null == maxMana
          ? _value.maxMana
          : maxMana // ignore: cast_nullable_to_non_nullable
              as int,
      stats: null == stats
          ? _value.stats
          : stats // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      gold: null == gold
          ? _value.gold
          : gold // ignore: cast_nullable_to_non_nullable
              as int,
      equippedItems: null == equippedItems
          ? _value.equippedItems
          : equippedItems // ignore: cast_nullable_to_non_nullable
              as List<String>,
      wounds: null == wounds
          ? _value.wounds
          : wounds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      activeConditions: null == activeConditions
          ? _value.activeConditions
          : activeConditions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      skillLevels: null == skillLevels
          ? _value.skillLevels
          : skillLevels // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      experience: null == experience
          ? _value.experience
          : experience // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      passiveTraits: null == passiveTraits
          ? _value.passiveTraits
          : passiveTraits // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerCharacterImplCopyWith<$Res>
    implements $PlayerCharacterCopyWith<$Res> {
  factory _$$PlayerCharacterImplCopyWith(_$PlayerCharacterImpl value,
          $Res Function(_$PlayerCharacterImpl) then) =
      __$$PlayerCharacterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String archetype,
      String background,
      String pronouns,
      int healthPoints,
      int maxHealthPoints,
      int stamina,
      int maxStamina,
      int mana,
      int maxMana,
      Map<String, int> stats,
      int gold,
      List<String> equippedItems,
      List<String> wounds,
      List<String> activeConditions,
      Map<String, int> skillLevels,
      int experience,
      int level,
      List<String> passiveTraits});
}

/// @nodoc
class __$$PlayerCharacterImplCopyWithImpl<$Res>
    extends _$PlayerCharacterCopyWithImpl<$Res, _$PlayerCharacterImpl>
    implements _$$PlayerCharacterImplCopyWith<$Res> {
  __$$PlayerCharacterImplCopyWithImpl(
      _$PlayerCharacterImpl _value, $Res Function(_$PlayerCharacterImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerCharacter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? archetype = null,
    Object? background = null,
    Object? pronouns = null,
    Object? healthPoints = null,
    Object? maxHealthPoints = null,
    Object? stamina = null,
    Object? maxStamina = null,
    Object? mana = null,
    Object? maxMana = null,
    Object? stats = null,
    Object? gold = null,
    Object? equippedItems = null,
    Object? wounds = null,
    Object? activeConditions = null,
    Object? skillLevels = null,
    Object? experience = null,
    Object? level = null,
    Object? passiveTraits = null,
  }) {
    return _then(_$PlayerCharacterImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      archetype: null == archetype
          ? _value.archetype
          : archetype // ignore: cast_nullable_to_non_nullable
              as String,
      background: null == background
          ? _value.background
          : background // ignore: cast_nullable_to_non_nullable
              as String,
      pronouns: null == pronouns
          ? _value.pronouns
          : pronouns // ignore: cast_nullable_to_non_nullable
              as String,
      healthPoints: null == healthPoints
          ? _value.healthPoints
          : healthPoints // ignore: cast_nullable_to_non_nullable
              as int,
      maxHealthPoints: null == maxHealthPoints
          ? _value.maxHealthPoints
          : maxHealthPoints // ignore: cast_nullable_to_non_nullable
              as int,
      stamina: null == stamina
          ? _value.stamina
          : stamina // ignore: cast_nullable_to_non_nullable
              as int,
      maxStamina: null == maxStamina
          ? _value.maxStamina
          : maxStamina // ignore: cast_nullable_to_non_nullable
              as int,
      mana: null == mana
          ? _value.mana
          : mana // ignore: cast_nullable_to_non_nullable
              as int,
      maxMana: null == maxMana
          ? _value.maxMana
          : maxMana // ignore: cast_nullable_to_non_nullable
              as int,
      stats: null == stats
          ? _value._stats
          : stats // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      gold: null == gold
          ? _value.gold
          : gold // ignore: cast_nullable_to_non_nullable
              as int,
      equippedItems: null == equippedItems
          ? _value._equippedItems
          : equippedItems // ignore: cast_nullable_to_non_nullable
              as List<String>,
      wounds: null == wounds
          ? _value._wounds
          : wounds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      activeConditions: null == activeConditions
          ? _value._activeConditions
          : activeConditions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      skillLevels: null == skillLevels
          ? _value._skillLevels
          : skillLevels // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      experience: null == experience
          ? _value.experience
          : experience // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      passiveTraits: null == passiveTraits
          ? _value._passiveTraits
          : passiveTraits // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerCharacterImpl implements _PlayerCharacter {
  const _$PlayerCharacterImpl(
      {required this.id,
      required this.name,
      required this.archetype,
      required this.background,
      required this.pronouns,
      required this.healthPoints,
      required this.maxHealthPoints,
      required this.stamina,
      required this.maxStamina,
      required this.mana,
      required this.maxMana,
      required final Map<String, int> stats,
      required this.gold,
      required final List<String> equippedItems,
      required final List<String> wounds,
      required final List<String> activeConditions,
      required final Map<String, int> skillLevels,
      required this.experience,
      required this.level,
      final List<String> passiveTraits = const []})
      : _stats = stats,
        _equippedItems = equippedItems,
        _wounds = wounds,
        _activeConditions = activeConditions,
        _skillLevels = skillLevels,
        _passiveTraits = passiveTraits;

  factory _$PlayerCharacterImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerCharacterImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String archetype;
  @override
  final String background;
  @override
  final String pronouns;
  @override
  final int healthPoints;
  @override
  final int maxHealthPoints;
  @override
  final int stamina;
  @override
  final int maxStamina;
  @override
  final int mana;
  @override
  final int maxMana;
  final Map<String, int> _stats;
  @override
  Map<String, int> get stats {
    if (_stats is EqualUnmodifiableMapView) return _stats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_stats);
  }

// str, agi, willpower, presence, intellect
  @override
  final int gold;
  final List<String> _equippedItems;
  @override
  List<String> get equippedItems {
    if (_equippedItems is EqualUnmodifiableListView) return _equippedItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_equippedItems);
  }

  final List<String> _wounds;
  @override
  List<String> get wounds {
    if (_wounds is EqualUnmodifiableListView) return _wounds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_wounds);
  }

  final List<String> _activeConditions;
  @override
  List<String> get activeConditions {
    if (_activeConditions is EqualUnmodifiableListView)
      return _activeConditions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activeConditions);
  }

  final Map<String, int> _skillLevels;
  @override
  Map<String, int> get skillLevels {
    if (_skillLevels is EqualUnmodifiableMapView) return _skillLevels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_skillLevels);
  }

  @override
  final int experience;
  @override
  final int level;
  final List<String> _passiveTraits;
  @override
  @JsonKey()
  List<String> get passiveTraits {
    if (_passiveTraits is EqualUnmodifiableListView) return _passiveTraits;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_passiveTraits);
  }

  @override
  String toString() {
    return 'PlayerCharacter(id: $id, name: $name, archetype: $archetype, background: $background, pronouns: $pronouns, healthPoints: $healthPoints, maxHealthPoints: $maxHealthPoints, stamina: $stamina, maxStamina: $maxStamina, mana: $mana, maxMana: $maxMana, stats: $stats, gold: $gold, equippedItems: $equippedItems, wounds: $wounds, activeConditions: $activeConditions, skillLevels: $skillLevels, experience: $experience, level: $level, passiveTraits: $passiveTraits)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerCharacterImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.archetype, archetype) ||
                other.archetype == archetype) &&
            (identical(other.background, background) ||
                other.background == background) &&
            (identical(other.pronouns, pronouns) ||
                other.pronouns == pronouns) &&
            (identical(other.healthPoints, healthPoints) ||
                other.healthPoints == healthPoints) &&
            (identical(other.maxHealthPoints, maxHealthPoints) ||
                other.maxHealthPoints == maxHealthPoints) &&
            (identical(other.stamina, stamina) || other.stamina == stamina) &&
            (identical(other.maxStamina, maxStamina) ||
                other.maxStamina == maxStamina) &&
            (identical(other.mana, mana) || other.mana == mana) &&
            (identical(other.maxMana, maxMana) || other.maxMana == maxMana) &&
            const DeepCollectionEquality().equals(other._stats, _stats) &&
            (identical(other.gold, gold) || other.gold == gold) &&
            const DeepCollectionEquality()
                .equals(other._equippedItems, _equippedItems) &&
            const DeepCollectionEquality().equals(other._wounds, _wounds) &&
            const DeepCollectionEquality()
                .equals(other._activeConditions, _activeConditions) &&
            const DeepCollectionEquality()
                .equals(other._skillLevels, _skillLevels) &&
            (identical(other.experience, experience) ||
                other.experience == experience) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality()
                .equals(other._passiveTraits, _passiveTraits));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        archetype,
        background,
        pronouns,
        healthPoints,
        maxHealthPoints,
        stamina,
        maxStamina,
        mana,
        maxMana,
        const DeepCollectionEquality().hash(_stats),
        gold,
        const DeepCollectionEquality().hash(_equippedItems),
        const DeepCollectionEquality().hash(_wounds),
        const DeepCollectionEquality().hash(_activeConditions),
        const DeepCollectionEquality().hash(_skillLevels),
        experience,
        level,
        const DeepCollectionEquality().hash(_passiveTraits)
      ]);

  /// Create a copy of PlayerCharacter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerCharacterImplCopyWith<_$PlayerCharacterImpl> get copyWith =>
      __$$PlayerCharacterImplCopyWithImpl<_$PlayerCharacterImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerCharacterImplToJson(
      this,
    );
  }
}

abstract class _PlayerCharacter implements PlayerCharacter {
  const factory _PlayerCharacter(
      {required final String id,
      required final String name,
      required final String archetype,
      required final String background,
      required final String pronouns,
      required final int healthPoints,
      required final int maxHealthPoints,
      required final int stamina,
      required final int maxStamina,
      required final int mana,
      required final int maxMana,
      required final Map<String, int> stats,
      required final int gold,
      required final List<String> equippedItems,
      required final List<String> wounds,
      required final List<String> activeConditions,
      required final Map<String, int> skillLevels,
      required final int experience,
      required final int level,
      final List<String> passiveTraits}) = _$PlayerCharacterImpl;

  factory _PlayerCharacter.fromJson(Map<String, dynamic> json) =
      _$PlayerCharacterImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get archetype;
  @override
  String get background;
  @override
  String get pronouns;
  @override
  int get healthPoints;
  @override
  int get maxHealthPoints;
  @override
  int get stamina;
  @override
  int get maxStamina;
  @override
  int get mana;
  @override
  int get maxMana;
  @override
  Map<String, int> get stats; // str, agi, willpower, presence, intellect
  @override
  int get gold;
  @override
  List<String> get equippedItems;
  @override
  List<String> get wounds;
  @override
  List<String> get activeConditions;
  @override
  Map<String, int> get skillLevels;
  @override
  int get experience;
  @override
  int get level;
  @override
  List<String> get passiveTraits;

  /// Create a copy of PlayerCharacter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerCharacterImplCopyWith<_$PlayerCharacterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Quest _$QuestFromJson(Map<String, dynamic> json) {
  return _Quest.fromJson(json);
}

/// @nodoc
mixin _$Quest {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // active, completed, failed, hidden
  String get questType =>
      throw _privateConstructorUsedError; // main, side, hidden
  String get location => throw _privateConstructorUsedError;
  List<String> get objectives => throw _privateConstructorUsedError;
  int get currentObjectiveIndex => throw _privateConstructorUsedError;
  List<String> get rewardItems => throw _privateConstructorUsedError;
  int get rewardGold => throw _privateConstructorUsedError;
  int get rewardExperience => throw _privateConstructorUsedError;
  int get timeLimit => throw _privateConstructorUsedError;
  List<String> get relatedNPCs => throw _privateConstructorUsedError;

  /// Serializes this Quest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Quest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuestCopyWith<Quest> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestCopyWith<$Res> {
  factory $QuestCopyWith(Quest value, $Res Function(Quest) then) =
      _$QuestCopyWithImpl<$Res, Quest>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String status,
      String questType,
      String location,
      List<String> objectives,
      int currentObjectiveIndex,
      List<String> rewardItems,
      int rewardGold,
      int rewardExperience,
      int timeLimit,
      List<String> relatedNPCs});
}

/// @nodoc
class _$QuestCopyWithImpl<$Res, $Val extends Quest>
    implements $QuestCopyWith<$Res> {
  _$QuestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Quest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? status = null,
    Object? questType = null,
    Object? location = null,
    Object? objectives = null,
    Object? currentObjectiveIndex = null,
    Object? rewardItems = null,
    Object? rewardGold = null,
    Object? rewardExperience = null,
    Object? timeLimit = null,
    Object? relatedNPCs = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      questType: null == questType
          ? _value.questType
          : questType // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      objectives: null == objectives
          ? _value.objectives
          : objectives // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentObjectiveIndex: null == currentObjectiveIndex
          ? _value.currentObjectiveIndex
          : currentObjectiveIndex // ignore: cast_nullable_to_non_nullable
              as int,
      rewardItems: null == rewardItems
          ? _value.rewardItems
          : rewardItems // ignore: cast_nullable_to_non_nullable
              as List<String>,
      rewardGold: null == rewardGold
          ? _value.rewardGold
          : rewardGold // ignore: cast_nullable_to_non_nullable
              as int,
      rewardExperience: null == rewardExperience
          ? _value.rewardExperience
          : rewardExperience // ignore: cast_nullable_to_non_nullable
              as int,
      timeLimit: null == timeLimit
          ? _value.timeLimit
          : timeLimit // ignore: cast_nullable_to_non_nullable
              as int,
      relatedNPCs: null == relatedNPCs
          ? _value.relatedNPCs
          : relatedNPCs // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuestImplCopyWith<$Res> implements $QuestCopyWith<$Res> {
  factory _$$QuestImplCopyWith(
          _$QuestImpl value, $Res Function(_$QuestImpl) then) =
      __$$QuestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String status,
      String questType,
      String location,
      List<String> objectives,
      int currentObjectiveIndex,
      List<String> rewardItems,
      int rewardGold,
      int rewardExperience,
      int timeLimit,
      List<String> relatedNPCs});
}

/// @nodoc
class __$$QuestImplCopyWithImpl<$Res>
    extends _$QuestCopyWithImpl<$Res, _$QuestImpl>
    implements _$$QuestImplCopyWith<$Res> {
  __$$QuestImplCopyWithImpl(
      _$QuestImpl _value, $Res Function(_$QuestImpl) _then)
      : super(_value, _then);

  /// Create a copy of Quest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? status = null,
    Object? questType = null,
    Object? location = null,
    Object? objectives = null,
    Object? currentObjectiveIndex = null,
    Object? rewardItems = null,
    Object? rewardGold = null,
    Object? rewardExperience = null,
    Object? timeLimit = null,
    Object? relatedNPCs = null,
  }) {
    return _then(_$QuestImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      questType: null == questType
          ? _value.questType
          : questType // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      objectives: null == objectives
          ? _value._objectives
          : objectives // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentObjectiveIndex: null == currentObjectiveIndex
          ? _value.currentObjectiveIndex
          : currentObjectiveIndex // ignore: cast_nullable_to_non_nullable
              as int,
      rewardItems: null == rewardItems
          ? _value._rewardItems
          : rewardItems // ignore: cast_nullable_to_non_nullable
              as List<String>,
      rewardGold: null == rewardGold
          ? _value.rewardGold
          : rewardGold // ignore: cast_nullable_to_non_nullable
              as int,
      rewardExperience: null == rewardExperience
          ? _value.rewardExperience
          : rewardExperience // ignore: cast_nullable_to_non_nullable
              as int,
      timeLimit: null == timeLimit
          ? _value.timeLimit
          : timeLimit // ignore: cast_nullable_to_non_nullable
              as int,
      relatedNPCs: null == relatedNPCs
          ? _value._relatedNPCs
          : relatedNPCs // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestImpl implements _Quest {
  const _$QuestImpl(
      {required this.id,
      required this.title,
      required this.description,
      required this.status,
      required this.questType,
      required this.location,
      required final List<String> objectives,
      required this.currentObjectiveIndex,
      required final List<String> rewardItems,
      required this.rewardGold,
      required this.rewardExperience,
      this.timeLimit = 0,
      final List<String> relatedNPCs = const []})
      : _objectives = objectives,
        _rewardItems = rewardItems,
        _relatedNPCs = relatedNPCs;

  factory _$QuestImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String status;
// active, completed, failed, hidden
  @override
  final String questType;
// main, side, hidden
  @override
  final String location;
  final List<String> _objectives;
  @override
  List<String> get objectives {
    if (_objectives is EqualUnmodifiableListView) return _objectives;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_objectives);
  }

  @override
  final int currentObjectiveIndex;
  final List<String> _rewardItems;
  @override
  List<String> get rewardItems {
    if (_rewardItems is EqualUnmodifiableListView) return _rewardItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rewardItems);
  }

  @override
  final int rewardGold;
  @override
  final int rewardExperience;
  @override
  @JsonKey()
  final int timeLimit;
  final List<String> _relatedNPCs;
  @override
  @JsonKey()
  List<String> get relatedNPCs {
    if (_relatedNPCs is EqualUnmodifiableListView) return _relatedNPCs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_relatedNPCs);
  }

  @override
  String toString() {
    return 'Quest(id: $id, title: $title, description: $description, status: $status, questType: $questType, location: $location, objectives: $objectives, currentObjectiveIndex: $currentObjectiveIndex, rewardItems: $rewardItems, rewardGold: $rewardGold, rewardExperience: $rewardExperience, timeLimit: $timeLimit, relatedNPCs: $relatedNPCs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.questType, questType) ||
                other.questType == questType) &&
            (identical(other.location, location) ||
                other.location == location) &&
            const DeepCollectionEquality()
                .equals(other._objectives, _objectives) &&
            (identical(other.currentObjectiveIndex, currentObjectiveIndex) ||
                other.currentObjectiveIndex == currentObjectiveIndex) &&
            const DeepCollectionEquality()
                .equals(other._rewardItems, _rewardItems) &&
            (identical(other.rewardGold, rewardGold) ||
                other.rewardGold == rewardGold) &&
            (identical(other.rewardExperience, rewardExperience) ||
                other.rewardExperience == rewardExperience) &&
            (identical(other.timeLimit, timeLimit) ||
                other.timeLimit == timeLimit) &&
            const DeepCollectionEquality()
                .equals(other._relatedNPCs, _relatedNPCs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      status,
      questType,
      location,
      const DeepCollectionEquality().hash(_objectives),
      currentObjectiveIndex,
      const DeepCollectionEquality().hash(_rewardItems),
      rewardGold,
      rewardExperience,
      timeLimit,
      const DeepCollectionEquality().hash(_relatedNPCs));

  /// Create a copy of Quest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestImplCopyWith<_$QuestImpl> get copyWith =>
      __$$QuestImplCopyWithImpl<_$QuestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestImplToJson(
      this,
    );
  }
}

abstract class _Quest implements Quest {
  const factory _Quest(
      {required final String id,
      required final String title,
      required final String description,
      required final String status,
      required final String questType,
      required final String location,
      required final List<String> objectives,
      required final int currentObjectiveIndex,
      required final List<String> rewardItems,
      required final int rewardGold,
      required final int rewardExperience,
      final int timeLimit,
      final List<String> relatedNPCs}) = _$QuestImpl;

  factory _Quest.fromJson(Map<String, dynamic> json) = _$QuestImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  String get status; // active, completed, failed, hidden
  @override
  String get questType; // main, side, hidden
  @override
  String get location;
  @override
  List<String> get objectives;
  @override
  int get currentObjectiveIndex;
  @override
  List<String> get rewardItems;
  @override
  int get rewardGold;
  @override
  int get rewardExperience;
  @override
  int get timeLimit;
  @override
  List<String> get relatedNPCs;

  /// Create a copy of Quest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuestImplCopyWith<_$QuestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InventoryItem _$InventoryItemFromJson(Map<String, dynamic> json) {
  return _InventoryItem.fromJson(json);
}

/// @nodoc
mixin _$InventoryItem {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get itemType =>
      throw _privateConstructorUsedError; // weapon, armor, consumable, quest, material, relic
  String get rarity =>
      throw _privateConstructorUsedError; // common, uncommon, rare, legendary, mythic
  int get quantity => throw _privateConstructorUsedError;
  int get weight => throw _privateConstructorUsedError;
  Map<String, dynamic> get effects => throw _privateConstructorUsedError;

  /// Serializes this InventoryItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InventoryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InventoryItemCopyWith<InventoryItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InventoryItemCopyWith<$Res> {
  factory $InventoryItemCopyWith(
          InventoryItem value, $Res Function(InventoryItem) then) =
      _$InventoryItemCopyWithImpl<$Res, InventoryItem>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      String itemType,
      String rarity,
      int quantity,
      int weight,
      Map<String, dynamic> effects});
}

/// @nodoc
class _$InventoryItemCopyWithImpl<$Res, $Val extends InventoryItem>
    implements $InventoryItemCopyWith<$Res> {
  _$InventoryItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InventoryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? itemType = null,
    Object? rarity = null,
    Object? quantity = null,
    Object? weight = null,
    Object? effects = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      itemType: null == itemType
          ? _value.itemType
          : itemType // ignore: cast_nullable_to_non_nullable
              as String,
      rarity: null == rarity
          ? _value.rarity
          : rarity // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
      effects: null == effects
          ? _value.effects
          : effects // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InventoryItemImplCopyWith<$Res>
    implements $InventoryItemCopyWith<$Res> {
  factory _$$InventoryItemImplCopyWith(
          _$InventoryItemImpl value, $Res Function(_$InventoryItemImpl) then) =
      __$$InventoryItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      String itemType,
      String rarity,
      int quantity,
      int weight,
      Map<String, dynamic> effects});
}

/// @nodoc
class __$$InventoryItemImplCopyWithImpl<$Res>
    extends _$InventoryItemCopyWithImpl<$Res, _$InventoryItemImpl>
    implements _$$InventoryItemImplCopyWith<$Res> {
  __$$InventoryItemImplCopyWithImpl(
      _$InventoryItemImpl _value, $Res Function(_$InventoryItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of InventoryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? itemType = null,
    Object? rarity = null,
    Object? quantity = null,
    Object? weight = null,
    Object? effects = null,
  }) {
    return _then(_$InventoryItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      itemType: null == itemType
          ? _value.itemType
          : itemType // ignore: cast_nullable_to_non_nullable
              as String,
      rarity: null == rarity
          ? _value.rarity
          : rarity // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
      effects: null == effects
          ? _value._effects
          : effects // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InventoryItemImpl implements _InventoryItem {
  const _$InventoryItemImpl(
      {required this.id,
      required this.name,
      required this.description,
      required this.itemType,
      required this.rarity,
      required this.quantity,
      this.weight = 0,
      final Map<String, dynamic> effects = const {}})
      : _effects = effects;

  factory _$InventoryItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$InventoryItemImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String itemType;
// weapon, armor, consumable, quest, material, relic
  @override
  final String rarity;
// common, uncommon, rare, legendary, mythic
  @override
  final int quantity;
  @override
  @JsonKey()
  final int weight;
  final Map<String, dynamic> _effects;
  @override
  @JsonKey()
  Map<String, dynamic> get effects {
    if (_effects is EqualUnmodifiableMapView) return _effects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_effects);
  }

  @override
  String toString() {
    return 'InventoryItem(id: $id, name: $name, description: $description, itemType: $itemType, rarity: $rarity, quantity: $quantity, weight: $weight, effects: $effects)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InventoryItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.itemType, itemType) ||
                other.itemType == itemType) &&
            (identical(other.rarity, rarity) || other.rarity == rarity) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            const DeepCollectionEquality().equals(other._effects, _effects));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description, itemType,
      rarity, quantity, weight, const DeepCollectionEquality().hash(_effects));

  /// Create a copy of InventoryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InventoryItemImplCopyWith<_$InventoryItemImpl> get copyWith =>
      __$$InventoryItemImplCopyWithImpl<_$InventoryItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InventoryItemImplToJson(
      this,
    );
  }
}

abstract class _InventoryItem implements InventoryItem {
  const factory _InventoryItem(
      {required final String id,
      required final String name,
      required final String description,
      required final String itemType,
      required final String rarity,
      required final int quantity,
      final int weight,
      final Map<String, dynamic> effects}) = _$InventoryItemImpl;

  factory _InventoryItem.fromJson(Map<String, dynamic> json) =
      _$InventoryItemImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  String get itemType; // weapon, armor, consumable, quest, material, relic
  @override
  String get rarity; // common, uncommon, rare, legendary, mythic
  @override
  int get quantity;
  @override
  int get weight;
  @override
  Map<String, dynamic> get effects;

  /// Create a copy of InventoryItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InventoryItemImplCopyWith<_$InventoryItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CodexEntry _$CodexEntryFromJson(Map<String, dynamic> json) {
  return _CodexEntry.fromJson(json);
}

/// @nodoc
mixin _$CodexEntry {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get category =>
      throw _privateConstructorUsedError; // location, npc, creature, faction, relic, history, clue
  String get content => throw _privateConstructorUsedError;
  bool get discovered => throw _privateConstructorUsedError;
  String get relatedId => throw _privateConstructorUsedError;
  int get discoveredAtRevision => throw _privateConstructorUsedError;

  /// Serializes this CodexEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CodexEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CodexEntryCopyWith<CodexEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CodexEntryCopyWith<$Res> {
  factory $CodexEntryCopyWith(
          CodexEntry value, $Res Function(CodexEntry) then) =
      _$CodexEntryCopyWithImpl<$Res, CodexEntry>;
  @useResult
  $Res call(
      {String id,
      String title,
      String category,
      String content,
      bool discovered,
      String relatedId,
      int discoveredAtRevision});
}

/// @nodoc
class _$CodexEntryCopyWithImpl<$Res, $Val extends CodexEntry>
    implements $CodexEntryCopyWith<$Res> {
  _$CodexEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CodexEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? category = null,
    Object? content = null,
    Object? discovered = null,
    Object? relatedId = null,
    Object? discoveredAtRevision = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      discovered: null == discovered
          ? _value.discovered
          : discovered // ignore: cast_nullable_to_non_nullable
              as bool,
      relatedId: null == relatedId
          ? _value.relatedId
          : relatedId // ignore: cast_nullable_to_non_nullable
              as String,
      discoveredAtRevision: null == discoveredAtRevision
          ? _value.discoveredAtRevision
          : discoveredAtRevision // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CodexEntryImplCopyWith<$Res>
    implements $CodexEntryCopyWith<$Res> {
  factory _$$CodexEntryImplCopyWith(
          _$CodexEntryImpl value, $Res Function(_$CodexEntryImpl) then) =
      __$$CodexEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String category,
      String content,
      bool discovered,
      String relatedId,
      int discoveredAtRevision});
}

/// @nodoc
class __$$CodexEntryImplCopyWithImpl<$Res>
    extends _$CodexEntryCopyWithImpl<$Res, _$CodexEntryImpl>
    implements _$$CodexEntryImplCopyWith<$Res> {
  __$$CodexEntryImplCopyWithImpl(
      _$CodexEntryImpl _value, $Res Function(_$CodexEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of CodexEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? category = null,
    Object? content = null,
    Object? discovered = null,
    Object? relatedId = null,
    Object? discoveredAtRevision = null,
  }) {
    return _then(_$CodexEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      discovered: null == discovered
          ? _value.discovered
          : discovered // ignore: cast_nullable_to_non_nullable
              as bool,
      relatedId: null == relatedId
          ? _value.relatedId
          : relatedId // ignore: cast_nullable_to_non_nullable
              as String,
      discoveredAtRevision: null == discoveredAtRevision
          ? _value.discoveredAtRevision
          : discoveredAtRevision // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CodexEntryImpl implements _CodexEntry {
  const _$CodexEntryImpl(
      {required this.id,
      required this.title,
      required this.category,
      required this.content,
      required this.discovered,
      this.relatedId = '',
      this.discoveredAtRevision = 0});

  factory _$CodexEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CodexEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String category;
// location, npc, creature, faction, relic, history, clue
  @override
  final String content;
  @override
  final bool discovered;
  @override
  @JsonKey()
  final String relatedId;
  @override
  @JsonKey()
  final int discoveredAtRevision;

  @override
  String toString() {
    return 'CodexEntry(id: $id, title: $title, category: $category, content: $content, discovered: $discovered, relatedId: $relatedId, discoveredAtRevision: $discoveredAtRevision)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CodexEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.discovered, discovered) ||
                other.discovered == discovered) &&
            (identical(other.relatedId, relatedId) ||
                other.relatedId == relatedId) &&
            (identical(other.discoveredAtRevision, discoveredAtRevision) ||
                other.discoveredAtRevision == discoveredAtRevision));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, category, content,
      discovered, relatedId, discoveredAtRevision);

  /// Create a copy of CodexEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CodexEntryImplCopyWith<_$CodexEntryImpl> get copyWith =>
      __$$CodexEntryImplCopyWithImpl<_$CodexEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CodexEntryImplToJson(
      this,
    );
  }
}

abstract class _CodexEntry implements CodexEntry {
  const factory _CodexEntry(
      {required final String id,
      required final String title,
      required final String category,
      required final String content,
      required final bool discovered,
      final String relatedId,
      final int discoveredAtRevision}) = _$CodexEntryImpl;

  factory _CodexEntry.fromJson(Map<String, dynamic> json) =
      _$CodexEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get category; // location, npc, creature, faction, relic, history, clue
  @override
  String get content;
  @override
  bool get discovered;
  @override
  String get relatedId;
  @override
  int get discoveredAtRevision;

  /// Create a copy of CodexEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CodexEntryImplCopyWith<_$CodexEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Faction _$FactionFromJson(Map<String, dynamic> json) {
  return _Faction.fromJson(json);
}

/// @nodoc
mixin _$Faction {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get standing => throw _privateConstructorUsedError; // -100 to 100
  String get tier =>
      throw _privateConstructorUsedError; // hostile, unfriendly, neutral, friendly, allied
  String get banner => throw _privateConstructorUsedError;
  String get controlledArea => throw _privateConstructorUsedError;
  List<String> get knownActions => throw _privateConstructorUsedError;

  /// Serializes this Faction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Faction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FactionCopyWith<Faction> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FactionCopyWith<$Res> {
  factory $FactionCopyWith(Faction value, $Res Function(Faction) then) =
      _$FactionCopyWithImpl<$Res, Faction>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      int standing,
      String tier,
      String banner,
      String controlledArea,
      List<String> knownActions});
}

/// @nodoc
class _$FactionCopyWithImpl<$Res, $Val extends Faction>
    implements $FactionCopyWith<$Res> {
  _$FactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Faction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? standing = null,
    Object? tier = null,
    Object? banner = null,
    Object? controlledArea = null,
    Object? knownActions = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      standing: null == standing
          ? _value.standing
          : standing // ignore: cast_nullable_to_non_nullable
              as int,
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as String,
      banner: null == banner
          ? _value.banner
          : banner // ignore: cast_nullable_to_non_nullable
              as String,
      controlledArea: null == controlledArea
          ? _value.controlledArea
          : controlledArea // ignore: cast_nullable_to_non_nullable
              as String,
      knownActions: null == knownActions
          ? _value.knownActions
          : knownActions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FactionImplCopyWith<$Res> implements $FactionCopyWith<$Res> {
  factory _$$FactionImplCopyWith(
          _$FactionImpl value, $Res Function(_$FactionImpl) then) =
      __$$FactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      int standing,
      String tier,
      String banner,
      String controlledArea,
      List<String> knownActions});
}

/// @nodoc
class __$$FactionImplCopyWithImpl<$Res>
    extends _$FactionCopyWithImpl<$Res, _$FactionImpl>
    implements _$$FactionImplCopyWith<$Res> {
  __$$FactionImplCopyWithImpl(
      _$FactionImpl _value, $Res Function(_$FactionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Faction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? standing = null,
    Object? tier = null,
    Object? banner = null,
    Object? controlledArea = null,
    Object? knownActions = null,
  }) {
    return _then(_$FactionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      standing: null == standing
          ? _value.standing
          : standing // ignore: cast_nullable_to_non_nullable
              as int,
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as String,
      banner: null == banner
          ? _value.banner
          : banner // ignore: cast_nullable_to_non_nullable
              as String,
      controlledArea: null == controlledArea
          ? _value.controlledArea
          : controlledArea // ignore: cast_nullable_to_non_nullable
              as String,
      knownActions: null == knownActions
          ? _value._knownActions
          : knownActions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FactionImpl implements _Faction {
  const _$FactionImpl(
      {required this.id,
      required this.name,
      required this.description,
      required this.standing,
      required this.tier,
      this.banner = '',
      this.controlledArea = '',
      final List<String> knownActions = const []})
      : _knownActions = knownActions;

  factory _$FactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$FactionImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final int standing;
// -100 to 100
  @override
  final String tier;
// hostile, unfriendly, neutral, friendly, allied
  @override
  @JsonKey()
  final String banner;
  @override
  @JsonKey()
  final String controlledArea;
  final List<String> _knownActions;
  @override
  @JsonKey()
  List<String> get knownActions {
    if (_knownActions is EqualUnmodifiableListView) return _knownActions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_knownActions);
  }

  @override
  String toString() {
    return 'Faction(id: $id, name: $name, description: $description, standing: $standing, tier: $tier, banner: $banner, controlledArea: $controlledArea, knownActions: $knownActions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.standing, standing) ||
                other.standing == standing) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.banner, banner) || other.banner == banner) &&
            (identical(other.controlledArea, controlledArea) ||
                other.controlledArea == controlledArea) &&
            const DeepCollectionEquality()
                .equals(other._knownActions, _knownActions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      standing,
      tier,
      banner,
      controlledArea,
      const DeepCollectionEquality().hash(_knownActions));

  /// Create a copy of Faction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FactionImplCopyWith<_$FactionImpl> get copyWith =>
      __$$FactionImplCopyWithImpl<_$FactionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FactionImplToJson(
      this,
    );
  }
}

abstract class _Faction implements Faction {
  const factory _Faction(
      {required final String id,
      required final String name,
      required final String description,
      required final int standing,
      required final String tier,
      final String banner,
      final String controlledArea,
      final List<String> knownActions}) = _$FactionImpl;

  factory _Faction.fromJson(Map<String, dynamic> json) = _$FactionImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  int get standing; // -100 to 100
  @override
  String get tier; // hostile, unfriendly, neutral, friendly, allied
  @override
  String get banner;
  @override
  String get controlledArea;
  @override
  List<String> get knownActions;

  /// Create a copy of Faction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FactionImplCopyWith<_$FactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Relationship _$RelationshipFromJson(Map<String, dynamic> json) {
  return _Relationship.fromJson(json);
}

/// @nodoc
mixin _$Relationship {
  String get npcId => throw _privateConstructorUsedError;
  String get npcName => throw _privateConstructorUsedError;
  String get role =>
      throw _privateConstructorUsedError; // ally, rival, mentor, love, enemy, neutral
  int get trustScore => throw _privateConstructorUsedError; // -100 to 100
  int get suspicion => throw _privateConstructorUsedError; // 0 to 100
  int get loyalty => throw _privateConstructorUsedError; // -100 to 100
  int get fearLevel => throw _privateConstructorUsedError; // 0 to 100
  String get lastInteraction => throw _privateConstructorUsedError;

  /// Serializes this Relationship to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Relationship
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RelationshipCopyWith<Relationship> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RelationshipCopyWith<$Res> {
  factory $RelationshipCopyWith(
          Relationship value, $Res Function(Relationship) then) =
      _$RelationshipCopyWithImpl<$Res, Relationship>;
  @useResult
  $Res call(
      {String npcId,
      String npcName,
      String role,
      int trustScore,
      int suspicion,
      int loyalty,
      int fearLevel,
      String lastInteraction});
}

/// @nodoc
class _$RelationshipCopyWithImpl<$Res, $Val extends Relationship>
    implements $RelationshipCopyWith<$Res> {
  _$RelationshipCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Relationship
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? npcId = null,
    Object? npcName = null,
    Object? role = null,
    Object? trustScore = null,
    Object? suspicion = null,
    Object? loyalty = null,
    Object? fearLevel = null,
    Object? lastInteraction = null,
  }) {
    return _then(_value.copyWith(
      npcId: null == npcId
          ? _value.npcId
          : npcId // ignore: cast_nullable_to_non_nullable
              as String,
      npcName: null == npcName
          ? _value.npcName
          : npcName // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      trustScore: null == trustScore
          ? _value.trustScore
          : trustScore // ignore: cast_nullable_to_non_nullable
              as int,
      suspicion: null == suspicion
          ? _value.suspicion
          : suspicion // ignore: cast_nullable_to_non_nullable
              as int,
      loyalty: null == loyalty
          ? _value.loyalty
          : loyalty // ignore: cast_nullable_to_non_nullable
              as int,
      fearLevel: null == fearLevel
          ? _value.fearLevel
          : fearLevel // ignore: cast_nullable_to_non_nullable
              as int,
      lastInteraction: null == lastInteraction
          ? _value.lastInteraction
          : lastInteraction // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RelationshipImplCopyWith<$Res>
    implements $RelationshipCopyWith<$Res> {
  factory _$$RelationshipImplCopyWith(
          _$RelationshipImpl value, $Res Function(_$RelationshipImpl) then) =
      __$$RelationshipImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String npcId,
      String npcName,
      String role,
      int trustScore,
      int suspicion,
      int loyalty,
      int fearLevel,
      String lastInteraction});
}

/// @nodoc
class __$$RelationshipImplCopyWithImpl<$Res>
    extends _$RelationshipCopyWithImpl<$Res, _$RelationshipImpl>
    implements _$$RelationshipImplCopyWith<$Res> {
  __$$RelationshipImplCopyWithImpl(
      _$RelationshipImpl _value, $Res Function(_$RelationshipImpl) _then)
      : super(_value, _then);

  /// Create a copy of Relationship
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? npcId = null,
    Object? npcName = null,
    Object? role = null,
    Object? trustScore = null,
    Object? suspicion = null,
    Object? loyalty = null,
    Object? fearLevel = null,
    Object? lastInteraction = null,
  }) {
    return _then(_$RelationshipImpl(
      npcId: null == npcId
          ? _value.npcId
          : npcId // ignore: cast_nullable_to_non_nullable
              as String,
      npcName: null == npcName
          ? _value.npcName
          : npcName // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      trustScore: null == trustScore
          ? _value.trustScore
          : trustScore // ignore: cast_nullable_to_non_nullable
              as int,
      suspicion: null == suspicion
          ? _value.suspicion
          : suspicion // ignore: cast_nullable_to_non_nullable
              as int,
      loyalty: null == loyalty
          ? _value.loyalty
          : loyalty // ignore: cast_nullable_to_non_nullable
              as int,
      fearLevel: null == fearLevel
          ? _value.fearLevel
          : fearLevel // ignore: cast_nullable_to_non_nullable
              as int,
      lastInteraction: null == lastInteraction
          ? _value.lastInteraction
          : lastInteraction // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RelationshipImpl implements _Relationship {
  const _$RelationshipImpl(
      {required this.npcId,
      required this.npcName,
      required this.role,
      required this.trustScore,
      required this.suspicion,
      required this.loyalty,
      required this.fearLevel,
      this.lastInteraction = ''});

  factory _$RelationshipImpl.fromJson(Map<String, dynamic> json) =>
      _$$RelationshipImplFromJson(json);

  @override
  final String npcId;
  @override
  final String npcName;
  @override
  final String role;
// ally, rival, mentor, love, enemy, neutral
  @override
  final int trustScore;
// -100 to 100
  @override
  final int suspicion;
// 0 to 100
  @override
  final int loyalty;
// -100 to 100
  @override
  final int fearLevel;
// 0 to 100
  @override
  @JsonKey()
  final String lastInteraction;

  @override
  String toString() {
    return 'Relationship(npcId: $npcId, npcName: $npcName, role: $role, trustScore: $trustScore, suspicion: $suspicion, loyalty: $loyalty, fearLevel: $fearLevel, lastInteraction: $lastInteraction)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RelationshipImpl &&
            (identical(other.npcId, npcId) || other.npcId == npcId) &&
            (identical(other.npcName, npcName) || other.npcName == npcName) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.trustScore, trustScore) ||
                other.trustScore == trustScore) &&
            (identical(other.suspicion, suspicion) ||
                other.suspicion == suspicion) &&
            (identical(other.loyalty, loyalty) || other.loyalty == loyalty) &&
            (identical(other.fearLevel, fearLevel) ||
                other.fearLevel == fearLevel) &&
            (identical(other.lastInteraction, lastInteraction) ||
                other.lastInteraction == lastInteraction));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, npcId, npcName, role, trustScore,
      suspicion, loyalty, fearLevel, lastInteraction);

  /// Create a copy of Relationship
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RelationshipImplCopyWith<_$RelationshipImpl> get copyWith =>
      __$$RelationshipImplCopyWithImpl<_$RelationshipImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RelationshipImplToJson(
      this,
    );
  }
}

abstract class _Relationship implements Relationship {
  const factory _Relationship(
      {required final String npcId,
      required final String npcName,
      required final String role,
      required final int trustScore,
      required final int suspicion,
      required final int loyalty,
      required final int fearLevel,
      final String lastInteraction}) = _$RelationshipImpl;

  factory _Relationship.fromJson(Map<String, dynamic> json) =
      _$RelationshipImpl.fromJson;

  @override
  String get npcId;
  @override
  String get npcName;
  @override
  String get role; // ally, rival, mentor, love, enemy, neutral
  @override
  int get trustScore; // -100 to 100
  @override
  int get suspicion; // 0 to 100
  @override
  int get loyalty; // -100 to 100
  @override
  int get fearLevel; // 0 to 100
  @override
  String get lastInteraction;

  /// Create a copy of Relationship
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RelationshipImplCopyWith<_$RelationshipImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SaveSlot _$SaveSlotFromJson(Map<String, dynamic> json) {
  return _SaveSlot.fromJson(json);
}

/// @nodoc
mixin _$SaveSlot {
  String get id => throw _privateConstructorUsedError;
  String get campaignTitle => throw _privateConstructorUsedError;
  String get characterName => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;
  String get currentChapter => throw _privateConstructorUsedError;
  DateTime get lastSavedAt => throw _privateConstructorUsedError;
  bool get isAutosave => throw _privateConstructorUsedError;
  bool get isCheckpoint => throw _privateConstructorUsedError;
  int get revisionNumber => throw _privateConstructorUsedError;
  int get playtimeMinutes => throw _privateConstructorUsedError;
  String get thumbnailUrl => throw _privateConstructorUsedError;

  /// Serializes this SaveSlot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SaveSlot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SaveSlotCopyWith<SaveSlot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SaveSlotCopyWith<$Res> {
  factory $SaveSlotCopyWith(SaveSlot value, $Res Function(SaveSlot) then) =
      _$SaveSlotCopyWithImpl<$Res, SaveSlot>;
  @useResult
  $Res call(
      {String id,
      String campaignTitle,
      String characterName,
      String location,
      String currentChapter,
      DateTime lastSavedAt,
      bool isAutosave,
      bool isCheckpoint,
      int revisionNumber,
      int playtimeMinutes,
      String thumbnailUrl});
}

/// @nodoc
class _$SaveSlotCopyWithImpl<$Res, $Val extends SaveSlot>
    implements $SaveSlotCopyWith<$Res> {
  _$SaveSlotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SaveSlot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? campaignTitle = null,
    Object? characterName = null,
    Object? location = null,
    Object? currentChapter = null,
    Object? lastSavedAt = null,
    Object? isAutosave = null,
    Object? isCheckpoint = null,
    Object? revisionNumber = null,
    Object? playtimeMinutes = null,
    Object? thumbnailUrl = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      campaignTitle: null == campaignTitle
          ? _value.campaignTitle
          : campaignTitle // ignore: cast_nullable_to_non_nullable
              as String,
      characterName: null == characterName
          ? _value.characterName
          : characterName // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      currentChapter: null == currentChapter
          ? _value.currentChapter
          : currentChapter // ignore: cast_nullable_to_non_nullable
              as String,
      lastSavedAt: null == lastSavedAt
          ? _value.lastSavedAt
          : lastSavedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isAutosave: null == isAutosave
          ? _value.isAutosave
          : isAutosave // ignore: cast_nullable_to_non_nullable
              as bool,
      isCheckpoint: null == isCheckpoint
          ? _value.isCheckpoint
          : isCheckpoint // ignore: cast_nullable_to_non_nullable
              as bool,
      revisionNumber: null == revisionNumber
          ? _value.revisionNumber
          : revisionNumber // ignore: cast_nullable_to_non_nullable
              as int,
      playtimeMinutes: null == playtimeMinutes
          ? _value.playtimeMinutes
          : playtimeMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      thumbnailUrl: null == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SaveSlotImplCopyWith<$Res>
    implements $SaveSlotCopyWith<$Res> {
  factory _$$SaveSlotImplCopyWith(
          _$SaveSlotImpl value, $Res Function(_$SaveSlotImpl) then) =
      __$$SaveSlotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String campaignTitle,
      String characterName,
      String location,
      String currentChapter,
      DateTime lastSavedAt,
      bool isAutosave,
      bool isCheckpoint,
      int revisionNumber,
      int playtimeMinutes,
      String thumbnailUrl});
}

/// @nodoc
class __$$SaveSlotImplCopyWithImpl<$Res>
    extends _$SaveSlotCopyWithImpl<$Res, _$SaveSlotImpl>
    implements _$$SaveSlotImplCopyWith<$Res> {
  __$$SaveSlotImplCopyWithImpl(
      _$SaveSlotImpl _value, $Res Function(_$SaveSlotImpl) _then)
      : super(_value, _then);

  /// Create a copy of SaveSlot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? campaignTitle = null,
    Object? characterName = null,
    Object? location = null,
    Object? currentChapter = null,
    Object? lastSavedAt = null,
    Object? isAutosave = null,
    Object? isCheckpoint = null,
    Object? revisionNumber = null,
    Object? playtimeMinutes = null,
    Object? thumbnailUrl = null,
  }) {
    return _then(_$SaveSlotImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      campaignTitle: null == campaignTitle
          ? _value.campaignTitle
          : campaignTitle // ignore: cast_nullable_to_non_nullable
              as String,
      characterName: null == characterName
          ? _value.characterName
          : characterName // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      currentChapter: null == currentChapter
          ? _value.currentChapter
          : currentChapter // ignore: cast_nullable_to_non_nullable
              as String,
      lastSavedAt: null == lastSavedAt
          ? _value.lastSavedAt
          : lastSavedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isAutosave: null == isAutosave
          ? _value.isAutosave
          : isAutosave // ignore: cast_nullable_to_non_nullable
              as bool,
      isCheckpoint: null == isCheckpoint
          ? _value.isCheckpoint
          : isCheckpoint // ignore: cast_nullable_to_non_nullable
              as bool,
      revisionNumber: null == revisionNumber
          ? _value.revisionNumber
          : revisionNumber // ignore: cast_nullable_to_non_nullable
              as int,
      playtimeMinutes: null == playtimeMinutes
          ? _value.playtimeMinutes
          : playtimeMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      thumbnailUrl: null == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SaveSlotImpl implements _SaveSlot {
  const _$SaveSlotImpl(
      {required this.id,
      required this.campaignTitle,
      required this.characterName,
      required this.location,
      required this.currentChapter,
      required this.lastSavedAt,
      required this.isAutosave,
      required this.isCheckpoint,
      required this.revisionNumber,
      required this.playtimeMinutes,
      this.thumbnailUrl = ''});

  factory _$SaveSlotImpl.fromJson(Map<String, dynamic> json) =>
      _$$SaveSlotImplFromJson(json);

  @override
  final String id;
  @override
  final String campaignTitle;
  @override
  final String characterName;
  @override
  final String location;
  @override
  final String currentChapter;
  @override
  final DateTime lastSavedAt;
  @override
  final bool isAutosave;
  @override
  final bool isCheckpoint;
  @override
  final int revisionNumber;
  @override
  final int playtimeMinutes;
  @override
  @JsonKey()
  final String thumbnailUrl;

  @override
  String toString() {
    return 'SaveSlot(id: $id, campaignTitle: $campaignTitle, characterName: $characterName, location: $location, currentChapter: $currentChapter, lastSavedAt: $lastSavedAt, isAutosave: $isAutosave, isCheckpoint: $isCheckpoint, revisionNumber: $revisionNumber, playtimeMinutes: $playtimeMinutes, thumbnailUrl: $thumbnailUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaveSlotImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.campaignTitle, campaignTitle) ||
                other.campaignTitle == campaignTitle) &&
            (identical(other.characterName, characterName) ||
                other.characterName == characterName) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.currentChapter, currentChapter) ||
                other.currentChapter == currentChapter) &&
            (identical(other.lastSavedAt, lastSavedAt) ||
                other.lastSavedAt == lastSavedAt) &&
            (identical(other.isAutosave, isAutosave) ||
                other.isAutosave == isAutosave) &&
            (identical(other.isCheckpoint, isCheckpoint) ||
                other.isCheckpoint == isCheckpoint) &&
            (identical(other.revisionNumber, revisionNumber) ||
                other.revisionNumber == revisionNumber) &&
            (identical(other.playtimeMinutes, playtimeMinutes) ||
                other.playtimeMinutes == playtimeMinutes) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      campaignTitle,
      characterName,
      location,
      currentChapter,
      lastSavedAt,
      isAutosave,
      isCheckpoint,
      revisionNumber,
      playtimeMinutes,
      thumbnailUrl);

  /// Create a copy of SaveSlot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaveSlotImplCopyWith<_$SaveSlotImpl> get copyWith =>
      __$$SaveSlotImplCopyWithImpl<_$SaveSlotImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SaveSlotImplToJson(
      this,
    );
  }
}

abstract class _SaveSlot implements SaveSlot {
  const factory _SaveSlot(
      {required final String id,
      required final String campaignTitle,
      required final String characterName,
      required final String location,
      required final String currentChapter,
      required final DateTime lastSavedAt,
      required final bool isAutosave,
      required final bool isCheckpoint,
      required final int revisionNumber,
      required final int playtimeMinutes,
      final String thumbnailUrl}) = _$SaveSlotImpl;

  factory _SaveSlot.fromJson(Map<String, dynamic> json) =
      _$SaveSlotImpl.fromJson;

  @override
  String get id;
  @override
  String get campaignTitle;
  @override
  String get characterName;
  @override
  String get location;
  @override
  String get currentChapter;
  @override
  DateTime get lastSavedAt;
  @override
  bool get isAutosave;
  @override
  bool get isCheckpoint;
  @override
  int get revisionNumber;
  @override
  int get playtimeMinutes;
  @override
  String get thumbnailUrl;

  /// Create a copy of SaveSlot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaveSlotImplCopyWith<_$SaveSlotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TurnResult _$TurnResultFromJson(Map<String, dynamic> json) {
  return _TurnResult.fromJson(json);
}

/// @nodoc
mixin _$TurnResult {
  String get revisionId => throw _privateConstructorUsedError;
  String get actionSummary => throw _privateConstructorUsedError;
  List<String> get canonicalEvents => throw _privateConstructorUsedError;
  int get authorityVersion => throw _privateConstructorUsedError;
  DateTime get committedAt => throw _privateConstructorUsedError;
  Map<String, dynamic> get stateDelta =>
      throw _privateConstructorUsedError; // What changed in player state
  List<String> get narrativeBlocks =>
      throw _privateConstructorUsedError; // Prose narration
  String get sceneSuggestion => throw _privateConstructorUsedError;

  /// Serializes this TurnResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TurnResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TurnResultCopyWith<TurnResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TurnResultCopyWith<$Res> {
  factory $TurnResultCopyWith(
          TurnResult value, $Res Function(TurnResult) then) =
      _$TurnResultCopyWithImpl<$Res, TurnResult>;
  @useResult
  $Res call(
      {String revisionId,
      String actionSummary,
      List<String> canonicalEvents,
      int authorityVersion,
      DateTime committedAt,
      Map<String, dynamic> stateDelta,
      List<String> narrativeBlocks,
      String sceneSuggestion});
}

/// @nodoc
class _$TurnResultCopyWithImpl<$Res, $Val extends TurnResult>
    implements $TurnResultCopyWith<$Res> {
  _$TurnResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TurnResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? revisionId = null,
    Object? actionSummary = null,
    Object? canonicalEvents = null,
    Object? authorityVersion = null,
    Object? committedAt = null,
    Object? stateDelta = null,
    Object? narrativeBlocks = null,
    Object? sceneSuggestion = null,
  }) {
    return _then(_value.copyWith(
      revisionId: null == revisionId
          ? _value.revisionId
          : revisionId // ignore: cast_nullable_to_non_nullable
              as String,
      actionSummary: null == actionSummary
          ? _value.actionSummary
          : actionSummary // ignore: cast_nullable_to_non_nullable
              as String,
      canonicalEvents: null == canonicalEvents
          ? _value.canonicalEvents
          : canonicalEvents // ignore: cast_nullable_to_non_nullable
              as List<String>,
      authorityVersion: null == authorityVersion
          ? _value.authorityVersion
          : authorityVersion // ignore: cast_nullable_to_non_nullable
              as int,
      committedAt: null == committedAt
          ? _value.committedAt
          : committedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      stateDelta: null == stateDelta
          ? _value.stateDelta
          : stateDelta // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      narrativeBlocks: null == narrativeBlocks
          ? _value.narrativeBlocks
          : narrativeBlocks // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sceneSuggestion: null == sceneSuggestion
          ? _value.sceneSuggestion
          : sceneSuggestion // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TurnResultImplCopyWith<$Res>
    implements $TurnResultCopyWith<$Res> {
  factory _$$TurnResultImplCopyWith(
          _$TurnResultImpl value, $Res Function(_$TurnResultImpl) then) =
      __$$TurnResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String revisionId,
      String actionSummary,
      List<String> canonicalEvents,
      int authorityVersion,
      DateTime committedAt,
      Map<String, dynamic> stateDelta,
      List<String> narrativeBlocks,
      String sceneSuggestion});
}

/// @nodoc
class __$$TurnResultImplCopyWithImpl<$Res>
    extends _$TurnResultCopyWithImpl<$Res, _$TurnResultImpl>
    implements _$$TurnResultImplCopyWith<$Res> {
  __$$TurnResultImplCopyWithImpl(
      _$TurnResultImpl _value, $Res Function(_$TurnResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of TurnResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? revisionId = null,
    Object? actionSummary = null,
    Object? canonicalEvents = null,
    Object? authorityVersion = null,
    Object? committedAt = null,
    Object? stateDelta = null,
    Object? narrativeBlocks = null,
    Object? sceneSuggestion = null,
  }) {
    return _then(_$TurnResultImpl(
      revisionId: null == revisionId
          ? _value.revisionId
          : revisionId // ignore: cast_nullable_to_non_nullable
              as String,
      actionSummary: null == actionSummary
          ? _value.actionSummary
          : actionSummary // ignore: cast_nullable_to_non_nullable
              as String,
      canonicalEvents: null == canonicalEvents
          ? _value._canonicalEvents
          : canonicalEvents // ignore: cast_nullable_to_non_nullable
              as List<String>,
      authorityVersion: null == authorityVersion
          ? _value.authorityVersion
          : authorityVersion // ignore: cast_nullable_to_non_nullable
              as int,
      committedAt: null == committedAt
          ? _value.committedAt
          : committedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      stateDelta: null == stateDelta
          ? _value._stateDelta
          : stateDelta // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      narrativeBlocks: null == narrativeBlocks
          ? _value._narrativeBlocks
          : narrativeBlocks // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sceneSuggestion: null == sceneSuggestion
          ? _value.sceneSuggestion
          : sceneSuggestion // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TurnResultImpl implements _TurnResult {
  const _$TurnResultImpl(
      {required this.revisionId,
      required this.actionSummary,
      required final List<String> canonicalEvents,
      required this.authorityVersion,
      required this.committedAt,
      required final Map<String, dynamic> stateDelta,
      final List<String> narrativeBlocks = const [],
      this.sceneSuggestion = ''})
      : _canonicalEvents = canonicalEvents,
        _stateDelta = stateDelta,
        _narrativeBlocks = narrativeBlocks;

  factory _$TurnResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$TurnResultImplFromJson(json);

  @override
  final String revisionId;
  @override
  final String actionSummary;
  final List<String> _canonicalEvents;
  @override
  List<String> get canonicalEvents {
    if (_canonicalEvents is EqualUnmodifiableListView) return _canonicalEvents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_canonicalEvents);
  }

  @override
  final int authorityVersion;
  @override
  final DateTime committedAt;
  final Map<String, dynamic> _stateDelta;
  @override
  Map<String, dynamic> get stateDelta {
    if (_stateDelta is EqualUnmodifiableMapView) return _stateDelta;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_stateDelta);
  }

// What changed in player state
  final List<String> _narrativeBlocks;
// What changed in player state
  @override
  @JsonKey()
  List<String> get narrativeBlocks {
    if (_narrativeBlocks is EqualUnmodifiableListView) return _narrativeBlocks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_narrativeBlocks);
  }

// Prose narration
  @override
  @JsonKey()
  final String sceneSuggestion;

  @override
  String toString() {
    return 'TurnResult(revisionId: $revisionId, actionSummary: $actionSummary, canonicalEvents: $canonicalEvents, authorityVersion: $authorityVersion, committedAt: $committedAt, stateDelta: $stateDelta, narrativeBlocks: $narrativeBlocks, sceneSuggestion: $sceneSuggestion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TurnResultImpl &&
            (identical(other.revisionId, revisionId) ||
                other.revisionId == revisionId) &&
            (identical(other.actionSummary, actionSummary) ||
                other.actionSummary == actionSummary) &&
            const DeepCollectionEquality()
                .equals(other._canonicalEvents, _canonicalEvents) &&
            (identical(other.authorityVersion, authorityVersion) ||
                other.authorityVersion == authorityVersion) &&
            (identical(other.committedAt, committedAt) ||
                other.committedAt == committedAt) &&
            const DeepCollectionEquality()
                .equals(other._stateDelta, _stateDelta) &&
            const DeepCollectionEquality()
                .equals(other._narrativeBlocks, _narrativeBlocks) &&
            (identical(other.sceneSuggestion, sceneSuggestion) ||
                other.sceneSuggestion == sceneSuggestion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      revisionId,
      actionSummary,
      const DeepCollectionEquality().hash(_canonicalEvents),
      authorityVersion,
      committedAt,
      const DeepCollectionEquality().hash(_stateDelta),
      const DeepCollectionEquality().hash(_narrativeBlocks),
      sceneSuggestion);

  /// Create a copy of TurnResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TurnResultImplCopyWith<_$TurnResultImpl> get copyWith =>
      __$$TurnResultImplCopyWithImpl<_$TurnResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TurnResultImplToJson(
      this,
    );
  }
}

abstract class _TurnResult implements TurnResult {
  const factory _TurnResult(
      {required final String revisionId,
      required final String actionSummary,
      required final List<String> canonicalEvents,
      required final int authorityVersion,
      required final DateTime committedAt,
      required final Map<String, dynamic> stateDelta,
      final List<String> narrativeBlocks,
      final String sceneSuggestion}) = _$TurnResultImpl;

  factory _TurnResult.fromJson(Map<String, dynamic> json) =
      _$TurnResultImpl.fromJson;

  @override
  String get revisionId;
  @override
  String get actionSummary;
  @override
  List<String> get canonicalEvents;
  @override
  int get authorityVersion;
  @override
  DateTime get committedAt;
  @override
  Map<String, dynamic> get stateDelta; // What changed in player state
  @override
  List<String> get narrativeBlocks; // Prose narration
  @override
  String get sceneSuggestion;

  /// Create a copy of TurnResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TurnResultImplCopyWith<_$TurnResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Scene _$SceneFromJson(Map<String, dynamic> json) {
  return _Scene.fromJson(json);
}

/// @nodoc
mixin _$Scene {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get controllingFaction => throw _privateConstructorUsedError;
  String get dangerLevel =>
      throw _privateConstructorUsedError; // safe, moderate, dangerous, deadly
  String get artPath => throw _privateConstructorUsedError;
  List<String> get npcsPresent => throw _privateConstructorUsedError;
  List<String> get availableActions => throw _privateConstructorUsedError;

  /// Serializes this Scene to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Scene
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SceneCopyWith<Scene> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SceneCopyWith<$Res> {
  factory $SceneCopyWith(Scene value, $Res Function(Scene) then) =
      _$SceneCopyWithImpl<$Res, Scene>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String controllingFaction,
      String dangerLevel,
      String artPath,
      List<String> npcsPresent,
      List<String> availableActions});
}

/// @nodoc
class _$SceneCopyWithImpl<$Res, $Val extends Scene>
    implements $SceneCopyWith<$Res> {
  _$SceneCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Scene
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? controllingFaction = null,
    Object? dangerLevel = null,
    Object? artPath = null,
    Object? npcsPresent = null,
    Object? availableActions = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      controllingFaction: null == controllingFaction
          ? _value.controllingFaction
          : controllingFaction // ignore: cast_nullable_to_non_nullable
              as String,
      dangerLevel: null == dangerLevel
          ? _value.dangerLevel
          : dangerLevel // ignore: cast_nullable_to_non_nullable
              as String,
      artPath: null == artPath
          ? _value.artPath
          : artPath // ignore: cast_nullable_to_non_nullable
              as String,
      npcsPresent: null == npcsPresent
          ? _value.npcsPresent
          : npcsPresent // ignore: cast_nullable_to_non_nullable
              as List<String>,
      availableActions: null == availableActions
          ? _value.availableActions
          : availableActions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SceneImplCopyWith<$Res> implements $SceneCopyWith<$Res> {
  factory _$$SceneImplCopyWith(
          _$SceneImpl value, $Res Function(_$SceneImpl) then) =
      __$$SceneImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String controllingFaction,
      String dangerLevel,
      String artPath,
      List<String> npcsPresent,
      List<String> availableActions});
}

/// @nodoc
class __$$SceneImplCopyWithImpl<$Res>
    extends _$SceneCopyWithImpl<$Res, _$SceneImpl>
    implements _$$SceneImplCopyWith<$Res> {
  __$$SceneImplCopyWithImpl(
      _$SceneImpl _value, $Res Function(_$SceneImpl) _then)
      : super(_value, _then);

  /// Create a copy of Scene
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? controllingFaction = null,
    Object? dangerLevel = null,
    Object? artPath = null,
    Object? npcsPresent = null,
    Object? availableActions = null,
  }) {
    return _then(_$SceneImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      controllingFaction: null == controllingFaction
          ? _value.controllingFaction
          : controllingFaction // ignore: cast_nullable_to_non_nullable
              as String,
      dangerLevel: null == dangerLevel
          ? _value.dangerLevel
          : dangerLevel // ignore: cast_nullable_to_non_nullable
              as String,
      artPath: null == artPath
          ? _value.artPath
          : artPath // ignore: cast_nullable_to_non_nullable
              as String,
      npcsPresent: null == npcsPresent
          ? _value._npcsPresent
          : npcsPresent // ignore: cast_nullable_to_non_nullable
              as List<String>,
      availableActions: null == availableActions
          ? _value._availableActions
          : availableActions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SceneImpl implements _Scene {
  const _$SceneImpl(
      {required this.id,
      required this.title,
      required this.description,
      required this.controllingFaction,
      required this.dangerLevel,
      this.artPath = '',
      final List<String> npcsPresent = const [],
      final List<String> availableActions = const []})
      : _npcsPresent = npcsPresent,
        _availableActions = availableActions;

  factory _$SceneImpl.fromJson(Map<String, dynamic> json) =>
      _$$SceneImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String controllingFaction;
  @override
  final String dangerLevel;
// safe, moderate, dangerous, deadly
  @override
  @JsonKey()
  final String artPath;
  final List<String> _npcsPresent;
  @override
  @JsonKey()
  List<String> get npcsPresent {
    if (_npcsPresent is EqualUnmodifiableListView) return _npcsPresent;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_npcsPresent);
  }

  final List<String> _availableActions;
  @override
  @JsonKey()
  List<String> get availableActions {
    if (_availableActions is EqualUnmodifiableListView)
      return _availableActions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableActions);
  }

  @override
  String toString() {
    return 'Scene(id: $id, title: $title, description: $description, controllingFaction: $controllingFaction, dangerLevel: $dangerLevel, artPath: $artPath, npcsPresent: $npcsPresent, availableActions: $availableActions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SceneImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.controllingFaction, controllingFaction) ||
                other.controllingFaction == controllingFaction) &&
            (identical(other.dangerLevel, dangerLevel) ||
                other.dangerLevel == dangerLevel) &&
            (identical(other.artPath, artPath) || other.artPath == artPath) &&
            const DeepCollectionEquality()
                .equals(other._npcsPresent, _npcsPresent) &&
            const DeepCollectionEquality()
                .equals(other._availableActions, _availableActions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      controllingFaction,
      dangerLevel,
      artPath,
      const DeepCollectionEquality().hash(_npcsPresent),
      const DeepCollectionEquality().hash(_availableActions));

  /// Create a copy of Scene
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SceneImplCopyWith<_$SceneImpl> get copyWith =>
      __$$SceneImplCopyWithImpl<_$SceneImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SceneImplToJson(
      this,
    );
  }
}

abstract class _Scene implements Scene {
  const factory _Scene(
      {required final String id,
      required final String title,
      required final String description,
      required final String controllingFaction,
      required final String dangerLevel,
      final String artPath,
      final List<String> npcsPresent,
      final List<String> availableActions}) = _$SceneImpl;

  factory _Scene.fromJson(Map<String, dynamic> json) = _$SceneImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  String get controllingFaction;
  @override
  String get dangerLevel; // safe, moderate, dangerous, deadly
  @override
  String get artPath;
  @override
  List<String> get npcsPresent;
  @override
  List<String> get availableActions;

  /// Create a copy of Scene
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SceneImplCopyWith<_$SceneImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Region _$RegionFromJson(Map<String, dynamic> json) {
  return _Region.fromJson(json);
}

/// @nodoc
mixin _$Region {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<String> get discoveredLocations => throw _privateConstructorUsedError;
  List<String> get routes => throw _privateConstructorUsedError;

  /// Serializes this Region to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Region
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RegionCopyWith<Region> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegionCopyWith<$Res> {
  factory $RegionCopyWith(Region value, $Res Function(Region) then) =
      _$RegionCopyWithImpl<$Res, Region>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      List<String> discoveredLocations,
      List<String> routes});
}

/// @nodoc
class _$RegionCopyWithImpl<$Res, $Val extends Region>
    implements $RegionCopyWith<$Res> {
  _$RegionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Region
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? discoveredLocations = null,
    Object? routes = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      discoveredLocations: null == discoveredLocations
          ? _value.discoveredLocations
          : discoveredLocations // ignore: cast_nullable_to_non_nullable
              as List<String>,
      routes: null == routes
          ? _value.routes
          : routes // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RegionImplCopyWith<$Res> implements $RegionCopyWith<$Res> {
  factory _$$RegionImplCopyWith(
          _$RegionImpl value, $Res Function(_$RegionImpl) then) =
      __$$RegionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      List<String> discoveredLocations,
      List<String> routes});
}

/// @nodoc
class __$$RegionImplCopyWithImpl<$Res>
    extends _$RegionCopyWithImpl<$Res, _$RegionImpl>
    implements _$$RegionImplCopyWith<$Res> {
  __$$RegionImplCopyWithImpl(
      _$RegionImpl _value, $Res Function(_$RegionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Region
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? discoveredLocations = null,
    Object? routes = null,
  }) {
    return _then(_$RegionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      discoveredLocations: null == discoveredLocations
          ? _value._discoveredLocations
          : discoveredLocations // ignore: cast_nullable_to_non_nullable
              as List<String>,
      routes: null == routes
          ? _value._routes
          : routes // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RegionImpl implements _Region {
  const _$RegionImpl(
      {required this.id,
      required this.name,
      required this.description,
      final List<String> discoveredLocations = const [],
      final List<String> routes = const []})
      : _discoveredLocations = discoveredLocations,
        _routes = routes;

  factory _$RegionImpl.fromJson(Map<String, dynamic> json) =>
      _$$RegionImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  final List<String> _discoveredLocations;
  @override
  @JsonKey()
  List<String> get discoveredLocations {
    if (_discoveredLocations is EqualUnmodifiableListView)
      return _discoveredLocations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_discoveredLocations);
  }

  final List<String> _routes;
  @override
  @JsonKey()
  List<String> get routes {
    if (_routes is EqualUnmodifiableListView) return _routes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_routes);
  }

  @override
  String toString() {
    return 'Region(id: $id, name: $name, description: $description, discoveredLocations: $discoveredLocations, routes: $routes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._discoveredLocations, _discoveredLocations) &&
            const DeepCollectionEquality().equals(other._routes, _routes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      const DeepCollectionEquality().hash(_discoveredLocations),
      const DeepCollectionEquality().hash(_routes));

  /// Create a copy of Region
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegionImplCopyWith<_$RegionImpl> get copyWith =>
      __$$RegionImplCopyWithImpl<_$RegionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RegionImplToJson(
      this,
    );
  }
}

abstract class _Region implements Region {
  const factory _Region(
      {required final String id,
      required final String name,
      required final String description,
      final List<String> discoveredLocations,
      final List<String> routes}) = _$RegionImpl;

  factory _Region.fromJson(Map<String, dynamic> json) = _$RegionImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  List<String> get discoveredLocations;
  @override
  List<String> get routes;

  /// Create a copy of Region
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegionImplCopyWith<_$RegionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Campaign _$CampaignFromJson(Map<String, dynamic> json) {
  return _Campaign.fromJson(json);
}

/// @nodoc
mixin _$Campaign {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get difficulty =>
      throw _privateConstructorUsedError; // story, seasoned, legendary
  String get tone =>
      throw _privateConstructorUsedError; // noir, heroic, gritty, mystical, dark
  int get estimatedLengthHours => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  String get worldSummary => throw _privateConstructorUsedError;

  /// Serializes this Campaign to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Campaign
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CampaignCopyWith<Campaign> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CampaignCopyWith<$Res> {
  factory $CampaignCopyWith(Campaign value, $Res Function(Campaign) then) =
      _$CampaignCopyWithImpl<$Res, Campaign>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String difficulty,
      String tone,
      int estimatedLengthHours,
      List<String> tags,
      String worldSummary});
}

/// @nodoc
class _$CampaignCopyWithImpl<$Res, $Val extends Campaign>
    implements $CampaignCopyWith<$Res> {
  _$CampaignCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Campaign
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? difficulty = null,
    Object? tone = null,
    Object? estimatedLengthHours = null,
    Object? tags = null,
    Object? worldSummary = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
      tone: null == tone
          ? _value.tone
          : tone // ignore: cast_nullable_to_non_nullable
              as String,
      estimatedLengthHours: null == estimatedLengthHours
          ? _value.estimatedLengthHours
          : estimatedLengthHours // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      worldSummary: null == worldSummary
          ? _value.worldSummary
          : worldSummary // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CampaignImplCopyWith<$Res>
    implements $CampaignCopyWith<$Res> {
  factory _$$CampaignImplCopyWith(
          _$CampaignImpl value, $Res Function(_$CampaignImpl) then) =
      __$$CampaignImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String difficulty,
      String tone,
      int estimatedLengthHours,
      List<String> tags,
      String worldSummary});
}

/// @nodoc
class __$$CampaignImplCopyWithImpl<$Res>
    extends _$CampaignCopyWithImpl<$Res, _$CampaignImpl>
    implements _$$CampaignImplCopyWith<$Res> {
  __$$CampaignImplCopyWithImpl(
      _$CampaignImpl _value, $Res Function(_$CampaignImpl) _then)
      : super(_value, _then);

  /// Create a copy of Campaign
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? difficulty = null,
    Object? tone = null,
    Object? estimatedLengthHours = null,
    Object? tags = null,
    Object? worldSummary = null,
  }) {
    return _then(_$CampaignImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
      tone: null == tone
          ? _value.tone
          : tone // ignore: cast_nullable_to_non_nullable
              as String,
      estimatedLengthHours: null == estimatedLengthHours
          ? _value.estimatedLengthHours
          : estimatedLengthHours // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      worldSummary: null == worldSummary
          ? _value.worldSummary
          : worldSummary // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CampaignImpl implements _Campaign {
  const _$CampaignImpl(
      {required this.id,
      required this.title,
      required this.description,
      required this.difficulty,
      required this.tone,
      required this.estimatedLengthHours,
      final List<String> tags = const [],
      this.worldSummary = ''})
      : _tags = tags;

  factory _$CampaignImpl.fromJson(Map<String, dynamic> json) =>
      _$$CampaignImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String difficulty;
// story, seasoned, legendary
  @override
  final String tone;
// noir, heroic, gritty, mystical, dark
  @override
  final int estimatedLengthHours;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final String worldSummary;

  @override
  String toString() {
    return 'Campaign(id: $id, title: $title, description: $description, difficulty: $difficulty, tone: $tone, estimatedLengthHours: $estimatedLengthHours, tags: $tags, worldSummary: $worldSummary)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CampaignImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.tone, tone) || other.tone == tone) &&
            (identical(other.estimatedLengthHours, estimatedLengthHours) ||
                other.estimatedLengthHours == estimatedLengthHours) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.worldSummary, worldSummary) ||
                other.worldSummary == worldSummary));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      difficulty,
      tone,
      estimatedLengthHours,
      const DeepCollectionEquality().hash(_tags),
      worldSummary);

  /// Create a copy of Campaign
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CampaignImplCopyWith<_$CampaignImpl> get copyWith =>
      __$$CampaignImplCopyWithImpl<_$CampaignImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CampaignImplToJson(
      this,
    );
  }
}

abstract class _Campaign implements Campaign {
  const factory _Campaign(
      {required final String id,
      required final String title,
      required final String description,
      required final String difficulty,
      required final String tone,
      required final int estimatedLengthHours,
      final List<String> tags,
      final String worldSummary}) = _$CampaignImpl;

  factory _Campaign.fromJson(Map<String, dynamic> json) =
      _$CampaignImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  String get difficulty; // story, seasoned, legendary
  @override
  String get tone; // noir, heroic, gritty, mystical, dark
  @override
  int get estimatedLengthHours;
  @override
  List<String> get tags;
  @override
  String get worldSummary;

  /// Create a copy of Campaign
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CampaignImplCopyWith<_$CampaignImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
