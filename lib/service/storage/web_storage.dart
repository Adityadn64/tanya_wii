// import 'dart:convert';
import 'dart:html' as html;

class StorageService {
  void saveChatHistory(String messagesJson) {
    // final encodedJson = Uri.encodeComponent(messagesJson);
    // html.window.document.cookie =
    //     'chat_history=$encodedJson; path=/; max-age=86400';
    // print("Chat history saved in cookies");
    html.window.localStorage['chat_history'] = messagesJson;
  }

  String? loadChatHistory() {
    // final cookies = html.window.document.cookie;
    // final cookieString = cookies?.split('; ').firstWhere(
    //       (cookie) => cookie.startsWith('chat_history='),
    //       orElse: () => 'chat_history=',
    //     );
    // if (cookieString != null) {
    //   final chatHistoryJson = cookieString.split('=')[1];
    //   return Uri.decodeComponent(chatHistoryJson);
    // }
    // return null;
    return html.window.localStorage['chat_history'];
  }

  void clearChatHistory() {
    // html.window.document.cookie =
    //     'chat_history=; path=/; max-age=0'; // Clear cookie
    // print("Chat history cleared from cookies");
    html.window.localStorage.remove('chat_history');
  }

  void saveDetailStorage(String detail) {
    // final encodedJson = Uri.encodeComponent(detail);
    // html.window.document.cookie = 'detail=$encodedJson; path=/; max-age=86400';
    // print("Chat history saved in cookies");
    html.window.localStorage['detail'] = detail;
  }

  String? loadDetailStorage() {
    // final cookies = html.window.document.cookie;
    // final cookieString = cookies?.split('; ').firstWhere(
    //       (cookie) => cookie.startsWith('detail='),
    //       orElse: () => 'detail=',
    //     );
    // if (cookieString != null) {
    //   final detailStorageJson = cookieString.split('=')[1];
    //   return Uri.decodeComponent(detailStorageJson);
    // }
    // return null;
    return html.window.localStorage['detail'];
  }

  void clearDetailStorage() {
    // html.window.document.cookie = 'detail=; path=/; max-age=0'; // Clear cookie
    // print("Chat history cleared from cookies");
    html.window.localStorage.remove('detail');
  }
}
