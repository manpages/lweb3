_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

io = require 'socket.io-browserify'

_.extend exports, require('../websocket')

webSocketClient = exports.webSocketClient = exports.webSocketChannel.extend4000
    initialize: -> @socketIo = io.connect @get('host') or "http://" + window?location?host
    stop: (cb) -> @socketIo.disconnect(); cb()