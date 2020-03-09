import 'package:frankfurter/frankfurter.dart';

void main() async {
  final frankfurter = Frankfurter();

  final latest = await frankfurter.latest(from: Currency('EUR'));
  latest.forEach(print);

  final rate = await frankfurter.getRate(
    from: Currency('EUR'),
    to: Currency('GBP'),
  );
  print('Single conversion: $rate');
}
