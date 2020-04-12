import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  /// You can export a function by setting a key on global [functions]
  /// object.
  ///
  /// For HTTPS functions the key is also a URL path prefix, so in below
  /// example `helloWorld` function will be available at `/helloWorld`
  /// URL path and it will also handle all paths under this prefix, e.g.
  /// HTTPS 関数のキーは URL パスのプレフィックスでもあるので、
  /// 以下の例では `helloWorld` 関数は `/helloWorld` の
  /// URL パスで利用でき、このプレフィックス以下のすべてのパスも処理します。
  /// `/helloWorld/any/number/of/sections`.
  functions['helloWorld'] = functions.https.onRequest(helloWorld);
  functions['helloWorldOnCall'] = functions.https.onCall(helloWorldCalled);
//  functions['makeUppercase'] =
//      functions.database.ref('/tests/{testId}/original').onWrite(makeUppercase);
//  functions['makeNamesUppercase'] = functions.firestore
//      .document('/users/{userId}')
//      .onWrite(makeNamesUppercase);
//  functions['logPubsub'] =
//      functions.pubsub.topic('my-topic').onPublish(logPubsub);
  //gcloud pubsub topics publish my-topic --message '{"name":"Xenia"}'
//  functions['logStorage'] = functions.storage.object().onFinalize(logStorage);
//  functions['logAuth'] = functions.auth.user().onCreate(logAuth);
}

/// Example Realtime Database function.
FutureOr<void> makeUppercase(
    Change<DataSnapshot<String>> change, EventContext context) {
  final DataSnapshot<String> snapshot = change.after;
  var original = snapshot.val();
  var pushId = context.params['testId'];
  print('Uppercasing $original');
  var uppercase = pushId.toString() + ': ' + original.toUpperCase();
  return snapshot.ref.parent.child('uppercase').setValue(uppercase);
}

/// Example Firestore
FutureOr<void> makeNamesUppercase(
    Change<DocumentSnapshot> change, EventContext context) {
  // Since this is an update of the same document we must guard against
  // infinite cycle of this function writing, reading and writing again.
  final snapshot = change.after;
  if (snapshot.data.getString("uppercasedName") == null) {
    var original = snapshot.data.getString("name");
    print('Uppercasing $original');

    UpdateData newData = new UpdateData();
    newData.setString("uppercasedName", original.toUpperCase());

    return snapshot.reference.updateData(newData);
  }
  return null;
}

/// Example Pubsub
void logPubsub(Message message, EventContext context) {
  // gcloud pubsub topics publish my-topic --message {\"name\":\"Xenia\"}
  print('The function was triggered at ' + context.timestamp.toString());
  print('The unique ID for the event is' + context.eventId.toString());
  print(message.data);
  String decoded = utf8.decode(base64Url.decode(message.data));
  var decodedJson = jsonDecode(decoded);
  print(decodedJson["name"]);
}

///// Example Storage
//void logStorage(ObjectMetadata data, EventContext context) {
//  print(data.name);
//}

/// Example Auth
void logAuth(UserRecord data, EventContext context) {
  print(data.email);
}

/// Example HTTPS function.
Future<void> helloWorld(ExpressHttpRequest request) async {
  try {
    request.response.writeln('Hello world Start');
    // 設定パラメータがある場合は、以下のようにアクセスできます。:
    var config = functions.config;
    var serviceKey = config.get('someservice.key');
    var serviceUrl = config.get('someservice.url');
    // 実際のプロジェクトでやるなよ:
    print('Service key: $serviceKey, service URL: $serviceUrl');

    /// The provided [request] is fully compatible with "dart:io" `HttpRequest`
    /// including the fact that it's a valid Dart `Stream`.
    /// Note though that Firebase uses body-parser expressjs middleware which
    /// decodes request body for some common content-types (json included).
    /// In such cases use `request.body` which contains decoded body.
    // 提供される [request] は "dart:io" `HttpRequest` と完全に互換性があります。
    // https://api.dart.dev/stable/2.7.2/dart-io/HttpRequest-class.html
    // これは有効な Dart `Stream`であるという事実も含めてです。
    // しかし、Firebaseはボディパーサexpressjsミドルウェアを使用しており、
    // 一般的なコンテンツタイプ(jsonを含む)のリクエストボディをデコードします。
    // そのような場合は、デコードされたボディを含む `request.body` を使う。

    print(request.method);
    print(request.headers.contentType);
    print(request.body);
//    String name = request.requestedUri.queryParameters['name'];

//    String decoded = utf8.decode(request.body);
    ContentType contentType = request.headers.contentType;
    if (request.method == 'POST' &&
        contentType?.mimeType == 'application/json') {
      print(request.body["name"]);
      var name = request.body["name"];
      if (name != null) {
        // We can also write to Realtime Database right here:
        var admin = FirebaseAdmin.instance;
        var path =
            "C:/firebase/isdf-git-firebase-adminsdk-flh56-459eb1467e.json";
        var appOptions = new AppOptions(
            credential: admin.certFromPath(path),
            databaseURL: 'https://isdf-git.firebaseio.com');
        var app = admin.initializeApp(appOptions);
        var fireStore = app.firestore();

        var citiesRef = fireStore.collection('users');
        DocumentData data = DocumentData.fromMap({'name': name});

        await citiesRef.document('testdoc').setData(data);
        request.response.writeln('fireStore setData');
      }
    }

    request.response.writeln('Hello world post OK');
  } finally {
    request.response.writeln('Hello world end');
    request.response.close();
  }
}

/// Example HTTPS function.
FutureOr<dynamic> helloWorldCalled(
    dynamic data, CallableContext context) async {
  final now = DateTime.now();
  var nowString = now.toUtc().toIso8601String();

  var admin = FirebaseAdmin.instance;
  var path =
      "C:/firebase/isdf-git-firebase-adminsdk-flh56-459eb1467e.json";
  var appOptions = new AppOptions(
      credential: admin.certFromPath(path),
      databaseURL: 'https://isdf-git.firebaseio.com');
  var app = admin.initializeApp(appOptions);
  var fireStore = app.firestore();

  var citiesRef = fireStore.collection('users');
  DocumentData data = DocumentData.fromMap({'now': nowString});

  await citiesRef.document('helloWorldCalled').setData(data);

  print("helloWorldCalled!!!");

  return {
    "name": "isdf",
    "asdf": nowString,
  };
}

//cd functions && npm run build && cd .. && firebase deploy --force
//curl -X POST -H "Content-Type: application/json" -d "{\"name\":\"ishida\"}" https://us-central1-isdf-git.cloudfunctions.net/helloWorld
