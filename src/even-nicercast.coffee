http    = require "http"
stream  = require "stream"
express = require "express"
Icy     = require "icy"


class EvenNicercast extends stream.PassThrough
  logPrefix: "(EvenNicercast)"

  @EncodingServer: require "./encoding-server"

  log:     console.log
  error:   console.error
  name:    "EvenNicercast"
  port:    8000
  metaint: 8192
  address: "127.0.0.1"
  advertise: "localhost"
  buffer:  192 * 1024 * 30 # 192Kbps * 30s
  mount:  "/listen"

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
    @app.get @mount,     @listener

  playlistEndpoint: (req, res) =>
    @log "serving playlist"
    # stream playlist (points to other endpoint)
    res.status 200
    res.set "Content-Type", "audio/x-mpegurl"
    res.send "http://#{@advertise}:#{@port}/#{@mount}"

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
    if acceptsMetadata
      prevMetadata  = 0
      icyWriter     = new Icy.Writer @metaint
      queueMetadata = =>
        metadata = @metadata or @name
        return unless metadata isnt prevMetadata
        metadata = metadata.toString() if metadata instanceof Buffer
        @log "queueing metadata", metadata
        icyWriter.queueMetadata metadata
        prevMetadata = metadata

      @log "laying pipe"
      queueMetadata()
      icyWriter.pipe res, end: false
      @pipe icyWriter, end: false
      @on "data", queueMetadata

      req.connection.on "close", =>
        @log "closing connection, unpiping"
        @removeListener "data", queueMetadata
        @unpipe icyWriter

    else
      @log "laying pipe"
      @pipe res, end: false

      req.connection.on "close", =>
        @log "closing connection, unpiping"
        @unpipe res

  setMetadata: (@metadata) ->

  start: (callback = ->) ->
    @log "starting server on :#{@port}"
    await @server = (http.createServer @app).listen @port, @address, defer()
    callback()

  stop: (callback = ->) ->
    @log "stopping"
    await @server.close defer err
    @error err if err
    callback err


module.exports = EvenNicercast
