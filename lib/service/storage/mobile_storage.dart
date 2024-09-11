import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveChatHistory(String messagesJson) async {
    await _storage.write(key: 'chat_history', value: messagesJson);
    // print("Chat history saved in secure storage");
  }

  Future<String?> loadChatHistory() async {
    return await _storage.read(key: 'chat_history');
  }

  Future<void> clearChatHistory() async {
    await _storage.delete(key: 'chat_history');
    // print("Chat history cleared from secure storage");
  }

  Future<void> saveDetailStorage(String detail) async {
    await _storage.write(key: 'detail', value: detail);
  }

  Future<String?> loadDetailStorage() async {
    return await _storage.read(key: 'detail');
  }

  Future<void> clearDetailStorage() async {
    await _storage.delete(key: 'detail');
    // print("Chat history cleared from secure storage");
  }
}
