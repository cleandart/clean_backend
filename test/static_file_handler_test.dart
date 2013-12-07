// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_backend.static_file_handler_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:clean_backend/static_file_handler.dart';

class HttpHeadersMock extends Mock implements HttpHeaders {
  DateTime ifModifiedSince = null;
  Map data = {};
  ContentType contentType;

  String set(String key, dynamic value){
    data[key] = value;
  }

  dynamic value(String key){
    return data[key];
  }
}

class HttpRequestMock extends Mock implements HttpRequest {
  //Uri uri;
  String method = "GET";
  String protocolVersion = "1.0";
  HttpHeaders headers = new HttpHeadersMock();
  HttpResponseMock response = new HttpResponseMock();
}

class HttpResponseMock extends Mock implements HttpResponse {
  HttpHeaders headers = new HttpHeadersMock();
  int statusCode = HttpStatus.OK;

  //TODO
  //Future close() => new Future.value();
  Future get done => new Future.value();
  String content = "";

  Future addStream(Stream stream){
    Completer completer = new Completer();

    stream.transform(UTF8.decoder) // use a StringDecoder
          .listen((String s) => content += s, // output the data
            onError: (error) => print("Error, could not open file"),
            onDone: () => completer.complete()
    );

    return completer.future;
  }
}

void main() {
  group('(StaticFileHandler)', () {

    StaticFileHandler fileHandler;

    setUp(() {
      fileHandler = new StaticFileHandler('./static_test');
    });

    test('allowed document root', () {
      // given & when & then
      new StaticFileHandler("./static_test");
      new StaticFileHandler("./static_test/");
      new StaticFileHandler("static_test");
      new StaticFileHandler("static_test/");
    });

    test('not allowed document root', () {
      // given & when & then
      expect(() => new StaticFileHandler("./not_existing_directory/"), throwsArgumentError);
      expect(() => new StaticFileHandler("simply/bad/route/"), throwsArgumentError);
    });

    //TODO consider adding last modified
    test('request file (200)', () {
      // given
      var request = new HttpRequestMock();
      var response = request.response;

      // when
      fileHandler.handleRequest(request, "testfile.txt");

      // test
      response.when(callsTo("close")).thenCall(expectAsync0(() {
         expect(response.statusCode, equals(HttpStatus.OK));
         expect(response.content, equals("testcontent"));
         expect(response.headers.value(HttpHeaders.CONTENT_LENGTH),
             equals("testcontent".length));
         expect(response.headers.contentType.toString(),
             equals("text/plain; charset=utf-8"));
         expect(response.headers.value(HttpHeaders.ACCEPT_RANGES),
             equals("bytes"));
      }));
    });

    test('request non-existing file (404)', () {
      // given
      var request = new HttpRequestMock();
      var response = request.response;

      // when
      fileHandler.handleRequest(request, "non-existing-file.txt");

      // test
      response.when(callsTo("close")).thenCall(expectAsync0(() {
         expect(response.statusCode, equals(HttpStatus.NOT_FOUND));
      }));
    });

    test('request directory (404)', () {
      // given
      var request = new HttpRequestMock();
      var response = request.response;

      // when
      fileHandler.handleRequest(request, "static_test");

      // test
      response.when(callsTo("close")).thenCall(expectAsync0(() {
         expect(response.statusCode, equals(HttpStatus.NOT_FOUND));
      }));
    });

    //TODO range

    test('not Modified (304)', () {
      // given
      var request = new HttpRequestMock();
      request.headers.ifModifiedSince = new DateTime.now();

      var response = request.response;

      // when
      fileHandler.handleRequest(request, "testfile.txt");

      // test
      response.when(callsTo("close")).thenCall(expectAsync0(() {
        expect(response.statusCode, equals(HttpStatus.NOT_MODIFIED));
      }));
    });

    test('range - content', () {
      // given
      var request = new HttpRequestMock();
      var response = request.response;
      request.headers.set("range", "bytes=1-7");

      // when
      fileHandler.handleRequest(request, "testfile.txt");

      // test
      response.when(callsTo("close")).thenCall(expectAsync0(() {
        expect(response.statusCode, equals(HttpStatus.PARTIAL_CONTENT));
        expect(response.content, equals("estcont"));
        expect(response.headers.value(HttpHeaders.CONTENT_LENGTH), equals(7));
        expect(response.headers.contentType.toString(),
            equals("text/plain; charset=utf-8"));
        expect(response.headers.value(HttpHeaders.CONTENT_RANGE),
            equals('bytes 1-7/11'));
      }));
    });

  });
}
