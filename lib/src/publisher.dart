// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_backend;

typedef DataProvider DataGenerator(Map args);

class Publisher {
  
  Map<String, DataGenerator> _publishedCollections = {};
  
  void publish(String collection, DataGenerator callback) {
    _publishedCollections[collection] = callback;
  }
  
  bool isPublished(String collection) {
    return _publishedCollections.keys.contains(collection);
  }

  dynamic getData(String collection, Map args) {
    return _publishedCollections[collection](args).data();
  }
  
  dynamic getDiff(String collection, Map args, num version) {
    return _publishedCollections[collection](args).diffFromVersion(version);
  }
  
}