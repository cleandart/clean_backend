// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:clean_backend/clean_backend.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';

class SimpleRequestHandler {
  Backend backend;
  SimpleRequestHandler(this.backend);
  void handleHttpRequest(Request request) {
    print('incoming HttpRequest:$request');
    request.response
      ..headers.contentType = ContentType.parse("text/html")
      ..write('<body>Response to request.</body>')
      ..close();
  }

  void handleAuthenticateRequest(Request request) {
    print('incoming AuthenticateRequest:$request');
    backend.authenticate(request.response, 'jozko');
    var cookies = request.response.headers[HttpHeaders.SET_COOKIE];
    request.response
      ..headers.contentType = ContentType.parse("text/html")
      ..write('<body>Response to authenticate request. set-cookie: $cookies</body>')
      ..close();
  }

  void handleIsAuthenticatedRequest(Request request) {
    print('incoming IsAuthenticatedRequest:$request');
    String userId = backend.getAuthenticatedUser(request.headers);
    var cookies = request.headers[HttpHeaders.SET_COOKIE];
    var cookies2 = request.headers[HttpHeaders.COOKIE];
    request.response
      ..headers.contentType = ContentType.parse("text/html")
      ..write('<body>Response to authenticate request. authenticated: $userId, $cookies, $cookies2</body>')
      ..close();
  }
}

void main() {
  Backend backend = new Backend([], new SHA256());
  SimpleRequestHandler requestHandler = new SimpleRequestHandler(backend);


//  backend.listen().then((_) {
    backend.addDefaultHttpHeader('Access-Control-Allow-Origin','*');
    backend.addView(r'/resources', requestHandler.handleHttpRequest);
    backend.addView(r'/add-cookie', requestHandler.handleAuthenticateRequest);
    backend.addView(r'/get-cookie', requestHandler.handleIsAuthenticatedRequest);
    backend.addStaticView(new RegExp(r'/.*'), '.');
//  });

}
