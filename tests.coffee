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

exports.ClientQuery = (test) ->
    query = require('protocol/query')
    
    gimmeEnv (lwebs, s, c,done) ->
        s.addProtocol query.server
        c.addProtocol query.client

        s.query.subscribe { test: Number }, (msg, reply) ->
            reply.write reply: msg.test + 3
            reply.end reply: msg.test + 2

        total = 0

        c.query.send { test: 7 }, (msg, end) ->
            total += msg.reply
            if end
                test.equal total, 19
                test.done()

