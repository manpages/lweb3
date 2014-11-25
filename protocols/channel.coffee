_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

core = require '../core'
query = require './query'

channelInterface = core.protocol.extend4000
    initialize: ->
        @channels = {}

    channel: (channelname) ->
        if channel = @channels[channelname] then return channel
        channel = @channels[channelname] = new @ChannelClass parent: @, name: channelname
        channel.once 'del', => delete @channels[channelname]
        return channel

    channelsubscribe: (channelname, pattern, callback) ->
        channel = @channel(channelname)
        if not callback and pattern.constructor is Function then callback = pattern; pattern = true
        channel.subscribe pattern, callback

    broadcast: (channel,message) -> true
    join: (name,pattern,callback) -> @channel('name').join pattern,callback
    part: (channel,listener) -> true
    del: -> true      


clientChannel = core.core.extend4000
    name: 'channelClient'
    initialize: ->
        @name = @get 'name'

    join: (pattern, callback) ->
        if not callback then callback = pattern; pattern = undefined
        if @joined then return else @joined = true
            
        msg = join: @name
        if pattern then msg.pattern = pattern
            
        @query = @parent.parent.query.send msg, (msg) =>
            @event msg.payload
        if callback then @subscribe true, callback
            
    part: ->
        @joined = false
        @query.cancel()

client = exports.client = channelInterface.extend4000
    requires: [ query.client ]        
    
serverChannel = core.core.extend4000
    initialize: ->
        @name = @get 'name'
        @clients = []
        
    join: (reply,pattern) ->
        @subscribe pattern or true, (msg)
            reply.write msg

    part: (reply) ->
        true

    broadcast: (msg) ->
        @event msg

    end: (msg) ->
        _.map @clients, (client) -> client.end msg
        @clients = []
        @trigger 'end'
                
server = exports.server = channelInterface.extend4000
    name: 'channelServer'
    requires: [ query.server ]
    initialize: ->
        @when 'parent', (parent) =>
            parent.query.subscribe { join: String }, (msg,reply) =>
                @channel(msg.join).join reply, msg.pattern
                
    