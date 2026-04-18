/// Application-wide constants for Right Now MVP
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Right Now';
  static const String appVersion = '1.0.0';

  // Intent constraints
  static const int maxIntentLength = 80;
  static const int maxPhotos = 3;

  // Time constraints (in minutes)
  static const int postExpiryMinutes = 60;
  static const int initialResponseWindowMinutes = 120; // 2 hours
  static const int chatInactivityExpiryMinutes = 60;

  // Expiry job interval
  static const int expiryJobIntervalMinutes = 5;

  // Content filter patterns
  static const List<String> blockedSocialKeywords = [
    'insta',
    'instagram',
    'snap',
    'snapchat',
    'twitter',
    'tiktok',
    'facebook',
    'whatsapp',
    'telegram',
    'signal',
    'discord',
    'linkedin',
    'youtube',
    'onlyfans',
  ];

  // URL regex pattern
  static const String urlPattern =
      r'(https?:\/\/[^\s]+)|(www\.[^\s]+)|([a-zA-Z0-9-]+\.(com|org|net|io|co|me|app|dev|xyz)[^\s]*)';

  // Phone number regex pattern  
  static const String phonePattern =
      r'(\+?\d{1,4}[\s.-]?)?\(?\d{1,4}\)?[\s.-]?\d{1,4}[\s.-]?\d{1,9}';

  // Report reasons
  static const List<String> reportReasons = [
    'Harassment',
    'Spam',
    'Inappropriate content',
    'Impersonation',
    'Other',
  ];

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String interestsCollection = 'interests';
  static const String matchesCollection = 'matches';
  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';
  static const String reportsCollection = 'reports';
  static const String blocksCollection = 'blocks';
}

/// Enums used throughout the app

enum Gender { man, woman, nonbinary }

enum Preference { men, women, everyone }

enum RelationshipType { solo, couple, open }

enum ContentMode { safe, openEnabled }

enum IntentType { talk, meet, date, open }

enum PostStatus { active, expired }

enum ChatStatus { active, expired, blocked }

enum MatchStatus { active, expired }

// Extension methods for enum display names
extension GenderExtension on Gender {
  String get displayName {
    switch (this) {
      case Gender.man:
        return 'Man';
      case Gender.woman:
        return 'Woman';
      case Gender.nonbinary:
        return 'Non-binary';
    }
  }

  String get value {
    switch (this) {
      case Gender.man:
        return 'man';
      case Gender.woman:
        return 'woman';
      case Gender.nonbinary:
        return 'nonbinary';
    }
  }

  static Gender fromString(String value) {
    switch (value) {
      case 'man':
        return Gender.man;
      case 'woman':
        return Gender.woman;
      case 'nonbinary':
        return Gender.nonbinary;
      default:
        return Gender.man;
    }
  }
}

extension PreferenceExtension on Preference {
  String get displayName {
    switch (this) {
      case Preference.men:
        return 'Men';
      case Preference.women:
        return 'Women';
      case Preference.everyone:
        return 'Everyone';
    }
  }

  String get value {
    switch (this) {
      case Preference.men:
        return 'men';
      case Preference.women:
        return 'women';
      case Preference.everyone:
        return 'everyone';
    }
  }

  static Preference fromString(String value) {
    switch (value) {
      case 'men':
        return Preference.men;
      case 'women':
        return Preference.women;
      case 'everyone':
        return Preference.everyone;
      default:
        return Preference.everyone;
    }
  }
}

extension RelationshipTypeExtension on RelationshipType {
  String get displayName {
    switch (this) {
      case RelationshipType.solo:
        return 'Solo';
      case RelationshipType.couple:
        return 'Couple';
      case RelationshipType.open:
        return 'Open';
    }
  }

  String get value {
    switch (this) {
      case RelationshipType.solo:
        return 'solo';
      case RelationshipType.couple:
        return 'couple';
      case RelationshipType.open:
        return 'open';
    }
  }

  static RelationshipType fromString(String value) {
    switch (value) {
      case 'solo':
        return RelationshipType.solo;
      case 'couple':
        return RelationshipType.couple;
      case 'open':
        return RelationshipType.open;
      default:
        return RelationshipType.solo;
    }
  }
}

extension ContentModeExtension on ContentMode {
  String get displayName {
    switch (this) {
      case ContentMode.safe:
        return 'Safe';
      case ContentMode.openEnabled:
        return 'Open';
    }
  }

  String get value {
    switch (this) {
      case ContentMode.safe:
        return 'safe';
      case ContentMode.openEnabled:
        return 'open_enabled';
    }
  }

  static ContentMode fromString(String value) {
    switch (value) {
      case 'safe':
        return ContentMode.safe;
      case 'open_enabled':
        return ContentMode.openEnabled;
      default:
        return ContentMode.safe;
    }
  }
}

extension IntentTypeExtension on IntentType {
  String get displayName {
    switch (this) {
      case IntentType.talk:
        return 'Talk';
      case IntentType.meet:
        return 'Meet';
      case IntentType.date:
        return 'Date';
      case IntentType.open:
        return 'Open';
    }
  }

  String get value {
    switch (this) {
      case IntentType.talk:
        return 'talk';
      case IntentType.meet:
        return 'meet';
      case IntentType.date:
        return 'date';
      case IntentType.open:
        return 'open';
    }
  }

  String get emoji {
    switch (this) {
      case IntentType.talk:
        return '💬';
      case IntentType.meet:
        return '☕';
      case IntentType.date:
        return '✨';
      case IntentType.open:
        return '🔓';
    }
  }

  static IntentType fromString(String value) {
    switch (value) {
      case 'talk':
        return IntentType.talk;
      case 'meet':
        return IntentType.meet;
      case 'date':
        return IntentType.date;
      case 'open':
        return IntentType.open;
      default:
        return IntentType.talk;
    }
  }
}
