#!/usr/bin/env node

var winston = require("winston"),
    winston_logstash = require('winston-logstash');

winston.add(winston.transports.Logstash, {
});
winston.loggers.add('app', {
  console: {
    level: 'debug',
    colorize: 'true',
    label: 'app'
  },
});
winston.loggers.add('stats', {
  console: {
    level: 'debug',
    colorize: 'true',
    label: 'stat'
  },
  logstash: {
    port: 28777,
    node_name: 'my node name',
    host: '127.0.0.1'
  }
});

logger = winston.loggers.get("app");

var express = require('express')
  , http = require('http')
  , mongoose = require('mongoose')
  , models = require('./models')
  , routes = require('./routes')
  , app = express();

app.configure(function () {
  // enable web server logging; pipe those log messages through winston
  var winstonStream = {
      write: function(message, encoding){
          logger.debug(message.replace(/\n$/, ''));
      }
  };

  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.favicon());
  app.use(express.logger({format: 'tiny', stream: winstonStream}));
  app.use(require('stylus').middleware({ src: __dirname + '/public' }));
  app.use(express.static(__dirname + '/public'));
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
});

app.configure('development', function () {
  app.use(express.errorHandler());
});

routes.init(app);

var port = process.env.VCAP_APP_PORT || 3000;

if(process.env.VCAP_SERVICES){
  var services = JSON.parse(process.env.VCAP_SERVICES);
  var dbcreds = services['mongodb'][0].credentials;
}

if(dbcreds){
  logger.info(dbcreds);
  mongoose.connect(dbcreds.host, dbcreds.db, dbcreds.port, {user: dbcreds.username, pass: dbcreds.password});
}else{
  mongoose.connect("127.0.0.1", "todomvc", 27017);
}

http.createServer(app).listen(port);
logger.info("Express server listening on port %s", port);
