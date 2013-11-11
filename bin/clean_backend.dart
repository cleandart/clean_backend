// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import '../lib/clean_backend.dart';
import 'package:yaml/yaml.dart';
import 'package:static_file_handler/static_file_handler.dart';

import 'package:clean_ajax/clean_server.dart';

void main() {
  Backend backend;
 // YamlMap config = loadConfig();

  StaticFileHandler fileHandler = new StaticFileHandler.serveFolder('/home/maty/vacuumlabs/git/');
  RequestHandler requestHandler = new RequestHandler();

  backend = new Backend( fileHandler, requestHandler)..listen();
}

YamlMap loadConfig() {
  return loadYaml((new File('../config.yml')).readAsStringSync(encoding: Encoding.getByName("utf-8")));
}