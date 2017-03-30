import 'dart:async';
import 'google-drive-connector.dart';

import 'package:colorize/colorize.dart';
import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';

main() async {
  // Just get the directory on which we want to run the script.
  Directory dir = await getDirectory(true);

  // Just make sure we are in the correct directory.
  printGreen("The directory selected is: ${dir.path}. Continue? (Y/N)");
  if (stdin.readLineSync().toUpperCase() != 'Y') {
    printRedBold("Restart the project and give a correct path");
    exit(2);
  }

  // Get the files in the directory specified.
  List<FileSystemEntity> directoryList = await dir.list(recursive: true, followLinks: true).toList();

  // Get the files to delete in the directory.
  List<File> files_to_delete = await getFilesToDelete(directoryList);

  // Get the files that can not be deleted according to the previous findings.
  List<File> files_that_can_not_be_deleted = await getFilesThatWillNotBeDeleted(directoryList, files_to_delete);

  // Delete files if the user wants to proceed.
  await doDelete(files_to_delete);

  // If there is files that could not be deleted..
  if (!files_that_can_not_be_deleted.isEmpty) {
    // List and show files that could not be deleted.
    await getFilesThatCanNotBeDeleted(files_that_can_not_be_deleted);

    // Offer to try to get more information on those files.
    printYellowBold("We can try to get more information on those files and locate them or find the owner.");
    printYellowBold("Would you like us to try and get that info? (Y/N)");
    if (stdin.readLineSync().toUpperCase() == 'Y') {
      await getMoreInformationOnFilesThatCanNotBeDeleted(files_that_can_not_be_deleted);
    }
  }
}

/// Just get a list of files that will not be deleted because
/// the real GDrive file could not be found.
Future<List<File>> getFilesThatWillNotBeDeleted(List<FileSystemEntity> directoryList, List<File> files_to_delete) async {
  List<File> list = new List<File>();

  // Loop through all the files in the specified directory, recursively and following symlinks.
  for (FileSystemEntity item in directoryList) {
    // Get the extension of the file
    if (isGoogleDriveBackupFile(extension(item.path))) {
      File not_deleted_file = await new File(item.path);
      if (!files_to_delete.contains(not_deleted_file)) {
        list.add(not_deleted_file);
      }
    }
  }

  return list;
}

/// Gets a list of all the files that we should delete by getting
/// all the files with the Drive Extensions and trying to find backups
/// on the same directory.
Future<List<File>> getFilesToDelete(List<FileSystemEntity> directoryList) async {
  List<File> list = new List<File>();

  // Loop through all the files in the specified directory, recursively and following symlinks.
  for (FileSystemEntity item in directoryList) {
    // Get the extension of the file
    String ext = extension(item.path);

    // If the file is a Drive file (gdoc, gsheet, etc), check if they have a backup
    if (isGoogleDriveFile(ext)) {
      // Get the file name of the backup and check if it exists
      String newPath = dirname(item.path) + "/" + basenameWithoutExtension(item.path) + _getExt(ext);
      if (await new File(newPath).exists()) {
        list.add(await new File(newPath));
      }
    }
  }

  return list;
}

/// Just checks if a file is NOT part of the Google Drive Ecosystem and is a Backup File
bool isGoogleDriveBackupFile(String ext) {
  return ext == ".gdsheet" || ext == ".gddoc" || ext == ".gdslides";
}

/// Just checks if a file is part of the Google Drive Ecosystem
bool isGoogleDriveFile(String ext) {
  return ext == ".gsheet" || ext == ".gdoc" || ext == ".gslides";
}

/// Get the Directory on which we want to run the script.
Future<Directory> getDirectory(bool color_notices) async {
  if (color_notices) {
    printGreen('Hello. Let\'s clean up the mess in Google Drive.');
    printYellowBold('Specify the fully qualified Path for the folder you want to clean:');
  }
  String input = null;
  while (input == null || input.isEmpty) {
    if (input != null) printYellowBold('Please specify a correct directory.');
    input = stdin.readLineSync();
  }
  Directory dir = await new Directory(input);
  bool exists = await dir.exists();

  Directory toReturn = null;
  if (!exists) {
    printRedBold("The given Directory does not exist.");
    printYellowBold("Please specify a correct one:");
    toReturn = await getDirectory(false);
  } else {
    toReturn = dir;
  }

  return toReturn;
}

Future getFilesThatCanNotBeDeleted(List<File> files_that_can_not_be_deleted) async {
  printRedBold("________  _______    ______   _______  ___      _______  _______  _______");
  printRedBold("|       ||       |  |      | |       ||   |    |       ||       ||       |");
  printRedBold("|_     _||   _   |  |  _    ||    ___||   |    |    ___||_     _||    ___|");
  printRedBold("  |   |  |  | |  |  | | |   ||   |___ |   |    |   |___   |   |  |   |___");
  printRedBold("  |   |  |  |_|  |  | |_|   ||    ___||   |___ |    ___|  |   |  |    ___|");
  printRedBold("  |   |  |       |  |       ||   |___ |       ||   |___   |   |  |   |___");
  printRedBold("  |___|  |_______|  |______| |_______||_______||_______|  |___|  |_______|");

  int files = files_that_can_not_be_deleted.length;
  printYellowBold('$files files can not yet be deleted, do you want to know them? (Y/N)');
  String input = stdin.readLineSync().toUpperCase();
  if (input == 'N') {
    return;
  } else {
    for (File file in files_that_can_not_be_deleted) {
      printCyanItalic(file.path.substring(30));
    }
  }
}

Future doDelete(List<File> files_to_delete) async {
  printRedBold("_______   _______  ___      _______  _______  _______");
  printRedBold("|      | |       ||   |    |       ||       ||       |");
  printRedBold("|  _    ||    ___||   |    |    ___||_     _||    ___|");
  printRedBold("| | |   ||   |___ |   |    |   |___   |   |  |   |___");
  printRedBold("| |_|   ||    ___||   |___ |    ___|  |   |  |    ___|");
  printRedBold("|       ||   |___ |       ||   |___   |   |  |   |___");
  printRedBold("|______| |_______||_______||_______|  |___|  |_______|");

  printYellowBold("About to remove the unwanted gd files, continue? (Y/N):");
  if (stdin.readLineSync().toUpperCase() != 'Y') {
    return;
  }

  if (files_to_delete.isEmpty) {
    printGreen("You can not remove any file right now, congratulations!");
    return;
  }

  printYellowBold('You have a total of ${files_to_delete.length} files to delete, do you want to proceed? (Y/N)');
  String input = stdin.readLineSync().toUpperCase();
  if (input == 'N') {
    printGreen("YOU DECIDED YOU DIDN'T WANT TO DELETE THE FILES.");
  } else if (input == 'Y') {
    printYellowBold("DELETING ALL ${files_to_delete.length} FILES");
    int deleted_files = 0;
    if (files_to_delete.isEmpty) {
      printGreen("There is no files left to delete at this moment.");
    } else {
      for (File file in files_to_delete) {
        File deleted = await file.delete();
        printCyanItalic("Removing file ${basename(file.path)}");
        bool deleted_exists = await deleted.exists();
        if (!deleted_exists) {
          deleted_files++;
        }
      }
      printGreen("A total number of ${files_to_delete.length} could be deleted");
      printGreen("A total number of $deleted_files have been deleted");
    }
  }
}

/// Gets the extension of the backup file given an old extension
String _getExt(String current) {
  if (current == ".gsheet") {
    return ".gdsheet";
  }
  if (current == ".gdoc") {
    return ".gddoc";
  }
  if (current == ".gslides") {
    return ".gdslides";
  }
  return null;
}

void printGreen(String text) => color(text, front: Styles.GREEN);

void printYellowBold(String text) => color(text, front: Styles.YELLOW, isBold: true);

void printRedBold(String text) => color(text, front: Styles.RED, isBold: true);

void printCyanItalic(String text) => color(text, front: Styles.CYAN, isItalic: true);
