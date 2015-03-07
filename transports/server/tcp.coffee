_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

net = require 'net'

core = require '../../core'

_.extend exports, require('../tcp')

tcpServer = exports.tcpServer = core.server.extend4000 validator.ValidatedModel,
    validator:
        port: Number

    defaults:
        name: 'tcpServer'
                                
    initialize: ->
        port = @get 'port'
        idcounter = 0
        
        channelClass = exports.tcpSocketChannel.extend4000 (@get('channelClass') or @channelClass or {})
        @server = net.createServer
            port: port,
            (socket) =>
                name = ++idcounter
                @log 'connection received', idcounter

                channel = new channelClass parent: @, socket: socket, name: name
                channel.on 'change:name', (model,newname) =>
                    delete @clients[name]
                    @clients[newname] = model
                    @trigger 'connect:' + newname, model
                    
                @clients[name] = channel
                @trigger 'connect:' + name, channel
                @trigger 'connect', channel

                channel.on 'disconnect', =>
                    @log 'connection lost', idcounter
                    delete @clients[channel.get('name')]
                    @trigger 'disconnect', channel

        @server.listen port, '0.0.0.0'
                    
    end: ->
        @server.close()
        core.core::end.call @
