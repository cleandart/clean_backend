// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library hop_runner;

import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';
import 'package:hop_unittest/hop_unittest.dart';
import 'package:hop_docgen/hop_docgen.dart';

import '../test/test_all.dart' as test_all;

void main (List<String> args) {

  addTask('docs', createDocGenTask('../lib'));
  addTask('analyze', createAnalyzerTask(['/lib/clean_backend.dart']));
  addTask('test', createUnitTestTask(test_all.run));

  runHop(args);
}