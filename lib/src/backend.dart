// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_backend;

class Backend {
  Publisher publisher;
  MongoProvider mongo;
  StaticFileHandler fileHandler;
  HttpServer server;
  String host;
  int port;

  Backend(MongoProvider mongo, Publisher publisher, StaticFileHandler fileHandler, {String host: "0.0.0.0", int port: 8080}) {
    this.fileHandler = fileHandler;
    this.mongo = mongo;
    this.publisher = publisher;
    this.host = host;
    this.port = port;
    
    print("MongoDB max history version: ${mongo.maxVersion}");
  }
  
  void listen() {
    print("Starting HTTP server");
    
    HttpServer.bind(host, port).then((HttpServer server) {
      this.server = server;
      var router = new Router(server);
      
      print("Listening on ${server.address.address}:${server.port}");
      
      router
        ..serve(new UrlPattern(r'/resources')).listen(_serveResources)
        ..defaultStream.listen(fileHandler.handleRequest);
    });
  }

  void _serveResources(request) {
    HttpBodyHandler.processRequest(request).then((HttpBody body) {
      List requests = JSON.decode(body.body);
      
      _processRequests(requests.reversed.toList(), []).then((response) {
        request.response
          ..headers.add("Access-Control-Allow-Origin", "*")
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
      var req = requests.removeLast();
      
      return _process(req["request"]["args"]).then((result) {
        response.add({"id" : req["id"], "response" : result});
        print("RESPONSE: ${result}");
        return _processRequests(requests, response);
      });    
    }
  }
  
  Future _process(Map data) {
    print("");
    print("REQUEST:  ${data}");
    if (data["action"] == "get_data") {
      num version = mongo.maxVersion;
      return publisher.getData(data["collection"], data["args"]).then((d) => {"data" : d, "version" : version});                             
    }
    else if (data["action"] == "get_diff") {
      return publisher.getDiff(data["collection"], data["args"], data["version"]);
    }
    else if (data["action"] == "add") {
      return mongo.collection(data["collection"]).add(data["data"], data["author"]);
    }
    else if (data["action"] == "change") {
      return mongo.collection(data["collection"]).change(data["_id"], data["data"], data["author"]);
    }
    else if (data["action"] == "remove") {
      return mongo.collection(data["collection"]).remove(data["_id"], data["author"]);
    }
    
    return new Future.value({"action" : data["action"]});
  }
}