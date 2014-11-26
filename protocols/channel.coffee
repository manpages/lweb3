_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

core = require '../core'
query = require './query'

manyBabies = (name) ->
    model = {}

    model.initialize = ->
        @[name + "s"] = {}

    model[name] = (instanceName) ->
        if instance = @[name + "s"][instanceName] then return instance
        instance = @[name + "s"][instanceName] = new @[name + "Class"] { parent: @, name: instanceName }
        instance.once 'end', => delete @[name + "s"][instanceName]
        return instance
    
    Backbone.Model.extend4000 {}


#channelInterface = core.manyBabies 'channel'
    

channelInterface = core.protocol.extend4000
    initialize: ->
        @channels = {}

    channel: (channelname) ->
        if channel = @channels[channelname] then return channel
        channel = @channels[channelname] = new @channelClass parent: @, name: channelname
        channel.once 'end', => delete @channels[channelname]
        return channel

    channelsubscribe: (channelname, pattern, callback) ->
        channel = @channel(channelname)
        if not callback and pattern.constructor is Function then callback = pattern; pattern = true
        channel.subscribe pattern, callback

    broadcast: (name,message) -> @channel(name).broadcast message



clientChannel = core.core.extend4000
    initialize: ->
        @name = @get 'name'

    join: (pattern, callback) ->
        if not callback then callback = pattern; pattern = undefined
        if @joined then return else @joined = true
            
        msg = joinChannel: @name
        if pattern then msg.pattern = pattern
            
        @query = @parent.parent.query msg, (msg) =>
            if msg.joined then callback undefined, @
            else @event msg
            
    part: ->
        @joined = false
        @query.end()


client = exports.client = channelInterface.extend4000
    defaults:
        name: 'channelClient'
        
    requires: [ query.client ]

    functions: ->
        channel: _.bind @channel, @
        channels: @channels
        join: _.bind @join, @

    channelClass: clientChannel
    join: (name,pattern,callback) -> @channel(name).join pattern, callback
    
serverChannel = core.core.extend4000
    initialize: ->
        @name = @get 'name'
        @clients = []
        
    join: (reply,pattern) ->
        reply.write { joined: true }
        
        @subscribe pattern or true, (msg) -> 
            reply.write msg

    broadcast: (msg) -> @event msg

    end: (msg) ->
        _.map @clients, (client) -> client.end msg
        @clients = []
        core.core::end.call @
                
server = exports.server = channelInterface.extend4000
    defaults:
        name: 'channelServer'
        
    requires: [ query.server ]

    functions: ->
        channel: _.bind @channel, @
        channels: @channels

    channelClass: serverChannel

    initialize: ->
        @when 'parent', (parent) =>
            parent.onQuery { joinChannel: String }, (msg,reply) =>
                @log "join request received for #" + msg.joinChannel
                @channel(msg.joinChannel).join reply, msg.pattern

            parent.on 'end', => @end()
