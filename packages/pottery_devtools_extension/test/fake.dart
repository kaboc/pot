import 'dart:async' show StreamController;

import 'package:devtools_app_shared/service.dart';
import 'package:vm_service/vm_service.dart';

import 'package:pottery/src/extension/communicator.dart';

class FakeVmService extends VmService {
  FakeVmService(super.inStream, super.writeMessage) {
    _eventStreamController = StreamController<Event>();
  }

  static StreamController<Event>? _eventStreamController;

  @override
  Stream<Event> get onExtensionEvent => _eventStreamController!.stream;

  @override
  Future<void> dispose() async {
    await _eventStreamController?.close();
    _eventStreamController = null;
    await super.dispose();
  }
}

// ignore: subtype_of_sealed_class
class FakeServiceManager extends ServiceManager {
  FakeServiceManager() : super() {
    _inStreamController = StreamController<String>();
    _service = FakeVmService(
      _inStreamController.stream,
      _inStreamController.sink.add,
    );
  }

  late final StreamController<String> _inStreamController;
  late final VmService _service;

  @override
  VmService get service => _service;

  void dispose() {
    _service.dispose();
    _inStreamController.close();
  }

  @override
  Future<VmService> get onServiceAvailable async => _service;

  @override
  Future<Response> callServiceExtensionOnMainIsolate(
    String method, {
    Map<String, dynamic>? args,
  }) async {
    final data = FakeExtensionCommunicator._methods[method]?.call();
    return Response.parse(data ?? {})!;
  }
}

class FakeExtensionCommunicator implements ExtensionCommunicator {
  FakeExtensionCommunicator() {
    _methods = {};
  }

  static late Map<String, Map<String, Object?> Function()> _methods;

  void dispose() {
    _methods.clear();
  }

  @override
  void post(String kind, [Map<String, Object?> data = const {}]) {
    FakeVmService._eventStreamController?.sink.add(
      Event(
        extensionKind: kind,
        extensionData: ExtensionData.parse(data),
      ),
    );
  }

  @override
  void onRequest(
    String methodName,
    Map<String, Object?> Function() dataBuilder,
  ) {
    _methods[methodName] = () => dataBuilder();
  }
}
