_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

core = require '../core'

query = core.core.extend4000
    end: () ->
        @get('unsubscribe')()
        @parent.endQuery @id

client = exports.client = core.protocol.extend4000 validator.ValidatedModel,
    validator:
        timeout: v().Default(3000).Number()

    defaults:
        name: 'queryClient'

    functions: ->
        query: _.bind @send, @
        
    initialize: ->
        @when 'parent', (parent) =>
            parent.subscribe { type: 'reply', id: String }, (msg) => @event msg    
            parent.on 'end', => @end()
            
    endQuery: (id) ->
        @parent.send { type: 'queryCancel', id: id }
    
    send: (msg, timeout, callback) ->
        if timeout.constructor is Function
            callback = timeout
            timeout = @get('timeout')

        @parent.send { type: 'query', id: id = helpers.uuid(10), payload: msg }
        unsubscribe = @subscribe { type: 'reply', id: id }, (msg) ->
            if msg.end then unsubscribe()
            callback msg.payload, msg.end
            
        #setTimeout unsubscribe, timeout
        return new query parent: @, id: id, unsubscribe: unsubscribe

reply = core.core.extend4000
    initialize: ->
        @unsubscribe = @parent.parent.subscribe type: 'queryCancel', id: @get('id'), => @cancel()
        @parent.on 'end', => @cancel()
        
    write: (msg) ->
#        if @ended then throw "this reply has ended"
        if @ended then return
        @parent.send msg, @id, false
        
    end: (msg) ->
        if not @ended then @ended = true else throw "this reply has ended"
        @unsubscribe()
        @parent.send msg, @id, true
        @trigger 'end'
        
    cancel: ->
        @ended = true
        @unsubscribe()
        @trigger 'cancel'
        @trigger 'end'

server = exports.server = core.protocol.extend4000
    defaults:
        name: 'queryServer'
    
    functions: ->
        onQuery: _.bind @subscribe, @

    initialize: ->
        @when 'parent', (parent) =>
            parent.subscribe { type: 'query', payload: true }, (msg) => @event msg.payload, msg.id
            parent.on 'end', => @end()

    send: (payload,id,end=false) ->
        msg = { type: 'reply', payload: payload, id: id }
        if end then msg.end = true
        @parent.send msg

    subscribe: (pattern=true ,callback) ->
        subscriptionMan.fancy::subscribe.call @, pattern, (payload, id) =>
            callback payload, new reply id: id, parent: @

