import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cleanroom/api/urlManager.dart';
import 'package:cleanroom/pages/documents.dart';
import 'package:cleanroom/pages/loginpage.dart';
import 'package:cleanroom/pages/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'model/resource.dart';
import 'widgets/actionbutton.dart';
import 'widgets/ripplebutton.dart';
import 'widgets/tappablecard.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'CleanRoom',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 12, 22, 132)),
        ),
        home: HomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  Resource? rootDirResource;
  Resource? selectedFileOrDirectory;
  String? username;
  int privilegeLevel = 0;
  String? auth_token; 

  Set<Directory> expandedDirectories = {};
  bool isAllExpanded = false;

  void collapseDirectory(Directory dir) {
      expandedDirectories.remove(dir);
      isAllExpanded = false;
      notifyListeners();
  }

  void expandDirectory(Directory dir) {
      expandedDirectories.add(dir);
      notifyListeners();

  }

  void collapseAll() {
      expandedDirectories.clear();
      isAllExpanded = false;
      notifyListeners();
  }

  void expandAll() {
      isAllExpanded = true;
      notifyListeners();
  }


  void setSelectedFileOrDirectory(Resource resource) {
    selectedFileOrDirectory = resource;
    notifyListeners();
  }

  void updateResourcesCache(Resource rootDirResource) {
    this.rootDirResource = rootDirResource;
    notifyListeners();
  }

  void clearSelected() {
    selectedFileOrDirectory = null;
    notifyListeners();
  }

  void setUsernameAndPrivLevel(String username, int privilegeLevel) {
    this.username = username;
    this.privilegeLevel = privilegeLevel;
    print("Username: $username  Privilege Level: $privilegeLevel");
    notifyListeners();
  }
  
  void setAuthToken(String token) {
    auth_token = token;
    notifyListeners();
  }

  void clearLoggedInState() {
    auth_token = null; 
    username = null;
    privilegeLevel = 0;
    notifyListeners();
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var selectedIndex = 0; // ← Add this property.

  void openPdfViewer() {
    setState(() {
      selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    Widget page;
    print(
        "AppState Selectedfile: ${appState.selectedFileOrDirectory?.filepath}");
    switch (selectedIndex) {
      case 0:
        page = LoginPage(
            setUsernameAndPrivLevel: appState.setUsernameAndPrivLevel,
            username: appState.username,
            privilegeLevel: appState.privilegeLevel,
            setAuthToken: appState.setAuthToken,
            getAuthToken: () => appState.auth_token.toString(),
            clearLoggedInState: appState.clearLoggedInState,
            );
        break;
      case 1:
        page = Documents(appState: appState, openPDF: openPdfViewer);
        break;
      case 2:
        print(
            "Creating PDF Viewer Page with Selectedfile: ${appState.selectedFileOrDirectory?.filepath}");
        page = PDFViewerPage(
            filePath: appState.selectedFileOrDirectory?.filepath ?? "",
            appState: appState);
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    TextStyle navRailButtonStyle = TextStyle(fontSize: 18);
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 13, 7, 44),
          title: Row(
            children: [
              Image.asset(
                'images/logo.png',
                scale: 13,
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 28.0, bottom: 28.0, left: 15),
                child: Text('CleanRoom',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontFamily: 'Pacifico',
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                    )),
              ),
            ],
          ),
          // You can customize the app bar further with other properties like actions, etc.
        ),
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.person),
                    label: Text('Login', style: navRailButtonStyle),
                  ),
                  NavigationRailDestination(
                    icon: Icon(CupertinoIcons.doc),
                    label: Text('Documents', style: navRailButtonStyle),
                  ),
                  NavigationRailDestination(
                    icon: Icon(CupertinoIcons.eye),
                    label: Text('PdfViewer', style: navRailButtonStyle),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}
