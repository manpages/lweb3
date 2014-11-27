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
        if typeof protocol is 'function' then return Boolean @[protocol::defaults.name]
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



# Just a common pattern,
# this is for model that hosts bunch of models of a same type with names and references to parent
# it automatically instantiates new ones when they are mentioned
#
# used for channelserver.. for example channelServer.channel('bla') automatically instantiates channelClass with name bla
#
# also used for collection server or client
# 
motherShip = exports.motherShip = (name) ->
    model = {}

    model.initialize = ->
        @[name + "s"] = {}

    model[name] = (instanceName, attributes={}) ->
        if instance = @[name + "s"][instanceName] then return instance

        instanceClass = @get(name + "Class")
        if not instanceClass then throw "I don't have " + name + "Class defined"
        instance = @[name + "s"][instanceName] = new instanceClass _.extend { parent: @, name: instanceName }, attributes
        instance.once 'end', => delete @[name + "s"][instanceName]
        @trigger 'new' + helpers.capitalize(name), instance
        return instance
    
    Backbone.Model.extend4000 model
