import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;

const defaultUrl = 'https://www.frankfurter.app/';

class Frankfurter {
  /// Defaults to https://www.frankfurter.app/
  final Uri url;
  final http.Client client;

  Frankfurter({Uri url, http.Client client})
      : url = url ?? Uri.parse(defaultUrl),
        client = client;

  Future<List<Rate>> latest({@required Currency from, Set<Currency> to}) async {
    Currency;

    final url = this.url.replace(path: 'latest', queryParameters: {
      'from': from.code,
      if (to != null) 'to': to.map((currency) => currency.code).join(','),
    });
    try {
      final response = await _withClient((client) => client.get(url));
      final decoded = jsonDecode(response.body);
      final rates = (decoded['rates'] as Map).cast<String, num>();
      return rates.keys
          .map<Rate>(
              (code) => Rate(from, Currency(code), rates[code].toDouble()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Uses the provided [client] if available, or creates a new one that gets
  /// closed immediately after use.
  Future<T> _withClient<T>(Future<T> Function(http.Client) fn) async {
    var client = this.client ?? http.Client();
    try {
      return await fn(client);
    } finally {
      if (client == null) {
        client.close();
      }
    }
  }
}

@immutable
class Rate {
  final Currency from;
  final Currency to;
  final double rate;

  Rate(this.from, this.to, this.rate);
}

@immutable
class Currency {
  /// Is guaranteed to be uppercase.
  /// E.g.: `EUR`
  final String code;

  factory Currency(String code) => Currency._(code.toUpperCase());

  const Currency._(this.code);

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}
