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
  HttpServer server;
  String host;
  int port;
  Router router;
  List _defaulHttpHeaders = new List();
  Hash _hashMethod;
  List<int> _key;

  final StreamController<Request> _onPrepareRequestController =
      new StreamController.broadcast();

  Stream<Request> get onPrepareRequest => _onPrepareRequestController.stream;

  Backend({String this.host: "0.0.0.0", int this.port: 8080, key: null, hashMethod: null}) {
//    this.host = host;
//    this.port = port;
    this._key = key;
    this._hashMethod = hashMethod;
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

  Future listen() {
    print("Starting HTTP server");
    return HttpServer.bind(host, port).then((HttpServer server) {
      this.server = server;
      router = new Router(server);
      print("Listening on ${server.address.address}:${server.port}");
    });
  }

  void authenticate(HttpResponse response, String userId, {HMAC hmac: null}){
    if (hmac == null) hmac = new HMAC(_hashMethod, _key);
    Utf8Codec codec = new Utf8Codec();
    List<int> encodedUserId = codec.encode(userId);
    hmac.add(encodedUserId);
    List<int> encodedUserIdSignature = hmac.close();
    String userIdSignature = codec.decode(encodedUserIdSignature);
    Cookie cookie = new Cookie('authentication', JSON.encode({'userID': userId, 'signature': userIdSignature}));
    response.headers.add(HttpHeaders.SET_COOKIE, cookie);
  }

  bool isAuthenticated(HttpHeaders headers){
    if (headers[HttpHeaders.COOKIE] == null) return false;
    headers[HttpHeaders.COOKIE].forEach((String cookieString){


    });

  }

}
