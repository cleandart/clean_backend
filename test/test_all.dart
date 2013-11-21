// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_all;

import "cookie_test.dart" as cookie_test;
import "static_file_handler_test.dart" as static_file_handler_test;
import "backend_test.dart" as backend_test;

void main() {
  cookie_test.main();
  static_file_handler_test.main();
  backend_test.main();
}