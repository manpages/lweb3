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
    send: (msg) -> throw "I'm a default channel, cant send msg",msg
    stop: (callback) -> true

queryClient = exports.queryClient = core.extend4000
    query: (msg,callback) -> true

queryServer = exports.queryServer =core.extend4000
    subscribe: (pattern,callback) -> true

queryBydirectional = exports.queryBydirectional = core.extend4000 queryClient, queryServer

# has events like 'connect' and 'disconnect', provides client objects
server = exports.server = core.extend4000
    stop: -> true


        
