_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

io = require 'socket.io-browserify'

_.extend exports, require('../websocket')

webSocketClient = exports.webSocketClient = exports.webSocketChannel.extend4000
    defaults:
        name: 'webSocketClient'
        
    initialize: ->
        @set socketIo: @socketIo = io.connect @get('host') or "http://" + window?location?host
        @socketIo.on 'connect', => @trigger 'connect'
    end: ->
        @socketIo.disconnect()
    
        