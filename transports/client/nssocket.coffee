_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

nssocket = require 'nssocket'

_.extend exports, require('../nssocket')

nssocketClient = exports.nssocketClient = exports.nssocketChannel.extend4000
    defaults:
        name: 'nssocketClient'
    initialize: ->
        @set nssocket: @nssocket = nssocket.NsSocket reconnect: true, type: 'tcp4'
        @nssocket.connect @get('host'), @get('port')
        @nssocket.on 'start', => @trigger 'connect'
        @nssocket.on 'close', => @trigger 'disconnect'
    end: ->
        @nssocket.disconnect()
    
        