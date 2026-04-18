import '../config/constants.dart';

/// Content filter result
class FilterResult {
  final bool isAllowed;
  final String filteredText;
  final String? reason;

  const FilterResult({
    required this.isAllowed,
    required this.filteredText,
    this.reason,
  });
}

/// Content filter for messages — blocks URLs, phone numbers, social handles
class ContentFilter {
  ContentFilter._();

  static final RegExp _urlRegex = RegExp(
    AppConstants.urlPattern,
    caseSensitive: false,
  );

  static final RegExp _phoneRegex = RegExp(
    AppConstants.phonePattern,
  );

  /// Filter a message for prohibited content
  static FilterResult filterMessage(String text) {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return const FilterResult(
        isAllowed: false,
        filteredText: '',
        reason: 'Message cannot be empty',
      );
    }

    // Check for URLs
    if (_urlRegex.hasMatch(trimmed)) {
      return FilterResult(
        isAllowed: false,
        filteredText: trimmed,
        reason: 'Links are not allowed in messages',
      );
    }

    // Check for phone numbers (sequences of 7+ digits)
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length >= 7) {
      return FilterResult(
        isAllowed: false,
        filteredText: trimmed,
        reason: 'Phone numbers are not allowed in messages',
      );
    }

    // Check for social media keywords
    final lowerText = trimmed.toLowerCase();
    for (final keyword in AppConstants.blockedSocialKeywords) {
      if (lowerText.contains(keyword)) {
        return FilterResult(
          isAllowed: false,
          filteredText: trimmed,
          reason: 'Social media handles are not allowed',
        );
      }
    }

    return FilterResult(
      isAllowed: true,
      filteredText: trimmed,
    );
  }

  /// Validate intent text (same rules but less strict on phone numbers)
  static FilterResult filterIntentText(String text) {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return const FilterResult(
        isAllowed: false,
        filteredText: '',
        reason: 'Intent text cannot be empty',
      );
    }

    if (trimmed.length > AppConstants.maxIntentLength) {
      return FilterResult(
        isAllowed: false,
        filteredText: trimmed,
        reason: 'Intent must be ${AppConstants.maxIntentLength} characters or less',
      );
    }

    // Check for URLs
    if (_urlRegex.hasMatch(trimmed)) {
      return FilterResult(
        isAllowed: false,
        filteredText: trimmed,
        reason: 'Links are not allowed',
      );
    }

    // Check for social keywords
    final lowerText = trimmed.toLowerCase();
    for (final keyword in AppConstants.blockedSocialKeywords) {
      if (lowerText.contains(keyword)) {
        return FilterResult(
          isAllowed: false,
          filteredText: trimmed,
          reason: 'Social media references are not allowed',
        );
      }
    }

    return FilterResult(
      isAllowed: true,
      filteredText: trimmed,
    );
  }
}
