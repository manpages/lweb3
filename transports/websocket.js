// Generated by CoffeeScript 1.7.1
(function() {
  var Backbone, core, helpers, subscriptionMan, v, validator, webSocketChannel, _;

  _ = require('underscore');

  Backbone = require('backbone4000');

  helpers = require('helpers');

  subscriptionMan = require('subscriptionman2');

  validator = require('validator2-extras');

  v = validator.v;

  core = require('../core');

  webSocketChannel = exports.webSocketChannel = core.channel.extend4000({
    defaults: {
      name: 'webSocket'
    },
    initialize: function() {
      var realm;
      realm = {
        client: this
      };
      this.when('socketIo', (function(_this) {
        return function(socketIo) {
          var id;
          _this.socketIo = socketIo;
          if (id = _this.socketIo.id) {
            _this.set({
              name: id
            });
          }
          _this.socketIo.on('msg', function(msg) {
            _this.log("<", msg);
            return _this.event(msg, realm);
          });
          return _this.socketIo.on('disconnect', function() {
            _this.log("Lost Connection");
            return _this.end();
          });
        };
      })(this));
      return this.when('parent', (function(_this) {
        return function(parent) {
          parent.on('end', function() {
            return _this.end();
          });
          return _this.socketIo.on('msg', function(msg) {
            return parent.event(msg, realm);
          });
        };
      })(this));
    },
    send: function(msg) {
      this.log(">", msg);
      return this.socketIo.emit('msg', msg);
    },
    receive: function(pattern, callback) {
      return this.socketIo.on('msg', callback);
    }
  });

}).call(this);
