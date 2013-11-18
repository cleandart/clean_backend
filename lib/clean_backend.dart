// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_backend;

import 'dart:io';
import 'dart:async';
import 'package:route/server.dart';
import 'package:static_file_handler/static_file_handler.dart';
import 'package:http_server/http_server.dart';

typedef void RequestHandler(Request request);

class Request {
  final String type;
  final dynamic body;
  final HttpResponse response;
  final HttpHeaders headers;
  final HttpRequest httpRequest;
  final Map<String, dynamic> meta = {};

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

  Stream<Request> onPrepareRequest;

  Backend({String host: "0.0.0.0", int port: 8080}) {
    this.host = host;
    this.port = port;
  }

  void addDefaultHttpHeader(name, value) {
    _defaulHttpHeaders.add({'name': name, 'value': value});
  }

  void addView(Pattern url,RequestHandler handler) {
    router.serve(url).listen((HttpRequest httpRequest) {
      if (_defaulHttpHeaders != null) {
        _defaulHttpHeaders.forEach((header) => httpRequest.response.headers.add(header['name'],header['value']));
      }
      HttpBodyHandler.processRequest(httpRequest).then((HttpBody body) {
        Request request = new Request(body.type, body.body, httpRequest.response, httpRequest.headers, httpRequest);
        return handler(request);
      });
    });
  }

  void addStaticView(Pattern url, String path) {
    StaticFileHandler fileHandler = new StaticFileHandler.serveFolder(path);
    router.serve(url).listen(fileHandler.handleRequest);
  }

  void addNotFoundView(RequestHandler handler) {
    router.defaultStream.listen((HttpRequest httpRequest) {
      HttpBodyHandler.processRequest(httpRequest).then((HttpBody body) {
        Request request = new Request(body.type, body.body, httpRequest.response, httpRequest.headers, httpRequest);
        return handler(request);
      });
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
}
