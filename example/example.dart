// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'package:clean_backend/clean_backend.dart';
import 'package:clean_router/common.dart';
import 'package:clean_logging/logger.dart';


Logger logger = new Logger('example');

//TODO test example -> move them to tests
class SimpleRequestHandler {
  Backend backend;
  SimpleRequestHandler(this.backend);
  void handleHttpRequest(Request request) {
    request.response
      ..headers.contentType = ContentType.parse("text/html")
      ..write('<body>Response to request.</body>')
      ..close();
  }

  void handleAuthenticateRequest(Request request) {
    print('incoming AuthenticateRequest:$request');
    backend.authenticate(request, 'jozko');
    var cookies = request.response.headers[HttpHeaders.SET_COOKIE];
    request.response
      ..headers.contentType = ContentType.parse("text/html")
      ..write('<body>Response to authenticate request. set-cookie: $cookies</body>')
      ..close();
  }

  void handleIsAuthenticatedRequest(Request request) {
    print('incoming IsAuthenticatedRequest:$request');
    String userId = backend.getAuthenticatedUser(request.httpRequest.cookies);
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

  void failHandler(Request request){
//    Zone.current[#requestBody]['body'] = 'body of failed request';
    new Future.delayed(new Duration(milliseconds: 100))
       .then((_) => throw new Exception('this will show them!'));
  }

  void handleDefault(Request request) {
    print('incoming default:$request');
    logger.warning('warning');

    request.response
      ..headers.contentType = ContentType.parse("text/html")
      ..write('<body>This is garbage. You should look for something clean.</body>')
      ..close();
  }
}

void main() {

   Logger.ROOT.logLevel = Level.WARNING;

   // these two lines enable logging for each request
   (new Logger('clean_backend.requests')).logLevel = Level.INFO;

   // this line enables mapping requestId's to metaData...
   Logger.getMetaData = () => Zone.current[#requestInfo] == null ?
       {} : {'requestId': Zone.current[#requestInfo]['id']};

   Logger.onRecord.listen((Map rec) {
     if(rec['fullSource']=='clean_backend.requests') {
       print('message: ${rec['event']}');
       print('data: ${rec['data']}');
       print('meta: ${rec['meta']}');
     } else {
       print(rec);
     }
   });

  Backend.bind('0.0.0.0', 8080, "secret").then((backend) {
    SimpleRequestHandler requestHandler = new SimpleRequestHandler(backend);

    //The order matters here
    backend.addRoute("resources", new Route('/resources/'));
    backend.addRoute("add_cookie", new Route("/add-cookie/"));
    backend.addRoute("get_cookie", new Route("/get-cookie/"));
    backend.addRoute("fail", new Route("/fail/"));
    backend.addRoute("static", new Route("/static/*"));

    //Note: browser also calls for /favicon.ico
    //The order doesn't matter here
    backend.addDefaultHttpHeader('Access-Control-Allow-Origin','*');
    backend.addView('resources', requestHandler.handleHttpRequest);
    backend.addView('add_cookie', requestHandler.handleAuthenticateRequest);
    backend.addView('get_cookie', requestHandler.handleIsAuthenticatedRequest);
    backend.addView('fail', requestHandler.failHandler);
    backend.addStaticView('static', '../test/www/');
    backend.addNotFoundView(requestHandler.handleDefault);
  });
}










