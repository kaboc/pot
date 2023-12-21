import 'dart:convert' show jsonEncode;

import 'package:pottery/src/extension/communicator.dart';

typedef SpyLog = (String label, String? data);

class SpyExtensionCommunicator implements ExtensionCommunicator {
  final methods = <String, String Function()>{};
  final log = <SpyLog>[];

  void dispose() {
    methods.clear();
    log.clear();
  }

  @override
  void post(String kind, [Map<String, Object?> data = const {}]) {
    log.add((kind, jsonEncode(data)));
  }

  @override
  void onRequest(
    String methodName,
    Map<String, Object?> Function() dataBuilder,
  ) {
    methods[methodName] = () => jsonEncode(dataBuilder());
  }

  void request(String methodName) {
    final method = methods[methodName];
    if (method != null) {
      log.add((methodName, method()));
    }
  }
}
