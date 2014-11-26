_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

core = require '../core'
channel = require './channel'

collectionInterface = core.core.extend4000, {}

collectionProtocol = core.protocol.extend4000, {}

clientCollection = collectionInterface.extend4000
    initialize: ->
        @name = @get 'name'

client = exports.client = collectionProtocol.extend4000
    name: 'collectionClient'
    requires: [ channel.client ]
    collectionClass: clientCollection
    
serverCollection = collectionInterface.extend4000
    initialize: ->
        @name = @get 'name'

server = exports.server = collectionProtocol.extend4000
    name: 'collectionServer'
    requires: [ channel.server ]
    collectionClass: serverCollection

