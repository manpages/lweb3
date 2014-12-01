_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

io = require 'socket.io'

core = require '../../core'

_.extend exports, require('../websocket')

webSocketServer = exports.webSocketServer = core.server.extend4000 validator.ValidatedModel,
    validator:
        http: 'Instance'

    defaults:
        name: 'webSocketServer'
                                
    initialize: ->
        @http = @get 'http'
        @clients = {}
        
        channelClass = exports.webSocketChannel.extend4000 (@get('channelClass') or {})
        @socketIo = io.listen @http, log: false

        @socketIo.on 'connection', (socketIoClient) =>
            @log 'connection received', socketIoClient.id
            channel = new channelClass parent: @, socketIo: socketIoClient, id: id = socketIoClient.id
            @clients[id] = channel
            @trigger 'connect', channel

        @socketIo.on 'disconnect', (socketIoClient) =>
            delete @clients[socketioClient.id]
            @trigger 'disconnect', channel
            
    end: ->
        @http.close()
        core.core::end.call @

        