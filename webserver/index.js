var express = require('express');

var app = express();

var styles = ['success', 'error', 'notice', 'warning', 'info'];
var i = 0;

app.get('/', function (req, res) {
    console.log(req.query.q);

    res.json({
        // 'title': 'Oh boy!',
        // 'text': req.query.q,
        // 'style': styles[i++],
        // 'activator': 'libactivator.system.homebutton',
        // 'doneText': 'A button!',
        // 'duration': 3.0,
        'reListen': true
    });

    if (i > styles.length) {
        i = 0;
    }
});

var server = app.listen(8080, function () {

    var host = server.address().address;
    var port = server.address().port;

    console.log('Example app listening at http://%s:%s', host, port);

});