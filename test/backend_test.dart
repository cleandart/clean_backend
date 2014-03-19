// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_backend.backend_test;

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
class MockHMAC extends Mock implements HMAC {
  var listOfInt = [];
  MockHMAC();
  add(List<int> val) => listOfInt.addAll(val);
  close() => listOfInt.map((int i) => i+10).toList();
  verify(List<int> digest) {
    if (digest.length != listOfInt.length) return false;
      for(int i = 0 ; i < digest.length; i++)
        if (digest[i] != listOfInt[i]+10) return false;
    return true;
  }
}

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
    HttpBodyHandlerMock httpBodyHandler;

    setUp(() {
      server = new MockHttpServer();
      router = new MockRouter();
      requestNavigator = new MockRequestNavigator();
      httpBodyHandler = new HttpBodyHandlerMock();

      backend = new Backend.config(server, router, requestNavigator, ()=>new MockHMAC(), httpBodyHandler.processRequest);
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

    test('default handler is registered exactly once.', () {
      // then
      requestNavigator.getLogs(callsTo('registerDefaultHandler'))
        .verify(happenedOnce);
    });

    test('adding slash when view is not found.', () {
      // given
      Function defaultHandler = requestNavigator
          .getLogs(callsTo('registerDefaultHandler')).first.args.first;
      HttpRequestMock request = new HttpRequestMock(Uri.parse('/static'));

      // when
      defaultHandler(request, null).then((_) {

        //then
        var redirectCalls = request.response.getLogs(callsTo('redirect'));
        redirectCalls.verify(happenedOnce);
        expect(redirectCalls.first.args.first.path, equals('/static/'));
      });
    });

    test('returning not found view if view has slash and is not found.', () {
      // given
      Function defaultHandler = requestNavigator
          .getLogs(callsTo('registerDefaultHandler')).first.args.first;
      HttpRequestMock request = new HttpRequestMock(Uri.parse('/static/'));
      Mock handler = new Mock();
      backend.addNotFoundView((Request request) => handler(request));

      // when
      defaultHandler(request, null).then((_){

        //then
        handler.getLogs().verify(happenedOnce);
      });
    });

    test('returning default not found view.', () {
      // given
      Function defaultHandler = requestNavigator
          .getLogs(callsTo('registerDefaultHandler')).first.args.first;
      HttpRequestMock request = new HttpRequestMock(Uri.parse('/static/'));

      // when
      defaultHandler(request, null).then((_) {

        // then
        request.response.getLogs(callsTo('set statusCode'))
          .verify(happenedOnce);
        expect(request.response.getLogs(callsTo('set statusCode'))
            .last.args.first, equals(HttpStatus.NOT_FOUND));
      });
    });

    test('signing and verifing message', (){
      //given
      var msg = 'random msg';

      //when
      var signature = backend.sign(msg);
      var badSignature = '1234${signature}';

      //then
      expect(backend.verifySignature(msg, signature), isTrue);
      expect(backend.verifySignature(msg, badSignature), isFalse);
      expect(backend.verifySignature('another msg', signature), isFalse);
    });

  });
}

