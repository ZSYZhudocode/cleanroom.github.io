import 'dart:convert';
import 'dart:typed_data';

import 'package:cleanroom/api/urlManager.dart';
import 'package:cleanroom/main.dart';
import 'package:cleanroom/model/resource.dart';
import 'package:cleanroom/widgets/actionbutton.dart';
import 'package:cleanroom/widgets/ripplebutton.dart';
import 'package:cleanroom/widgets/tappablecard.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

class Documents extends StatefulWidget {
  final MyAppState appState;
  final void Function() openPDF;

  Documents({required this.appState, required this.openPDF});

  @override
  State<StatefulWidget> createState() => _DocumentsState();
}

class _DocumentsState extends State<Documents> {
  late MyAppState appState;

  Directory rootDir = Directory(
      name: "default_placeholder", filepath: "/", contents: List.of([]));

  void updateResources(Directory newRootDir) {
    setState(() {
      rootDir = newRootDir;
    });
  }

  @override
  void initState() {
    super.initState();
    appState = widget.appState;
    if (appState.rootDirResource != null &&
        appState.rootDirResource is Directory) {
      rootDir = appState.rootDirResource as Directory;
    }
    fetchDataFromBackend();
  }

  Future<void> fetchDataFromBackend() async {
    try {
      final response =
          await http.get(Uri.parse('${UrlManager.baseUrl}/uploads'));
      if (response.statusCode == 200) {
        setState(() {
          // dynamic decodedResponse = json.decode(response.body)['uploads_directory'];
          // _uploadsData = decodedResponse.toString();
          // print("uploads data: ${_uploadsData}");
          // Decode JSON
          Map<String, dynamic> jsonMap = json.decode(response.body);
          Map<String, dynamic> uploadsDirectory = jsonMap['uploads_directory'];

          // Create Directory object
          Directory uploads = parseDirectory(uploadsDirectory);
          rootDir = uploads;
          appState.updateResourcesCache(rootDir);
        });
      } else {
        print('Failed to fetch data: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to connect to the server. ${error.toString()}');
    }
  }

  // Function to recursively parse JSON and create Directory objects
  Directory parseDirectory(Map<String, dynamic> json) {
    List<Resource> contents = [];
    if (json.containsKey('contents')) {
      json['contents'].forEach((item) {
        if (item.containsKey('contents')) {
          contents.add(parseDirectory(item));
        } else {
          if (path.extension(item['file_path']).toLowerCase() == '.pdf') {
            contents.add(
                PdfFile(name: item['file_name'], filepath: item['file_path']));
          }
        }
      });
    }
    return Directory(
        name: json['directory_name'],
        contents: contents,
        filepath: json['file_path']);
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    List<Widget> resourceWidgets = [];
    if (rootDir.name != "default_placeholder") {
      resourceWidgets.add(TappableCard(
        onTap: (resource) {
          print("Tapped On: ${resource.name}");
          appState.setSelectedFileOrDirectory(resource);
        },
        resource: rootDir,
        isSelected: rootDir == appState.selectedFileOrDirectory,
        child: Wrap(children: [
          Padding(
              padding: const EdgeInsets.all(10.0),
              child: Wrap(children: getResourceWidgets(rootDir, appState))),
        ]),
      ));
    } else {
      resourceWidgets.add(Text("Loading"));
    }

    Resource? selected = appState.selectedFileOrDirectory;
    bool dirSelected = false;
    bool fileSelected = false;
    bool isRootFolderSelected = false;

    if (selected != null) {
      dirSelected = selected is Directory;
      fileSelected = selected is PdfFile;
      isRootFolderSelected = selected.name == "uploads";
    }

    List<Widget> expandCollapseButtons = [];
    if (!appState.isAllExpanded) {
      expandCollapseButtons
          .add(buildButton(CupertinoIcons.fullscreen, "Expand All", () {
        appState.expandAll();
      }));
    } else {
      expandCollapseButtons
          .add(buildButton(CupertinoIcons.fullscreen_exit, "Collapse All", () {
        appState.collapseAll();
      }));
    }

    List<Widget> buttonList = [];
    if (selected != null && fileSelected) {
      buttonList.add(buildButton(CupertinoIcons.eye, "View", widget.openPDF));
    }
    if (selected != null) {
      if (dirSelected) {
        if (!isRootFolderSelected) {
          if (appState.expandedDirectories.contains(selected)) {
            buttonList.add(
                buildButton(CupertinoIcons.fullscreen_exit, "Collapse", () {
              appState.collapseDirectory(selected as Directory);
            }));
          } else {
            buttonList.add(buildButton(CupertinoIcons.fullscreen, "Expand", () {
              appState.expandDirectory(selected as Directory);
            }));
          }
        }
        buttonList
            .add(buildButton(CupertinoIcons.add_circled, "Upload File", () {
          pickPdfAndUpload(appState.selectedFileOrDirectory!.filepath);
        }));
        buttonList.add(buildButton(
            CupertinoIcons.rectangle_stack_fill, "Upload Zip and Unzip", () {
          pickZipAndUpload(appState.selectedFileOrDirectory!.filepath);
        }));
        buttonList.add(
            buildButton(CupertinoIcons.folder_badge_plus, "New Directory", () {
          createDirectoryFromUserInput(
              appState.selectedFileOrDirectory!.filepath);
        }));
      }
      buttonList.add(buildButton(CupertinoIcons.rays, "Unselect", () {
        appState.clearSelected();
      }));
      buttonList.add(buildButton(CupertinoIcons.delete, "Delete", () {
        deleteFiles([selected.filepath], appState.clearSelected);
      }));
      if (fileSelected) {
        buttonList.add(buildButton(CupertinoIcons.move, "Move", () {
          moveFileToUserInputDirectory(selected.filepath);
          appState.clearSelected();
        }));
      }
      if ((fileSelected || dirSelected) && !isRootFolderSelected) {
        buttonList.add(buildButton(CupertinoIcons.pencil_circle, "Rename", () {
          if (!isRootFolderSelected) {
            _getUserInputNewFileName(selected);
            appState.clearSelected();
          } else {
            print("Cannot Rename Uploads directory");
            showToast('Cannot rename "uploads" directory');
          }
        }));
      }
    }
    if (buttonList.isEmpty) {
      buttonList.add(buildButton(CupertinoIcons.cursor_rays,
          "Select something to see actions", _noOpFunction));
    }

    return Container(
      color: Color.fromARGB(255, 23, 8, 78),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15.0, top: 5.0, right: 15.0),
            child: Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.start,
              children: expandCollapseButtons,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0),
            child: Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.start,
              children: buttonList,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, bottom: 15.0, top: 8.0),
              child: SingleChildScrollView(
                child: Wrap(
                  children: resourceWidgets,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButton(IconData icon, String buttonName, Function() call) {
    return RippleButton(
      onPressed: () {
        print("Button tapped: $buttonName");
        call();
      },
      child: ActionButton(
          icon: icon, buttonName: buttonName, enabled: call != _noOpFunction),
    );
  }

  void _noOpFunction() {}

  Future<void> createDirectoryFromUserInput(String targetDirectory) async {
    print("Creating directory inside $targetDirectory");
    String newDirectoryName = "";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter the destination directory'),
          content: TextField(
            autofocus: true,
            onChanged: (value) {
              newDirectoryName = value;
            },
            decoration: InputDecoration(hintText: 'uploads/directory/'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Do something with userInput variable
                print('User entered: $newDirectoryName');
                createDirectory(targetDirectory, newDirectoryName);
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> createDirectory(
      String targetDirectory, String newDirectoryName) async {
    final url = Uri.parse('${UrlManager.baseUrl}/newdir');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    final body = jsonEncode({
      'new_directory_name': newDirectoryName,
      'target_directory': targetDirectory
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        print('Directory created successfully');
        fetchDataFromBackend();
      } else {
        print('Failed to create directory');
        showToast('Failed to create directory');
      }
    } catch (error) {
      print('Failed to connect to the server: $error');
    }
  }

  Future<void> moveFileToUserInputDirectory(String oldPath) async {
    TextEditingController _controller =
        TextEditingController(text: path.dirname(oldPath) + "/");
    String newDirectory = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter the destination directory'),
          content: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (value) {
              newDirectory = value;
            },
            decoration: InputDecoration(hintText: 'uploads/directory/'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Do something with userInput variable
                print('User entered: $newDirectory');
                // Clean the input
                // New directory should always start with "uploads"
                if (newDirectory.startsWith("uploads/")) {
                } else {
                  newDirectory = "uploads/$newDirectory";
                }
                String oldFileName = path.basename(oldPath);
                updatePath(oldPath, path.join(newDirectory, oldFileName));

                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getUserInputNewFileName(Resource fileOrDirectory) async {
    TextEditingController _controller =
        TextEditingController(text: path.basename(fileOrDirectory.name));
    String instruction = "";
    String inputHintText = "";
    if (fileOrDirectory is PdfFile) {
      instruction = "Enter new file name";
      inputHintText = "new_file_name.pdf";
    } else if (fileOrDirectory is Directory) {
      instruction = "Enter new directory name";
      inputHintText = "your_directory_name";
    }

    String newName = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(instruction),
          content: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (value) {
              newName = value;
            },
            decoration: InputDecoration(hintText: inputHintText),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Do something with userInput variable
                print('User entered: $newName');

                if (fileOrDirectory is PdfFile) {
                  if (!newName.endsWith(".pdf")) {
                    newName += ".pdf";
                  }
                  String oldPath = fileOrDirectory.filepath;
                  String oldPathDir = path.dirname(oldPath);
                  updatePath(oldPath, path.join(oldPathDir, newName));
                } else if (fileOrDirectory is Directory) {
                  // Split the directory string by '/'
                  String oldPath = fileOrDirectory.filepath;
                  List<String> directories = oldPath.split('/');
                  // Remove the last directory
                  directories.removeLast();
                  // Append the new directory name
                  directories.add(newName);
                  // Join the directories back into a single string
                  String updatedDirectory = directories.join('/');
                  updatePath(oldPath, updatedDirectory);
                }
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updatePath(String oldPath, String newPath) async {
    print("Updating $oldPath to $newPath");
    final url = Uri.parse('${UrlManager.baseUrl}/move');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    final body = jsonEncode({
      'file_path': oldPath,
      'new_path': newPath,
      'auth_token': appState.auth_token
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        print('File moved successfully');
        fetchDataFromBackend();
      } else if (response.statusCode == 403) {
        showToast('Failed to make the updates. You may not have necessary permissions.');
      } 
      else {
        print('Failed to move files: ${response.statusCode}');
        showToast('Failed to move files');
      }
    } catch (error) {
      print('Failed to connect to the server: $error');
    }
  }

  Future<void> uploadPdf(
      Uint8List pdfBytes, String filePath, String fileName) async {
    final uri = Uri.parse('${UrlManager.baseUrl}/upload_pdf');
    final request = http.MultipartRequest('POST', uri);
    request.files
        .add(http.MultipartFile.fromBytes('pdf', pdfBytes, filename: fileName));
    request.fields['file_path'] = filePath + "/$fileName";
    request.fields['auth_token'] = appState.auth_token.toString();

    try {
      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        print('PDF uploaded successfully');
        print('Response: ${response.body}');
        fetchDataFromBackend();
      } else {
        print('Failed to upload PDF: ${response.statusCode}');
        showToast('Failed to upload PDF');
      }
    } catch (error) {
      print('Failed to connect to the server: $error');
    }
  }

  Future<void> pickPdfAndUpload(String filePath) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      final fileType = file.extension;
      print("fileType: $fileType");
      if (fileType == "pdf") {
        Uint8List pickedFileBytes = file.bytes!;
        // File pickedFile = File(file.path!);
        await uploadPdf(pickedFileBytes, filePath, file.name);
        fetchDataFromBackend();
      } else {
        print("Not a pdf file. Skipping");
      }
    } else {
      // User canceled the file picker
      print('User canceled file picker');
    }
  }

  Future<void> pickZipAndUpload(String filePath) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null) {
      // Web apps need to get the zip file as bytes, not a file.
      Uint8List? pickedZipFile = result.files.single.bytes;
      if (pickedZipFile != null) {
        await uploadZip(pickedZipFile, filePath);
        fetchDataFromBackend();
      }
    } else {
      // User canceled the file picker
      print('User canceled selecting a zip');
    }
  }

  Future<void> uploadZip(Uint8List fileAsBytes, String filePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${UrlManager.baseUrl}/uploadzip'),
      );

      request.fields['directory_name'] = filePath;
      request.fields['auth_token'] = appState.auth_token.toString();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileAsBytes,
        filename: 'picked_zip_file.zip',
      ));

      var response = await request.send();

      if (response.statusCode == 200) {
        // Upload successful
        print('Zip file uploaded successfully');
      } else {
        // Handle upload failure
        print('Failed to upload zip file');
        showToast('Failed to upload zip file');
      }
    } catch (e) {
      // Handle upload failure
      print('Failed to upload zip file: $e');
    }
  }

  Future<void> deleteFiles(List<String> filesToDeletePaths, Function() clearSelected) async {
    final url = Uri.parse('${UrlManager.baseUrl}/delete');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    final body = jsonEncode({
      'filesToDelete': filesToDeletePaths,
      'auth_token': appState.auth_token
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        print('Files deleted successfully');
        fetchDataFromBackend();
        clearSelected();
      } else if (response.statusCode == 403) {
        showToast('Failed to delete files. You may not have the permissions.');
      } else {
        print('Failed to delete files: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to connect to the server: $error');
    }
  }

  List<Widget> getResourceWidgets(Directory directory, MyAppState appState) {
    List<Widget> widgets = [];
    List<Resource> resources = directory.contents;

    // For the sake of readability, show PDFfiles first, and then Directories
    resources.sort((a, b) {
      if (a is Directory && b is PdfFile) {
        // Directories come after PdfFiles
        return 1;
      } else if (a is PdfFile && b is Directory) {
        // PdfFiles come after Directories
        return -1;
      } else {
        // Otherwise, maintain the existing order
        return 0;
      }
    });

    for (var resource in directory.contents) {
      if (resource is PdfFile) {
        widgets.add(Row(
          children: [
            TappableCard(
              onTap: (resource) {
                print("Tapped On: ${resource.name}");
                appState.setSelectedFileOrDirectory(resource);
              },
              resource: resource,
              child: null,
              isSelected: resource == appState.selectedFileOrDirectory,
            ),
          ],
        ));
      }
      if (resource is Directory) {
        widgets.add(TappableCard(
          onTap: (resource) {
            print("Tapped On: ${resource.name}");
            appState.setSelectedFileOrDirectory(resource);
          },
          resource: resource,
          isSelected: resource == appState.selectedFileOrDirectory,
          child: Wrap(children: [
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: (appState.expandedDirectories.contains(resource))
                    ? Wrap(children: getResourceWidgets(resource, appState))
                    : null),
          ]),
        ));
      }
    }
    return widgets;
  }

  void showToast(msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.grey,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
