import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  functions['helloWorld'] = functions.https.onRequest(helloWorld);
  functions['hellWorld'] = functions.https.onRequest(hellWorld);
}

void helloWorld(ExpressHttpRequest request) {
  request.response.writeln('Hello world');
  request.response.close();
}

void hellWorld(ExpressHttpRequest request) {
  request.response.writeln('Hell world...');
  request.response.close();
}
