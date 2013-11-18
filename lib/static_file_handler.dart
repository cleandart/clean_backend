// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//Forked from https://github.com/DanieleSalatti/static-file-handler/blob/master/lib/static_file_handler.dart

library static_file_handler;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';

class StaticFileHandler {
  Builder _root;
  String get documentRoot => _root.root;

  /**
   * Default constructor.
   */
  StaticFileHandler(String documentRoot) {
    _root = new Builder(root: absolute(normalize(documentRoot)));

    var dir = new Directory(_root.root);
    if (!dir.existsSync()) {
      throw new ArgumentError("Root path does not exist or is not a directory");
    }
  }

  /**
   * Add the MIME types [types] to the list of supported MIME types
   */
  void addMIMETypes(Map<String, String> types){
    _extToContentType.addAll(types);
  }

  /**
   * Serve the file [file] to the [request]. The content of the file will be
   * streamed to the response. If a supported [:Range:] header is received, only
   * a smaller part of the [file] will be streamed.
   */
  void _serveFile(File file, HttpRequest request) {
    HttpResponse response = request.response;

    // Callback used if file operations fails.
    void fileError(e) {
      response.statusCode = HttpStatus.NOT_FOUND;
      response.close();
    }

    void pipeToResponse(Stream fileContent, HttpResponse response) {
      fileContent.pipe(response).then((_) => response.close()).catchError(
          //TODO
        () => throw new StateError("Streaming file gone wrong.")
      );
    }

    void _sendRange(File file, HttpResponse response, String range, length) {
      // TODO We only support one range, where the standard support several.
      Match matches = new RegExp(r"^bytes=(\d*)\-(\d*)$").firstMatch(range);

      // If the range header have the right format, handle it.
      if (matches != null) {
        // Serve sub-range.
        int start;
        int end;
        if (matches[1].isEmpty) {
          start = matches[2].isEmpty ? length : length - int.parse(matches[2]);
          end = length;
        } else {
          start = int.parse(matches[1]);
          end = matches[2].isEmpty ? length : int.parse(matches[2]) + 1;
        }

        // Override Content-Length with the actual bytes sent.
        response.headers.set(HttpHeaders.CONTENT_LENGTH, end - start);

        // Set 'Partial Content' status code.
        response.statusCode = HttpStatus.PARTIAL_CONTENT;
        response.headers.set(HttpHeaders.CONTENT_RANGE, "bytes $start-${end - 1}/$length");

        // Pipe the 'range' of the file.
        pipeToResponse(file.openRead(start, end), response);
      }
    }

    file.lastModified().then((lastModified) {
      // If If-Modified-Since is present and file haven't changed, return 304.
      if (request.headers.ifModifiedSince != null &&
          !lastModified.isAfter(request.headers.ifModifiedSince)) {
        response.statusCode = HttpStatus.NOT_MODIFIED;
        response.close();
        return;
      }

      file.length().then((length) {
        // Always set Accept-Ranges and Last-Modified headers.
        response.headers.set(HttpHeaders.ACCEPT_RANGES, "bytes");
        response.headers.set(HttpHeaders.LAST_MODIFIED, lastModified);

        String ext = extension(file.path);
        if (_extToContentType.containsKey(ext.toLowerCase())) {
          response.headers.contentType = ContentType.parse(_extToContentType[ext.toLowerCase()]);
        }

        if (request.method == 'HEAD') {
          response.close();
          return;
        }

        // If the Range header was received, handle it.
        String range = request.headers.value("range");
        if (range != null) {
          _sendRange(file, response, range, length);
          return;
        }

        /*
         * Send content length if using HTTP/1.0
         * When using HTTP/1.1 chunked transfer encoding is used
         */
        if (request.protocolVersion == "1.0") {
          response.headers.set(HttpHeaders.CONTENT_LENGTH, length);
        }

        // Fall back to sending the entire content.
        pipeToResponse(file.openRead(), response);
      }, onError: fileError);
    }, onError: fileError);
  }

  /**
   * Seeks for file at documentRoot/relativePath and depending on [request]
   * parameters it fills [request.response].
   */
  void handleRequest(String relativePath, HttpRequest request) {
    request.response.done.catchError(
        //TODO
      () => throw new StateError("Error creating response")
    );

    //TODO check format, consider using Builder
    String path = documentRoot + relativePath;

    FileSystemEntity.type(path)
    .then((type) {
      switch (type) {
        case FileSystemEntityType.FILE:
          // If file, serve as such.
          _serveFile(new File(path), request);
          break;

        case FileSystemEntityType.DIRECTORY:
          throw new ArgumentError("Cannot serve directories");

        default:
          // File not found, fall back to 404.
          request.response.statusCode = HttpStatus.NOT_FOUND;
          request.response.close();
          break;
      }
    });
  }

  //TODO extend list, consider moving into separate file
  final _extToContentType = {
    "bz"      : "application/x-bzip",
    "bz2"     : "application/x-bzip2",
    "dart"    : "application/dart",
    "exe"     : "application/octet-stream",
    "gif"     : "image/gif",
    "gz"      : "application/x-gzip",
    "html"    : "text/html; charset=utf-8",  // Assumes UTF-8 files.
    "jpg"     : "image/jpeg",
    "js"      : "application/javascript",
    "json"    : "application/json",
    "mp3"     : "audio/mpeg",
    "mp4"     : "video/mp4",
    "pdf"     : "application/pdf",
    "png"     : "image/png",
    "tar.gz"  : "application/x-tar",
    "tgz"     : "application/x-tar",
    "txt"     : "text/plain; charset=utf-8",  // Assumes UTF-8 files.
    "webp"    : "image/webp",
    "webm"    : "video/webm",
    "zip"     : "application/zip"
  };
}
