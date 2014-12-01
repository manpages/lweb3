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
        channelClass = exports.webSocketChannel.extend4000 (@get('channelClass') or {})
        @socketIo = io.listen @http, log: false

        @socketIo.on 'connection', (socketIoClient) =>
            @log 'connection received', socketIoClient.id
            @trigger 'connect', new channelClass parent: @, socketIo: socketIoClient
                                    
    end: ->
        @http.close()
        core.core::end.call @



