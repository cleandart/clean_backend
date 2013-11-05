// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_backend;

typedef Future RequestExecutor(request);

class RequestHandler {
 
  final Map<String, RequestExecutor> _registeredExecutors = new Map();
  
  bool get isEmpty => _registeredExecutors.isEmpty;
  
 Future handleRequest(String name, request){

   if(_registeredExecutors.containsKey(name)){
     return _registeredExecutors[name](request);
   }
   
   if(_registeredExecutors.containsKey('')){
     return _registeredExecutors[''](request);
   }
   
   throw new Exception("Uknown Request");
   //return new Future();
 }
 
 bool registerExecutor(String name, RequestExecutor requestExecutor){
   
   if(_registeredExecutors.containsKey(name)){
     return false;
   }
   _registeredExecutors[name] = requestExecutor;
   return true;
 }
 
 bool unregisterExecutor(String name){
   if(!_registeredExecutors.containsKey(name)){
     return false;
   }
   _registeredExecutors.remove(name);
   return true;
 }
}