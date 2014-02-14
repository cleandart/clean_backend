// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_backend.test_all;

import "cookie_test.dart" as cookie_test;
import "backend_test.dart" as backend_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';


main() {
  run(new VMConfiguration());
}


void run(configuration) {
  unittestConfiguration = configuration;
  cookie_test.main();
  backend_test.main();
}