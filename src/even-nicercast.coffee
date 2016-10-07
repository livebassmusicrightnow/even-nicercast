http    = require "http"
stream  = require "stream"
express = require "express"
Icy     = require "icy"


NO_METADATA = new Buffer [0]


Icy.Writer::_inject = (write) ->
  if @disableMetadata
    @_passthrough Infinity
    return

  buffer = if @_queue.length
    @_queue.shift()
  else
    NO_METADATA
  write buffer

  # passthrough "metaint" bytes before injecting the next metabyte
  @_passthrough @metaint, @_inject


class EvenNicercast extends stream.PassThrough
  logPrefix: "(EvenNicercast)"

  @EncodingServer: require "./encoding-server"

  log:     console.log
  error:   console.error
  name:    "EvenNicercast"
  port:    8000
  metaint: 8192
  address: "127.0.0.1"
  buffer:  192 * 1024 * 30 # 192Kbps * 30s

  constructor: (o) ->
    @[key] = value for key, value of o
    @log "creating"
    super highWaterMark: @buffer

    @app or= express()
    @app.disable "x-powered-by"
    @setupRoutes()

  setupRoutes: ->
    @app.get "/",           @playlistEndpoint
    @app.get "/listen.m3u", @playlistEndpoint
    # audio endpoint
    @app.get "/listen",     @listener

  playlistEndpoint: (req, res) =>
    @log "serving playlist"
    # stream playlist (points to other endpoint)
    res.status 200
    res.set "Content-Type", "audio/x-mpegurl"
    res.send "http://#{@address}:#{@port}/listen"

  listener: (req, res, next) =>
    @log "listening"

    acceptsMetadata = req.headers["icy-metadata"] is 1

    # generate response header
    headers =
      "Content-Type": "audio/mpeg"
      "Connection":   "close"
    if acceptsMetadata
      @log "client accepts metadata"
      headers["icy-metaint"] = @metaint
    res.writeHead 200, headers

    # setup metadata transport
    prevMetadata = 0
    queueMetadata = (metadata = @metadata or @name) =>
      return unless acceptsMetadata and prevMetadata isnt metadata
      @log "queueing metadata"
      icyWriter.queueMetadata metadata
      prevMetadata = metadata

    @log "laying pipe"
    icyWriter = new Icy.Writer @metaint
    icyWriter.disableMetadata = true unless acceptsMetadata
    queueMetadata()
    icyWriter.pipe res, end: false
    @pipe icyWriter, end: false
    @on "data", queueMetadata

    req.connection.on "close", =>
      @log "closing connection, unpiping"
      @removeListener "data", queueMetadata
      @unpipe icyWriter

  setMetadata: (@metadata) -> @queueMetadata()

  start: (port = @port, callback = ->) ->
    @log "starting server on :#{port}"
    await @server = (http.createServer @app).listen port, defer()
    @port = @server.address().port
    callback @port

  stop: ->
    @log "stopping"
    try
      @server.close()
    catch err
      @error err


module.exports = EvenNicercast
