// Generated by CoffeeScript 1.7.1
(function() {
  var Backbone, channelInterface, client, clientChannel, core, helpers, motherShip, query, server, serverChannel, subscriptionMan, v, validator, _;

  _ = require('underscore');

  Backbone = require('backbone4000');

  helpers = require('helpers');

  subscriptionMan = require('subscriptionman2');

  validator = require('validator2-extras');

  v = validator.v;

  core = require('../core');

  query = require('./query');

  motherShip = function(name) {
    var model;
    model = {};
    model.initialize = function() {
      return this[name + "s"] = {};
    };
    model[name] = function(instanceName) {
      var instance;
      if (instance = this[name + "s"][instanceName]) {
        return instance;
      }
      instance = this[name + "s"][instanceName] = new this[name + "Class"]({
        parent: this,
        name: instanceName
      });
      instance.once('end', (function(_this) {
        return function() {
          return delete _this[name + "s"][instanceName];
        };
      })(this));
      return instance;
    };
    return Backbone.Model.extend4000(model);
  };

  channelInterface = core.protocol.extend4000(motherShip('channel'), {
    channelsubscribe: function(channelname, pattern, callback) {
      var channel;
      channel = this.channel(channelname);
      if (!callback && pattern.constructor === Function) {
        callback = pattern;
        pattern = true;
      }
      return channel.subscribe(pattern, callback);
    },
    broadcast: function(name, message) {
      return this.channel(name).broadcast(message);
    }
  });

  clientChannel = core.core.extend4000({
    initialize: function() {
      return this.name = this.get('name');
    },
    join: function(pattern, callback) {
      var msg;
      if (!callback) {
        callback = pattern;
        pattern = void 0;
      }
      if (this.joined) {
        return;
      } else {
        this.joined = true;
      }
      msg = {
        joinChannel: this.name
      };
      if (pattern) {
        msg.pattern = pattern;
      }
      return this.query = this.parent.parent.query(msg, (function(_this) {
        return function(msg) {
          if (msg.joined) {
            return callback(void 0, _this);
          } else {
            return _this.event(msg);
          }
        };
      })(this));
    },
    part: function() {
      this.joined = false;
      return this.query.end();
    }
  });

  client = exports.client = channelInterface.extend4000({
    defaults: {
      name: 'channelClient'
    },
    requires: [query.client],
    functions: function() {
      return {
        channel: _.bind(this.channel, this),
        channels: this.channels,
        join: _.bind(this.join, this)
      };
    },
    channelClass: clientChannel,
    join: function(name, pattern, callback) {
      return this.channel(name).join(pattern, callback);
    }
  });

  serverChannel = core.core.extend4000({
    initialize: function() {
      this.name = this.get('name');
      return this.clients = [];
    },
    join: function(reply, pattern) {
      reply.write({
        joined: true
      });
      return this.subscribe(pattern || true, function(msg) {
        return reply.write(msg);
      });
    },
    broadcast: function(msg) {
      return this.event(msg);
    },
    end: function(msg) {
      _.map(this.clients, function(client) {
        return client.end(msg);
      });
      this.clients = [];
      return core.core.prototype.end.call(this);
    }
  });

  server = exports.server = channelInterface.extend4000({
    defaults: {
      name: 'channelServer'
    },
    requires: [query.server],
    functions: function() {
      return {
        channel: _.bind(this.channel, this),
        channels: this.channels
      };
    },
    channelClass: serverChannel,
    initialize: function() {
      return this.when('parent', (function(_this) {
        return function(parent) {
          parent.onQuery({
            joinChannel: String
          }, function(msg, reply) {
            _this.log("join request received for #" + msg.joinChannel);
            return _this.channel(msg.joinChannel).join(reply, msg.pattern);
          });
          return parent.on('end', function() {
            return _this.end();
          });
        };
      })(this));
    }
  });

}).call(this);
