// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import '../lib/clean_backend.dart';
import 'package:yaml/yaml.dart';
import 'package:static_file_handler/static_file_handler.dart';

void main() {
  Backend backend;
  YamlMap config = loadConfig();
  YamlMap dbConfig = config["database"];
  String dbUrl = "mongodb://${dbConfig["username"]}:${dbConfig["password"]}@${dbConfig["host"]}:${dbConfig["port"]}/${dbConfig["database"]}";

  MongoProvider mongo = new MongoProvider(dbUrl);
  Publisher publisher = new Publisher();
  StaticFileHandler fileHandler = new StaticFileHandler.serveFolder(config["root_dir"]);
  
  publisher.publish('persons', (_) {
    return mongo.collection("persons");
  });
  
  publisher.publish('personsOlderThan24', (_) {
    return mongo.collection("persons").find({"age" : {'\$gt' : 24}});
  });
  
  mongo.initialize(config["collections"]).then((_) {
    backend = new Backend(mongo, publisher, fileHandler, host: config["host"], port: config["port"])..listen();
  });
}

YamlMap loadConfig() {
  return loadYaml((new File('../config.yml')).readAsStringSync(encoding: Encoding.getByName("utf-8")));
}