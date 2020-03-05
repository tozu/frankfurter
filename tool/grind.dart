import 'dart:io' hide ProcessException;

import 'package:grind_publish/grind_publish.dart' as grind_publish;
import 'package:grinder/grinder.dart';

@Task('Runs dartanalyzer and fails if there is a hint, warning or lint error')
void analyze() => runAsync('dartanalyzer',
    arguments: ['.', '--fatal-hints', '--fatal-warnings', '--fatal-lints']);

@Task()
void checkFormat() {
  if (DartFmt.dryRun('.')) {
    fail('Code is not properly formatted. Run `grind format`');
  }
}

@Task()
void format() => DartFmt.format('.');

@Task()
void testUnit() => TestRunner().testAsync(files: Directory('test'));

@Task()
@Depends(checkFormat, analyze, testUnit)
void test() => true;

@Task('Automatically publishes this package if the pubspec version increases')
void autoPublish() async {
  final credentials = grind_publish.Credentials.fromEnvironment();
  await grind_publish.autoPublish('fankfurter', credentials);
}

/// Setup grinder and logging.
void main(List<String> args) {
  grind(args);
}
