export const BLOCKED_SOCIAL_KEYWORDS = [
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

export const URL_PATTERN = /(https?:\/\/[^\s]+)|(www\.[^\s]+)|([a-zA-Z0-9-]+\.(com|org|net|io|co|me|app|dev|xyz)[^\s]*)/i;
export const PHONE_PATTERN = /(\+?\d{1,4}[\s.-]?)?\(?\d{1,4}\)?[\s.-]?\d{1,4}[\s.-]?\d{1,9}/;

export interface FilterResult {
  isAllowed: boolean;
  filteredText: string;
  reason?: string;
}

export function filterMessage(text: string): FilterResult {
  const trimmed = text.trim();

  if (trimmed.length === 0) {
    return {
      isAllowed: false,
      filteredText: '',
      reason: 'Message cannot be empty',
    };
  }

  // Check for URLs
  if (URL_PATTERN.test(trimmed)) {
    return {
      isAllowed: false,
      filteredText: trimmed,
      reason: 'Links are not allowed in messages',
    };
  }

  // Check for phone numbers
  const digitsOnly = trimmed.replace(/[^\d]/g, '');
  if (digitsOnly.length >= 7) {
    return {
      isAllowed: false,
      filteredText: trimmed,
      reason: 'Phone numbers are not allowed in messages',
    };
  }

  // Check for social media keywords
  const lowerText = trimmed.toLowerCase();
  for (const keyword of BLOCKED_SOCIAL_KEYWORDS) {
    if (lowerText.includes(keyword)) {
      return {
        isAllowed: false,
        filteredText: trimmed,
        reason: 'Social media handles are not allowed',
      };
    }
  }

  return {
    isAllowed: true,
    filteredText: trimmed,
  };
}
