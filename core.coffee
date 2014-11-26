_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

startTime = new Date().getTime()

core = exports.core = subscriptionMan.fancy.extend4000
    initialize: ->
        @verbose = @get('verbose') or false
        #console.log "initializing",@name(), @verbose
        @when 'parent', (@parent) =>
            @verbose = @get('verbose') or @parent?.verbose or false
            
    name: ->
        if @parent then @parent.name() + "-" + @get('name')
        else @get('name') or 'noname'
        
    end: ->
        if @ended then return else @ended = true
        @log 'ending'
        @trigger 'end'
            
    log: (args...) ->
        if @verbose then console.log.apply console, [].concat( '::', new Date().getTime() - startTime, @name(), args)
            

channel = exports.channel = core.extend4000
    initialize: ->
        @protocols = {}
        
    send: (msg) -> throw "I'm a default channel, cant send msg #{msg}"

    hasProtocol: (protocol) ->
        if typeof protocol is 'function' then return Boolean @[protocol::?defaults?.name]
        if typeof protocol is 'object' then return Boolean @[protocol.name()]
        throw "what is this?"
        
    addProtocol: (protocol) ->
        if not name = protocol.name() then throw "what is this?"
        if @hasProtocol protocol then throw "this protocol (#{protocol.name()}) is already active on channel"        
        _.map protocol.requires, (dependancyProtocol) =>
            if not @hasProtocol dependancyProtocol then @addProtocol new dependancyProtocol()
          
        @[name] = protocol
        protocol.set parent: @
        
        if protocol.functions then _.extend @, protocol.functions()
        
protocol = exports.protocol = core.extend4000
    requires: []

# has events like 'connect' and 'disconnect', provides client objects
server = exports.server = core.extend4000
    stop: -> true
