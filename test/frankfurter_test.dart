import 'dart:convert';
import 'dart:io';

import 'package:frankfurter/frankfurter.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

import 'example_data.dart' as data;

class MockClient extends Mock implements http.Client {}

void main() {
  group('Frankurter', () {
    Frankfurter frank;
    http.Client client;

    final eur = Currency('EUR');
    final usd = Currency('USD');
    final gbp = Currency('GBP');

    final _map = jsonDecode(data.fromEur);
    _map['rates'].keys.forEach((key) => _map['rates'][key] = 9.9);
    final modifiedRates = jsonEncode(_map);

    setUp(() {
      client = MockClient();
      frank = Frankfurter(client: client);
    });

    void _setupClientAnswer([String jsonData = data.fromEur]) {
      when(client.get(any)).thenAnswer(
          (req) => Future.value(http.Response(jsonData, HttpStatus.ok)));
    }

    test('.latest() makes a request to the right URL', () async {
      _setupClientAnswer();
      await frank.latest(from: eur);
      verify(client.get(Uri.parse('${defaultUrl}latest?from=EUR'))).called(1);

      await frank.latest(
        from: eur,
        to: {gbp, usd},
      );
      verify(client.get(Uri.parse('${defaultUrl}latest?from=EUR&to=GBP%2CUSD')))
          .called(1);
    });
    group('.getRate()', () {
      test('gets the rate from the `latest()` response', () async {
        _setupClientAnswer();
        final cacheDuration = Duration(milliseconds: 50);
        var frank = Frankfurter(client: client, cacheDuration: cacheDuration);
        var rate = await frank.getRate(eur, usd);
        expect(rate.rate, 1.1122);
        verify(client.get(any)).called(1);
      });
      test('uses cache for subsequent calls', () async {
        _setupClientAnswer();
        final cacheDuration = Duration(milliseconds: 50);
        var frank = Frankfurter(client: client, cacheDuration: cacheDuration);
        var rate = await frank.getRate(eur, usd);
        expect(rate.rate, 1.1122);
        verify(client.get(any)).called(1);

        _setupClientAnswer(modifiedRates);

        rate = await frank.getRate(eur, usd);
        rate = await frank.getRate(eur, usd);
        rate = await frank.getRate(eur, usd);
        expect(rate.rate, 1.1122);

        /// Not being called again.
        verifyNever(client.get(any));

        await Future.delayed(cacheDuration);

        rate = await frank.getRate(eur, usd);
        expect(rate.rate, 9.9);

        /// Not being called again.
        verify(client.get(any)).called(1);
      });
      test('uses the same recent() result for different currencies', () async {
        _setupClientAnswer();
        final cacheDuration = Duration(milliseconds: 50);
        var frank = Frankfurter(client: client, cacheDuration: cacheDuration);
        expect((await frank.getRate(eur, usd)).rate, 1.1122);
        expect((await frank.getRate(eur, gbp)).rate, 0.87113);
        expect((await frank.getRate(eur, Currency('JPY'))).rate, 119.82);
        expect((await frank.getRate(eur, Currency('SEK'))).rate, 10.6063);
        verify(client.get(any)).called(1);
      });
    });
  });
}
