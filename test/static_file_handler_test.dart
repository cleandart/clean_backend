library clean_backend.static_file_handler;

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

  //dynamic value(String key)
  //range := r"^bytes=(\d*)\-(\d*)$"
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
          .listen((String data) => content += data, // output the data
            onError: (error) => print("Error, could not open file"),
            onDone: () => completer.complete()
    );

    return completer.future;
  }
}

void main() {
  group('StaticFileHandler', () {

    StaticFileHandler fileHandler;

    setUp(() {
      fileHandler = new StaticFileHandler('./www');
    });

    /*
    test('bad document root', () {
      // given & when & then
      expect(new StaticFileHandler("./not_existing_directory/"), throwsArgumentError);
      expect(new StaticFileHandler("simply/bad/route/"), throwsArgumentError);
    }); */

    test('request file', () {
      // given
      var request = new HttpRequestMock();
      var response = request.response;
      var lastModified =

      // when
      fileHandler.handleRequest(request, "testfile.txt");

      // test
      response.when(callsTo("close")).thenCall(expectAsync0(() {
         expect(response.statusCode, equals(HttpStatus.OK));
         expect(response.content, equals("testcontent"));
         expect(response.headers.data[HttpHeaders.CONTENT_LENGTH], equals("testcontent".length));
      }));
    });

    //TODO NOT existing root path
    //TODO NOT existing file path
    //TODO range
/*
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
*/
  });

}
