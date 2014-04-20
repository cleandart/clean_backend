// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library clean_backend.cookie_test;

import 'dart:io';
import 'dart:convert';
import 'package:http_server/http_server.dart';
import 'package:crypto/crypto.dart';
import 'package:unittest/unittest.dart';
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

  Cookie get lastCookie => response.headers.getLogs(callsTo('add', HttpHeaders.SET_COOKIE)).last.args[1] as Cookie;
}

void main() {
  group('(Cookie)', () {
    Backend backend;
    List<int> signature;
    setUp(() {
      signature = [0,0,0,0,0,0];
      var hmacFactory = () => new MockHMAC(signature);
      MockHttpServer server = new MockHttpServer();
      MockRouter router = new MockRouter();
      var requestNavigator = new MockRequestNavigator();
      backend = new Backend.config(server, router, requestNavigator, hmacFactory, HttpBodyHandler.processRequest);
    });

    test('Authenticate test (T01).', () {
      //given
      MockRequest request = new MockRequest();
      String userId = 'john.doe25';

      //when
      backend.authenticate(request, userId);

      //then
      var cookie = request.lastCookie;
      expect(cookie.path, equals(Backend.COOKIE_PATH));
      expect(cookie.httpOnly, isTrue);
      expect(cookie.name, equals('authentication'));
      expect(cookie.expires.isAfter(new DateTime.now().add(new Duration(days: 300))), isTrue);

      expect(backend.getAuthenticatedUser([cookie]), equals(userId));
    });

    test('get userId from cookies test - not existing user (T03).', () {

      //when
      String getUserId = backend.getAuthenticatedUser([]);

      //then
      expect(getUserId, isNull);
    });

    test('get userId from cookies test - bad authentication code (T04).', () {
      //given
      String userId = 'john.doe25';
      Cookie cookie = new Cookie('authentication', toCookieString({'userID': userId, 'signature': CryptoUtils.bytesToBase64([0,1,0,0,0,0])}));

      //when
      String getUserId = backend.getAuthenticatedUser([cookie]);

      //then
      expect(getUserId, isNull);

    });

    test('delete authentication cookie (T05).', () {
      //given
      String userId = 'john.doe25';
      MockRequest request = new MockRequest();
      backend.authenticate(request, userId);
      var cookie = request.lastCookie;
      request.headers.when(callsTo('[]', HttpHeaders.COOKIE)).alwaysReturn([cookie.toString()]);

      //when
      backend.logout(request);
      print(request.lastCookie);
      cookie.expires = new DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      cookie.value = '';

      //then
      expect(backend.getAuthenticatedUser([request.lastCookie]), isNull);
      expect(request.lastCookie.expires.isBefore(new DateTime(2000)), isTrue);
    });
  });
 }
