import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Method untuk membuka URL di browser
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  final String markdownData = '''
# TanyaWii

TanyaWii adalah aplikasi chatbot yang dirancang untuk memberikan jawaban atas pertanyaan pengguna secara cepat dan akurat. Dengan teknologi yang canggih, aplikasi ini mampu memahami dan menanggapi berbagai jenis pertanyaan dari pengguna.

## Fitur Utama:
- **Chatbot Interaktif**: TanyaWii dapat menjawab berbagai pertanyaan secara real-time.
- **Profil Pengguna**: Pengguna dapat mengatur profil mereka, termasuk foto dan nama tampilan.
- **Pengambilan Foto/File**: Pengguna dapat mengirimkan foto atau file melalui aplikasi ini.

## Tentang Pengembang:
Aplikasi ini dikembangkan oleh **Nyxeldevid**, sebuah organisasi yang dipimpin oleh **Aditya Dwi Nugraha**. Nyxeldevid berfokus pada pengembangan teknologi yang inovatif dan solutif untuk berbagai kebutuhan masyarakat.

## Repositori GitHub:
[https://github.com/Adityadn64/tanya_wii.git](https://github.com/Adityadn64/tanya_wii.git)

## Hak Cipta:
© 2024 Nyxeldevid. All rights reserved. Aditya Dwi Nugraha.
''';

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        // appBar: AppBar(
        // title: MarkdownBody( selectable: true, data:'About TanyaWii'),
        // backgroundColor: Theme.of(context).brightness == Brightness.dark
        //     ? const Color.fromARGB(50, 0, 0, 0)
        //     : const Color.fromARGB(50, 255, 255, 255),
        // ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(
                  data: markdownData,
                  styleSheet: MarkdownStyleSheet(
                    h1: const TextStyle(
                        fontSize: 24.0, fontWeight: FontWeight.bold),
                    h2: const TextStyle(
                        fontSize: 18.0, fontWeight: FontWeight.bold),
                    p: const TextStyle(fontSize: 16.0),
                    a: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline),
                    blockquote: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
