b = require 'backbone4000'

Core = b.Model.extend4000
    initialize: ->
        if parent = @get 'parent'  then @parent = parent
        @verbose = @get('verbose') or @parent?verbose or false
        
Channel = core.extend4000
    send: (msg) -> true
    receive: (callback) -> true

QueryClient = core.extend4000
    query: (msg,callback) -> true

QueryServer = core.extend4000
    subscribe: (pattern,callback) -> true

QueryBydirectional = core.extend4000 QueryClient, QueryServer

# has events like 'connect' and 'disconnect', provides client objects
Server = core.extend4000, subscriptionMan.basic
    validator: clientClass


        
