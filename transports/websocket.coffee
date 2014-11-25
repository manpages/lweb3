_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

io = require 'socket.io'

core = require '../core'

webSocketChannel = exports.webSocketChannel = core.channel.extend4000
    initialize: ->
        @when 'socketIo', (@socketIo) =>
            @socketIo.on 'msg', (msg) =>
                console.log "<",msg
                @event msg
        
    send: (msg) ->
        console.log ">",msg
        @socketIo.emit 'msg', msg
        
    receive: (pattern, callback) ->
        @socketIo.on 'msg', callback
