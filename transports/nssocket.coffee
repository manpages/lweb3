_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

core = require '../core'

nssocketChannel = exports.nssocketChannel = core.channel.extend4000
    defaults:
        name: 'nsSocket'
        
    initialize: ->
        realm = { client: @ }
        
        @when 'nssocket', (@nssocket) =>
            @nssocket.data 'msg', (msg) =>
                @log "<", msg
                @event msg, realm
                
            @nssocket.on 'start', => @trigger 'connect'
            @nssocket.on 'close', => @trigger 'disconnect'
            
        @when 'parent', (parent) =>
            #parent.on 'end', => @end()
            @nssocket.on 'msg', (msg) =>
                parent.event msg, realm

    send: (msg) ->
        @log ">", msg
        @nssocket.send 'msg', msg
        