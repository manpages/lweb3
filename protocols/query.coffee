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
            parent.subscribe { type: 'reply', id: String }, (msg) =>
                if msg.end then @log 'query completed', msg.id, msg.payload
                else @log 'got query reply', msg.id, msg.payload
                
                @event msg
            parent.on 'end', => @end()
            
    endQuery: (id) ->
        @log 'canceling query', id
        @parent.send { type: 'queryCancel', id: id }
    
    send: (msg, timeout, callback) ->
        if timeout?.constructor is Function
            callback = timeout
            timeout = @get('timeout')

        @parent.send { type: 'query', id: id = helpers.uuid(10), payload: msg }
        @log 'querying', id, msg
        
        unsubscribe = @subscribe { type: 'reply', id: id }, (msg) =>
            if msg.end then unsubscribe()
            helpers.cbc callback, msg.payload, msg.end
            
        #setTimeout unsubscribe, timeout
        return new query parent: @, id: id, unsubscribe: unsubscribe

reply = core.core.extend4000
    initialize: ->
        @set name: @get 'id'
        @unsubscribe = @parent.parent.subscribe type: 'queryCancel', id: @get('id'), =>
            @log 'got query cancel request'
            @cancel()
        @parent.on 'end', => @cancel()
        
    write: (msg) ->
#        if @ended then throw "this reply has ended"
        if @ended then return false
        @parent.send msg, @id, false
        return true
        
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


serverServer = exports.serverServer = core.protocol.extend4000
    defaults:
        name: 'queryServerServer'
        
    functions: ->
        onQuery: _.bind @subscribe, @

    subscribe: (pattern,callback) ->
        subscriptionMan.fancy::subscribe.call @, pattern, (payload, id, realm) =>
            callback payload, new reply(id: id, parent: realm.client.queryServer), realm

    initialize: ->
        @when 'parent', (parent) =>
            parent.on 'connect', (client) =>
                client.addProtocol new server verbose: @verbose, core: @
                
            _.map parent.clients, (client,id) =>
                client.addProtocol new server verbose: @verbose, core: @
                                                           
    channel: (channel) ->
        channel.addProtocol new server verbose: @get 'verbose'


server = exports.server = core.protocol.extend4000
    defaults:
        name: 'queryServer'
    
    functions: ->
        onQuery: _.bind @subscribe, @

    initialize: ->
        @when 'core', (core) => @core = core
            
        @when 'parent', (parent) =>
            parent.subscribe { type: 'query', payload: true }, (msg, realm) =>
                @log 'got query',msg.id,msg.payload
                @event msg.payload, msg.id, realm
                @core?.event msg.payload, msg.id, realm
                
            parent.on 'end', => @end()

    send: (payload,id,end=false) ->
        msg = { type: 'reply', payload: payload, id: id }
        if end then msg.end = true; @log 'ending query',id,payload
        else @log 'replying to query',id,payload
        @parent.send msg

    subscribe: (pattern=true, callback) ->
        subscriptionMan.fancy::subscribe.call @, pattern, (payload, id, realm) =>
            callback payload, new reply(id: id, parent: @), realm



