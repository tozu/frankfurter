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

    setUp(() {
      client = MockClient();
      frank = Frankfurter(client: client);
    });

    test('.latest() makes a request to the right address', () async {
      when(client.get(any)).thenAnswer(
          (req) => Future.value(http.Response(data.fromEur, HttpStatus.ok)));
      await frank.latest(from: Currency('EUR'));
      verify(client.get(Uri.parse('${defaultUrl}latest?from=EUR'))).called(1);

      await frank.latest(
        from: Currency('EUR'),
        to: {Currency('GBP'), Currency('USD')},
      );
      verify(client.get(Uri.parse('${defaultUrl}latest?from=EUR&to=GBP%2CUSD')))
          .called(1);
    });
  });
}
