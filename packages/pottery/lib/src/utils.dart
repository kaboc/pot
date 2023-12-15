// ignore_for_file: public_member_api_docs

extension MapToRecord<K, V> on Map<K, V> {
  List<(K, V)> get records => [
        for (final MapEntry(:key, :value) in entries) (key, value),
      ];
}
