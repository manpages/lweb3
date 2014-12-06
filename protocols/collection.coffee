_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

core = require '../core'
channel = require './channel'
query = require './query'

collectionInterface = core.core.extend4000 {}

collectionProtocol = core.protocol.extend4000 core.motherShip('collection'),
    functions: ->
        collection: _.bind @collection, @
        collections: @collections
        
queryToCallback = (callback) ->
    (msg,end) ->
        #if not end then throw "this query is supposed to be translated to callback but I got multiple responses"
        callback msg.err, msg.data
        
clientCollection = exports.clientCollection = collectionInterface.extend4000

    query: (msg,callback) ->
        msg.collection = @get 'name'
        @parent.parent.query msg, callback

    create: (data,callback) ->
        @log 'create',data
        @query { create: data }, queryToCallback callback

    remove: (pattern,callback) -> 
        @query { remove: pattern }, queryToCallback callback

    findOne: (pattern,callback) ->
        @query { findOne: pattern }, queryToCallback callback

    update: (pattern,data,callback) ->
        @query { update: pattern, data: data }, queryToCallback callback

    fcall: (name, args, pattern, callback) ->
        @query { call: name, args: args, pattern: pattern }, queryToCallback callback

    find: (pattern,limits,callback,callbackDone) ->
        query = { find: pattern }
        if limits then query.limits = limits
            
        @query query, (msg,end) ->
            if end then return helpers.cbc callbackDone, null, end
            callback null, msg

client = exports.client = collectionProtocol.extend4000
    defaults:
        name: 'collectionClient'
        collectionClass: clientCollection
    requires: [ channel.client ]
    
serverCollection = exports.serverCollection = collectionInterface.extend4000
    initialize: ->
        c = @get 'collection'
        
        @set name: name =  c.get('name')
        
        @when 'parent', (parent) =>
            parent.parent.onQuery { collection: name }, (msg, res, realm={}) =>
                @event msg, res, realm
                @core?.event msg.payload, msg.id, realm
                
        callbackToRes = (res) -> (err,data) ->
            if err?.name then err = err.name
            res.end err: err, data: data

        @subscribe { create: Object }, (msg, res, realm) ->
            c.createModel msg.create, realm, callbackToRes(res)
            
        @subscribe { remove: Object }, (msg, res, realm) ->
            c.removeModel msg.remove, realm, callbackToRes(res)
            
        @subscribe { update: Object, data: Object }, (msg, res, realm) ->
            c.updateModel msg.update, msg.data, realm, callbackToRes(res)
            
        @subscribe { findOne: Object }, (msg, res, realm) ->
            c.findModel msg.findOne, (err,model) ->
                if err then return callbackToRes(res)(err)
                model.render realm, callbackToRes(res)
            
        @subscribe { call: String, pattern: Object, args: v().default([]).Array() }, (msg, res, realm) ->
            c.fcall msg.call, msg.args, msg.pattern, realm, callbackToRes(res), (err,data) ->
                if err?.name then err = err.name
                res.write err: err, data: data
                            
        @subscribe { find: Object }, (msg, res, realm) =>
            bucket = new helpers.parallelBucket()
            endCb = bucket.cb()
                        
            c.findModels msg.find, msg.limits or {}, ((err,model) ->
                bucketCallback = bucket.cb()
                model.render realm, (err,data) ->
                    if not err then res.write data
                    bucketCallback()), ((err,data) -> endCb())
                    
            bucket.done (err,data) -> res.end()    

server = exports.server = collectionProtocol.extend4000
    defaults:
        name: 'collectionServer'
        collectionClass: serverCollection
        
    requires: [ channel.server ]


serverServer = exports.serverServer = collectionProtocol.extend4000
    defaults:
        name: 'collectionServerServer'
        collectionClass: serverCollection
        
    requires: [ query.serverServer ]

    initialize: ->
        @when 'parent', (parent) =>
            parent.on 'connect', (client) =>
                client.addProtocol new server verbose: @verbose, core: @
                
            _.map parent.clients, (client,id) =>
                client.addProtocol new server verbose: @verbose, core: @
