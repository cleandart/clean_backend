// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_backend;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http_server/http_server.dart';
import 'package:clean_backend/static_file_handler.dart';
import 'package:clean_router/server.dart';

typedef void RequestHandler(Request request);

class Request {
  final String type;
  final dynamic body;
  final HttpResponse response;
  final HttpHeaders headers;
  final HttpRequest httpRequest;

  /**
   * Params returned from parsing of the path, i.e. /path/{param}/
   */
  final Map urlParams;

  final Map<String, dynamic> meta = {};
  String authenticatedUserId;

  Request(
      this.type,
      this.body,
      this.response,
      this.headers,
      this.httpRequest,
      this.urlParams
      );
}

class Backend {
  /**
   * Register routes which are matched with request.uri .
   */
  final Router _router;

  /**
   * Calls handlers associated with a particular routeName.
   */
  final RequestNavigator _requestNavigator;

  /**
   * Handles the incoming stream of [HttpRequest]s
   */
  final HttpServer _server;

  List _defaulHttpHeaders = new List();

  /**
   * For cookies.
   */
  final _hmacFactory;

  /**
   * Constructor.
   */
  Backend.config(this._server, this._router, this._requestNavigator, this._hmacFactory);

  /**
   * Creates a new backend.
   */
  factory Backend(List<int> key, Hash hashMethod, {String host: "0.0.0.0", int port: 8080}) {
    var server = HttpServer.bind(host, port);
    var router = new Router(host, {});
    var requestNavigator = new RequestNavigator(server.asStream(), router);
    return new Backend.config(server, router, requestNavigator, () => new HMAC(hashMethod, key));
  }

  /**
   * Adds header which will be attached to each response. Could be overwritten.
   */
  void addDefaultHttpHeader(name, value) {
    _defaulHttpHeaders.add({'name': name, 'value': value});
  }

  /**
   * C
   */
  void _prepareRequestHandler(HttpRequest httpRequest, Map urlParams, RequestHandler handler) {
    HttpBodyHandler.processRequest(httpRequest).then((HttpBody body) {
      if (_defaulHttpHeaders != null) {
        _defaulHttpHeaders.forEach((header) => httpRequest.response.headers.add(header['name'],header['value']));
      }

      Request request = new Request(body.type, body.body, httpRequest.response,
          httpRequest.headers, httpRequest, urlParams);

      handler(request);
    });
  }

  /**
   * Adds [route] for a particular [route] so handler could be attached to [routeName]s.
   */
  void addRoute(String routeName, Route route){
    _router.registerRoute(routeName, route);
  }

  /**
   * Adds [handler] for a particular [routeName].
   */
  void addView(String routeName, RequestHandler handler) {
    _requestNavigator.registerHandler(routeName, (httpRequest, urlParams)
        => _prepareRequestHandler(httpRequest, urlParams, handler));
  }

  /**
   * Corresponding [Route] for [routeName] should be in the prefix format,
   * i.e. "/uploads/*", as backend will look for files documentRoot/matchedSufix
   */*/
  void addStaticView(String routeName, String documentRoot) {
    StaticFileHandler fileHandler = new StaticFileHandler(documentRoot);
    _requestNavigator.registerHandler(routeName, (httpRequest, urlParams)
        => fileHandler.handleRequest(httpRequest, urlParams["_tail"]));
  }

  /**
   * If nothing is matched.
   */
  void addNotFoundView(RequestHandler handler) {
    _requestNavigator.registerDefaultHandler((httpRequest, urlParams)
        => _prepareRequestHandler(httpRequest, urlParams, handler));
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
}
