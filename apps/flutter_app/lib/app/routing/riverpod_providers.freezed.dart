// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'riverpod_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DraftAction {
  String get text => throw _privateConstructorUsedError;
  String? get quickActionType => throw _privateConstructorUsedError;
  bool get hasClarificationPending => throw _privateConstructorUsedError;
  String get clarificationPrompt => throw _privateConstructorUsedError;

  /// Create a copy of DraftAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DraftActionCopyWith<DraftAction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DraftActionCopyWith<$Res> {
  factory $DraftActionCopyWith(
          DraftAction value, $Res Function(DraftAction) then) =
      _$DraftActionCopyWithImpl<$Res, DraftAction>;
  @useResult
  $Res call(
      {String text,
      String? quickActionType,
      bool hasClarificationPending,
      String clarificationPrompt});
}

/// @nodoc
class _$DraftActionCopyWithImpl<$Res, $Val extends DraftAction>
    implements $DraftActionCopyWith<$Res> {
  _$DraftActionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DraftAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? quickActionType = freezed,
    Object? hasClarificationPending = null,
    Object? clarificationPrompt = null,
  }) {
    return _then(_value.copyWith(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      quickActionType: freezed == quickActionType
          ? _value.quickActionType
          : quickActionType // ignore: cast_nullable_to_non_nullable
              as String?,
      hasClarificationPending: null == hasClarificationPending
          ? _value.hasClarificationPending
          : hasClarificationPending // ignore: cast_nullable_to_non_nullable
              as bool,
      clarificationPrompt: null == clarificationPrompt
          ? _value.clarificationPrompt
          : clarificationPrompt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DraftActionImplCopyWith<$Res>
    implements $DraftActionCopyWith<$Res> {
  factory _$$DraftActionImplCopyWith(
          _$DraftActionImpl value, $Res Function(_$DraftActionImpl) then) =
      __$$DraftActionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String text,
      String? quickActionType,
      bool hasClarificationPending,
      String clarificationPrompt});
}

/// @nodoc
class __$$DraftActionImplCopyWithImpl<$Res>
    extends _$DraftActionCopyWithImpl<$Res, _$DraftActionImpl>
    implements _$$DraftActionImplCopyWith<$Res> {
  __$$DraftActionImplCopyWithImpl(
      _$DraftActionImpl _value, $Res Function(_$DraftActionImpl) _then)
      : super(_value, _then);

  /// Create a copy of DraftAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? quickActionType = freezed,
    Object? hasClarificationPending = null,
    Object? clarificationPrompt = null,
  }) {
    return _then(_$DraftActionImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      quickActionType: freezed == quickActionType
          ? _value.quickActionType
          : quickActionType // ignore: cast_nullable_to_non_nullable
              as String?,
      hasClarificationPending: null == hasClarificationPending
          ? _value.hasClarificationPending
          : hasClarificationPending // ignore: cast_nullable_to_non_nullable
              as bool,
      clarificationPrompt: null == clarificationPrompt
          ? _value.clarificationPrompt
          : clarificationPrompt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$DraftActionImpl implements _DraftAction {
  const _$DraftActionImpl(
      {required this.text,
      required this.quickActionType,
      required this.hasClarificationPending,
      this.clarificationPrompt = ''});

  @override
  final String text;
  @override
  final String? quickActionType;
  @override
  final bool hasClarificationPending;
  @override
  @JsonKey()
  final String clarificationPrompt;

  @override
  String toString() {
    return 'DraftAction(text: $text, quickActionType: $quickActionType, hasClarificationPending: $hasClarificationPending, clarificationPrompt: $clarificationPrompt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DraftActionImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.quickActionType, quickActionType) ||
                other.quickActionType == quickActionType) &&
            (identical(
                    other.hasClarificationPending, hasClarificationPending) ||
                other.hasClarificationPending == hasClarificationPending) &&
            (identical(other.clarificationPrompt, clarificationPrompt) ||
                other.clarificationPrompt == clarificationPrompt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, text, quickActionType,
      hasClarificationPending, clarificationPrompt);

  /// Create a copy of DraftAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DraftActionImplCopyWith<_$DraftActionImpl> get copyWith =>
      __$$DraftActionImplCopyWithImpl<_$DraftActionImpl>(this, _$identity);
}

abstract class _DraftAction implements DraftAction {
  const factory _DraftAction(
      {required final String text,
      required final String? quickActionType,
      required final bool hasClarificationPending,
      final String clarificationPrompt}) = _$DraftActionImpl;

  @override
  String get text;
  @override
  String? get quickActionType;
  @override
  bool get hasClarificationPending;
  @override
  String get clarificationPrompt;

  /// Create a copy of DraftAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DraftActionImplCopyWith<_$DraftActionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ContentSettings {
  String get violenceLevel => throw _privateConstructorUsedError;
  bool get romanceEnabled => throw _privateConstructorUsedError;
  bool get horrorEnabled => throw _privateConstructorUsedError;
  bool get matureThemesEnabled => throw _privateConstructorUsedError;
  bool get betrayalEnabled => throw _privateConstructorUsedError;
  List<String> get customExclusions => throw _privateConstructorUsedError;

  /// Create a copy of ContentSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContentSettingsCopyWith<ContentSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentSettingsCopyWith<$Res> {
  factory $ContentSettingsCopyWith(
          ContentSettings value, $Res Function(ContentSettings) then) =
      _$ContentSettingsCopyWithImpl<$Res, ContentSettings>;
  @useResult
  $Res call(
      {String violenceLevel,
      bool romanceEnabled,
      bool horrorEnabled,
      bool matureThemesEnabled,
      bool betrayalEnabled,
      List<String> customExclusions});
}

/// @nodoc
class _$ContentSettingsCopyWithImpl<$Res, $Val extends ContentSettings>
    implements $ContentSettingsCopyWith<$Res> {
  _$ContentSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContentSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? violenceLevel = null,
    Object? romanceEnabled = null,
    Object? horrorEnabled = null,
    Object? matureThemesEnabled = null,
    Object? betrayalEnabled = null,
    Object? customExclusions = null,
  }) {
    return _then(_value.copyWith(
      violenceLevel: null == violenceLevel
          ? _value.violenceLevel
          : violenceLevel // ignore: cast_nullable_to_non_nullable
              as String,
      romanceEnabled: null == romanceEnabled
          ? _value.romanceEnabled
          : romanceEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      horrorEnabled: null == horrorEnabled
          ? _value.horrorEnabled
          : horrorEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      matureThemesEnabled: null == matureThemesEnabled
          ? _value.matureThemesEnabled
          : matureThemesEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      betrayalEnabled: null == betrayalEnabled
          ? _value.betrayalEnabled
          : betrayalEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      customExclusions: null == customExclusions
          ? _value.customExclusions
          : customExclusions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ContentSettingsImplCopyWith<$Res>
    implements $ContentSettingsCopyWith<$Res> {
  factory _$$ContentSettingsImplCopyWith(_$ContentSettingsImpl value,
          $Res Function(_$ContentSettingsImpl) then) =
      __$$ContentSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String violenceLevel,
      bool romanceEnabled,
      bool horrorEnabled,
      bool matureThemesEnabled,
      bool betrayalEnabled,
      List<String> customExclusions});
}

/// @nodoc
class __$$ContentSettingsImplCopyWithImpl<$Res>
    extends _$ContentSettingsCopyWithImpl<$Res, _$ContentSettingsImpl>
    implements _$$ContentSettingsImplCopyWith<$Res> {
  __$$ContentSettingsImplCopyWithImpl(
      _$ContentSettingsImpl _value, $Res Function(_$ContentSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ContentSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? violenceLevel = null,
    Object? romanceEnabled = null,
    Object? horrorEnabled = null,
    Object? matureThemesEnabled = null,
    Object? betrayalEnabled = null,
    Object? customExclusions = null,
  }) {
    return _then(_$ContentSettingsImpl(
      violenceLevel: null == violenceLevel
          ? _value.violenceLevel
          : violenceLevel // ignore: cast_nullable_to_non_nullable
              as String,
      romanceEnabled: null == romanceEnabled
          ? _value.romanceEnabled
          : romanceEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      horrorEnabled: null == horrorEnabled
          ? _value.horrorEnabled
          : horrorEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      matureThemesEnabled: null == matureThemesEnabled
          ? _value.matureThemesEnabled
          : matureThemesEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      betrayalEnabled: null == betrayalEnabled
          ? _value.betrayalEnabled
          : betrayalEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      customExclusions: null == customExclusions
          ? _value._customExclusions
          : customExclusions // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$ContentSettingsImpl implements _ContentSettings {
  const _$ContentSettingsImpl(
      {this.violenceLevel = 'medium',
      this.romanceEnabled = true,
      this.horrorEnabled = true,
      this.matureThemesEnabled = true,
      this.betrayalEnabled = true,
      final List<String> customExclusions = const []})
      : _customExclusions = customExclusions;

  @override
  @JsonKey()
  final String violenceLevel;
  @override
  @JsonKey()
  final bool romanceEnabled;
  @override
  @JsonKey()
  final bool horrorEnabled;
  @override
  @JsonKey()
  final bool matureThemesEnabled;
  @override
  @JsonKey()
  final bool betrayalEnabled;
  final List<String> _customExclusions;
  @override
  @JsonKey()
  List<String> get customExclusions {
    if (_customExclusions is EqualUnmodifiableListView)
      return _customExclusions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_customExclusions);
  }

  @override
  String toString() {
    return 'ContentSettings(violenceLevel: $violenceLevel, romanceEnabled: $romanceEnabled, horrorEnabled: $horrorEnabled, matureThemesEnabled: $matureThemesEnabled, betrayalEnabled: $betrayalEnabled, customExclusions: $customExclusions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContentSettingsImpl &&
            (identical(other.violenceLevel, violenceLevel) ||
                other.violenceLevel == violenceLevel) &&
            (identical(other.romanceEnabled, romanceEnabled) ||
                other.romanceEnabled == romanceEnabled) &&
            (identical(other.horrorEnabled, horrorEnabled) ||
                other.horrorEnabled == horrorEnabled) &&
            (identical(other.matureThemesEnabled, matureThemesEnabled) ||
                other.matureThemesEnabled == matureThemesEnabled) &&
            (identical(other.betrayalEnabled, betrayalEnabled) ||
                other.betrayalEnabled == betrayalEnabled) &&
            const DeepCollectionEquality()
                .equals(other._customExclusions, _customExclusions));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      violenceLevel,
      romanceEnabled,
      horrorEnabled,
      matureThemesEnabled,
      betrayalEnabled,
      const DeepCollectionEquality().hash(_customExclusions));

  /// Create a copy of ContentSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContentSettingsImplCopyWith<_$ContentSettingsImpl> get copyWith =>
      __$$ContentSettingsImplCopyWithImpl<_$ContentSettingsImpl>(
          this, _$identity);
}

abstract class _ContentSettings implements ContentSettings {
  const factory _ContentSettings(
      {final String violenceLevel,
      final bool romanceEnabled,
      final bool horrorEnabled,
      final bool matureThemesEnabled,
      final bool betrayalEnabled,
      final List<String> customExclusions}) = _$ContentSettingsImpl;

  @override
  String get violenceLevel;
  @override
  bool get romanceEnabled;
  @override
  bool get horrorEnabled;
  @override
  bool get matureThemesEnabled;
  @override
  bool get betrayalEnabled;
  @override
  List<String> get customExclusions;

  /// Create a copy of ContentSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContentSettingsImplCopyWith<_$ContentSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AccessibilitySettings {
  double get fontSizeMultiplier => throw _privateConstructorUsedError;
  bool get highContrast => throw _privateConstructorUsedError;
  bool get reduceMotion => throw _privateConstructorUsedError;
  bool get screenReaderMode => throw _privateConstructorUsedError;

  /// Create a copy of AccessibilitySettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccessibilitySettingsCopyWith<AccessibilitySettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccessibilitySettingsCopyWith<$Res> {
  factory $AccessibilitySettingsCopyWith(AccessibilitySettings value,
          $Res Function(AccessibilitySettings) then) =
      _$AccessibilitySettingsCopyWithImpl<$Res, AccessibilitySettings>;
  @useResult
  $Res call(
      {double fontSizeMultiplier,
      bool highContrast,
      bool reduceMotion,
      bool screenReaderMode});
}

/// @nodoc
class _$AccessibilitySettingsCopyWithImpl<$Res,
        $Val extends AccessibilitySettings>
    implements $AccessibilitySettingsCopyWith<$Res> {
  _$AccessibilitySettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccessibilitySettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fontSizeMultiplier = null,
    Object? highContrast = null,
    Object? reduceMotion = null,
    Object? screenReaderMode = null,
  }) {
    return _then(_value.copyWith(
      fontSizeMultiplier: null == fontSizeMultiplier
          ? _value.fontSizeMultiplier
          : fontSizeMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      highContrast: null == highContrast
          ? _value.highContrast
          : highContrast // ignore: cast_nullable_to_non_nullable
              as bool,
      reduceMotion: null == reduceMotion
          ? _value.reduceMotion
          : reduceMotion // ignore: cast_nullable_to_non_nullable
              as bool,
      screenReaderMode: null == screenReaderMode
          ? _value.screenReaderMode
          : screenReaderMode // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AccessibilitySettingsImplCopyWith<$Res>
    implements $AccessibilitySettingsCopyWith<$Res> {
  factory _$$AccessibilitySettingsImplCopyWith(
          _$AccessibilitySettingsImpl value,
          $Res Function(_$AccessibilitySettingsImpl) then) =
      __$$AccessibilitySettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double fontSizeMultiplier,
      bool highContrast,
      bool reduceMotion,
      bool screenReaderMode});
}

/// @nodoc
class __$$AccessibilitySettingsImplCopyWithImpl<$Res>
    extends _$AccessibilitySettingsCopyWithImpl<$Res,
        _$AccessibilitySettingsImpl>
    implements _$$AccessibilitySettingsImplCopyWith<$Res> {
  __$$AccessibilitySettingsImplCopyWithImpl(_$AccessibilitySettingsImpl _value,
      $Res Function(_$AccessibilitySettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of AccessibilitySettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fontSizeMultiplier = null,
    Object? highContrast = null,
    Object? reduceMotion = null,
    Object? screenReaderMode = null,
  }) {
    return _then(_$AccessibilitySettingsImpl(
      fontSizeMultiplier: null == fontSizeMultiplier
          ? _value.fontSizeMultiplier
          : fontSizeMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      highContrast: null == highContrast
          ? _value.highContrast
          : highContrast // ignore: cast_nullable_to_non_nullable
              as bool,
      reduceMotion: null == reduceMotion
          ? _value.reduceMotion
          : reduceMotion // ignore: cast_nullable_to_non_nullable
              as bool,
      screenReaderMode: null == screenReaderMode
          ? _value.screenReaderMode
          : screenReaderMode // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$AccessibilitySettingsImpl implements _AccessibilitySettings {
  const _$AccessibilitySettingsImpl(
      {this.fontSizeMultiplier = 1.0,
      this.highContrast = false,
      this.reduceMotion = false,
      this.screenReaderMode = false});

  @override
  @JsonKey()
  final double fontSizeMultiplier;
  @override
  @JsonKey()
  final bool highContrast;
  @override
  @JsonKey()
  final bool reduceMotion;
  @override
  @JsonKey()
  final bool screenReaderMode;

  @override
  String toString() {
    return 'AccessibilitySettings(fontSizeMultiplier: $fontSizeMultiplier, highContrast: $highContrast, reduceMotion: $reduceMotion, screenReaderMode: $screenReaderMode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccessibilitySettingsImpl &&
            (identical(other.fontSizeMultiplier, fontSizeMultiplier) ||
                other.fontSizeMultiplier == fontSizeMultiplier) &&
            (identical(other.highContrast, highContrast) ||
                other.highContrast == highContrast) &&
            (identical(other.reduceMotion, reduceMotion) ||
                other.reduceMotion == reduceMotion) &&
            (identical(other.screenReaderMode, screenReaderMode) ||
                other.screenReaderMode == screenReaderMode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fontSizeMultiplier, highContrast,
      reduceMotion, screenReaderMode);

  /// Create a copy of AccessibilitySettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccessibilitySettingsImplCopyWith<_$AccessibilitySettingsImpl>
      get copyWith => __$$AccessibilitySettingsImplCopyWithImpl<
          _$AccessibilitySettingsImpl>(this, _$identity);
}

abstract class _AccessibilitySettings implements AccessibilitySettings {
  const factory _AccessibilitySettings(
      {final double fontSizeMultiplier,
      final bool highContrast,
      final bool reduceMotion,
      final bool screenReaderMode}) = _$AccessibilitySettingsImpl;

  @override
  double get fontSizeMultiplier;
  @override
  bool get highContrast;
  @override
  bool get reduceMotion;
  @override
  bool get screenReaderMode;

  /// Create a copy of AccessibilitySettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccessibilitySettingsImplCopyWith<_$AccessibilitySettingsImpl>
      get copyWith => throw _privateConstructorUsedError;
}
