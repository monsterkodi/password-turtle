var http   = require("http");
var url    = require("url");
var exec   = require("child_process").exec;
var prcss  = require("process");
var moment = require('moment');

function onRequest(request, response)
{
  console.log(":: " + process.cwd() + url.parse(request.url).path);
  exec("atom " + process.cwd() + url.parse(request.url).path);
  response.end()
}

http.createServer(onRequest).listen(8888);
console.log(":: "+moment().format('h:mm:ss'));
