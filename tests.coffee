validator = require('validator2-extras'); v = validator.v

Server = require './transports/server/websocket'
Client = require './transports/client/websocket'


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

    lwebs = new Server.webSocketServer http: http
    lwebc = new Client.webSocketClient host: 'http://localhost:' + port
    
    lwebs.on 'connect', (s) -> callback lwebs, s, lwebc, (test) ->
        lwebs.stop -> lwebc.stop -> test.done()

exports.init = (test) ->
    gimmeEnv ->
        test.done()
        
exports.ClientSend = (test) ->
    gimmeEnv (lwebs, s, c,done) ->
        s.subscribe { test: true}, (msg) ->
            done test            
        c.send { test: 1 }



exports.ServerSend = (test) ->
    gimmeEnv (lwebs, s, c,done) ->
        c.subscribe { test: true}, (msg) ->
            done test            
        s.send { test: 1 }
