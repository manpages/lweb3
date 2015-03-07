_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v
util = require 'util'

core = require '../core'

webSocketChannel = exports.webSocketChannel = core.channel.extend4000
    defaults:
        name: 'webSocket'
        
    initialize: ->
        realm = { client: @ }
        
        @when 'socketIo', (@socketIo) =>
            if id = @socketIo.id then @set name: id
            @socketIo.on 'msg', (msg) =>
                @log "<", msg
                @event msg, realm
                
            @socketIo.on 'disconnect', =>
                @trigger 'disconnect'
                @log "Lost Connection"
                @end()
                                    
        @when 'parent', (parent) =>
            parent.on 'end', => @end()
            @socketIo.on 'msg', (msg) =>
                parent.event msg, realm
        
    send: (msg) ->
        @log ">", msg
        try
            JSON.stringify(msg)
        catch err
            console.error "cannot stringify", util.inspect msg, depth: 4, colors: true
            throw err
            
        @socketIo.emit 'msg', msg
        

