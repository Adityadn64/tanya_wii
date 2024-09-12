import 'dart:convert';
import 'dart:math';

import 'package:tex_markdown/tex_markdown.dart';
import 'package:translit/translit.dart';

// import 'style/inputMarkDown.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/auth/user.dart';
import '../service/storage/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:video_player/video_player.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
// import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controllerInput = TextEditingController();
  final TextEditingController _controllerInputEditing = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, List<dynamic>>> _messages = [];
  final ValueNotifier<bool> _isButtonEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isButtonEnabledEditing =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isGenerateAnsBot = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isHasClientsScrollController =
      ValueNotifier<bool>(false);

  final StorageService _storageService = StorageService();
  final optionOfSafetySettings = [false, false, false, false, false];
  final isSafetySettings = false;

  final List<md.BlockSyntax> blockSyntaxes = [
    const md.AlertBlockSyntax(),
    const md.BlockquoteSyntax(),
    const md.CodeBlockSyntax(),
    // md.DummyBlockSyntax(),
    // md.EmptyBlockSyntax(),
    const md.FencedBlockquoteSyntax(),
    const md.FencedCodeBlockSyntax(),
    const md.FootnoteDefSyntax(),
    const md.HeaderSyntax(),
    const md.HeaderWithIdSyntax(),
    const md.HorizontalRuleSyntax(),
    const md.HtmlBlockSyntax(),
    const md.OrderedListSyntax(),
    const md.OrderedListWithCheckboxSyntax(),
    const md.SetextHeaderSyntax(),
    const md.SetextHeaderWithIdSyntax(),
    const md.TableSyntax(),
    const md.ParagraphSyntax(),
    const md.UnorderedListSyntax(),
    const md.UnorderedListWithCheckboxSyntax(),
    LatexBlockSyntax(),
  ];

  final List<md.InlineSyntax> inlineSyntaxes = [
    md.SoftLineBreakSyntax(),
    md.AutolinkSyntax(),
    md.AutolinkExtensionSyntax(),
    md.AutolinkSyntax(),
    md.CodeSyntax(),
    md.ColorSwatchSyntax(),
    md.DecodeHtmlSyntax(),
    md.EmailAutolinkSyntax(),
    md.EmojiSyntax(),
    // md.EscapeHtmlSyntax(),
    md.InlineHtmlSyntax(),
    md.LineBreakSyntax(),
    md.StrikethroughSyntax(),
    LatexInlineSyntax(),
  ];

  // final CustomLatexEditingController _controllerInput =
  //     CustomLatexEditingController();

  Uint8List? _fileBytes;
  String? _fileName;
  bool _isFilePicked = false;
  bool _generateAnsBot = false;
  // Uri? _uri;
  String _url = "";
  String? _mimeType;

  String? _photoURL;
  String? _displayName;

  // late AnimationController _controllerInputLoadingFilePick;

  double _process = 0;

  ChatSession? _chat;
  List<Content>? previousMessages;
  GenerativeModel? model;

  int? _editingIndex;
  bool _editingUser = false;

  @override
  void initState() {
    super.initState();
    _controllerInput.addListener(_handleTextChanged);
    _controllerInputEditing.addListener(_handleTextChanged);
    _loadChatHistory();
    _scrollToBottom();

    // _isHasClientsScrollController.value = _scrollController.hasClients;
    // Add listener to monitor hasClients changes
    _scrollController.addListener(() {
      _isHasClientsScrollController.value = _scrollController.hasClients;
    });
    // Perform the asynchronous operation
    MyUser().loadUserData().then((userResult) {
      // After the async operation completes, update the state
      if (mounted) {
        // Check if the widget is still in the tree
        setState(() {
          // _displayName = userResult?.displayName;
          _photoURL = userResult?.photoURL;
          _displayName = userResult?.displayName;
        });
      }
    });

    // _controllerInputLoadingFilePick = AnimationController(
    //   /// [AnimationController]s can be created with `vsync: this` because of
    //   /// [TickerProviderStateMixin].
    //   vsync: this,
    //   // duration: const Duration(seconds: 2),
    // )..addListener(() {
    //     setState(() {});
    //   });
    // _controllerInputLoadingFilePick.repeat(reverse: true);

    var apiKey = dotenv.env['API_KEY'] ?? "";
    var modelV = "gemini-1.5-flash";

    // print(apiKey);

    final safetySettings = [
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.low),
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.low),
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.low),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.low),
      // SafetySetting(HarmCategory.unspecified, HarmBlockThreshold.low),
    ];

    final model = GenerativeModel(
      model: modelV,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.5,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'text/plain',
      ),
      safetySettings: safetySettings,
      systemInstruction: Content.multi(
        [
          if (_displayName != null)
            TextPart(
              "Namaku $_displayName",
            ),
          TextPart(
            "Tanyawii adalah Chatbot yang dikembangkan oleh Aditya Dwi Nugraha",
          ),
          TextPart(
            "Kamu adalah Dwi, chatbot yang dikembangkan oleh Aditya Dwi Nugraha pada Tahun 2024",
          ),
          TextPart(
            "Kamu mengenal Dwi yaitu Aditya Dwi Nugraha",
          ),
          TextPart(
            "Aditya Dwi Nugraha adalah seorang Developer",
          ),
          TextPart(
            "Aditya Dwi Nugraha memiliki minat dan bakat Coding pada tahun 2020 sejak usia 10 Tahun",
          ),
          // TextPart(
          //   "Aditya Dwi Nugraha menyukai seseorang yang bernama Capa",
          // ),
          // TextPart(
          //   "Aditya Dwi Nugraha mencintai seseorang yang bernama Capa",
          // ),
          TextPart(
            "Nyxeldevid adalah organisasi yang didirikan oleh Aditya Dwi Nugraha",
          ),
          TextPart(
            "Nyxeldevid terletak di Toko kedua orang tuanya Aditya Dwi Nugraha",
          ),
          TextPart(
            "Toko kedua orang tuanya Aditya Dwi Nugraha terletak di Indonesia, Jawa, Jawa Timur, Sidoarjo, Taman, Sidodadi, Sambirono Wetan",
          ),
          TextPart(
            "Aditya Dwi Nugraha menguasai beberapa bahasa pemrograman antara lain: JavaScript, Python, PHP & Flutter",
          ),
          TextPart(
            "Aditya Dwi Nugraha bisa dipanggil Adit atau Dwi",
          ),
          TextPart(
            'Nama Tanyawii terinspirasi dari teman teman Aditya Dwi Nugraha yang selalu bertanya ke Aditya Dwi Nugraha dengan memanggilnya "Wii Takon" dalam bahasa jawa yang artinya "Wii Tanya"',
          ),
        ],
      ),
    );

    var previousMessages = _messages
        .map((message) {
          if (message.containsKey('user')) {
            return Content.multi([
              TextPart(message.containsKey("index")
                  ? message['user']![message["index"]?.last]
                  : message['user']?.last),
            ]);
          } else if (message.containsKey('bot')) {
            return Content.model([
              TextPart(message.containsKey("index")
                  ? message['bot']![message["index"]?.last]
                  : message['bot']?.last),
            ]);
          }
          return null;
        })
        .whereType<Content>()
        .toList();

    _chat = model.startChat(history: previousMessages);
  }

  @override
  void dispose() {
    _controllerInput.removeListener(_handleTextChanged);
    _controllerInput.dispose();
    _controllerInputEditing.removeListener(_handleTextChanged);
    _controllerInputEditing.dispose();
    _isButtonEnabled.dispose();
    _isButtonEnabledEditing.dispose();
    // _scrollToBottom();
    super.dispose();
  }

  void _handleTextChanged() {
    _isButtonEnabled.value =
        (_controllerInput.text.trim().isNotEmpty || _isFilePicked); // &&
    !_generateAnsBot;
    _isButtonEnabledEditing.value =
        (_controllerInputEditing.text.trim().isNotEmpty || _isFilePicked); // &&
    !_generateAnsBot;
    _isGenerateAnsBot.value = _generateAnsBot;
  }

  void _breakGeneration() {
    setState(() {
      _generateAnsBot = false;
    });
  }

  Future<void> _catchResponse({
    bool regenerate = true,
    int? index,
    bool isProcessGenerate = true,
    String? error,
  }) async {
    // Map<String, List<dynamic>>? messageReUser =
    //     regenerate ? _messages[index! - 1] : {};
    Map<String, List<dynamic>>? messageReBot =
        regenerate ? _messages[index!] : {};

    setState(() {
      if (regenerate) {
        if (isProcessGenerate) {
          messageReBot["bot"]?.last =
              "Failed to get response from model. $error";
          messageReBot["error"]?.last = true;
        } else {
          messageReBot["bot"]?.add("Failed to get response from model.");
          // messageReBot["index"]?.last + 1;
          messageReBot["error"]?.add(true);
        }
        messageReBot["index"]?.last = messageReBot["bot"]!.length - 2;
        // messageReBot["index"]?.add(
        //   messageReBot.containsKey("index")
        //       ? messageReBot["index"]?.last + 1
        //       : 1,
        // );
      } else {
        _messages[_messages.length - 1] = {
          'bot': ['Failed to get response from model.'],
          "error": [true],
        };
      }
      _scrollToBottom();
    });

    if (kDebugMode) {
      print("Error Bot: $e");
    }

    if (regenerate) {
      if (kDebugMode) {
        print("_catchResponse regenerate last");
      }
      messageReBot.containsKey("index")
          ? messageReBot["index"] = [messageReBot["index"]?.last + 1]
          : messageReBot["index"] = [1];
    }
  }

  Future<void> _ganResponseBot({
    Content? content,
    required bool regenerate,
    int? index,
    bool isBotMessage = true,
    bool isUserEdit = true,
    String? fileName,
    String? url,
    String? textOfEdit,
    Uint8List? fileBytesRe,
    String? mimeTypeRe,
  }) async {
    try {
      // Uint8List? fileBytesRe;
      // String? mimeTypeRe;
      Map<String, List<dynamic>>? messageReBot = {};
      Map<String, List<dynamic>>? messageReUser = {};
      Content? contentRe;
      String? url_;
      // int? indexUpdt;
      int? messageReUserLenght;
      int? messageReBotLenght;

      if (kDebugMode) {
        print("_ganResponseBot 1");
        print(regenerate);
        print(_chat);
        print(previousMessages);
        print(_messages);
      }

      if (regenerate) {
        // textOfEdit = Translit().toTranslit(source: textOfEdit!);
        // messageReUser = isUserEdit == true && isBotMessage == false
        //     ? _messages[index!]
        //     : _messages[index! - 1];
        // messageReBot = isBotMessage == true && isUserEdit == false
        //     ? _messages[index + 1]
        //     : _messages[index];

        if (isUserEdit == true && isBotMessage == false) {
          messageReUser = _messages[index!];
          messageReBot = _messages[index + 1];
        } else if (isBotMessage == true && isUserEdit == false) {
          messageReBot = _messages[index!];
          messageReUser = _messages[index - 1];
        } else {
          return showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: SelectionArea(
                  child: MarkdownBody(
                    data:
                        "Invalid Regenerate isBotMessage && isUserEdit not in conditions!",
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              );
            },
          );
        }

        messageReUserLenght = messageReUser["user"]!.length;
        messageReBotLenght = messageReBot["bot"]!.length;

        // if (messageReUser.containsKey("index")) {
        //   if (messageReUserLenght != messageReUser["index"]?.last) {
        //     indexUpdt = messageReUserLenght;
        //   }
        // }

        if (kDebugMode) {
          print("The Pesan ulang:");
          print(index);
          print("$messageReBot $messageReUser");
          print([messageReUserLenght, messageReBotLenght]);
        }

        messageReUser["user"]?.add(isUserEdit
            ? textOfEdit
            : messageReUser.containsKey("index")
                ? messageReUser["user"]![messageReUser["index"]?.last]
                : messageReUser["user"]?.last);

        messageReUser["url"]?.add(isUserEdit
            ? url
            : messageReUser.containsKey("index")
                ? messageReUser["url"]![messageReUser["index"]?.last]
                : messageReUser["url"]?.last);

        messageReUser["fileName"]?.add(isUserEdit
            ? fileName
            : messageReUser.containsKey("index")
                ? messageReUser["url"]![messageReUser["index"]?.last]
                : messageReUser["fileName"]?.last);

        // messageReUser["index"]?.last = messageReUser.containsKey("index")
        //     ? [messageReUser["index"]?.last + 1]
        //     : [1];

        // messageReUser["error"]?.add(false);
        messageReUser.containsKey("index")
            ? messageReUser["index"] = [messageReUserLenght]
            : messageReUser["index"] = [1];
      }

      if (regenerate &&
          (url != null || messageReUser["url"]?.last.isNotEmpty)) {
        if (kDebugMode) {
          print("contain url: ${messageReUser["url"]!}");
        }

        url_ = messageReUser["url"]?.last;

        String? fileName_ = messageReUser["fileName"]?.last;

        if (url_!.isNotEmpty)
          fileBytesRe = fileBytesRe ?? await fetchFileBytes(url_);
        if (fileName_!.isNotEmpty) {
          mimeTypeRe =
              mimeTypeRe ?? lookupMimeType(fileName_, headerBytes: fileBytesRe);
        }

        if (kDebugMode) {
          print(mimeTypeRe);
        }
      }

      if (kDebugMode) {
        print("_ganResponseBot 2");
        print(messageReUser);
      }

      if (regenerate) {
        contentRe = Content.multi([
          if (mimeTypeRe != null && fileBytesRe != null)
            DataPart(mimeTypeRe, fileBytesRe),
          TextPart(messageReUser.containsKey("index")
              ? messageReUser["user"]![messageReUser["index"]?.last as int]
              : messageReUser["user"]?.last),
        ]);
      }

      // if (kDebugMode) {
      //   print(contentRe.toString());
      //   print(messageReUser.toString());
      // }

      if (kDebugMode) {
        print("_ganResponseBot 3");
        // print("_chat Session: $_chat");
      }

      try {
        setState(() {
          regenerate
              ? messageReBot!['bot']?.add("Regenerating response...")
              : _messages.add({
                  'bot': ['Generating response...']
                });

          if (regenerate) {
            messageReBot!["error"]?.add(false);
            messageReBot.containsKey("index")
                ? messageReBot["index"] = [messageReBotLenght]
                : messageReBot["index"] = [1];
          }
        });

        final response = await _chat!.sendMessage(
          regenerate ? contentRe! : content!,
        );

        if (kDebugMode) {
          print("_ganResponseBot 4");
          print(response.candidates);
          print(response.promptFeedback);
          print(response.usageMetadata);
        }

        final responseText = Translit().toTranslit(source: response.text!);

        if (kDebugMode) {
          print(
              "Response Bot: $response\nResponse Bot the Text: $responseText");
        }

        setState(() {
          regenerate
              ? messageReBot!['bot']?.last = ""
              : _messages[_messages.length - 1] = {
                  'bot': [""],
                  "error": [false],
                };
          _scrollToBottom();
          _generateAnsBot = true;
        });

        int speed = 50;

        for (int i = 1; i <= responseText.length; i++) {
          final User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            speed *= 10;
          }

          if (kDebugMode) {
            print(user);
            print(_messages);
          }

          if (i % speed == 0) {
            await Future.delayed(Duration(milliseconds: (1 / i).round()));
          }

          if (_generateAnsBot) {
            setState(() {
              regenerate
                  ? messageReBot!["bot"]?.last = responseText.substring(0, i)
                  : _messages[_messages.length - 1] = {
                      'bot': [responseText.substring(0, i)]
                    };
              _scrollToBottom();
            });
          } else {
            break;
          }
        }
      } catch (e) {
        await _catchResponse(
          index: isUserEdit ? index! + 1 : index,
          regenerate: true,
          isProcessGenerate: true,
          error: e.toString(),
        );
      }
    } catch (e) {
      await _catchResponse(
        index: isUserEdit ? index! + 1 : index,
        regenerate: true,
        isProcessGenerate: false,
        error: e.toString(),
      );
    }

    setState(() {
      _fileBytes = null;
      _fileName = "";
      _isFilePicked = false;
      _url = "";
      _mimeType = "";
      _generateAnsBot = false;
    });

    _handleTextChanged();

    await _saveChatHistory();
    if (kDebugMode) {
      print("_ganResponseBot 5");
    }
  }

  void _sendMessage({
    bool isHasFileContent = true,
    String? fileName,
    String? mimeType,
    String? url,
  }) async {
    setState(() {
      _isFilePicked = false;
      _generateAnsBot = true;
    });

    var inputUser = Translit().toTranslit(source: _controllerInput.text);
    if (inputUser.trim().isEmpty && !isHasFileContent) {
      return;
    }

    if (kDebugMode) {
      print("URL adalah: $url ini.");
      print(inputUser);
      print(
          ("has content: $isHasFileContent, url: $url, file name: $fileName"));
    }

    setState(() {
      // Add the user's message immediately

      _messages.add({
        'user': [inputUser],
        'url': [isHasFileContent == true ? url : ""],
        'fileName': [isHasFileContent == true ? fileName : ""]
      });

      _controllerInput.clear();
      _scrollToBottom();
    });

    try {
      Uint8List? fileBytes;

      if (isHasFileContent) {
        fileBytes = await fetchFileBytes(url!); // Ensure URL is not null
      }

      if (fileBytes != null) {
        if (kDebugMode) {
          print("fileBytes berhasil diambil");
        }
      }

      if (kDebugMode) {
        print(inputUser);
      }

      final content = Content.multi([
        if (isHasFileContent)
          DataPart(mimeType!,
              fileBytes!), // Ensure mimeType and fileBytes are not null
        TextPart(Translit().toTranslit(source: inputUser)),
      ]);

      await _ganResponseBot(content: content, regenerate: false);

      // setState(() {
      //   _messages[_messages.length - 1] = {'bot': responseText};
      //   _scrollToBottom();
      // });

      _scrollToBottom();
    } catch (e) {
      if (e.toString().contains('429')) {
        setState(() {
          _messages[_messages.length - 1] = {
            'bot': ['Rate limit exceeded. Please try again later.'],
            "error": [true],
          };
          _scrollToBottom();
        });
      } else {
        setState(() {
          _messages[_messages.length - 1] = {
            'bot': ['Failed to get response from model. $e'],
            "error": [true],
          };
          _scrollToBottom();
        });
      }
      if (kDebugMode) {
        print("Error Bot: $e");
      }
    }

    setState(() {
      _fileBytes = null;
      _fileName = "";
      _isFilePicked = false;
      _url = "";
      _mimeType = "";
      _generateAnsBot = false;
    });

    _handleTextChanged();

    await _saveChatHistory();
    if (kDebugMode) {
      print("Save Message");
    }

    _scrollToBottom();
  }

  Future<Uint8List?> fetchFileBytes(String dataUrl) async {
    try {
      final response = await http.get(Uri.parse(dataUrl));

      if (kDebugMode) {
        print(dataUrl);
      }
      // if (kDebugMode) {
      //   print(Uri.parse(dataUrl) as String?);
      // }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('File bytes length: ${response.bodyBytes.length}');
        }
        return response.bodyBytes;
      }
      if (kDebugMode) {
        print('Failed to load url. Status code: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching url bytes: $e');
      }
    }
    return null;
  }

  Future<void> _saveChatHistory() async {
    try {
      final messagesJson = jsonEncode(_messages.map((message) {
        final updatedMessage = Map<String, List<dynamic>>.from(message);

        return updatedMessage; // Tidak perlu membuat map baru jika tidak ada perubahan
      }).toList());

      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final uid = user.uid;
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('users').doc(uid).update({
          'chatHistory': messagesJson,
        });
        if (kDebugMode) {
          print("Chat history saved to Firestore");
        }
      } else {
        _storageService.saveChatHistory(messagesJson);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error saving chat history: $e");
      }
    }
    setState(() {
      _generateAnsBot = false;
    });
  }

  Future<void> _loadChatHistory() async {
    if (kDebugMode) {
      print("_messages ${_messages.runtimeType}");
    }
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final uid = user.uid;
        final firestore = FirebaseFirestore.instance;
        final userDoc = await firestore.collection('users').doc(uid).get();

        // print(uid);

        if (userDoc.exists) {
          final chatHistoryJson = userDoc.data()?['chatHistory'] as String?;
          if (kDebugMode) {
            print("chatHistoryJson ${chatHistoryJson.runtimeType}");
          }

          if (chatHistoryJson != null) {
            _processChatHistory(chatHistoryJson as String);
          }
        }
      } else {
        final chatHistoryJson = _storageService.loadChatHistory();
        if (kDebugMode) {
          print("chatHistoryJson ${chatHistoryJson.runtimeType}");
        }

        if (chatHistoryJson != null) {
          _processChatHistory(chatHistoryJson as String);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading chat history: $e');
      }
    }

    _scrollToBottom();
  }

  void _processChatHistory(String chatHistoryJson) {
    try {
      final List<dynamic> decodedMessages = jsonDecode(chatHistoryJson);

      final validatedMessages = decodedMessages.map((item) {
        final itemN = ["user", "url", "fileName", "bot", "error"];
        final itemS = item as Map;

        // Jika itemS bukan Map<String, List<dynamic>>, ubah menjadi Map<String, List<dynamic>>
        if (itemS is! Map<String, List<dynamic>>) {
          // Buat Map<String, List<dynamic>> baru
          final transformedItem = <String, List<dynamic>>{};

          itemS.forEach((key, value) {
            if (value is List) {
              transformedItem[key] = value.map((v) => v).toList();
            } else {
              transformedItem[key] = [value];
            }
          });

          // Ganti itemS dengan transformedItem
          itemS.clear();
          itemS.addAll(transformedItem);
        }

        final mapItem = Map<String, List<dynamic>>.from(itemS);
        // if (mapItem.containsKey('url')) {
        //   try {
        //     final url = mapItem['url'];
        //     return {
        //       ...mapItem,
        //       'url': url,
        //     };
        //   } catch (e) {
        //     if (kDebugMode) {
        //       print("Error decoding url: $e");
        //     }
        //     return mapItem; // Return the map item without fileBytes if there's an error
        //   }
        // }
        // Loop through the keys defined in itemN
        // itemN.forEach((key) {
        for (var key in itemN) {
          if (mapItem.containsKey(key)) {
            final value = mapItem[key];

            if (kDebugMode) {
              print(value);
              print(mapItem);
            }
            // If the value is not a List, wrap it in a List
            if (value is! List) {
              mapItem[key] = [value];
            } else {
              // Ensure the list is of type List<dynamic>
              mapItem[key] = value.map((v) => v).toList();
            }
          }
        }

        if (kDebugMode) {
          print(mapItem);
        }
        // );
        return mapItem;
      }).toList();

      if (kDebugMode) {
        print(validatedMessages);
      }

      setState(() {
        _messages.addAll(
            validatedMessages.cast<Map<String, List<dynamic>>>().toList());
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding chat history: $e');
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error decoding chat history"),
            content: const Text(
                "An error occurred when retrieving chat history because TanyaWii has updated to the latest version, click delete chat to start a new chat"),
            actions: <Widget>[
              TextButton(
                onPressed: () => _confirmClearChatHistory(all: true),
                child: const Text('Delete Messages'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _confirmClearChatHistory({
    bool all = true,
    int? index,
    Map<String, List<dynamic>>? message,
    bool? isUserMessage,
  }) async {
    try {
      // Determine the URL and filename based on message content
      String? url_;
      String? fileName_;
      Uint8List? fileBytes_;

      // if (kDebugMode) {
      //   print("confirm clear chat history: $all $index");
      //   if (index != null) {
      //     print("confirm ${_messages[index]}");
      //   }
      // }

      if (all == false) {
        if (isUserMessage == false) message = _messages[index! - 1];
        bool? hasFile = (message!.containsKey("url"));
        int? indexUs;
        indexUs = message.containsKey("index") ? message["index"]?.last : null;

        if (hasFile) {
          url_ =
              indexUs != null ? message["url"]![indexUs] : message["url"]?.last;
          fileName_ = indexUs != null
              ? message["fileName"]![indexUs]
              : message["fileName"]?.last;
          fileBytes_ = await fetchFileBytes(indexUs != null
              ? message['url']![indexUs]
              : message['url']?.last);
        }

        if (kDebugMode) {
          print("The of Select And Preview");
          print(
              "${url_.toString()} ${fileName_.toString()} ${isUserMessage.toString()} ${indexUs.toString()}");
        }
      }

      final bool? confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SelectionArea(
            child: AlertDialog(
              title: MarkdownBody(
                styleSheet:
                    MarkdownStyleSheet(p: const TextStyle(fontSize: 32)),
                data: '**Confirm**',
                extensionSet: md.ExtensionSet(
                  blockSyntaxes,
                  inlineSyntaxes,
                ),
                builders: {
                  'latex': LatexElementBuilder(),
                },
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment:
                          MainAxisAlignment.start, // Adjust to start
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Are you sure you want to clear the chat history?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (index != null && all == false)
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (_hasValidUrl(
                                        message: message, anyUrl: false))
                                      IconButton(
                                        icon: const Icon(Icons.open_in_browser),
                                        onPressed: () {
                                          _launchURL(url_!);
                                        },
                                        tooltip: 'View in Browser',
                                      ),
                                    if (_hasValidUrl(
                                        message: message, anyUrl: false))
                                      Expanded(
                                        child: Text(
                                          fileName_ ?? 'Unknown File',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _hasValidUrl(message: message, anyUrl: false)
                                    ? fileBytes_ != null
                                        ? _generateFilePreviewWidget(
                                            url: url_,
                                            fileName: fileName_,
                                            fileBytes: fileBytes_,
                                            width: 384,
                                            height: 384,
                                          )
                                        : const CircularProgressIndicator() // Show loading indicator while fetching
                                    : const SizedBox(
                                        height: 0,
                                      ),
                                const SizedBox(height: 16),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment
                                      .start, // Adjust to start
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MarkdownBody(
                                      data: "**Message User:**",
                                      extensionSet: md.ExtensionSet(
                                        blockSyntaxes,
                                        inlineSyntaxes,
                                      ),
                                      builders: {
                                        'latex': LatexElementBuilder(),
                                      },
                                    ),
                                    MarkdownBody(
                                      extensionSet: md.ExtensionSet(
                                        blockSyntaxes,
                                        inlineSyntaxes,
                                      ),
                                      builders: {
                                        'latex': LatexElementBuilder(),
                                        'text': CustomTextBuilder(maxLines: 5),
                                      },
                                      data: _messages[index].containsKey("user")
                                          ? _messages[index]["user"]?.last
                                          : _messages[index - 1]["user"]
                                                  ?.last ??
                                              "No user message available",
                                    ),
                                    const SizedBox(
                                        height: 16), // Adjust spacing as needed
                                    MarkdownBody(
                                      data: "**Message Bot:**",
                                      extensionSet: md.ExtensionSet(
                                        blockSyntaxes,
                                        inlineSyntaxes,
                                      ),
                                      builders: {
                                        'latex': LatexElementBuilder(),
                                      },
                                    ),
                                    MarkdownBody(
                                      extensionSet: md.ExtensionSet(
                                        blockSyntaxes,
                                        inlineSyntaxes,
                                      ),
                                      builders: {
                                        'latex': LatexElementBuilder(),
                                        'text': CustomTextBuilder(maxLines: 5),
                                      },
                                      data: _messages[index].containsKey("bot")
                                          ? _messages[index]["bot"]?.last
                                          : _messages[index + 1]["bot"]?.last ??
                                              "No bot message available",
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        // : const Text(
                        //     'Invalid message index or no additional messages available.'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          );
        },
      );

      if (confirm == true) {
        all == true ? await _clearChatHistory() : _deleteMessage(index!);
      } else {
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  Future<void> _clearChatHistory() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      _storageService.clearChatHistory();
      setState(() {
        _messages.clear();
      });

      if (user != null) {
        final uid = user.uid;
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('users').doc(uid).update({
          'chatHistory': FieldValue.delete(),
        });
        if (kDebugMode) {
          print("Chat history cleared from Firestore");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error clearing chat history: $e");
      }
    }

    setState(() {
      _messages.clear();
    });
  }

  Future<void> _removeUploadFile() async {
    setState(() {
      _fileBytes = null;
      _fileName = "";
      _isFilePicked = false;
      _mimeType = "";
      _url = "";
      // _uri = Uri();
    });
    _handleTextChanged();
    initState();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.isNotEmpty) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Uploading'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(value: _process / 100),
                  const SizedBox(height: 16),
                  Text("Upload ${_process.round()}%"),
                ],
              ),
            );
          },
        );

        final file = result.files.single;
        final mimeType = lookupMimeType(file.name, headerBytes: file.bytes);
        final fileBytes = file.bytes;
        final fileName = file.name;

        if (fileBytes != null && fileName.isNotEmpty) {
          setState(() {
            _process = 25;
          });

          await _simulateLoading();

          setState(() {
            _process = 50;
          });

          await _simulateLoading();

          final uploadResult =
              await _uploadFileToFirebaseStorage(fileBytes, fileName, mimeType);

          setState(() {
            _process = 75;
          });

          await _simulateLoading();

          setState(() {
            // _uri = (uploadResult?.uri ?? "") as Uri;
            _url = uploadResult!;
            _process = 100;
          });

          Navigator.of(context).pop();

          setState(() {
            _isFilePicked = true;
            _fileName = fileName;
            _mimeType = mimeType;
            _fileBytes = file.bytes;
          });

          _handleTextChanged();

          if (kDebugMode) {
            print("File picked: $_isFilePicked");
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking file: $e');
      }
    }
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<String?> _uploadFileToFirebaseStorage(
      Uint8List fileBytes, String fileName, String? mimeType) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      String? detail;
      bool ale = false;
      const String chars =
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
      Random random = Random();
      int length = 10;

      if (user != null) {
        detail = user.providerData.first.email;
        ale = true;
      } else {
        detail = _storageService.loadDetailStorage() as String;
      }

      if (detail == null || detail.isEmpty) {
        detail = String.fromCharCodes(
          Iterable.generate(
            length,
            (_) => chars.codeUnitAt(random.nextInt(chars.length)),
          ),
        );
        // print("Generated detail: $detail");
        _storageService.saveDetailStorage(detail);

        // Check if it was saved correctly
        // final savedDetail = _storageService.loadDetailStorage();
        // print("Saved detail: $savedDetail");
      }

      if (kDebugMode) {
        print(detail);
      }

      if (kDebugMode) {
        print('Uploading file: $fileName');
      }
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('uploads/$ale/$detail/$fileName');
      // if (kDebugMode) {
      // print(storageRef as String?);
      // }

      // Tambahkan metadata dengan mimeType
      SettableMetadata metadata = SettableMetadata(contentType: mimeType);

      UploadTask uploadTask = storageRef.putData(fileBytes, metadata);

      // if (kDebugMode) {
      //   print(uploadTask as String?);
      // }

      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});

      // if (kDebugMode) {
      //   print(snapshot as String?);
      // }

      String downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        print('File uploaded successfully: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading file: $e');
      }
      return null;
    }
  }

  Widget _buildMessageWidget({
    required Map<String, List<dynamic>> message,
    String? url,
    String? mimeType,
    required int indexOfCM,
  }) {
    int? indexEs;

    if (message.containsKey("index")) indexEs = message["index"]?.last;

    if (kDebugMode) print(["_buildMessageWidget" * 5, indexEs]);

    if (_hasValidUrl(message: message, anyUrl: false)) {
      return FutureBuilder<Uint8List?>(
        future: fetchFileBytes(
            indexEs != null ? message['url']![indexEs] : message["url"]?.last),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return const Text('Error loading file');
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            String fileName = indexEs != null
                ? message['fileName']![indexEs]
                : message["fileName"]?.last;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _generateFilePreviewWidget(
                  url: indexEs != null
                      ? message["url"]![indexEs]
                      : message["url"]?.last,
                  fileName: fileName,
                  fileBytes: snapshot.data,
                  mimeType: mimeType,
                ),
                _buildMarkdownBody(message, indexEs),
              ],
            );
          } else {
            return _buildFailedLoadWidget(message, indexEs, indexOfCM);
          }
        },
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMarkdownBody(message, indexEs),
        ],
      );
    }
  }

  Widget _buildMarkdownBody(Map<String, List<dynamic>> message, int? index) {
    return MarkdownBody(
      data:
          index != null ? message['user']![index] : message['user']?.last ?? '',
      extensionSet: md.ExtensionSet(blockSyntaxes, inlineSyntaxes),
      builders: {'latex': LatexElementBuilder()},
    );
  }

  Widget _buildFailedLoadWidget(
      Map<String, List<dynamic>> message, int? index, int? indexOfCM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Failed Load File"),
        _buildMarkdownBody(message, index),
      ],
    );
  }

  Widget _buildNavigationIcons({required int index, required isUserMess}) {
    try {
      final messUser = isUserMess ? _messages[index] : _messages[index - 1];
      final messBot = isUserMess ? _messages[index + 1] : _messages[index];

      if (kDebugMode) {
        print([isUserMess, index, messUser, messBot]);
      }

      if (!messUser.containsKey("index") || !messBot.containsKey("index")) {
        return const SizedBox(
          width: 0,
        );
      }

      // Ambil panjang dari list user dan bot untuk membatasi index
      int maxLengthUser = (messUser["user"])!.length - 1;
      int maxLengthBot = (messBot["bot"])!.length - 1;

      if (kDebugMode) {
        print([maxLengthUser, maxLengthBot]);
      }

      // Validasi agar panjang list user dan bot sama
      if (maxLengthUser != maxLengthBot) {
        throw ArgumentError(
            'List length of messUser["user"] and messBot["bot"] must be equal.');
      }

      // Pastikan bahwa index minimal adalah 1
      // if (index < 0 || maxLengthUser < 1 || maxLengthBot < 1) {
      // throw ArgumentError('index must be at least 1');
      // }

      final int indexUser = messUser["index"]?.last;
      final int indexBot = messBot["index"]?.last;

      if (kDebugMode) {
        print([messUser, messBot]);
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(
            height: 20,
          ),
          if (indexUser > 0 || indexBot > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => changeIndexMess(
                index: index,
                oP: "-",
                maxLengthUser: maxLengthUser,
                maxLengthBot: maxLengthBot,
                messUser: messUser,
                messBot: messBot,
                isUserMess: isUserMess,
                indexUser: indexUser,
              ),
              iconSize: 15,
            ),
          Text(
            "${(messUser["index"]?.last) + 1}/${maxLengthUser + 1}",
            style: const TextStyle(fontSize: 12.5),
          ),
          if (maxLengthUser > indexUser || maxLengthBot > indexBot)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => changeIndexMess(
                index: index,
                oP: "+",
                maxLengthUser: maxLengthUser,
                maxLengthBot: maxLengthBot,
                messUser: messUser,
                messBot: messBot,
                isUserMess: isUserMess,
                indexUser: indexUser,
              ),
              iconSize: 15,
            ),
        ],
      );
    } catch (e) {
      return const SizedBox(
        width: 0,
      );
    }
  }

  bool isImage(Uint8List bytes) {
    try {
      img.Image? image = img.decodeImage(bytes);
      return image != null;
    } catch (e) {
      return false;
    }
  }

  Future<VideoPlayerController> _initializeVideoPlayer(Uri url) async {
    try {
      if (kDebugMode) {
        print("URL VIDEO: ${[url.toString()]}");
      }
      // final videoPlayerController = VideoPlayerController.networkUrl(url,
      //     formatHint: VideoFormat.other,
      //     httpHeaders: const {'Accept': 'video/webm'},
      //     videoPlayerOptions: VideoPlayerOptions(
      //         mixWithOthers: true,
      //         allowBackgroundPlayback: true,
      //         webOptions: const VideoPlayerWebOptions(
      //           controls: VideoPlayerWebOptionsControls.enabled(),
      //         )));
      final videoPlayerController = VideoPlayerController.network(
        url.toString(),
        videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: true,
            webOptions: const VideoPlayerWebOptions(
                controls: VideoPlayerWebOptionsControls.enabled())),
      );
      if (kDebugMode) {
        print("await controller $videoPlayerController");
      }
      videoPlayerController.setLooping(true);
      await videoPlayerController.initialize();
      if (kDebugMode) {
        print("return controller");
      }
      return videoPlayerController;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }

  // Helper function to handle the complex logic
  bool _hasValidUrl({Map<String, List<dynamic>>? message, bool? anyUrl}) {
    if (message!.containsKey('url')) {
      if (message.containsKey('index')) {
        // Safely access the index and check if the URL is not empty
        var index = message["index"]?.last;
        return index != null && (message["url"]?[index]).isNotEmpty;
      }
      // Check if the last URL is not empty when there's no index
      return (message["url"]?.last).isNotEmpty;
    }
    return anyUrl == true ? true : false;
  }

  Future<void> _showFilePreviewDialog(
      BuildContext context, Map<String, List<dynamic>> message,
      {bool? isUserMessage}) async {
    // Determine the URL and filename based on message content
    String? url_;
    String? fileName_;
    Uint8List? fileBytes_;

    bool? hasFile = (message.containsKey("url"));
    int? index;

    index = message.containsKey("index") ? message["index"]?.last : null;

    if (hasFile) {
      url_ = index != null ? message["url"]![index] : message["url"]?.last;
      fileName_ = index != null
          ? message["fileName"]![index]
          : message["fileName"]?.last;
      fileBytes_ = await fetchFileBytes(
          index != null ? message['url']![index] : message['url']?.last);
    }

    if (kDebugMode) {
      print("The of Select And Preview");
      print(
          "${url_.toString()} ${fileName_.toString()} ${isUserMessage.toString()} ${index.toString()}");
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SelectionArea(
          child: AlertDialog(
            // title: Text(
            //   hasFile == true ? 'Select Text or Preview File' : 'Select Text',
            // ),
            content: Container(
              constraints: const BoxConstraints(
                maxHeight:
                    500, // Batas tinggi konten (misal 200 pixel, sesuaikan dengan kebutuhan)
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _hasValidUrl(message: message, anyUrl: false)
                              ? 'Select Text\nPreview File\n'
                              : 'Select Text',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Expanded(
                          child: SizedBox(
                            width: 0,
                          ),
                        ),
                        const Expanded(
                          child: SizedBox(
                            width: 0,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_hasValidUrl(message: message, anyUrl: false))
                          IconButton(
                            icon: const Icon(Icons.open_in_browser),
                            onPressed: () {
                              _launchURL(url_!);
                            },
                            tooltip: 'View in Browser',
                          ),
                        if (_hasValidUrl(message: message, anyUrl: false))
                          Expanded(
                            child: Text(
                              fileName_ ?? 'Unknown File',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(
                        height: 16), // Space between actions and content
                    _hasValidUrl(message: message, anyUrl: false)
                        ? fileBytes_ != null
                            ? _generateFilePreviewWidget(
                                url: url_,
                                fileName: fileName_,
                                fileBytes: fileBytes_,
                                width: 384,
                                height: 384,
                              )
                            : const CircularProgressIndicator() // Show loading indicator while fetching
                        : const SizedBox(
                            height: 0,
                          ),
                    const SizedBox(height: 16),
                    MarkdownBody(
                      extensionSet: md.ExtensionSet(
                        blockSyntaxes,
                        inlineSyntaxes,
                      ),
                      builders: {
                        'latex': LatexElementBuilder(),
                        // Kamu bisa menambahkan custom builder untuk teks jika ingin memberikan batasan.
                        'text': CustomTextBuilder(maxLines: 5),
                      },
                      data: isUserMessage == true
                          ? message.containsKey("index")
                              ? message['user']![index!]
                              : message['user']?.last
                          : message.containsKey('error') &&
                                  (message.containsKey('index')
                                      ? message["error"]![index!] == true
                                      : message["error"]?.last == true)
                              ? message.containsKey("index")
                                  ? message["bot"]![index!]
                                  : message['bot']?.last
                              : message.containsKey("index")
                                  ? message["bot"]![index!]
                                  : message['bot']?.last,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _generateFilePreviewWidget({
    String? url,
    String? fileName,
    Uint8List? fileBytes,
    String? mimeType,
    double? width,
    double? height,
  }) {
    try {
      // final extension = fileName.split('.').last.toLowerCase();

      mimeType ??= lookupMimeType(fileName ?? "", headerBytes: fileBytes);
      width ??= 256;
      height ??= 256;

      if (kDebugMode) {
        print(mimeType);
        print(fileName);
        // print(fileBytes);
      }

      // url = Uri.encodeFull(url);

      // if (isImage(fileBytes)) {
      if (mimeType!.trim().startsWith("image")) {
        if (kDebugMode) {
          print("Is image True");
          print(url);
        }
        return Image.network(
          url!,
          scale: 3.0,
          width: width,
          height: height,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.low,
          cacheHeight: 64,
          cacheWidth: 64,
          headers: const {'Accept': 'image/webp'},
          gaplessPlayback: true,
          isAntiAlias: false,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Text('Failed to load image');
          },
        );
      } else if (mimeType.trim().startsWith("video")) {
        if (kDebugMode) {
          print("Is video True");
          print(url);
        }
        return FutureBuilder(
          future: _initializeVideoPlayer(
            Uri.parse(url!),
          ),
          builder: (context, snapshot) {
            if (kDebugMode) {
              print("Context Video: $context Snapshot Video: $snapshot");
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(); // Show a loading indicator while fetching data
            } else if (snapshot.hasError) {
              return const Text(
                  'Error loading file'); // Handle any errors that occur
            } else if (snapshot.connectionState == ConnectionState.done) {
              final VideoPlayerController controller =
                  snapshot.data as VideoPlayerController;
              if (kDebugMode) {
                print("Hasil Controller Video: $snapshot");
              }
              return controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: <Widget>[
                          VideoPlayer(controller),
                          // ClosedCaption(text: _controllerInput.value.caption.text),
                          // _ControlsOverlay(controller: _controllerInput),
                          // VideoProgressIndicator(_controllerInput as VideoPlayerController,
                          //     allowScrubbing: true),
                        ],
                      ),
                    )
                  : const CircularProgressIndicator();
            } else {
              return const Text('Failed to load video');
            }
          },
        );
      }

      if (kDebugMode) {
        print("Is image/video false");
      }
      return const Icon(Icons.insert_drive_file, size: 50, color: Colors.grey);
    } catch (e) {
      if (kDebugMode) {
        print("Error _generateFilePreviewWidget: $e");
      }
      return const Icon(Icons.error, size: 50, color: Colors.red);
    }
  }

  void _copyToClipboard(String? text) {
    if (text != null) {
      Clipboard.setData(ClipboardData(text: text)).then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black87
                  : Colors.white70,
              content: Text(
                'Text copied to clipboard',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
                ),
              ),
              showCloseIcon: true,
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('No Text'),
          showCloseIcon: true,
        ),
      );
    }
  }

  // Method untuk membuka URL di browser
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _deleteMessage(int index) async {
    if (kDebugMode) {
      print("_deleteMessage ${_messages[index]}");
    }

    try {
      if (_messages[index].containsKey("user")) {
        setState(() {
          _messages.removeRange(index, index + 2);
        });
      } else if (_messages[index].containsKey("bot")) {
        setState(() {
          _messages.removeRange(index - 1, index + 1);
        });
      }
    } catch (e) {
      setState(() {
        _messages.removeAt(index);
      });
    }
    await _saveChatHistory();
  }

  Future<void> _editMessage({
    int? index,
  }) async {
    String? fileName;
    String? url;
    Uint8List? fileBytes;
    String? mimeType;

    if (_hasValidUrl(message: _messages[index!], anyUrl: false)) {
      fileName = _messages[index].containsKey("index")
          ? _messages[index]["fileName"]![_messages[index]["index"]?.last]
          : _messages[index]["fileName"]?.last;
      url = _messages[index].containsKey("index")
          ? _messages[index]["url"]![_messages[index]["index"]?.last]
          : _messages[index]["url"]?.last;
      fileBytes = await fetchFileBytes(url!);
      mimeType = lookupMimeType(
        fileName!,
        headerBytes: fileBytes,
      );
    }

    setState(() {
      // Update the index to indicate which message is being edited
      _editingIndex = index;
      _editingUser = true;
      _controllerInputEditing.text = _messages[index].containsKey("index")
          ? _messages[index]['user']![_messages[index]["index"]?.last]
          : _messages[index]["user"]?.last ??
              ['']; // Load the current message into the TextField
      if (_hasValidUrl(message: _messages[index], anyUrl: false)) {
        _isFilePicked = true;
        _fileName = fileName;
        _url = url!;
        _fileBytes = fileBytes!;
        _mimeType = mimeType;
      }
    });
  }

  void _saveEditedMessage() {
    if (kDebugMode) {
      print("Save 1");
    }

    setState(() {
      // Save the edited message back to the messages list
      // _messages[_editingIndex!]['user']?.add(_controllerInput.text);
      // if (_messages[_editingIndex!].containsKey("index")) {
      //   _messages[_editingIndex!]["index"]?.last + 1;
      // } else {
      //   _messages[_editingIndex!]['index'] = [1];
      // }
      // _controllerInput.clear(); // Clear the controller
    });

    _saveChatHistory();

    if (kDebugMode) {
      print("Save 2");
    }

    _ganResponseBot(
      index: _editingIndex!,
      regenerate: true,
      isBotMessage: false,
      isUserEdit: true,
      fileName: _fileName,
      url: _url,
      fileBytesRe: _fileBytes,
      mimeTypeRe: _mimeType,
      textOfEdit: _controllerInputEditing.text,
    );

    if (kDebugMode) {
      print("Generate finish");
    }

    setState(() {
      _editingIndex = null; // Exit edit mode
      _editingUser = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null; // Exit edit mode
      _editingUser = false;
      _controllerInputEditing.clear(); // Clear the controller
    });
  }

  void changeIndexMess({
    required int index,
    required String oP,
    required maxLengthUser,
    required maxLengthBot,
    required messUser,
    required messBot,
    required bool isUserMess,
    required int indexUser,
  }) async {
    // Pastikan bahwa index yang diubah tidak keluar dari batas list
    if ((indexUser < 1 && indexUser == 0 && oP == "-") ||
        (indexUser >= maxLengthUser && oP == "+")) {
      throw RangeError(
          'Index out of bounds. Must be between 1 and ${maxLengthUser - 1}');
    }

    if (kDebugMode) {
      print([messUser, messBot]);
    }

    setState(() {
      // Lakukan operasi penambahan atau pengurangan pada index sesuai nilai oP
      messUser["index"]?.last =
          oP == "+" ? messUser["index"]?.last + 1 : messUser["index"]?.last - 1;

      // Sinkronkan messBot agar selalu sama dengan messUser
      messBot["index"]?.last = messUser["index"]?.last;
    });

    await _saveChatHistory();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          actions: [
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 2.0),
            //   margin: const EdgeInsets.all(8.0),
            //   decoration: BoxDecoration(
            //     color: Theme.of(context).brightness == Brightness.light
            //         ? const Color.fromARGB(255, 233, 233, 233)
            //         : const Color.fromARGB(255, 33, 33, 33),
            //     borderRadius: BorderRadius.circular(8.0),
            //   ),
            //   child:
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmClearChatHistory(all: true, index: null),
              tooltip: "Delete Chat",
            ),
            // ),
          ],
          backgroundColor: Colors.transparent,
          // Theme.of(context).brightness == Brightness.dark
          //     ? const Color.fromARGB(50, 0, 0, 0)
          //     : const Color.fromARGB(50, 255, 255, 255),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUserMessage = message.containsKey('user');
                      return ListTile(
                        title: Align(
                          alignment: isUserMessage
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: isUserMessage
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUserMessage)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    'assets/icon/TanyaWii 256.png',
                                    height: 24.0,
                                    width: 24.0,
                                  ),
                                ),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isUserMessage
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8.0),
                                      margin: isUserMessage
                                          ? const EdgeInsets.only(left: 24.0)
                                          : const EdgeInsets.all(0.0),
                                      decoration: BoxDecoration(
                                        color: isUserMessage
                                            ? Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? Colors.white
                                                : const Color.fromARGB(
                                                    255, 25, 25, 25)
                                            : message.containsKey("error")
                                                ? (message.containsKey("index")
                                                        ? message['error']![
                                                                message["index"]!
                                                                    .last] ==
                                                            true
                                                        : message["error"]
                                                                ?.last ==
                                                            true)
                                                    ? Colors.red
                                                    : Colors.transparent
                                                : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'copy') {
                                            _copyToClipboard(
                                              (isUserMessage
                                                  ? message.containsKey(
                                                              "url") &&
                                                          (message.containsKey(
                                                                  "index")
                                                              ? message[
                                                                  "url"]![_messages[
                                                                          index]
                                                                      ["index"]
                                                                  ?.last
                                                                  .isNotEmpty]
                                                              : message["url"]
                                                                  ?.last
                                                                  .isNotEmpty)
                                                      ? "Message: ${(message.containsKey("index") ? message["user"]![message["index"]?.last] : message['user']?.last)}\nContent: ${(message.containsKey("index") ? message["url"]![message["index"]?.last] : message['url']?.last)}"
                                                      : message.containsKey(
                                                              "index")
                                                          ? message["user"]![
                                                              message["index"]
                                                                  ?.last]
                                                          : message['user']
                                                              ?.last
                                                  : message.containsKey("index")
                                                      ? message["bot"]![
                                                          message["index"]
                                                              ?.last]
                                                      : message['bot']?.last),
                                            );
                                          } else if (value == 'preview') {
                                            _showFilePreviewDialog(
                                              context,
                                              message,
                                              isUserMessage: isUserMessage,
                                              // index: index,
                                            );
                                          } else if (value == 'delete') {
                                            _confirmClearChatHistory(
                                              all: false,
                                              index: index,
                                              message: message,
                                              isUserMessage: isUserMessage,
                                            );
                                          } else if (value == 'regenerate') {
                                            _ganResponseBot(
                                              regenerate: true,
                                              index: index,
                                              isUserEdit: false,
                                              isBotMessage: true,
                                            );
                                          } else if (value == 'edit') {
                                            _editMessage(index: index);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem<String>(
                                            value: 'copy',
                                            child: Text('Copy'),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'preview',
                                            child: Text(_hasValidUrl(
                                                    message: message,
                                                    anyUrl: false)
                                                ? 'Select Text or Preview File'
                                                : "Select Text"),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                          if (!isUserMessage)
                                            const PopupMenuItem<String>(
                                              value: 'regenerate',
                                              child:
                                                  Text('Regenerate Response'),
                                            ),
                                          if (isUserMessage)
                                            const PopupMenuItem<String>(
                                              value: 'edit',
                                              child: Text('Edit'),
                                            ),
                                        ],
                                        child: isUserMessage
                                            ? _editingUser == true &&
                                                    _editingIndex == index
                                                ? Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: <Widget>[
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.attach_file,
                                                            color: Theme.of(context)
                                                                        .brightness ==
                                                                    Brightness
                                                                        .light
                                                                ? Colors.black
                                                                : Colors.white,
                                                          ),
                                                          onPressed: _pickFile,
                                                          tooltip: "Pick File",
                                                          color: const Color
                                                              .fromARGB(100,
                                                              158, 158, 158),
                                                          hoverColor: Theme.of(
                                                                          context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? const Color
                                                                  .fromARGB(255,
                                                                  35, 35, 35)
                                                              : const Color
                                                                  .fromARGB(
                                                                  255,
                                                                  225,
                                                                  225,
                                                                  225),
                                                        ),
                                                        Expanded(
                                                          child: TextField(
                                                            keyboardType:
                                                                TextInputType
                                                                    .multiline,
                                                            controller:
                                                                _controllerInputEditing,
                                                            decoration:
                                                                const InputDecoration(
                                                              filled: true,
                                                              fillColor: Colors
                                                                  .transparent,
                                                              hintText:
                                                                  'Edit your message here...',
                                                              border:
                                                                  OutlineInputBorder(),
                                                              isDense: true,
                                                            ),
                                                            minLines: 1,
                                                            maxLines: 10,
                                                            onChanged: (text) {
                                                              setState(() {});
                                                            },
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons.cancel),
                                                          tooltip: "Cancel",
                                                          onPressed:
                                                              _cancelEdit,
                                                        ),
                                                        ValueListenableBuilder<
                                                            bool>(
                                                          valueListenable:
                                                              _isButtonEnabledEditing,
                                                          builder: (context,
                                                              isEnabled,
                                                              child) {
                                                            return IconButton(
                                                              icon:
                                                                  !_generateAnsBot
                                                                      ? Icon(
                                                                          Icons
                                                                              .send,
                                                                          color: !isEnabled
                                                                              ? const Color.fromARGB(100, 158, 158, 158)
                                                                              : Theme.of(context).brightness == Brightness.light
                                                                                  ? Colors.black
                                                                                  : Colors.white,
                                                                        )
                                                                      : const Icon(
                                                                          Icons
                                                                              .stop_circle),
                                                              tooltip:
                                                                  !_generateAnsBot
                                                                      ? "Send"
                                                                      : "Stop",
                                                              onPressed: isEnabled
                                                                  ? _saveEditedMessage
                                                                  : _breakGeneration,
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : _buildMessageWidget(
                                                    message: message,
                                                    url: _url,
                                                    mimeType: _mimeType,
                                                    indexOfCM: index,
                                                  )
                                            : message.containsKey('error') &&
                                                    (message.containsKey(
                                                            'index')
                                                        ? message["error"]![
                                                                message["index"]!
                                                                    .last] ==
                                                            true
                                                        : message["error"]
                                                                ?.last ==
                                                            true)
                                                ? MarkdownBody(
                                                    extensionSet:
                                                        md.ExtensionSet(
                                                      blockSyntaxes,
                                                      inlineSyntaxes,
                                                    ),
                                                    builders: {
                                                      'latex':
                                                          LatexElementBuilder(),
                                                    },
                                                    data: message.containsKey(
                                                            "index")
                                                        ? message["bot"]![
                                                            message["index"]
                                                                ?.last]
                                                        : message['bot']?.last,
                                                    styleSheet:
                                                        MarkdownStyleSheet(
                                                      p: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  )
                                                : MarkdownBody(
                                                    extensionSet:
                                                        md.ExtensionSet(
                                                      blockSyntaxes,
                                                      inlineSyntaxes,
                                                    ),
                                                    builders: {
                                                      'latex':
                                                          LatexElementBuilder(),
                                                    },
                                                    data: message
                                                            .containsKey(
                                                                "index")
                                                        ? message["bot"]![
                                                            message["index"]
                                                                ?.last]
                                                        : message['bot']?.last),
                                      ),
                                    ),
                                    if (message.containsKey("index"))
                                      _buildNavigationIcons(
                                          index: index,
                                          isUserMess: isUserMessage),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              if (isUserMessage)
                                CircleAvatar(
                                  backgroundImage: _photoURL != null
                                      ? NetworkImage(_photoURL!)
                                      : null,
                                  radius: 16.0,
                                  child: _photoURL == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (_messages.isEmpty)
                    Center(
                      child: Text(
                        'Start chatting with our AI assistant!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  // File preview widget
                  if (_isFilePicked)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        padding: const EdgeInsets.all(8.0),
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color.fromARGB(100, 200, 200, 200)
                            : const Color.fromARGB(100, 41, 41, 41),
                        child: Stack(
                          children: [
                            _generateFilePreviewWidget(
                                url: _url,
                                fileName: _fileName,
                                mimeType: _mimeType,
                                fileBytes:
                                    _fileBytes), // Menampilkan preview file
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: _removeUploadFile,
                                tooltip: "Remove Pick File",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_scrollController.hasClients)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color.fromARGB(150, 0, 0, 0)
                                    : const Color.fromARGB(150, 255, 255, 255)),
                        margin: const EdgeInsets.all(8.0),
                        padding: const EdgeInsets.all(8.0),
                        child: _scrollController.hasClients
                            ? ValueListenableBuilder<bool>(
                                valueListenable: _isHasClientsScrollController,
                                builder: (context, isEnabled, child) {
                                  return IconButton(
                                    icon:
                                        const Icon(Icons.arrow_downward_sharp),
                                    onPressed: isEnabled
                                        ? () => _scrollToBottom()
                                        : null,
                                    tooltip: "Scroll To Bottom",
                                  );
                                },
                              )
                            : Container(),
                      ),
                    )
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : const Color.fromARGB(255, 25, 25, 25),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    // Attach file icon
                    IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                      onPressed: _pickFile,
                      tooltip: "Pick File",
                      color: const Color.fromARGB(100, 158, 158, 158),
                      hoverColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color.fromARGB(255, 35, 35, 35)
                              : const Color.fromARGB(255, 225, 225, 225),
                    ),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.multiline,
                        controller: _controllerInput,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          hintText: 'Type your message here...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        minLines: 1,
                        maxLines: 10,
                        onChanged: (text) {
                          setState(() {});
                        },
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isButtonEnabled,
                      builder: (context, isEnabled, child) {
                        return IconButton(
                          icon: !_generateAnsBot
                              ? Icon(
                                  Icons.send,
                                  color: !isEnabled
                                      ? const Color.fromARGB(100, 158, 158, 158)
                                      : Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.black
                                          : Colors.white,
                                )
                              : const Icon(Icons.stop_circle),
                          tooltip: !_generateAnsBot ? "Send" : "Stop",
                          onPressed: isEnabled
                              ? () => _sendMessage(
                                    isHasFileContent: _isFilePicked,
                                    // fileBytes: fileBytes,
                                    fileName: _fileName,
                                    url: _url,
                                    mimeType: _mimeType,
                                  )
                              : _breakGeneration,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void previewMessage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          // title: const Text('Preview Message'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text(
                      "Preview Message",
                      style: TextStyle(fontSize: 22),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      tooltip: 'Close',
                    ),
                  ],
                ),
                MarkdownBody(
                  data: _controllerInput.text,
                  extensionSet: md.ExtensionSet(
                    blockSyntaxes,
                    inlineSyntaxes,
                  ),
                  builders: {
                    'latex': LatexElementBuilder(),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CustomTextBuilder extends MarkdownElementBuilder {
  final int maxLines;

  CustomTextBuilder({required this.maxLines});

  @override
  Widget visitText(md.Text text, TextStyle? preferredStyle) {
    return Text(
      text.text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: preferredStyle,
    );
  }
}
