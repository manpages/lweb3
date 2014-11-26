// Generated by CoffeeScript 1.7.1
(function() {
  var Backbone, channel, core, helpers, protocol, server, subscriptionMan, v, validator, _;

  _ = require('underscore');

  Backbone = require('backbone4000');

  helpers = require('helpers');

  subscriptionMan = require('subscriptionman2');

  validator = require('validator2-extras');

  v = validator.v;

  core = exports.core = subscriptionMan.fancy.extend4000({
    initialize: function() {
      this.verbose = this.get('verbose') || false;
      return this.when('parent', (function(_this) {
        return function(parent) {
          _this.parent = parent;
          return _this.verbose = _this.get('verbose') || (typeof _this.parent === "function" ? _this.parent(verbose || false) : void 0);
        };
      })(this));
    }
  });

  channel = exports.channel = core.extend4000({
    initialize: function() {
      return this.protocols = {};
    },
    send: function(msg) {
      throw "I'm a default channel, cant send msg " + msg;
    },
    stop: function(callback) {
      throw "I'm a default channel, cant stop me";
    },
    hasProtocol: function(protocol) {
      return Boolean(this[protocol.name] || this[typeof protocol.prototype === "function" ? protocol.prototype(name) : void 0]);
    },
    addProtocol: function(protocol) {
      if (!protocol.name) {
        throw "what is this?";
      }
      if (this.hasProtocol(protocol)) {
        throw "this protocol (" + protocol.name + ") is already active on channel";
      }
      _.map(protocol.requires, (function(_this) {
        return function(protocol) {
          if (!_this.hasProtocol(protocol)) {
            return _this.addProtocol(new protocol());
          }
        };
      })(this));
      this[protocol.name] = protocol;
      protocol.set({
        parent: this
      });
      if (protocol.functions) {
        return _.extend(this, protocol.functions());
      }
    }
  });

  protocol = exports.protocol = core.extend4000({
    requires: []
  });

  server = exports.server = core.extend4000({
    stop: function() {
      return true;
    }
  });

}).call(this);
