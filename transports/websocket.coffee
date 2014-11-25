
webSocketChannel = Channel.extend4000, validator.ValidatedModel
    validator:
        socketIo: 'Instance'
        
    initialize: ->
        @socketIo = @get 'socketIo'
        
    send: (msg) -> 
        @socketIo.emit 'msg',msg
        
    receive: (callback) ->
        @socketIo.on 'msg', callback
