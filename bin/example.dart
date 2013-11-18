// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:clean_backend/clean_backend.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';

class SimpleRequestHandler {
  void handleHttpRequest(Request request) {
    print('incoming HttpRequest:$request');
    request.response
      ..headers.contentType = ContentType.parse("text/html")
      ..write('<body>Response to request.</body>')
      ..close();
  }
}

void main() {
  Backend backend = new Backend(hashMethod: new SHA256(), key: [1,1,1]);
  SimpleRequestHandler requestHandler = new SimpleRequestHandler();


  backend.listen().then((_) {
    backend.addDefaultHttpHeader('Access-Control-Allow-Origin','*');
    backend.addView(r'/resources', requestHandler.handleHttpRequest);
    backend.addView(r'/add-cookie', (request) => backend.authenticate(request.response, 'jozko12'));
    backend.addStaticView(new RegExp(r'/.*'), '.');
  });

}
