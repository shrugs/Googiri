var express = require('express');

var app = express();

app.get('/', function (req, res) {
    console.log(req.query.q);
    res.json({
        // 'activator': 'libactivator.system.homebutton',
        'text': req.query.q
    });
});

var server = app.listen(8080, function () {

    var host = server.address().address;
    var port = server.address().port;

    console.log('Example app listening at http://%s:%s', host, port);

});