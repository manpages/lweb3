_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

core = require '../core'

client = exports.client = core.protocol.extend4000
    name: 'queryClient'
    send: (msg, callback) ->
        @parent.send { type: 'query', id: id = helpers.uuid(10), payload: msg }
        unsubscribe = @parent.subscribe { type: 'reply', id: id }, (msg) ->
            if msg.end then unsubscribe()
            callback msg.payload, msg.end

reply = core.protocol.extend4000
    write: (msg) -> @parent.send msg, @id, false
    end: (msg) -> @parent.send msg, @id, true

server = exports.server = core.protocol.extend4000
    name: 'queryServer'

    initialize: ->
        @when 'parent', (parent) =>
            console.log "initializing queryserver"
            parent.subscribe { type: 'query', payload: true }, (msg) => @event msg.payload, msg.id

    send: (payload,id,end=false) ->
        msg = { type: 'reply', payload: payload, id: id }
        if end then msg.end = true
        @parent.send msg

    subscribe: (pattern=true ,callback) ->
        subscriptionMan.fancy::subscribe.call @, pattern, (payload, id) =>
            callback payload, new reply id: id, parent: @

