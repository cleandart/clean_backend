// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http_server/http_server.dart';
import 'package:crypto/crypto.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_backend/clean_backend.dart';
import 'package:clean_router/server.dart';

class MockHttpServer extends Mock implements HttpServer {}
class MockRouter extends Mock implements Router {}
class MockRequestNavigator extends Mock implements RequestNavigator {}
class MockHMAC extends Mock implements HMAC {}
class HttpBodyMock extends Mock implements HttpBody {}

class HttpResponseMock extends Mock implements HttpResponse{
  HttpHeaders headers = new HttpHeadersMock();
}

class HttpHeadersMock extends Mock implements HttpHeaders {
  Map data = {};

  String add(String key, dynamic value){
    data[key] = value;
  }

  dynamic value(String key){
    return data[key];
  }
}

class HttpBodyHandlerMock extends Mock implements HttpBodyHandler {
  Future<HttpRequestBody> processRequest(
      HttpRequest request,
      {Encoding defaultEncoding}){
      Completer completer = new Completer();
      new Timer(new Duration(milliseconds:1), () => completer.complete(new HttpBodyMock()));
      return completer.future;
  }
}
class HttpRequestMock extends Mock implements HttpRequest {
  Uri uri;
  HttpHeaders headers = new HttpHeadersMock();
  HttpResponse response = new HttpResponseMock();

  HttpRequestMock(this.uri);
}

class StreamHttpRequestMock extends Mock implements Stream<HttpRequest> {}

void main() {
  group('(Backend)', () {
    Backend backend;
    MockHttpServer server;
    MockRequestNavigator requestNavigator;
    MockRouter router;
    MockHMAC hmac;
    HttpBodyHandlerMock httpBodyHandler;

    setUp(() {
      server = new MockHttpServer();
      router = new MockRouter();
      requestNavigator = new MockRequestNavigator();
      hmac = new MockHMAC();
      httpBodyHandler = new HttpBodyHandlerMock();

      backend = new Backend.config(server, router, requestNavigator, hmac, httpBodyHandler.processRequest);
    });

    test('addRoute', () {
      // given

      // when
      backend.addRoute('name', new Route('/'));

      // then
      router.getLogs(callsTo('addRoute')).verify(happenedOnce);

    });

    test('addView', () {
      // given

      // when
      backend.addView('name', (_) {});

      // then
      requestNavigator.getLogs(callsTo('registerHandler')).verify(happenedOnce);
    });

    test('prepareRequestHandler', () {
      // given
      var request = new HttpRequestMock(Uri.parse('/static/'));

      // when & then
      backend.prepareRequestHandler(request, {'key':'value'}, expectAsync1((Request request) {
        expect(request.match, equals({'key':'value'}));
        expect(request.httpRequest.uri.path, equals('/static/'));
        expect(request.body, isNull);
        expect(request.headers, new isInstanceOf<HttpHeaders>());
        expect(request.type, isNull);
      }));
    });

    test('addDefaultHttpHeader', () {
      // given
      var request = new HttpRequestMock(Uri.parse('/static/'));

      // when
      backend.addDefaultHttpHeader("header_name", "header_value");

      // then
      backend.prepareRequestHandler(request, {}, expectAsync1((Request request) {
        expect(request.response.headers.value("header_name"), equals("header_value"));
      }));
    });

    test('addStaticView', () {
      // given

      // when
      backend.addStaticView('name', "/root/");

      // then
      requestNavigator.getLogs(callsTo('registerHandler')).verify(happenedOnce);
    });

    test('addNotFoundView', () {
      // given

      // when
      backend.addNotFoundView((_) {});

      // then
      requestNavigator.getLogs(callsTo('registerDefaultHandler')).verify(happenedOnce);
    });

    test('addNotFoundView with forgotten backslash', () {
      //setUp real-like environment - so the backend made redirect callback will be called
      var realRouter = new Router("", {});
      var realRequestNavigator = new RequestNavigator(
          new StreamHttpRequestMock(), realRouter);

      backend = new Backend.config(server, realRouter, realRequestNavigator,
          hmac, httpBodyHandler.processRequest);

      // given
      backend.addRoute('static', new Route('/static/'));
      backend.addView('static', (_) {});
      backend.addNotFoundView(expectAsync1((_) {}, count : 0));

      //incoming request
      HttpRequestMock request = new HttpRequestMock(Uri.parse('/static'));
      HttpResponseMock response = request.response;

      // when
      realRequestNavigator.processHttpRequest(request);

      // then
      return new Future.delayed(new Duration(milliseconds: 100), () {
        response.getLogs(callsTo('redirect')).verify(happenedOnce);
        expect(response.getLogs(callsTo('redirect')).last.args[0].path,
            equals('/static/'));
      });
    });
  });
}

