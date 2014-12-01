# Backend server for convenient request handling
[![Build Status](https://drone.io/github.com/cleandart/clean_backend/status.png)](https://drone.io/github.com/cleandart/clean_backend/latest)

## Motivation

Have you ever tried to work with *HttpServer* ? It's just a stream of *HttpRequests*, all going to
this single location, where you would have to handle them differently based on their URI, manage 
cookies, handle cases when URI is invalid...and all this on your own. This just makes your life
much easier.

## What is it good for ?

Basically, it is a *HttpServer*, which supports adding *Request* handlers per path and manages cookies 
conveniently. This *Request* is a special class, which wraps the imporant parts of the whole request  
together. It's just as simple as adding a new *Route* path associated with some name and then 
adding a *Request* handler for this route's name. Route paths support parameters, which are then accessible 
in the *Request* object in handler. Additionally, all requests - failed or not, are logged with duration of the process. 
