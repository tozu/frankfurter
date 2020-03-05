import 'package:frankfurter/frankfurter.dart';

void main() async {
  final frankfurter = Frankfurter();
  final latest = await frankfurter.latest(from: Currency('EUR'));

  latest.forEach((rate) => print('1 ${rate.from} = ${rate.rate} ${rate.to}'));
}
