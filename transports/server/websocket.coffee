_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

io = require 'socket.io'

core = require '../../core'

_.extend exports, websocket = require './websocket'


webSocketServer = core.server.extend4000 validator.ValidatedModel,
    validator:
        http: 'Instance'
        channelClass: 'Function'
        
    initialize: ->
        http = @get 'http'
        channelClass = webSocketChannel.extend4000 @get('channelClass')
        @socketIo = io.listen http, log: false

        @socketIo.on 'conection', (socketIoClient) =>
            @trigger 'connect', new channelClass socketIo: socketIoClient

            