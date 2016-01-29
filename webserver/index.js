'use strict';

var express = require('express');

var app = express();

var styles = ['success', 'error', 'notice', 'warning', 'info'];
var i = 0;

var context = {};
var uniqueKey = 'test';

app.get('/', function (req, res) {

  console.log(JSON.stringify(req.query, 2, undefined));

  res.json({
    'title': 'Oh boy!',
    'text': req.query.q,
    // 'style': styles[i++],
    // 'activator': 'libactivator.system.homebutton',
    // 'doneText': 'A button!',
    // 'duration': 3.0,
    // reListen: true,
    context: uniqueKey,
  });

  context[uniqueKey] = req.query.q;

  if (i > styles.length) {
    i = 0;
  }
});

var server = app.listen(8000, function () {

  var port = server.address().port;

  console.log('Example app listening on localhost:%s', port);

});
