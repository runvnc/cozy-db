// Generated by CoffeeScript 1.9.1
(function() {
  var CozyBackedModel, FormData, LaterStream, Model, _old, checkError, client, cozyBinaryAdapter, cozyDataAdapter, cozyFileAdapter, cozyIndexAdapter, cozyRequestsAdapter, errorMaker, util,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  client = require('./utils/client');

  Model = require('./model');

  util = require('util');

  LaterStream = require('./utils/later_stream');

  checkError = function(error, response, body, code, callback) {
    return callback(errorMaker(error, response, body, code));
  };

  errorMaker = function(error, response, body, expectedCode) {
    var err, msgStatus;
    if (error) {
      return error;
    } else if (response.statusCode !== expectedCode) {
      msgStatus = "expected: " + expectedCode + ", got: " + response.statusCode;
      err = new Error(msgStatus + " -- " + body.error + " -- " + body.reason);
      err.status = response.statusCode;
      return err;
    } else {
      return null;
    }
  };

  FormData = require('request-json-light/node_modules/form-data');

  _old = FormData.prototype.pipe;

  FormData.prototype.pipe = function(request) {
    var length;
    length = request.getHeader('Content-Length');
    if (!length) {
      request.removeHeader('Content-Length');
    }
    return _old.apply(this, arguments);
  };

  cozyDataAdapter = {
    exists: function(id, callback) {
      return client.get("data/exist/" + id + "/", function(error, response, body) {
        if (error) {
          return callback(error);
        } else if ((body == null) || (body.exist == null)) {
          return callback(new Error("Data system returned invalid data."));
        } else {
          return callback(null, body.exist);
        }
      });
    },
    find: function(id, callback) {
      return client.get("data/" + id + "/", function(error, response, body) {
        if (error) {
          return callback(error);
        } else if (response.statusCode === 404) {
          return callback(null, null);
        } else {
          return callback(null, body);
        }
      });
    },
    create: function(attributes, callback) {
      var path;
      path = "data/";
      if (attributes.id != null) {
        path += attributes.id + "/";
        delete attributes.id;
        return callback(new Error('cant create an object with a set id'));
      }
      return client.post(path, attributes, function(error, response, body) {
        if (error) {
          return callback(error);
        } else if (response.statusCode === 409) {
          return callback(new Error("This document already exists"));
        } else if (response.statusCode !== 201) {
          return callback(new Error("Server error occured."));
        } else {
          body.id = body._id;
          return callback(null, body);
        }
      });
    },
    save: function(id, data, callback) {
      return client.put("data/" + id + "/", data, function(error, response, body) {
        if (error) {
          return callback(error);
        } else if (response.statusCode === 404) {
          return callback(new Error("Document " + id + " not found"));
        } else if (response.statusCode !== 200) {
          return callback(new Error("Server error occured."));
        } else {
          return callback(null, body);
        }
      });
    },
    updateAttributes: function(id, data, callback) {
      return client.put("data/merge/" + id + "/", data, function(error, response, body) {
        if (error) {
          return callback(error);
        } else if (response.statusCode === 404) {
          return callback(new Error("Document " + id + " not found"));
        } else if (response.statusCode !== 200) {
          return callback(new Error("Server error occured."));
        } else {
          return callback(null, body);
        }
      });
    },
    destroy: function(id, callback) {
      return client.del("data/" + id + "/", function(error, response, body) {
        if (error) {
          return callback(error);
        } else if (response.statusCode === 404) {
          return callback(new Error("Document " + id + " not found"));
        } else if (response.statusCode !== 204) {
          return callback(new Error("Server error occured."));
        } else {
          return callback(null);
        }
      });
    }
  };

  cozyIndexAdapter = {
    search: function(query, callback) {
      var data, docType;
      docType = this.getDocType();
      data = {
        query: query
      };
      return client.post("data/search/" + docType, data, function(error, response, body) {
        var results;
        if (error) {
          return callback(error);
        } else if (response.statusCode !== 200) {
          return callback(new Error(util.inspect(body)));
        } else {
          results = body.rows;
          return callback(null, results);
        }
      });
    },
    index: function(id, fields, callback) {
      var cb;
      cb = function(error, response, body) {
        if (error) {
          return callback(error);
        } else if (response.statusCode !== 200) {
          return callback(new Error(util.inspect(body)));
        } else {
          return callback(null);
        }
      };
      return client.post("data/index/" + id, {
        fields: fields
      }, cb, false);
    }
  };

  cozyFileAdapter = {
    attach: function(id, path, data, callback) {
      var ref, urlPath;
      if (typeof data === "function") {
        ref = [null, data], data = ref[0], callback = ref[1];
      }
      urlPath = "data/" + id + "/attachments/";
      return client.sendFile(urlPath, path, data, function(error, response, body) {
        try {
          body = JSON.parse(body);
        } catch (_error) {}
        return checkError(error, response, body, 201, callback);
      });
    },
    get: function(id, filename, callback) {
      var output, urlPath;
      urlPath = "data/" + id + "/attachments/" + (encodeURIComponent(filename));
      output = new LaterStream(callback);
      client.saveFileAsStream(urlPath, output.onReadableReady);
      return output;
    },
    remove: function(id, filename, callback) {
      var urlPath;
      urlPath = "data/" + id + "/attachments/" + (encodeURIComponent(filename));
      return client.del(urlPath, function(error, response, body) {
        return checkError(error, response, body, 204, callback);
      });
    }
  };

  cozyBinaryAdapter = {
    attach: function(id, path, data, callback) {
      var ref, urlPath;
      if (typeof data === "function") {
        ref = [null, data], data = ref[0], callback = ref[1];
      }
      urlPath = "data/" + id + "/binaries/";
      return client.sendFile(urlPath, path, data, function(error, response, body) {
        try {
          body = JSON.parse(body);
        } catch (_error) {}
        return checkError(error, response, body, 201, callback);
      });
    },
    get: function(id, filename, callback) {
      var output, urlPath;
      urlPath = "data/" + id + "/binaries/" + (encodeURIComponent(filename));
      output = new LaterStream(callback);
      client.saveFileAsStream(urlPath, output.onReadableReady);
      return output;
    },
    remove: function(id, filename, callback) {
      var urlPath;
      urlPath = "data/" + id + "/binaries/" + (encodeURIComponent(filename));
      return client.del(urlPath, function(error, response, body) {
        return checkError(error, response, body, 204, callback);
      });
    }
  };

  cozyRequestsAdapter = {
    define: function(name, request, callback) {
      var docType, map, path, reduce, view;
      docType = this.getDocType();
      map = request.map, reduce = request.reduce;
      view = {
        reduce: reduce != null ? reduce.toString() : void 0,
        map: "function (doc) {\n  if (doc.docType.toLowerCase() === \"" + docType + "\") {\n    filter = " + (map.toString()) + ";\n    filter(doc);\n  }\n}"
      };
      path = "request/" + docType + "/" + (name.toLowerCase()) + "/";
      return client.put(path, view, function(error, response, body) {
        return checkError(error, response, body, 200, callback);
      });
    },
    run: function(name, params, callback) {
      var docType, path, ref;
      if (typeof params === "function") {
        ref = [{}, params], params = ref[0], callback = ref[1];
      }
      docType = this.getDocType();
      path = "request/" + docType + "/" + (name.toLowerCase()) + "/";
      return client.post(path, params, function(error, response, body) {
        if (error) {
          return callback(error);
        } else if (response.statusCode !== 200) {
          return callback(new Error(util.inspect(body)));
        } else {
          return callback(null, body);
        }
      });
    },
    remove: function(name, callback) {
      var docType, path;
      docType = this.getDocType();
      path = "request/" + docType + "/" + (name.toLowerCase()) + "/";
      return client.del(path, function(error, response, body) {
        return checkError(error, response, body, 204, callback);
      });
    },
    requestDestroy: function(name, params, callback) {
      var docType, path, ref;
      if (typeof params === "function") {
        ref = [{}, params], params = ref[0], callback = ref[1];
      }
      if (params.limit == null) {
        params.limit = 100;
      }
      docType = this.getDocType();
      path = "request/" + docType + "/" + (name.toLowerCase()) + "/destroy/";
      return client.put(path, params, function(error, response, body) {
        return checkError(error, response, body, 204, callback);
      });
    }
  };

  module.exports = CozyBackedModel = (function(superClass) {
    extend(CozyBackedModel, superClass);

    function CozyBackedModel() {
      return CozyBackedModel.__super__.constructor.apply(this, arguments);
    }

    CozyBackedModel.adapter = cozyDataAdapter;

    CozyBackedModel.indexAdapter = cozyIndexAdapter;

    CozyBackedModel.fileAdapter = cozyFileAdapter;

    CozyBackedModel.binaryAdapter = cozyBinaryAdapter;

    CozyBackedModel.requestsAdapter = cozyRequestsAdapter;

    CozyBackedModel.cast = function() {
      if (!this.__addedToSchema) {
        this.__addedToSchema = true;
        this.schema._id = String;
        this.schema._attachments = Object;
        this.schema._rev = String;
        this.schema.id = String;
        this.schema.docType = String;
        this.schema.binaries = Object;
      }
      return CozyBackedModel.__super__.constructor.cast.apply(this, arguments);
    };

    CozyBackedModel.convertBinary = function(id, callback) {
      var url;
      url = "data/" + id + "/binaries/convert";
      return client.get(url, function(error, response, body) {
        if (error) {
          return callback(error);
        } else if (response.statusCode === 404) {
          return callback(new Error("Document not found"));
        } else if (response.statusCode !== 200) {
          return callback(new Error("Server error occured."));
        } else {
          return callback();
        }
      });
    };

    CozyBackedModel.prototype.convertBinary = function(cb) {
      return this.constructor.convertBinary.call(this.constructor, this.id, cb);
    };

    return CozyBackedModel;

  })(Model);

}).call(this);
