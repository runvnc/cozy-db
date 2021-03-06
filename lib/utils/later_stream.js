// Generated by CoffeeScript 1.9.1
(function() {
  var EventEmitter, LaterStream, drainStream,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  EventEmitter = require('events').EventEmitter;

  drainStream = function(stream, cb) {
    var body;
    body = '';
    stream.on('data', function(chunk) {
      if (cb) {
        return body += chunk;
      }
    });
    return stream.on('end', function() {
      return typeof cb === "function" ? cb(body) : void 0;
    });
  };

  module.exports = LaterStream = (function(superClass) {
    extend(LaterStream, superClass);

    function LaterStream(callback) {
      this.callback = callback;
      this.onReadableReady = bind(this.onReadableReady, this);
      this.pipe = bind(this.pipe, this);
      this.abort = bind(this.abort, this);
      this._onStreamingDone = bind(this._onStreamingDone, this);
      LaterStream.__super__.constructor.apply(this, arguments);
      this.pipeDests = [];
      this.aborted = false;
      this.callbackCalled = false;
      this.trueStream = null;
    }

    LaterStream.prototype._onStreamingDone = function(err) {
      if (!this.callbackCalled) {
        this.callbackCalled = true;
        return this.callback(err);
      }
    };

    LaterStream.prototype.abort = function() {
      if (this.trueStream) {
        return this.trueStream.req.abort();
      } else {
        return this.aborted = true;
      }
    };

    LaterStream.prototype.pipe = function(dest) {
      if (this.trueStream) {
        if (typeof this.pipefilter === "function") {
          this.pipefilter(this.trueStream, dest);
        }
        return this.trueStream.pipe(dest);
      } else {
        return this.pipeDests.push(dest);
      }
    };

    LaterStream.prototype.onReadableReady = function(error, stream) {
      var dest, i, len, ref, results;
      if (error) {
        drainStream(stream);
        return this._onStreamingDone(error);
      } else if ((stream != null ? stream.statusCode : void 0) !== 200) {
        return drainStream(stream, (function(_this) {
          return function(body) {
            error = new Error("Error code " + (stream != null ? stream.statusCode : void 0) + " - " + body);
            error.status = (stream != null ? stream.statusCode : void 0) || 500;
            return _this._onStreamingDone(error);
          };
        })(this));
      } else if (this.aborted) {
        stream.req.abort();
        return drainStream(stream);
      } else {
        this.trueStream = stream;
        this.emit('ready', this.trueStream);
        this.trueStream.on('error', this._onStreamingDone);
        this.trueStream.on('end', this._onStreamingDone);
        ref = this.pipeDests;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          dest = ref[i];
          if (typeof this.pipefilter === "function") {
            this.pipefilter(this.trueStream, dest);
          }
          results.push(this.trueStream.pipe(dest));
        }
        return results;
      }
    };

    return LaterStream;

  })(EventEmitter);

}).call(this);
