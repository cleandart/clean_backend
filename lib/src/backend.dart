// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_backend;

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
        ..serve(new UrlPattern(r'/resources')).listen(_serveResources) // why only on resources and not everything?
        ..defaultStream.listen(fileHandler.handleRequest); // and maybe we can set this as deafault to requestHandler?
    });
  }

  void _serveResources(request) {
    HttpBodyHandler.processRequest(request).then((HttpBody body) {
      List requests = JSON.decode(body.body); // requests are request_list from  performHttpRequest function in clean_ajax, server.dart

      _splitAndProcessRequests(requests).then((response) {
        request.response
          ..headers.add("Access-Control-Allow-Origin", "*") // I do not know why this is needed
            ..headers.contentType = ContentType.parse("application/json")
            ..write(JSON.encode(response))
              ..close();
      }).catchError((e){
        request.response
          ..headers.add("Access-Control-Allow-Origin", "*") // I do not know why this is needed
            ..headers.contentType = ContentType.parse("application/json")
            ..statusCode = HttpStatus.BAD_REQUEST
              ..close();
      });
    });
  }

  Future<List> _splitAndProcessRequests(List requests) {
    Completer c = new Completer();

    final List responses = new List();
    //processingFunc will be function for processing one request
    var processingFunc = (req) => requestHandler.handleRequest(req["request"].name, req["request"]);

    //now you need to call on each element of requests function processingFunc
    //this calls are asynchronous but must run in seqencial order
    //results from calls are collected inside response
    //if you encounter error durig execution of any fuction run you end
    // execution all of next functions and complete returned future with error
    Future.forEach(
      requests,
      (oneRequest) => processingFunc(oneRequest).then((oneResponse){responses.add(oneResponse); print("RESPONSE: ${oneResponse}");})
    ).then((_)=>c.complete(responses))
     .catchError((e)=> c.completeError(e));

    return c.future;
  }
}