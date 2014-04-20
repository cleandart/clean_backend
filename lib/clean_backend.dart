// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_backend;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http_server/http_server.dart';
import 'package:clean_router/server.dart';
import 'package:path/path.dart' as p;

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
  final Map match;

  final Map<String, dynamic> meta = {};
  String authenticatedUserId;

  Request(
      this.type,
      this.body,
      this.response,
      this.headers,
      this.httpRequest,
      this.match
  );

  String toString(){
    return JSON.encode({
      'url' : httpRequest.uri.path,
      'type' : type.toString(),
      'body' : body.toString(),
      'response' : response.toString(),
      'headers' : headers.toString(),
      'httpRequest' : httpRequest.toString(),
      'match' : match.toString(),
    });
  }
}

/**
 * Convert any JSON encodable [value] to cookie-safe string value as specified
 * by RFC 6265.
 */
String toCookieString(value) =>
    CryptoUtils.bytesToBase64(UTF8.encode(JSON.encode(value)), urlSafe: true);

/**
 * Parse string value encoded by [toCookieString] method and return originaly
 * encoded object.
 */
dynamic parseCookieString(String str) =>
    JSON.decode(UTF8.decode(CryptoUtils.base64StringToBytes(str)));

class Backend {
  static final String COOKIE_PATH = "/";
  static final bool COOKIE_HTTP_ONLY = true;

  /**
   * Register routes which are matched with request.uri .
   */
  final Router router;

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
   * HttpBodyHandler.processRequest
   */
  final _httpBodyExtractor;

  /**
   * Default handler for NotFoundView.
   */
  RequestHandler _notFoundViewHandler = (Request request) {
    request.response
      ..statusCode = HttpStatus.NOT_FOUND
      ..close();
  };

  /**
   * Constructor.
   */
  Backend.config(this._server, this.router, this._requestNavigator,
    this._hmacFactory, this._httpBodyExtractor) {
    // Add default handler for not found views. Before not found view response
    // is sent, check if URI ends with a slash and if not, try to add it.
    _requestNavigator.registerDefaultHandler((httpRequest, urlParams)
      => prepareRequestHandler(httpRequest, urlParams, (Request request) {
        var uri = request.httpRequest.uri;
        if (!uri.path.endsWith('/')) {
          //we set request.httpRequest.response because of consistency
          //  as (request.response := request.httpRequest.response)
          request.httpRequest.response.redirect(new Uri(
              scheme: uri.scheme,
              host: uri.host,
              port: uri.port,
              path: uri.path + '/',
              query: uri.query
          ));
        }
        else{
          _notFoundViewHandler(request);
        }
      }));
  }

  /**
   * Creates a new backend.
   */
  static Future<Backend> bind( String host, int port, String key, {Hash hashMethod: null, String presentedHost: null}){
    if (presentedHost == null) presentedHost = '$host:$port';
    if (hashMethod == null) hashMethod = new SHA256();

    return HttpServer.bind(host, port).then((httpServer) {
      var router = new Router("http://$presentedHost", {});
      var requestNavigator = new RequestNavigator(httpServer.asBroadcastStream(), router);
      return new Backend.config(httpServer, router, requestNavigator,
          () => new HMAC(hashMethod, UTF8.encode(key)), HttpBodyHandler.processRequest);
    });
  }

  /**
   * Adds header which will be attached to each response. Could be overwritten.
   */
  void addDefaultHttpHeader(name, value) {
    _defaulHttpHeaders.add({'name': name, 'value': value});
  }

  /**
   * Transforms [httpRequest] with [urlParams] and creates [Request] which is
   * passed asynchronously to [handler].
   */
  Future prepareRequestHandler(HttpRequest httpRequest, Map urlParams,
    RequestHandler handler) {
    return _httpBodyExtractor(httpRequest).then((HttpBody body) {

      if (_defaulHttpHeaders != null) {
        _defaulHttpHeaders.forEach((header) =>
            httpRequest.response.headers.add(header['name'], header['value']));
      }

      Request request = new Request(body.type, body.body, httpRequest.response,
          httpRequest.headers, httpRequest, urlParams);
      request.authenticatedUserId = getAuthenticatedUser(request.httpRequest.cookies);

      handler(request);
      return true;
    });
  }

  /**
   * Adds [route] for a particular [route] so handler could be attached to [routeName]s.
   */
  void addRoute(String routeName, Route route){
    router.addRoute(routeName, route);
  }

  /**
   * Adds [handler] for a particular [routeName].
   */
  void addView(String routeName, RequestHandler handler) {
    _requestNavigator.registerHandler(routeName, (httpRequest, urlParams)
        => prepareRequestHandler(httpRequest, urlParams, handler));
  }

  /**
   * Corresponding [Route] for [routeName] should be in the prefix format,
   * i.e. "/uploads/*", as backend will look for files documentRoot/matchedSufix
   */*/
  void addStaticView(String routeName, String documentRoot) {
    var vd = new VirtualDirectory(documentRoot);
    _requestNavigator.registerHandler(routeName, (httpRequest, urlParams) {
      var relativePath = urlParams['_tail'];
      if (relativePath.split('/').contains('..')) {
        httpRequest.response.statusCode = HttpStatus.NOT_FOUND;
        httpRequest.response.close();
        return;
      }
      String path = p.join(documentRoot, relativePath);
      FileSystemEntity.type(path).then((type) {
        switch (type) {
          case FileSystemEntityType.FILE:
            // If file, serve as such.
            vd.serveFile(new File(path), httpRequest);
            break;
          case FileSystemEntityType.DIRECTORY:
            // File not found, fall back to 404.
            httpRequest.response.statusCode = HttpStatus.NOT_FOUND;
            httpRequest.response.close();
            break;
          default:
            // File not found, fall back to 404.
            httpRequest.response.statusCode = HttpStatus.NOT_FOUND;
            httpRequest.response.close();
            break;
         }
      });
    });
  }

  /**
   * If nothing is matched. There is a default [_notFoundViewHandler], but it
   * can be overwritten by this method.
   */
  void addNotFoundView(RequestHandler handler) {
    _notFoundViewHandler = handler;
  }

  String sign(String msg) {
    HMAC hmac = _hmacFactory();
    _stringToHash(msg, hmac);
    return CryptoUtils.bytesToBase64(hmac.close(), urlSafe: true);
  }

  bool verifySignature(String msg, String signature) {
    HMAC hmac = _hmacFactory();
    _stringToHash(msg, hmac);
    return hmac.verify(CryptoUtils.base64StringToBytes(signature));
  }

  void _stringToHash(String value, HMAC hmac) {
    Utf8Codec codec = new Utf8Codec();
    List<int> encodedUserId = codec.encode(value);
    hmac.add(encodedUserId);
  }

  _parseAuthenticationValue(String value) {
    var auth = parseCookieString(value);

    // No user signed
    if (auth == null) return null;

    var userId = auth['userID'];
    var signature = auth['signature'];

    if (userId is! String || signature is! String) {
      throw new FormatException('Invalid authentication cookie: $auth');
    }

    if (!verifySignature(userId, signature)) {
      throw new FormatException('Signature $signature does not match $userId');
    }

    return userId;
  }

  _toAuthenticationValue(String userId) {
    if (userId == null) return toCookieString(null);
    else return toCookieString({'userID': userId, 'signature': sign(userId)});
  }

  void authenticate(Request request, String userId) {
    Cookie cookie = new Cookie('authentication', _toAuthenticationValue(userId));
    cookie.expires = new DateTime.now().add(new Duration(days: 365));
    cookie.path = COOKIE_PATH;
    cookie.httpOnly = COOKIE_HTTP_ONLY;
    request.response.headers.add(HttpHeaders.SET_COOKIE, cookie);
    request.authenticatedUserId = userId;
  }

  String getAuthenticatedUser(List<Cookie> cookies) {
    for (Cookie cookie in cookies) {
      if (cookie.name == 'authentication') {
        try {
          return _parseAuthenticationValue(cookie.value);
        } on FormatException {
          return null;
        }
      }
    }
    return null;
  }

  void logout(Request request) {
    Cookie cookie = new Cookie('authentication', _toAuthenticationValue(null));
    cookie.expires = new DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    cookie.path = COOKIE_PATH;
    cookie.httpOnly = COOKIE_HTTP_ONLY;
    request.response.headers.add(HttpHeaders.SET_COOKIE, cookie);
  }
}
