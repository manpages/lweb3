_ = require 'underscore'
Backbone = require 'backbone4000'
helpers = require 'helpers'

subscriptionMan = require('subscriptionman2')
validator = require('validator2-extras'); v = validator.v

core = require '../core'

client = exports.client = core.protocol.extend4000
    query: (msg,callback) -> true

server = exports.server = core.protocol.extend4000
    subscribe: (pattern,callback) -> true
