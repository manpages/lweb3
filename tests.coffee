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

    lwebs = new Server.webSocketServer http: http, verbose: true
    lwebc = new Client.webSocketClient host: 'http://localhost:' + port, verbose: true

    
    lwebs.on 'connect', (s) -> callback lwebs, s, lwebc, (test) ->
        lwebc.end()
        helpers.wait 30, -> 
            lwebs.end()
            helpers.wait 10, -> test.done()

exports.init = (test) ->
    gimmeEnv (lwebs, s, c, done) ->
        done test
        
exports.ClientSend = (test) ->
    gimmeEnv (lwebs, s, c, done) ->
        s.subscribe { test: true}, (msg) ->
            console.log 'done test!'
            done test            
        c.send { test: 1 }

exports.ServerSend = (test) ->
    gimmeEnv (lwebs, s, c, done) ->
        c.subscribe { test: true}, (msg) ->
            done test

        s.send { test: 1 }

exports.QueryProtocol = (test) ->
    query = require('./protocols/query')
    
    gimmeEnv (lwebs, s, c,done) ->
        s.addProtocol new query.server()
        c.addProtocol new query.client()

        s.queryServer.subscribe { test: Number }, (msg, reply) ->
            reply.write reply: msg.test + 3
            helpers.wait 100, -> reply.end reply: msg.test + 2

        total = 0

        c.queryClient.send { test: 7 }, (msg, end) ->
            total += msg.reply
            if end
                test.equal total, 19
                test.done()


exports.QueryProtocolCancel = (test) ->
    query = require('./protocols/query')
    
    gimmeEnv (lwebs, s, c,done) ->
        s.addProtocol new query.server()
        c.addProtocol new query.client()

        s.queryServer.subscribe { test: Number }, (msg, reply) ->
            reply.write reply: msg.test + 3
            helpers.wait 100, -> test.equal reply.ended, true

        total = 0

        query = c.queryClient.send { test: 7 }, (msg, end) ->
            query.end()
            total += msg.reply
            
            c.subscribe { type: 'reply', end: true }, (msg) ->
                test.ok false, "didnt cancel"
                
            helpers.wait 200, -> test.done()
        

exports.ChannelProtocol = (test) ->
    channel = require('./protocols/channel')

    gimmeEnv (lwebs, s, c, done) ->
        s.addProtocol new channel.server( verbose: true )
        c.addProtocol new channel.client( verbose: true )

        c.join 'testchannel', (err,channel) ->
            if err then return test.fail()

            test.equal channel, c.channel('testchannel')

            channel.subscribe { test: 1 }, (msg) ->
                test.equal msg.bla, 3, "bla isn't 3. BLA ISN'T 3 MAN!!!"
                channel.part()
                helpers.wait 50, -> 
                    s.channels.testchannel.broadcast { test: 2, bla: 4 }
                    helpers.wait 50, ->
                        done test

            s.channelServer.channel('testchannel').broadcast { test: 1, bla: 3 }


exports.CollectionProtocol = (test) ->
    collection = require('./protocols/collection')
    gimmeEnv (lwebs,s,c,done) ->
        s.addProtocol new collection.server verbose: true, backend: new Mongo(db: db)
        c.addProtocol new collection.client verbose: true

        s.defineCollection 'bla'
        c.defineCollection 'bla'

        c.collection.bla.findModels {},{}, (err,model) ->
            console.log model


class Test
    done: ->
        console.log 'test done'
#        process.exit(0)
    equal: (x,y) ->
        if x isnt y then throw "not equal"
            


#exports.ChannelProtocol new Test()