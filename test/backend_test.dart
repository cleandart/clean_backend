// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:clean_backend/clean_backend.dart';
import 'package:crypto/crypto.dart';
import 'package:unittest/mock.dart';
import 'dart:io';
import 'dart:convert';

class MockHMAC extends Mock implements HMAC{

  MockHMAC(userIdSignature){
    Utf8Codec codec = new Utf8Codec();
    List<int> encodedUserIdSignature = codec.encode(userIdSignature);
    when(callsTo('close')).alwaysReturn(encodedUserIdSignature);
  }
}
class MockHttpHeaders extends Mock implements HttpHeaders {
//  void add(String type, Cookie cookie){}
}
class MockHttpResponse extends Mock implements HttpResponse{
//  Mock httpHeaders = new MockHttpHeaders();
  var headers = new MockHttpHeaders();
//  MockHttpRequest() {
//    when(callsTo('get headers')).alwaysReturn(httpHeaders);
//  }
}

void main() {

  group('Backend', () {
    test('Authenticate test (T01).', () {
      //given
      Backend backend = new Backend();

      MockHttpResponse response = new MockHttpResponse();
      String userId = 'martinko.Klingáčik25';
      MockHMAC hmac = new MockHMAC('mrtk14');

      //when
      backend.authenticate(response, userId, hmac: hmac);

      //then
      var cookie = response.headers.getLogs(callsTo('add', HttpHeaders.SET_COOKIE)).last.args[1];
      expect(cookie.toString(), equals('authentication={"userID":"martinko.Klingáčik25","signature":"mrtk14"}'));
    });

    test('get userId from cookies test (T02).', () {
      //given
      Backend backend = new Backend();

      MockHttpHeaders headers = new MockHttpHeaders();
      String userId = 'martinko.Klingáčik25';
      MockHMAC hmac = new MockHMAC('mrtk14');

      //when
      backend.isAuthenticated(headers);

      //then
      var cookie = response.headers.getLogs(callsTo('add', HttpHeaders.SET_COOKIE)).last.args[1];
      expect(cookie.toString(), equals('authentication={"userID":"martinko.Klingáčik25","signature":"mrtk14"}'));
    });


  });
 }
