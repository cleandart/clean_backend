library staticFileHandlerTest;

import 'package:unittest/unittest.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:static_file_handler/static_file_handler.dart';

void main() {

  StaticFileHandler fileHandler;
  int port = 3500;
  String directory = './test/www';
  String ip = '0.0.0.0';
  HttpClient client = new HttpClient();

  group('Server', () {

    setUp(() {
      Completer<bool> completer = new Completer();
      fileHandler = new StaticFileHandler(directory, port:port, ip: ip);
      fileHandler.start().then((success) {
        completer.complete(success);
      });
      return completer.future;
    });

    tearDown(() {
      fileHandler.stop();
    });

    test('Port is properly set', () {
      expect(fileHandler.port, equals(port));
    });

    test('Simple GET Request', () {
      Completer<bool> completer = new Completer();
      String finalString = "";

      client.get("127.0.0.1", port, "/").then((HttpClientRequest request) {
        return request.close();

      }).then((HttpClientResponse response) {
        expect(response.statusCode, equals(HttpStatus.OK));
        completer.complete(true);
      });

      return completer.future;
    });

    test('File not found (404)', () {
      Completer<bool> completer = new Completer();
      String finalString = "";

      client.get("127.0.0.1", port, "/nonexistentfile.html").then((HttpClientRequest request) {
        return request.close();

      }).then((HttpClientResponse response) {
        expect(response.statusCode, equals(HttpStatus.NOT_FOUND));
        completer.complete(true);
      });

      return completer.future;
    });

    test('Serving file', () {
      Completer<bool> completer = new Completer();
      String finalString = "";

      client.get("127.0.0.1", port, "/textfile.txt").then((HttpClientRequest request) {
        return request.close();

      }).then((HttpClientResponse response) {
        response.transform(new Utf8Decoder())
        .transform(new LineSplitter())
        .listen((String result) {
          finalString += result;
        },
        onDone: () {
          expect(finalString, equals("test"));
          completer.complete(true);
        });
      });

      return completer.future;
    });

    test('Not Modified (304)', () {
      Completer<bool> completer = new Completer();
      String finalString = "";

      client.get("127.0.0.1", port, "/textfile.txt").then((HttpClientRequest request) {
        request.headers.add("If-Modified-Since", new DateTime.now());
        return request.close();

      }).then((HttpClientResponse response) {
        expect(response.statusCode, equals(HttpStatus.NOT_MODIFIED));
        completer.complete(true);
      });

      return completer.future;
    });
    
    test('Max Age', () {
      Completer<bool> completer = new Completer();
      String finalString = "";
      fileHandler.maxAge = 3600;
      
      client.get("127.0.0.1", port, "/textfile.txt").then((HttpClientRequest request) {
        return request.close();
      }).then((HttpClientResponse response) {
        expect(response.headers[HttpHeaders.CACHE_CONTROL][0], equals("max-age=3600"));
        completer.complete(true);
      });

      return completer.future;
    });

    test('Range - content', () {
      Completer<bool> completer = new Completer();
      String finalString = "";

      client.get("127.0.0.1", port, "/textfile.txt").then((HttpClientRequest request) {
        request.headers.add("range", "bytes=1-2");
        return request.close();

      }).then((HttpClientResponse response) {
        response.transform(new Utf8Decoder())
        .transform(new LineSplitter())
        .listen((String result) {
          finalString += result;
        },
        onDone: () {
          expect(finalString, equals("es"));
          completer.complete(true);
        });
      });

      return completer.future;
    });

    test('Range - content length header', () {
      Completer<bool> completer = new Completer();
      String finalString = "";

      client.get("127.0.0.1", port, "/textfile.txt").then((HttpClientRequest request) {
        request.headers.add("range", "bytes=1-2");
        return request.close();

      }).then((HttpClientResponse response) {
        expect(response.headers[HttpHeaders.CONTENT_LENGTH], equals(['2']));
        completer.complete(true);
      });

      return completer.future;
    });

    test('Range - partial content status', () {
      Completer<bool> completer = new Completer();
      String finalString = "";

      client.get("127.0.0.1", port, "/textfile.txt").then((HttpClientRequest request) {
        request.headers.add("range", "bytes=1-2");
        return request.close();

      }).then((HttpClientResponse response) {
        expect(response.statusCode, equals(HttpStatus.PARTIAL_CONTENT));
        completer.complete(true);
      });

      return completer.future;
    });

    test('Range - content range header', () {
      Completer<bool> completer = new Completer();
      String finalString = "";

      client.get("127.0.0.1", port, "/textfile.txt").then((HttpClientRequest request) {
        request.headers.add("range", "bytes=1-2");
        return request.close();

      }).then((HttpClientResponse response) {
        expect(response.headers[HttpHeaders.CONTENT_RANGE], equals(['bytes 1-2/4']));
        completer.complete(true);
      });

      return completer.future;
    });

  });

}
