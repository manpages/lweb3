
Server = require './transports/server/websocket'
helpers = require 'helpers'

express = require 'express'
Http = require 'http'

port = 8192

gimmeEnv = (callback) -> 
    app = express()
    app.configure ->
        app.set 'view engine', 'ejs'
        app.use express.favicon()
        app.use express.bodyParser()
        app.use express.methodOverride()
        app.use express.cookieParser()
        app.use app.router
        app.use (err, req, res, next) ->
            res.send 500, 'BOOOM!'

    http = Http.createServer app
    
    # I dont know why but I need to cycle ports, maybe http doesn't fully close, I don't know man.
    http.listen ++port 

    lwebs = new Server.webSocketServer
        http: http
        channelClass: -> true

    helpers.wait 200, callback

init: (test) ->
    gimmeEnv ->
        test.done()

