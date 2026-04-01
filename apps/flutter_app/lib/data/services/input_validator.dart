import 'network_config.dart';

/// Input validation for security and UX
/// Enforces length limits, content filtering, and basic sanitization
class InputValidator {
  /// Validate player action text
  /// Returns error message if invalid, null if valid
  static String? validateActionText(String? input) {
    if (input == null || input.isEmpty) {
      return 'Action cannot be empty';
    }

    if (input.length < NetworkConfig.minActionTextLength) {
      return 'Action must be at least 1 character';
    }

    if (input.length > NetworkConfig.maxActionTextLength) {
      return 'Action cannot exceed ${NetworkConfig.maxActionTextLength} characters (${input.length} entered)';
    }

    // Basic whitespace validation
    if (input.trim().isEmpty) {
      return 'Action cannot be only whitespace';
    }

    return null;
  }

  /// Validate clarification answer
  static String? validateClarificationAnswer(String? input) {
    if (input == null || input.isEmpty) {
      return 'Answer cannot be empty';
    }

    if (input.length > NetworkConfig.maxClarificationAnswerLength) {
      return 'Answer cannot exceed ${NetworkConfig.maxClarificationAnswerLength} characters';
    }

    if (input.trim().isEmpty) {
      return 'Answer cannot be only whitespace';
    }

    return null;
  }

  /// Validate save slot name
  static String? validateSaveSlotName(String? input) {
    if (input == null || input.isEmpty) {
      return 'Save name cannot be empty';
    }

    if (input.length > 100) {
      return 'Save name cannot exceed 100 characters';
    }

    return null;
  }

  /// Sanitize input by trimming and removing excessive whitespace
  /// Does NOT remove content - safe to call on user input
  static String sanitize(String input) {
    // Remove leading/trailing whitespace
    String sanitized = input.trim();
    
    // Collapse multiple spaces to single space
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    
    return sanitized;
  }

  /// Check if input contains suspicious patterns
  /// Returns false if patterns are detected that might indicate injection attempts
  /// NOTE: This is client-side only and NOT a security boundary.
  /// Backend must validate all inputs.
  static bool isSuspicious(String input) {
    // Common SQL injection patterns (client-side warning only)
    final sqlPatterns = RegExp(
      r"(union|select|insert|update|delete|drop|create|alter|exec|execute|script|javascript|onerror|onload)",
      caseSensitive: false,
    );

    if (sqlPatterns.hasMatch(input)) {
      return true;
    }

    return false;
  }
}
