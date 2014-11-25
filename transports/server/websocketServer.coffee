_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

SubscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

io = require 'socket.io'

_.extend exports, websocket = require './websocket'

                                        
webSocketServer = Server.extend4000, validator.ValidatedModel
    validator:
        http: 'Instance'
        channelClass: 'Function'
        
    initialize: ->
        http = @get 'http'
        channelClass = webSocketChannel.extend4000 @get('channelClass')
        @socketIo = io.listen http, log: false

        @socketIo.on 'conection', (socketIoClient) =>
            @trigger 'connect', new channelClass socketIo: socketIoClient

            