import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:tanya_wii/page/profile_page.dart';
import 'page/about_page.dart';
import 'page/chat_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'service/auth/user.dart';
// import 'service/fix/fix.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // if (kDebugMode) {
    print('Error initializing Firebase: $e');
    // }
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    // injectJavaScript();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString('themeMode') ?? 'system';
    setState(() {
      _themeMode = _getThemeModeFromString(themeMode);
    });
  }

  ThemeMode _getThemeModeFromString(String themeMode) {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _toggleThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    await prefs.setString(
        'themeMode', _themeMode == ThemeMode.light ? 'light' : 'dark');
  }

  // Definisi warna hitam kustom
  static const int _blackPrimaryValue = 0xFF000000;

  static const MaterialColor blackCustomSwatch = MaterialColor(
    _blackPrimaryValue,
    <int, Color>{
      50: Color(0xFFE0E0E0), // Abu-abu terang
      100: Color(0xFFB3B3B3),
      200: Color(0xFF808080), // Abu-abu menengah
      300: Color(0xFF4D4D4D),
      400: Color(0xFF262626),
      500: Color(_blackPrimaryValue), // Warna hitam utama
      600: Color(0xFF000000),
      700: Color(0xFF000000),
      800: Color(0xFF000000),
      900: Color(0xFF000000),
    },
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TanyaWii',
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blue, // Warna kursor biru
          selectionColor: Colors.blue
              .withOpacity(0.5), // Warna latar belakang teks yang dipilih
          selectionHandleColor: Colors.blue, // Warna pegangan teks yang dipilih
        ),
        brightness: Brightness.light,
        primarySwatch: blackCustomSwatch, // Warna utama abu-abu
        primaryColor: const Color.fromARGB(125, 0, 0, 0), // Warna utama hitam
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: blackCustomSwatch,
          accentColor: const Color.fromARGB(125, 0, 0, 0), // Aksen warna hitam
          backgroundColor:
              const Color.fromARGB(125, 255, 255, 255), // Latar belakang putih
          errorColor: Colors.red, // Warna error merah
          brightness: Brightness.light, // Menggunakan brightness terang
        ).copyWith(
          secondary: const Color.fromARGB(125, 0, 0, 0), // Warna sekunder hitam
        ),
        scaffoldBackgroundColor:
            const Color.fromARGB(50, 255, 255, 255), // Latar belakang putih
        appBarTheme: const AppBarTheme(
          color: Color.fromARGB(125, 255, 255, 255), // AppBar putih
          elevation: 0,
          iconTheme:
              IconThemeData(color: Color.fromARGB(200, 0, 0, 0)), // Ikon hitam
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black), // Teks hitam
          bodyMedium: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(
            color: Color.fromARGB(125, 0, 0, 0)), // Ikon hitam
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue, // Item yang dipilih hitam
          unselectedItemColor: Colors.blue, // Item tidak dipilih abu-abu
          backgroundColor:
              Color.fromARGB(125, 255, 255, 255), // Background putih
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
                const Color.fromARGB(125, 200, 200, 200)), // Warna tombol hitam
            foregroundColor: WidgetStateProperty.all(
                const Color.fromARGB(125, 255, 255, 255)), // Teks tombol putih
            overlayColor: WidgetStateProperty.all(
                Colors.transparent), // Menghilangkan warna overlay
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(
                const Color.fromARGB(125, 0, 0, 0)), // Teks tombol hitam
            overlayColor: WidgetStateProperty.all(
                Colors.transparent), // Menghilangkan warna overlay
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            side: WidgetStateProperty.all(const BorderSide(
                color: Color.fromARGB(125, 0, 0, 0))), // Border hitam
            foregroundColor: WidgetStateProperty.all(
                const Color.fromARGB(125, 0, 0, 0)), // Teks tombol hitam
            overlayColor: WidgetStateProperty.all(
                Colors.transparent), // Menghilangkan warna overlay
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.all(
              const Color.fromARGB(125, 0, 0, 0)), // Warna centang hitam
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.all(
              const Color.fromARGB(125, 0, 0, 0)), // Warna radio button hitam
        ),
        switchTheme: SwitchThemeData(
          trackColor:
              WidgetStateProperty.all(Colors.blue), // Track switch abu-abu
          thumbColor: WidgetStateProperty.all(
              const Color.fromARGB(125, 0, 0, 0)), // Thumb switch hitam
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color.fromARGB(125, 0, 0, 0), // Slider aktif hitam
          inactiveTrackColor: Colors.blue, // Slider tidak aktif abu-abu
          thumbColor: Color.fromARGB(125, 0, 0, 0), // Thumb hitam
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Colors.blue, // Background chip abu-abu muda
          selectedColor: Colors.blue, // Chip yang dipilih hitam
          disabledColor: Colors.blue, // Chip yang dinonaktifkan abu-abu
          secondarySelectedColor:
              Colors.blue, // Chip sekunder yang dipilih hitam
          padding: EdgeInsets.all(4.0), // Padding chip
        ),
        dialogTheme: const DialogTheme(
          backgroundColor:
              Color.fromARGB(200, 255, 255, 255), // Background dialog putih
          titleTextStyle: TextStyle(color: Colors.black), // Judul dialog hitam
          contentTextStyle:
              TextStyle(color: Colors.black), // Konten dialog hitam
        ),
        tooltipTheme: const TooltipThemeData(
          decoration: BoxDecoration(
            color: Color.fromARGB(125, 0, 0, 0), // Background tooltip hitam
          ),
          textStyle: TextStyle(color: Colors.white), // Teks tooltip putih
        ),
        // Hapus warna ungu default
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: const Color.fromARGB(50, 255, 255, 255),
      ),
      darkTheme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blue, // Warna kursor biru
          selectionColor: Colors.blue
              .withOpacity(0.5), // Warna latar belakang teks yang dipilih
          selectionHandleColor: Colors.blue, // Warna pegangan teks yang dipilih
        ),
        brightness: Brightness.dark,
        primarySwatch: blackCustomSwatch, // Menggunakan warna abu-abu
        primaryColor: const Color.fromARGB(125, 0, 0, 0), // Warna utama hitam
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: blackCustomSwatch,
          accentColor: const Color.fromARGB(125, 0, 0, 0), // Aksen warna hitam
          backgroundColor:
              const Color.fromARGB(125, 0, 0, 0), // Latar belakang hitam
          errorColor: Colors.red, // Warna error merah
          brightness: Brightness.dark, // Menggunakan brightness gelap
        ).copyWith(
          secondary:
              const Color.fromARGB(125, 255, 255, 255), // Warna sekunder hitam
        ),
        scaffoldBackgroundColor:
            const Color.fromARGB(50, 0, 0, 0), // Latar belakang hitam
        appBarTheme: const AppBarTheme(
          color: Color.fromARGB(125, 0, 0, 0), // AppBar hitam
          elevation: 0,
          iconTheme: IconThemeData(
              color: Color.fromARGB(200, 255, 255, 255)), // Ikon putih
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white), // Teks putih
          bodyMedium: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
            color: Color.fromARGB(125, 255, 255, 255)), // Ikon putih
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue, // Item yang dipilih putih
          unselectedItemColor: Colors.blue, // Item tidak dipilih abu-abu
          backgroundColor: Color.fromARGB(125, 0, 0, 0), // Background hitam
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
                const Color.fromARGB(125, 0, 0, 0)), // Warna tombol hitam
            foregroundColor: WidgetStateProperty.all(
                const Color.fromARGB(125, 255, 255, 255)), // Teks tombol putih
            overlayColor: WidgetStateProperty.all(
                Colors.transparent), // Menghilangkan warna overlay
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(
                const Color.fromARGB(125, 255, 255, 255)), // Teks tombol putih
            overlayColor: WidgetStateProperty.all(
                Colors.transparent), // Menghilangkan warna overlay
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            side: WidgetStateProperty.all(const BorderSide(
                color: Color.fromARGB(125, 255, 255, 255))), // Border putih
            foregroundColor: WidgetStateProperty.all(
                const Color.fromARGB(125, 255, 255, 255)), // Teks tombol putih
            overlayColor: WidgetStateProperty.all(
                Colors.transparent), // Menghilangkan warna overlay
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.all(
              const Color.fromARGB(125, 255, 255, 255)), // Warna centang putih
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.all(const Color.fromARGB(
              125, 255, 255, 255)), // Warna radio button putih
        ),
        switchTheme: SwitchThemeData(
          trackColor:
              WidgetStateProperty.all(Colors.blue), // Track switch abu-abu
          thumbColor: WidgetStateProperty.all(
              const Color.fromARGB(125, 0, 0, 0)), // Thumb hitam
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor:
              Color.fromARGB(125, 255, 255, 255), // Slider aktif putih
          inactiveTrackColor: Colors.blue, // Slider tidak aktif abu-abu
          thumbColor: Color.fromARGB(125, 0, 0, 0), // Thumb hitam
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Colors.blue, // Background chip abu-abu tua
          selectedColor: Colors.blue, // Chip yang dipilih putih
          disabledColor: Colors.blue, // Chip yang dinonaktifkan abu-abu
          secondarySelectedColor:
              Colors.blue, // Chip sekunder yang dipilih putih
          padding: EdgeInsets.all(4.0), // Padding chip
        ),
        dialogTheme: const DialogTheme(
          backgroundColor:
              Color.fromARGB(200, 0, 0, 0), // Background dialog hitam
          titleTextStyle: TextStyle(color: Colors.white), // Judul dialog putih
          contentTextStyle:
              TextStyle(color: Colors.white), // Konten dialog putih
        ),
        tooltipTheme: const TooltipThemeData(
          decoration: BoxDecoration(
            color:
                Color.fromARGB(125, 255, 255, 255), // Background tooltip putih
          ),
          textStyle: TextStyle(color: Colors.black), // Teks tooltip hitam
        ),
        highlightColor: Colors.transparent, // Highlight abu-abu gelap
        splashColor: Colors.transparent, // Warna splash abu-abu
        focusColor: Colors.transparent, // Fokus putih
        hoverColor: const Color.fromARGB(50, 0, 0, 0), // Warna hover abu-abu
      ),
      themeMode: _themeMode,
      home: HomePage(
        onThemeToggle: _toggleThemeMode,
        themeMode: _themeMode,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage(
      {super.key, required this.onThemeToggle, required this.themeMode});

  final VoidCallback onThemeToggle;
  final ThemeMode themeMode;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _displayName;
  String? _photoURL;

  @override
  void initState() {
    super.initState();
    MyUser().loadUserData().then((userResult) {
      if (mounted) {
        setState(() {
          _displayName = userResult?.displayName;
          _photoURL = userResult?.photoURL;
        });
      }
    });
  }

  static const List<Widget> _pages = <Widget>[
    ChatScreen(),
    ProfilePage(),
    AboutPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            MarkdownBody(
              data: '# TanyaWii',
              styleSheet: MarkdownStyleSheet(
                h1: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(widget.themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode),
              onPressed: widget.onThemeToggle,
              tooltip: Theme.of(context).brightness == Brightness.light
                  ? "Dark Mode"
                  : "Light Mode",
            ),
            Row(
              children: [
                _photoURL != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(_photoURL!),
                        radius: 16.0,
                      )
                    : const CircleAvatar(
                        radius: 16.0,
                        child: Icon(Icons.person),
                      ),
                const SizedBox(width: 8.0),
                Text(_displayName ?? 'Guest'),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color.fromARGB(255, 39, 39, 39)
          : const Color.fromARGB(255, 238, 238, 238),
      drawer: MediaQuery.of(context).size.width < 700
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  UserAccountsDrawerHeader(
                    accountName: Text(
                      _displayName ?? 'Guest',
                      style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black87
                                  : null),
                    ),
                    accountEmail: const Text(''),
                    currentAccountPicture: CircleAvatar(
                      backgroundImage:
                          _photoURL != null ? NetworkImage(_photoURL!) : null,
                      child: _photoURL == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    // Atur background di sini menggunakan decoration
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color.fromARGB(25, 75, 75, 75)
                          : null,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('TanyaWii'),
                    onTap: () {
                      _onItemTapped(0);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Profile'),
                    onTap: () {
                      _onItemTapped(1);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    onTap: () {
                      _onItemTapped(2);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            )
          : null, // Untuk layar lebih besar, drawer tidak aktif

      body: MediaQuery.of(context).size.width >= 700
          ? Row(
              children: [
                // Sidebar dengan proporsi 1
                Expanded(
                  flex: 1,
                  child: NavigationRail(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color.fromARGB(25, 75, 75, 75)
                            : null,
                    extended: true, // Sidebar tetap terlihat
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.chat),
                        label: Text('TanyaWii'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.people),
                        label: Text('Profile'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.info),
                        label: Text('About'),
                      ),
                    ],
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onItemTapped,
                  ),
                ),
                const VerticalDivider(thickness: 1, width: 1),

                // Konten utama dengan proporsi 3
                Expanded(
                  flex: 3,
                  // child: Padding(
                  //   padding: MediaQuery.of(context).size.width >= 900
                  //       ? const EdgeInsets.only(left: 50, right: 50)
                  //       : EdgeInsets
                  //           .zero, // Menambahkan padding di sebelah kiri
                  child: _pages[_selectedIndex],
                  // ),
                ),
              ],
            )
          : _pages[_selectedIndex],
      // Untuk layar kecil, hanya menampilkan halaman yang dipilih
    );
  }
}
