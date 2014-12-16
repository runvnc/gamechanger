# ToffeeScript, a Game-Changer for Node.js callbacks

The following article does a good job of explaining "callback hell" in Node.js:

http://strongloop.com/strongblog/node-js-callback-hell-promises-generators/

The article shows some ways to deal with handling a series of asynchronous tasks.
All of the popular options are somewhat less readable than purely synchronous
code would be.  Certainly some people will try to argue that point, but I believe
it is an objective statement.

One thing about all of those approaches is that they are all written in JavaScript.
In other words, they all follow the same basic set of rules in terms of syntax.

So, first here are some of the many examples of approaches that follow the rules:

``` javascript
# callbacks

var path = require('path')
 
module.exports = function (dir, cb) {
  fs.readdir(dir, function (er, files) { // [1]
    if (er) return cb(er)
    var counter = files.length
    var errored = false
    var stats = []
 
    files.forEach(function (file, index) {
      fs.stat(path.join(dir,file), function (er, stat) { // [2]
        if (errored) return
        if (er) {
          errored = true
          return cb(er)
        }
        stats[index] = stat // [3]
 
        if (--counter == 0) { // [4]
          var largest = stats
            .filter(function (stat) { return stat.isFile() }) // [5]
            .reduce(function (prev, next) { // [6]
              if (prev.size > next.size) return prev
              return next
            })
          cb(null, files[stats.indexOf(largest)]) // [7]
        }
      })
    })
  })

```


``` javascript
# modular

function getStats (paths, cb) {
  var counter = paths.length
  var errored = false
  var stats = []
  paths.forEach(function (path, index) {
    fs.stat(path, function (er, stat) {
      if (errored) return
      if (er) {
        errored = true
        return cb(er)
      }
      stats[index] = stat
      if (--counter == 0) cb(null, stats)
    })
  })
}

function getLargestFile (files, stats) {
  var largest = stats
    .filter(function (stat) { return stat.isFile() })
    .reduce(function (prev, next) {
      if (prev.size > next.size) return prev
      return next
    })
    return files[stats.indexOf(largest)]
}

var fs = require('fs')
var path = require('path')
 
module.exports = function (dir, cb) {
  fs.readdir(dir, function (er, files) {
    if (er) return cb(er)
    var paths = files.map(function (file) { // [1]
      return path.join(dir,file)
    })
 
    getStats(paths, function (er, stats) {
      if (er) return cb(er)
      var largestFile = getLargestFile(files, stats)
      cb(null, largestFile)
    })
  })
}

```

``` javascript
# using async module

var fs = require('fs')
var async = require('async')
var path = require('path')
 
module.exports = function (dir, cb) {
  async.waterfall([ // [1]
    function (next) {
      fs.readdir(dir, next)
    },
    function (files, next) {
      var paths = 
       files.map(function (file) { return path.join(dir,file) })
      async.map(paths, fs.stat, function (er, stats) { // [2]
        next(er, files, stats)
      })
    },
    function (files, stats, next) {
      var largest = stats
        .filter(function (stat) { return stat.isFile() })
        .reduce(function (prev, next) {
        if (prev.size > next.size) return prev
          return next
        })
        next(null, files[stats.indexOf(largest)])
    }
  ], cb) // [3]
}

```

``` javascript
# promises
var fs = require('fs')
var path = require('path')
var Q = require('q')
var fs_readdir = Q.denodeify(fs.readdir) // [1]
var fs_stat = Q.denodeify(fs.stat)
 
module.exports = function (dir) {
  return fs_readdir(dir)
    .then(function (files) {
      var promises = files.map(function (file) {
        return fs_stat(path.join(dir,file))
      })
      return Q.all(promises).then(function (stats) { // [2]
        return [files, stats] // [3]
      })
    })
    .then(function (data) { // [4]
      var files = data[0]
      var stats = data[1]
      var largest = stats
        .filter(function (stat) { return stat.isFile() })
        .reduce(function (prev, next) {
        if (prev.size > next.size) return prev
          return next
        })
      return files[stats.indexOf(largest)]
    })
}
```

``` javascript
# generators

o = require('co')
var thunkify = require('thunkify')
var fs = require('fs')
var path = require('path')
var readdir = thunkify(fs.readdir) <strong>[1]</strong>
var stat = thunkify(fs.stat)
 
module.exports = co(function* (dir) { // [2]
  var files = yield readdir(dir) // [3]
  var stats = yield files.map(function (file) { // [4]
    return stat(path.join(dir,file))
  })
  var largest = stats
    .filter(function (stat) { return stat.isFile() })
    .reduce(function (prev, next) {
      if (prev.size > next.size) return prev
      return next
    })
  return files[stats.indexOf(largest)] // [5]
})
```


Why have so many different ways been invented to solve the callback problem in JavaScript?  Perhaps because people have felt as though the existing solutions were less 
than ideal in terms of readability and maintainability.

My solution does not follow the rules of JavaScript.  It is written in [ToffeeScript](https://github.com/jiangmiao/toffee-script).
ToffeeScript is a derivation of CoffeeScript which allows one to write asynchronous
code as though it were synchronous.

``` coffeescript
# toffeescript
fs = require 'fs'
 
module.exports = (dir, cb) ->
  err, files = fs.readdir! dir
  largest = 0
  for file in files
    er, stat = fs.stat! "#{dir}/#{file}"
    if stat.isFile and stat.size > largest
      fname = file
      largest = stat.size
  cb fname
```

The trick is recognizing when you are in a box, why you got in that box, and when to
get out.  Waiting for everyone else to get out of the box first might not be the best approach.

http://en.m.wikipedia.org/wiki/System_justification
