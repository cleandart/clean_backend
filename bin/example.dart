// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:clean_backend/clean_backend.dart';
import 'package:clean_router/common.dart';

//TODO test example -> move them to tests
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

  void handleLogoutRequest(Request request) {
    print('incoming IsAuthenticatedRequest:$request');
    backend.logout(request);
    var cookies = request.headers[HttpHeaders.SET_COOKIE];
    var cookies2 = request.headers[HttpHeaders.COOKIE];
    request.response
      ..headers.contentType = ContentType.parse("text/html")
      ..write('<body>Response to logout request. cookies: $cookies, $cookies2 </body>')
      ..close();
  }
}

void main() {
  Backend.bind([], new SHA256()).then((backend) {
    SimpleRequestHandler requestHandler = new SimpleRequestHandler(backend);

    //The order matters here
    backend.addRoute("resources", new Route('/resources/'));
    backend.addRoute("add_cookie", new Route("/add-cookie/"));
    backend.addRoute("get_cookie", new Route("/get-cookie/"));
    backend.addRoute("static", new Route("/*"));

    //The order doesn't matter here
    backend.addDefaultHttpHeader('Access-Control-Allow-Origin','*');
    backend.addView('resources', requestHandler.handleHttpRequest);
    backend.addView('add_cookie', requestHandler.handleAuthenticateRequest);
    backend.addView('get_cookie', requestHandler.handleIsAuthenticatedRequest);
    backend.addStaticView('static', './');
  });
}










