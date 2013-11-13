// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_backend;

import 'dart:io';
import 'dart:async';
import 'package:route/server.dart';
import 'package:static_file_handler/static_file_handler.dart';

import 'package:clean_ajax/server.dart';

class Backend {
  StaticFileHandler fileHandler;
  HttpServer server;
  String host;
  int port;
  RequestHandler requestHandler;

  Backend(StaticFileHandler this.fileHandler,RequestHandler this.requestHandler, {String host: "0.0.0.0", int port: 8080}) {
    this.host = host;
    this.port = port;
  }

  void listen() {
    print("Starting HTTP server");

    HttpServer.bind(host, port).then((HttpServer server) {
      this.server = server;
      var router = new Router(server);

      print("Listening on ${server.address.address}:${server.port}");

      router
        ..serve(new UrlPattern(r'/resources')).listen(requestHandler.serveHttpRequest) // why only on resources and not everything?
        ..defaultStream.listen(fileHandler.handleRequest); // and maybe we can set this as deafault to requestHandler?
    });
  }

}
