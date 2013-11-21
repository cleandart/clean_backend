// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'package:unittest/unittest.dart';
import 'package:crypto/crypto.dart';
import 'package:unittest/mock.dart';
import 'package:clean_backend/clean_backend.dart';
import 'package:clean_router/server.dart';

Utf8Codec codec = new Utf8Codec();

class MockHMAC extends Mock implements HMAC{
  List<int> signature;
  bool verify(List<int> digest){
    if (digest.length != signature.length) return false;
    for (int i = 0; i< digest.length; i++){
      if (digest[i] != signature[i])
        return false;
    }
    return true;
  }
  MockHMAC(signature){
    this.signature = signature;
    when(callsTo('close')).alwaysReturn(signature);
  }
}

class MockHttpHeaders extends Mock implements HttpHeaders {}
class MockHttpServer extends Mock implements HttpServer {}
class MockRouter extends Mock implements Router {}
class MockRequestNavigator extends Mock implements RequestNavigator {}

class MockHttpResponse extends Mock implements HttpResponse{
  var headers = new MockHttpHeaders();
}

class MockRequest extends Mock implements Request {
  var headers = new MockHttpHeaders();
  var response = new MockHttpResponse();
}

void main() {
  group('Backend', () {
    Backend backend;
    List<int> signature;
    setUp(() {
      signature = [0,0,0,0,0,0];
      var hmacFactory = () => new MockHMAC(signature);
      MockHttpServer server = new MockHttpServer();
      MockRouter router = new MockRouter();
      var requestNavigator = new MockRequestNavigator();
      backend = new Backend.config(server, router, requestNavigator, hmacFactory);
    });

    test('Authenticate test (T01).', () {
      //given
      MockHttpResponse response = new MockHttpResponse();
      String userId = 'john.doe25';

      //when
      backend.authenticate(response, userId);

      //then
      var cookie = response.headers.getLogs(callsTo('add', HttpHeaders.SET_COOKIE)).last.args[1];
      expect(cookie.toString(), equals('authentication=${JSON.encode({
        'userID': userId, 'signature': signature})}; Max-Age=${
          Backend.COOKIE_MAX_AGE}; Path=${Backend.COOKIE_PATH}; HttpOnly'));
    });

    test('get userId from cookies test (T02).', () {
      //given
      String userId = 'john.doe25';
      Cookie cookie = new Cookie('authentication', JSON.encode({'userID': userId, 'signature': signature}));
      MockHttpHeaders headers = new MockHttpHeaders();
      headers.when(callsTo('[]', HttpHeaders.COOKIE)).alwaysReturn([cookie.toString()]);

      //when
      String getUserId = backend.getAuthenticatedUser(headers);

      //then
      expect(getUserId, equals(userId));
    });

    test('get userId from cookies test - not existing user (T03).', () {
      //given
      String userId = 'john.doe25';
      MockHttpHeaders headers = new MockHttpHeaders();
      headers.when(callsTo('[]', HttpHeaders.COOKIE)).alwaysReturn(null);

      //when
      String getUserId = backend.getAuthenticatedUser(headers);

      //then
      expect(getUserId, isNull);
    });

    test('get userId from cookies test - bad authentication code (T04).', () {
      //given
      String userId = 'john.doe25';
      Cookie cookie = new Cookie('authentication', JSON.encode({'userID': userId, 'signature': [0,1,0,0,0,0]}));
      MockHttpHeaders headers = new MockHttpHeaders();
      headers.when(callsTo('[]', HttpHeaders.COOKIE)).alwaysReturn([cookie.toString()]);

      //when
      String getUserId = backend.getAuthenticatedUser(headers);

      //then
      expect(getUserId, isNull);

    });

    test('delete authentication cookie (T05).', () {
      //given
      String userId = 'john.doe25';
      MockRequest request = new MockRequest();
      Cookie cookie = new Cookie('authentication', JSON.encode({'userID': userId, 'signature': signature}));
      request.headers.when(callsTo('[]', HttpHeaders.COOKIE)).alwaysReturn([cookie.toString()]);

      //when
      backend.logout(request);
      cookie.maxAge = 0;

      //then
      List addedHeader = request.response.headers.getLogs(callsTo('add')).last.args;
      expect(addedHeader[0], equals(HttpHeaders.SET_COOKIE));
      expect(addedHeader[1].toString(), equals(cookie.toString()));
    });
  });
 }
