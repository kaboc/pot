// ignore_for_file: public_member_api_docs

import 'dart:convert' show jsonEncode;
import 'dart:developer' as developer;

class ExtensionCommunicator {
  const ExtensionCommunicator();

  void post(String kind, [Map<String, Object?> data = const {}]) {
    developer.postEvent(kind, data);
  }

  void onRequest(
    String methodName,
    Map<String, Object?> Function() dataBuilder,
  ) {
    developer.registerExtension(methodName, (_, __) async {
      final data = dataBuilder();
      final json = jsonEncode(data);
      return developer.ServiceExtensionResponse.result(json);
    });
  }
}
