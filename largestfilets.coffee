# actually toffeescript

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
