// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:clean_backend/clean_backend.dart';
import 'dart:io';

class SimpleRequestHandler {
  void handleHttpRequest(HttpRequest httpRequest) {
    print('incoming HttpRequest:$httpRequest');
    httpRequest.response
      ..headers.contentType = ContentType.parse("text/html")
      ..write('<body>Response to request.</body>')
      ..close();
  }
}

void main() {
  Backend backend = new Backend();
  SimpleRequestHandler requestHandler = new SimpleRequestHandler();


  backend.listen().then((_) {
    backend.addDefaultHttpHeader('Access-Control-Allow-Origin','*');
    backend.addView(r'/resources', requestHandler.handleHttpRequest);
    backend.addStaticView(new RegExp(r'/.*'), '.');
  });
}
