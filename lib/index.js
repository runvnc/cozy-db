// Generated by CoffeeScript 1.9.1
(function() {
  var Controller, CozyModel, Model, NoSchema, api, defaultRequests, emit, log,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  log = require('printit')({
    date: true,
    prefix: 'Cozy DB'
  });

  ({
    Public: the(Model(constructor))
  });

  module.exports.Model = Model = require('./model');

  module.exports.CozyModel = CozyModel = require('./cozymodel');

  module.exports.SimpleController = Controller = require('./controller');

  NoSchema = require('./utils/type_checking').NoSchema;

  module.exports.NoSchema = NoSchema;

  emit = function() {};

  module.exports.defaultRequests = defaultRequests = {
    all: function(doc) {
      return emit(doc._id, doc);
    },
    tags: function(doc) {
      var j, len, ref, results, tag;
      ref = doc.tags || [];
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        tag = ref[j];
        results.push(emit(tag, doc));
      }
      return results;
    },
    by: function(field) {
      return (function(doc) {
        return emit(doc.FIELD, doc);
      }).toString().replace('FIELD', field);
    }
  };

  module.exports.getModel = function(name, schema) {
    var ClassFromGetModel, klass;
    klass = ClassFromGetModel = (function(superClass) {
      extend(ClassFromGetModel, superClass);

      function ClassFromGetModel() {
        return ClassFromGetModel.__super__.constructor.apply(this, arguments);
      }

      ClassFromGetModel.schema = schema;

      return ClassFromGetModel;

    })(CozyModel);
    klass.displayName = klass.name = name;
    klass.toString = function() {
      return name + "Constructor";
    };
    klass.docType = name;
    return klass;
  };

  module.exports.api = api = require('./api');

  module.exports.configure = function(options, app, callback) {
    var Pouch, PouchModel, docType, err, model, modelPath, requestDefinition, requestDefinitions, requestName, requests, requestsToSave, step;
    if (callback == null) {
      callback = function() {};
    }
    if (typeof options === 'string') {
      options = {
        root: options
      };
    }
    if (process.env.RUN_STANDALONE || options.db || options.dbName) {
      try {
        Pouch = require('pouchdb');
        PouchModel = require('./pouchmodel');
        module.exports.CozyModel = CozyModel = PouchModel;
        if (options.db) {
          PouchModel.db = options.db;
        } else {
          if (options.dbName == null) {
            options.dbName = process.env.POUCHDB_NAME || 'cozy';
          }
          PouchModel.db = new Pouch(options.dbName);
        }
      } catch (_error) {
        err = _error;
        console.log("Fail to init pouchdb, did you install it ?");
        console.log(err);
        return callback(err);
      }
    }
    modelPath = options.root + "/server/models/";
    api.setupModels();
    try {
      requests = require(modelPath + "requests");
    } catch (_error) {
      err = _error;
      log.raw(err);
      log.error("Failed to load requests file.");
      return callback(err);
    }
    requestsToSave = [];
    for (docType in requests) {
      requestDefinitions = requests[docType];
      model = require(modelPath + docType);
      for (requestName in requestDefinitions) {
        requestDefinition = requestDefinitions[requestName];
        requestsToSave.push({
          model: model,
          requestName: requestName,
          requestDefinition: requestDefinition
        });
      }
    }
    requestsToSave.push({
      model: api.CozyInstance,
      optional: true,
      requestName: 'all',
      requestDefinition: defaultRequests.all
    });
    requestsToSave.push({
      model: api.CozyUser,
      optional: true,
      requestName: 'all',
      requestDefinition: defaultRequests.all
    });
    step = function(i) {
      var optional, ref;
      if (i == null) {
        i = 0;
      }
      ref = requestsToSave[i], model = ref.model, requestName = ref.requestName, requestDefinition = ref.requestDefinition, optional = ref.optional;
      log.info((model.getDocType()) + " - " + requestName + " request creation...");
      return model.defineRequest(requestName, requestDefinition, function(err) {
        if (err && !optional) {
          log.raw(err);
          log.error("A request creation failed, abandon.");
          return callback(err);
        } else if (i + 1 >= requestsToSave.length) {
          log.info("requests creation completed");
          return callback(null);
        } else {
          log.info("succeeded");
          return step(i + 1);
        }
      });
    };
    return step(0);
  };

}).call(this);