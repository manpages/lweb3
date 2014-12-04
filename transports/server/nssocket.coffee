_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

nssocket = require 'nssocket'

core = require '../../core'

_.extend exports, require('../nssocket')

nssocketServer = exports.nssocketServer = core.server.extend4000 validator.ValidatedModel,
    validator:
        port: Number

    defaults:
        name: 'nssocketServer'
                                
    initialize: ->
        port = @get 'port'
        idcounter = 0
        
        channelClass = exports.nssocketChannel.extend4000 (@get('channelClass') or @channelClass or {})
        @nssocket = nssocket.createServer (clientSocket) =>
            name = ++idcounter
            @log 'connection received', idcounter
            channel = new channelClass parent: @, nssocket: clientSocket, name: name

            channel.on 'change:name', (model,newname) =>
                delete @clients[name]
                @clients[newname] = model                
            @clients[name] = channel

            
            @trigger 'connect', channel
        @nssocket.listen @get 'port'
        #@socketIo.on 'disconnect', (socketIoClient) =>
            #delete @clients[socketioClient.id]
            #@trigger 'disconnect', channel
            
    end: ->
        @nssocket.disconnect()
        core.core::end.call @
