import 'dart:async';

import 'package:fs_shim/fs_io.dart';
import 'package:googleapis/drive/v2.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:path/path.dart';
import 'drive-clean.dart';
import 'package:googleapis_auth/src/auth_http_utils.dart';
import 'package:http/http.dart';
import 'dart:convert';

// Define the client that we'll be using.
const CLIENT_ID = "239832560167-laq2thg0cqsgjdia8tqise6po1v3t327.apps.googleusercontent.com";
const CLIENT_SECRET = "NUW_k_IEicHhPF_FO34LqFnb";
const _SCOPES = drive.DriveApi.DriveReadonlyScope;
auth.AutoRefreshingAuthClient _client = null;

/// Try to get more information on those files that could not be deleted.
Future getMoreInformationOnFilesThatCanNotBeDeleted(List<File> files_that_can_not_be_deleted) async {
  // Get the Drive Api Implementation while getting the
  // authorization from the client.
  drive.DriveApi api = await getDriveApi();

  printGreen("Looking for all ${files_that_can_not_be_deleted.length} files, please wait");

  List<File> found_items = new List<File>();

  // Loop through each file that we want to look for,
  for (File real_file in files_that_can_not_be_deleted) {
    // The best way to find the files is by their real name with no extension.
    String query = basenameWithoutExtension(real_file.path);

    // We should also get the real extension to later identify the file.
    String ext = extension(real_file.path);

    // There's some weird cases in which I'm still getting an error.
    // So let's just be safe and make sure they won't break the flow.
    try {
      // Using DDrives search engine, look for all the files
      // That match a certain query and a given mimetype (Extension)
      String search = "title='${query}' and " + queryMapping[ext];

      // Do the search and get the returning items.
      drive.FileList results = await api.files.list(includeTeamDriveItems: true, q: search, supportsTeamDrives: true);
      List<drive.File> files = results.items;

      // If there is actually some results investigate.
      if (!files.isEmpty) {
        // Keep a counter of real files that have been matched with at least one result.
        found_items.add(real_file);

        // Give the user some contextual information
        printRedBold("Match(es) for \"$query$ext\":");
        for (drive.File f in files) {
          printRedBold("\n  - File \"${f.title}\" with extension ${f.mimeType} FOUND");
          printCyanItalic("   - System Directory: ${dirname(real_file.path)}");
          printCyanItalic("   - Can ve viewed here: ${f.alternateLink}");
          printCyanItalic("   - Creation Date: ${f.createdDate.toLocal()}");
          if (f.ownerNames.length > 1) {
            printCyanItalic("   - Owners of the file:");
            for (String owner in f.ownerNames) {
              printCyanItalic("     - $owner");
            }
          } else {
            printCyanItalic("   - Owner of the document: ${f.ownerNames[0]}");
          }
          printCyanItalic("   - Last Modification:user ${f.lastModifyingUser.displayName} - ${f.lastModifyingUser.emailAddress} at ${f.modifiedDate.toString()}");
        }
        print("");
        printYellowBold("###########################################");
        printYellowBold("###########################################");
      }
    } catch (exception) {
      // If there are errors, print them.
      printRedBold("!!!!!!!!!!! $exception !!!!!!!!!!!");
    }
  }

  // Close the http client now, no longer needed
  _client.close();

  // Give a little more information on what has happened and shut down.
  printYellowBold("A total of ${found_items.length} files out of ${files_that_can_not_be_deleted.length} files have been located.");

  exit(0);
}

/// Handles the oAuth and login process for the user
Future<drive.DriveApi> getDriveApi({bool forceUpdate: false}) async {
  // Create a new ClientId
  auth.ClientId client_id = new auth.ClientId(CLIENT_ID, CLIENT_SECRET);

  // The api object will be the one we'll be returning
  // Make sure it's there.
  drive.DriveApi api = null;

  // Sometimes, on exceptions we'll be wanting the user to re-login
  // also, we need to make sure that the user has a refresh token
  // before we try to automatically authorize his/her requests
  if (!forceUpdate && await hasRefreshTokenSavedLocally()) {
    // Try and if fail, re-authenticate the user.
    try {
      // Get the user credentials from previous visits to the program.
      auth.AccessCredentials accessCredentials = await new auth.AccessCredentials(await getAccessTokenSavedLocally(), await getRefreshTokenSavedLocally(), [_SCOPES]);

      // Generate a client using the newly created credentials.
      _client = await new AutoRefreshingClient(new Client(), client_id, accessCredentials, closeUnderlyingClient: true);

      // Make a new DriveApi Instance. We'll be using
      api = new drive.DriveApi(_client);

      // Use a small request to actually get things done and, in the mean time
      // also check it the authenticated user has a correct access to the
      // GDrive account authenticated.
      drive.About about = await api.about.get();

      // Just printing some information.
      printYellowBold("###########################################");
      printGreen("You are logged in as : ${about.user.displayName}");
      printGreen("Associated email address: ${about.user.emailAddress}");
      printYellowBold("###########################################");
    } catch (e) {
      // If something fails, return a new Instance of the DriveApi forcing the
      // user to authenticate again.
      return getDriveApi(forceUpdate: true);
    }
  } else {
    // If the user had never logged in, log him/her in.
    _client = await auth.clientViaUserConsent(client_id, [_SCOPES], prompt);

    // Create a new directory to save the credentials
    Directory auth_dir = await new Directory(await dir());
    if (!await auth_dir.exists()) {
      await auth_dir.create();
    }

    // Write the credentials locally to be used next time.
    await file("refresh_token")..writeAsString(BASE64.encode(UTF8.encode(_client.credentials.refreshToken)));
    await file("auth_token")..writeAsString(BASE64.encode(UTF8.encode(_client.credentials.accessToken.data)));
    await file("expiry")..writeAsString(BASE64.encode(UTF8.encode(_client.credentials.accessToken.expiry.toUtc().millisecondsSinceEpoch.toString())));

    // Make the instance we need.
    api = new drive.DriveApi(_client);
  }

  return api;
}

/// Get the refresh token we have locally
Future<String> getRefreshTokenSavedLocally() async {
  File f = await file("refresh_token");
  return UTF8.decode(await f.readAsBytes());
}

/// Check if we have a refresh token saved locally
Future<bool> hasRefreshTokenSavedLocally() async {
  File f = await file("refresh_token");
  return await f.exists();
}

/// Get and generate the AccessToken with the information
/// we have locally
Future<auth.AccessToken> getAccessTokenSavedLocally() async {
  try {
    String auth_token = UTF8.decode(BASE64.decode(await (await file("auth_token")).readAsString()));
    String expiry = UTF8.decode(BASE64.decode(await (await file("expiry")).readAsString()));
    return new auth.AccessToken("Bearer", auth_token, new DateTime.fromMillisecondsSinceEpoch(int.parse(expiry)).toUtc());
  } catch (e) {
    throw e;
  }
}

/// Check if we have an auth token saved locally
Future<bool> hasAuthToken() async {
  return await (await file("auth_token")).exists();
}

/// Callback function whenever we get the prompt url to log in.
void prompt(String url) {
  print("The Google Drive cleaner needs access to your Google Drive Cloud instance, plase follow the url:");
  print("  => $url");
  print("");
}

/// Maps document types to Drive Query strings.
final Map queryMapping = const {
  '.gddoc': "mimeType='application/vnd.google-apps.document'",
  '.gdsheet': "mimeType='application/vnd.google-apps.spreadsheet'",
  '.gdslides': "mimeType='application/vnd.google-apps.presentation'",
  '.link': "mimeType='application/vnd.google-apps.drive-sdk'",
};

Future<String> dir() async {
  return await new Directory(dirname(Platform.script.path)).parent.path + '/.auth/';
}

Future<File> file(String name) async {
  return new File(await dir() + name);
}
