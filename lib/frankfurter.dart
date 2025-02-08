import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;

const defaultUrl = 'https://api.frankfurter.dev/v1/';

class Frankfurter {
  /// Defaults to [defaultUrl]
  final Uri url;
  final http.Client? client;
  final Duration cacheDuration;

  final _cache = <_Cache>{};

  Frankfurter({Uri? url, Duration? cacheDuration, this.client})
      : url = url ?? Uri.parse(defaultUrl),
        cacheDuration = cacheDuration ?? Duration(hours: 12);

  /// Returns a list of the latest rates.
  Future<List<Rate>> latest({required Currency from, Set<Currency>? to}) async {
    Currency;

    final url = this.url.replace(path: this.url.path + 'latest', queryParameters: {
      'from': from.code,
      if (to != null) 'to': to.map((currency) => currency.code).join(','),
    });
    try {
      final response = await _withClient((client) => client.get(url));
      final decoded = jsonDecode(response.body);
      final ratesMap = (decoded['rates'] as Map).cast<String, num>();
      final rates = ratesMap.keys
          .map<Rate>(
              (code) => Rate(from, Currency(code), ratesMap[code]!.toDouble()))
          .toList();

      _cache.addAll(rates.map((rate) => _Cache(rate)));

      return rates;
    } catch (e) {
      rethrow;
    }
  }

  /// Uses caching to avoid fetching the rate every time.
  ///
  /// To set the cache duration see [cacheDuration].
  Future<Rate> getRate({required Currency from, required Currency to}) async {
    // Create a fake rate so we get a [_Cache] object with the right id.
    final fakeCache = _Cache(Rate(from, to, 1.0));
    var cache = _cache.lookup(fakeCache);

    if (cache != null &&
        cache.created.add(cacheDuration).isBefore(DateTime.now())) {
      _cache.remove(cache);
      cache = null;
    }
    if (cache == null) {
      final latest = await this.latest(from: from);
      _cache.addAll(latest.map((rate) => _Cache(rate)));
      cache = _cache.lookup(fakeCache);
    }
    return cache!.rate;
  }

  /// Uses the provided [client] if available, or creates a new one that gets
  /// closed immediately after use.
  Future<T> _withClient<T>(Future<T> Function(http.Client) fn) async {
    var client = this.client ?? http.Client();
    try {
      return await fn(client);
    } finally {
      if (this.client == null) {
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

  @override
  String toString() => '1 $from = $rate $to';
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

/// A simple class to serve as cache. It's identity function has been
/// overwritten so two objects that share the same "from" and "to" currency
/// (even though the rates and created date might differ) appear identical.
///
/// This allows for the cache [Set] where they are stored to rapidly lookup
/// the value and disallow multiple entities of the same set.
class _Cache {
  final created = DateTime.now();
  final Rate rate;

  String get id => '${rate.from}->${rate.to}';

  _Cache(this.rate);

  @override
  bool operator ==(Object other) => other is _Cache && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Cache $id';
}
