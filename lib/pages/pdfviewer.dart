import 'dart:convert';
import 'dart:typed_data';

import 'package:cleanroom/api/urlManager.dart';
import 'package:cleanroom/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';


class PDFViewerPage extends StatefulWidget {
  // Normally we'd just want to get the auth token and the pdf file name instead of the 
  // entire state object. This was done to quicken the POC process. 
  final MyAppState appState;

  const PDFViewerPage({super.key, required this.filePath, required this.appState});

  final String filePath;

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  late Future<Uint8List> _future;
  late String _filePath;
  late MyAppState _appState;

  Uri pdfUrl = Uri.parse("${UrlManager.baseUrl}/viewv2");

  @override
  void initState() {
    super.initState();
    _appState = widget.appState;
    _filePath = widget.filePath;
    _future = _fetchPdf();
    print("Filepath passed in: $_filePath");
  }

  Future<Uint8List> _fetchPdf() async {
    // Fetch PDF URL from Flask endpoint
    print("Fetching filepath $_filePath");
    final response = await http.post(
      pdfUrl,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'pdf_file_path': _filePath,
        'auth_token': _appState.auth_token
      })
    );

    if (response.statusCode == 200) {
      var bodyresponse = response.bodyBytes;
      return bodyresponse;
    
    } else if (response.statusCode == 403) {
      throw Exception('Permission Denied');
    } else {
      throw Exception('Failed to load PDF, or no PDF file was selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_filePath != "" ? _filePath : "No file selected"),
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, AsyncSnapshot<Uint8List> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            print("Loaded ${snapshot.data!.length}");
            return SfPdfViewer.memory(
              snapshot.data as Uint8List,
            );
          }
        },
      ),
    );
  }
}