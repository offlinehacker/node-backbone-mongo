/**
 * Very basic CRUD route creation utility for models.
 * For validation, simply override the model's save method.
 */

(function (exports) {

  "use strict";

  var winston = require('winston');
  var logger = winston.loggers.get('stats');

  function errMsg(msg) {
    return {'error': {'message': msg.toString()}};
  }

  //------------------------------
  // List
  //
  function getListController(model) {
    return function (req, res) {
      logger.info(
        'getting %ss', model.modelName,
        { model: model.modelName, user: req.get("X-Auth-Token")}
      );
      
      model.find({user: req.get("X-Auth-Token")}, function (err, result) {
        if (!err) {
          res.send(result);
        } else {
          res.send(errMsg(err));
        }
      });
    };
  }

  //------------------------------
  // Create
  //
  function getCreateController(model) {
    return function (req, res) {
      logger.info(
        'creating %s', model.modelName,
         { model: model.modelName, user: req.get("X-Auth-Token"),
          content: req.body }
      );

      var m = new model(req.body);
      m.save(function (err) {
        if (!err) {
          res.send(m);
        } else {
          res.send(errMsg(err));
         }
       });
     };
  } 

  //------------------------------
  // Read
  //
  function getReadController(model) {
    return function (req, res) {
      logger.info(
        'reading %s', model.modelName,
        { model: model.modelName, user: req.get("X-Auth-Token"), 
           content: req.body }
      );

      model.findById(req.params.id, function (err, result) {
        if (!err) {
          res.send(result);
        } else {
          res.send(errMsg(err));
        }
      });
     };
  } 

  //------------------------------
  // Update
  //
  function getUpdateController(model) {
    return function (req, res) {
      logger.info(
        'updating %s', model.modelName,
        { model: model.modelName, user: req.get("X-Auth-Token"), 
          id: req.params.id }
      );

      model.findById(req.params.id, function (err, result) {
        var key;
        for (key in req.body) {
          result[key] = req.body[key];
        }
        result.save(function (err) {
          if (!err) {
            res.send(result);
          } else {
            res.send(errMsg(err));
          }
        });
      });
    };
  }

  //------------------------------
  // Delete
  //
  function getDeleteController(model) {
    return function (req, res) {
      logger.info(
        'deleting %s', model.modelName,
         { model: model.modelName, user: req.get("X-Auth-Token"), 
           id: req.params.id }
      );

      model.findById(req.params.id, function (err, result) {
        if (err) {
          res.send(errMsg(err));
        } else {
          result.remove();
          result.save(function (err) {
            if (!err) {
              res.send({});
            } else {
              res.send(errMsg(err));
            }
          });
        }
      });
    };
  }

  exports.initRoutesForModel = function (options) {
    var app = options.app,
      model = options.model,
      path,
      pathWithId;

    if (!app || !model) {
      return;
    }

    path = options.path || '/' + model.modelName.toLowerCase();
    pathWithId = path + '/:id';

    app.get(path, getListController(model));
    app.post(path, getCreateController(model));
    app.get(pathWithId, getReadController(model));
    app.put(pathWithId, getUpdateController(model));
    app.del(pathWithId, getDeleteController(model));
  };

}(exports));
