abstract class Resource {
  String name;
  String filepath;

  Resource(this.name, this.filepath);

  // Needed so that we can maintain the "selected" state of directories and pdf files. 
  // Otherwise, we'd be comparing the old stored selected Resource object with a newly created one due 
  // to refreshing of the ui state
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Resource &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          filepath == other.filepath;

  @override
  int get hashCode => name.hashCode ^ filepath.hashCode;
}

class PdfFile extends Resource {

  PdfFile({required String name, required String filepath}) : super(name, filepath);
}

class Directory extends Resource {

  final List<Resource> contents;

  Directory({
    required String name, 
    required String filepath, 
    required this.contents
  }) : super(name, filepath);

}
