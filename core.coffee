_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

core = exports.core = subscriptionMan.fancy.extend4000
    initialize: ->
        @verbose = @get('verbose') or false
        @when 'parent', (@parent) => @verbose = @get('verbose') or @parent?verbose or false
    
channel = exports.channel = core.extend4000
    send: (msg) -> throw "I'm a default channel, cant send msg #{msg}"
    stop: (callback) -> true

    hasProtocol: (protocol) -> Boolean @[protocol.name] or @[protocol::name]    
    addProtocol: (protocol) ->
        if @hasProtocol protocol then throw "this protocol (#{protocol.name}) is already active on channel"
        @[protocol.name] = protocol
        protocol.set parent: @

        _.map protocol.requires, (protocol) -> if not @hasProtocol protocol then @addProtocol new protocol()
        
protocol = exports.protocol = core.extend4000 {}

# has events like 'connect' and 'disconnect', provides client objects
server = exports.server = core.extend4000
    stop: -> true


        
