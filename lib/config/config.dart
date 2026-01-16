class Config {
  // Update this with your backend URL
  static const String baseUrl = 'http://192.168.1.14:3000';
  static const String apiUrl = '$baseUrl/api';
  static const String wsUrl = 'http://192.168.1.14:3000';
  
  // Message expiry in hours
  static const int messageExpiryHours = 12;
  
  // App settings
  static const String appName = 'Incognito Chats';
  static const int searchDebounceMs = 500;
  static const int maxImageSizeMB = 5;
}
