// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_backend;

class Backend {
//  Publisher publisher;  should be part of serverside sync
//  MongoProvider mongo;  should be part of serverside sync
  StaticFileHandler fileHandler;
  HttpServer server;
  String host;
  int port;
  RequestHandler requestHandler;

  Backend(StaticFileHandler this.fileHandler, this.requestHandler, {String host: "0.0.0.0", int port: 8080}) {
//    this.fileHandler = fileHandler;
//    this.mongo = mongo;
//    this.publisher = publisher;
    this.host = host;
    this.port = port;
    
//    print("MongoDB max history version: ${mongo.maxVersion}");
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
      
      _processRequests(requests.reversed.toList(), []).then((response) {
        request.response
          ..headers.add("Access-Control-Allow-Origin", "*") // I do not know why this is needed 
            ..headers.contentType = ContentType.parse("application/json")
            ..write(JSON.encode(response))
              ..close();
      });
    });
  }
  
  Future _processRequests(List requests, List response) {
    if (requests.isEmpty) {
      return new Future.value(response);
    }
    else {
      var req = requests.removeLast(); // req is {'id': int requestCount, 'request': Request request} see performHttpRequest in clean_ajax, server.dart
      
      return requestHandler.handleRequest(req["request"].name, req["request"]).then((result) {
        response.add({"id" : req["id"], "response" : result}); 
        print("RESPONSE: ${result}");
        return _processRequests(requests, response);
      });
//      return _process(req["request"]["args"]).then((result) { // we have request hadler for this
//        response.add({"id" : req["id"], "response" : result});
//        print("RESPONSE: ${result}");
//        return _processRequests(requests, response);
//      });    
    }
  }
//  This probably should be in serverside sync? or somewhere registered as requestExecutor to requestHandler
//  Future _process(Map data) {
//    print("");
//    print("REQUEST:  ${data}");
//    if (data["action"] == "get_data") {
//      num version = mongo.maxVersion;
//      return publisher.getData(data["collection"], data["args"]).then((d) => {"data" : d, "version" : version});                             
//    }
//    else if (data["action"] == "get_diff") {
//      return publisher.getDiff(data["collection"], data["args"], data["version"]);
//    }
//    else if (data["action"] == "add") {
//      return mongo.collection(data["collection"]).add(data["data"], data["author"]);
//    }
//    else if (data["action"] == "change") {
//      return mongo.collection(data["collection"]).change(data["_id"], data["data"], data["author"]);
//    }
//    else if (data["action"] == "remove") {
//      return mongo.collection(data["collection"]).remove(data["_id"], data["author"]);
//    }
//    
//    return new Future.value({"action" : data["action"]});
//  }
}