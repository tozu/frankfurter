import 'dart:io' hide ProcessException;

import 'package:grinder/grinder.dart';

@Task('Runs dartanalyzer and fails if there is a hint, warning or lint error')
void analyze() => runAsync('dart',
    arguments: ['analyze', '--fatal-infos', '--fatal-warnings', '.']);

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

/// Setup grinder and logging.
void main(List<String> args) {
  grind(args);
}
