// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_backend;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:route/server.dart';
import 'package:static_file_handler/static_file_handler.dart';
import 'package:http_server/http_server.dart';
import 'package:crypto/crypto.dart';

typedef void RequestHandler(Request request);

class Request {
  final String type;
  final dynamic body;
  final HttpResponse response;
  final HttpHeaders headers;
  final HttpRequest httpRequest;
  final Map<String, dynamic> meta = {};
  String authenticatedUserId;

  Request(
      this.type,
      this.body,
      this.response,
      this.headers,
      this.httpRequest
      );

}

class Backend {
  final HttpServer server;
  final Router router;
  List _defaulHttpHeaders = new List();
  final _hmacFactory;

  final StreamController<Request> _onPrepareRequestController =
      new StreamController.broadcast();

  Stream<Request> get onPrepareRequest => _onPrepareRequestController.stream;

  Backend.config(this.server, this.router, this._hmacFactory);


  static Future<Backend> bind(key, hashMethod, {String host: "0.0.0.0", int port: 8080}){
    return HttpServer.bind(host, port).then((httpServer) {
      var router = new Router(httpServer);
      return new Backend.config(httpServer, router, () => new HMAC(hashMethod, key));});
  }

  void addDefaultHttpHeader(name, value) {
    _defaulHttpHeaders.add({'name': name, 'value': value});
  }

  void _prepareRequestHandler(HttpRequest httpRequest, RequestHandler handler) {
    HttpBodyHandler.processRequest(httpRequest).then((HttpBody body) {
      Request request = new Request(body.type, body.body, httpRequest.response, httpRequest.headers, httpRequest);
      _onPrepareRequestController.add(request);
      handler(request);
    });
  }

  void addView(Pattern url,RequestHandler handler) {
    router.serve(url).listen((HttpRequest httpRequest) {
      if (_defaulHttpHeaders != null) {
        _defaulHttpHeaders.forEach((header) => httpRequest.response.headers.add(header['name'],header['value']));
      }
      _prepareRequestHandler(httpRequest, handler);
    });
  }



  void addStaticView(Pattern url, String path) {
    StaticFileHandler fileHandler = new StaticFileHandler.serveFolder(path);
    router.serve(url).listen(fileHandler.handleRequest);
  }

  void addNotFoundView(RequestHandler handler) {
    router.defaultStream.listen((HttpRequest httpRequest) {
      _prepareRequestHandler(httpRequest, handler);
    });
  }

  void _stringToHash(String value, HMAC hmac){

    Utf8Codec codec = new Utf8Codec();
    List<int> encodedUserId = codec.encode(value);
    hmac.add(encodedUserId);
  }

  void authenticate(HttpResponse response, String userId){
    HMAC hmac = _hmacFactory();
    _stringToHash(userId, hmac);
    List<int> userIdSignature = hmac.close();
    Cookie cookie = new Cookie('authentication', JSON.encode({'userID': userId, 'signature': userIdSignature}));
    response.headers.add(HttpHeaders.SET_COOKIE, cookie);
  }

  String getAuthenticatedUser(HttpHeaders headers){
    if (headers[HttpHeaders.COOKIE] == null) return null;

    for (String cookieString in headers[HttpHeaders.COOKIE]) {
      Cookie cookie = new Cookie.fromSetCookieValue(cookieString);
      cookie.maxAge = 365 * 24 * 60 * 60;
      cookie.path = '/';
      cookie.httpOnly = true;
      if (cookie.name == 'authentication') {
        HMAC hmac = _hmacFactory();
        Map authentication = JSON.decode(cookie.value);
        _stringToHash(authentication['userID'], hmac);
        if (hmac.verify(authentication['signature'])){
          return authentication['userID'];
        }
      }
    }
    return null;

  }

  void logout(Request request){
    if (request.headers[HttpHeaders.COOKIE] == null) return;
    for (String cookieString in request.headers[HttpHeaders.COOKIE]) {

      Cookie cookie = new Cookie.fromSetCookieValue(cookieString);
      if (cookie.name == 'authentication') {
        cookie.maxAge = 0;
        request.response.headers.add(HttpHeaders.SET_COOKIE, cookie);
      }
    }
  }

}
