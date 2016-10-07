stream     = require "stream"
{expect}   = require "chai"
{spy}      = require "sinon"
express    = require "express"
Icy        = require "icy"
Server     = require "../src/even-nicercast"


describe "EvenNicercast", ->
  server = null
  log    = ->

  beforeEach ->
    server = new Server {log}

  afterEach ->
    server = null

  describe "##constructor", ->
    it "should set defaults", ->
      defaults = ["log", "error", "name", "port", "metaint", "address", "buffer", "mount"]
      expect(server[key]).to.exist for key in defaults

    it "should set options", ->
      options =
        log:     ->
        error:   ->
        name:    "test"
        port:    8001
        metaint: 8193
        address: "127.0.0.2"
        buffer:  192 * 1024 * 31 # 192Kbps * 30s
        mount:  "/mounttest"

      server = new Server options

      expect(server[key]).to.equal value for key, value of options

    it "should create an express app", ->
      expect(server.app).to.be.an instanceof express

    it "should accept an express app", ->
      app    = express()
      server = new Server {log, app}
      expect(server.app).to.equal app

    it "should call setupRoutes()", ->
      bond   = spy Server::, "setupRoutes"
      server = new Server {log}
      bond.restore()
      expect(bond.called).to.be.true

  describe "##playlistEndpoint", ->
    res = null

    beforeEach ->
      res =
        status: ->
        set: ->
        send: ->

    afterEach ->
      res = null

    it "should set status 200", (done) ->
      await
        res.status = defer status
        server.playlistEndpoint null, res

      expect(status).to.equal 200
      done()

    it "should set contenttype", (done) ->
      await
        res.set = defer header, value
        server.playlistEndpoint null, res

      expect(header).to.equal "Content-Type"
      expect(value).to.equal "audio/x-mpegurl"
      done()

    it "should send the stream URI", (done) ->
      {address, port, mount} = server

      await
        res.send = defer uri
        server.playlistEndpoint null, res

      expect(uri).to.equal "http://#{address}:#{port}/#{mount}"
      done()

  describe "listener", ->
    req = null
    res = null

    beforeEach ->
      res =
        writeHead: ->
        on: ->
        once: ->
        emit: ->
      req =
        headers: {}
        connection: on: ->

    afterEach ->
      req = null
      res = null

    it "should write statusCode and headers", (done) ->
      defaults =
        "Content-Type": "audio/mpeg"
        "Connection":   "close"

      await
        res.writeHead = defer statusCode, headers
        server.listener req, res

      expect(statusCode).to.eql 200
      expect(headers).to.eql defaults
      done()

    it "should write icy-metaint header", (done) ->
      defaults =
        "Content-Type": "audio/mpeg"
        "Connection":   "close"
        "icy-metaint":  8192

      req.headers = "icy-metadata": 1

      await
        res.writeHead = defer statusCode, headers
        server.listener req, res

      expect(headers).to.eql defaults
      done()

    it "should pipe data to the response", (done) ->
      res           = new stream.PassThrough
      res.writeHead = ->
      reader        = new Icy.Reader server.metaint

      server.listener req, res
      res.pipe reader

      reader.once "metadata", done
      data = new Buffer 8192
      await
        server.once "data", defer piped
        server.write data

      expect(piped).to.equal data
      done()

    it "should unpipe from the response when connection closes", (done) ->
      res           = new stream.PassThrough
      res.writeHead = ->
      req.connection = new stream.PassThrough

      server.listener req, res

      await
        res.once "unpipe", defer source
        req.connection.emit "close"

      expect(source).to.equal server
      done()

    it "should pipe data through an Icy.Writer", (done) ->
      res           = new stream.PassThrough
      res.writeHead = ->
      req.headers   = "icy-metadata": 1
      reader        = new Icy.Reader server.metaint

      server.listener req, res
      res.pipe reader

      await
        reader.once "metadata", defer metadata
        server.write new Buffer 8192

      expect(metadata.toString()).to.match new RegExp "StreamTitle='#{server.name}'"
      expect(server.listenerCount "data").to.equal 2
      done()

    it "should remove data listener and unpipe from Icy.Writer when connection closes", (done) ->
      res           = new stream.PassThrough
      res.writeHead = ->
      req.headers   = "icy-metadata": 1
      req.connection = new stream.PassThrough
      reader        = new Icy.Reader server.metaint

      server.listener req, res
      res.pipe reader

      reader.once "metadata", done
      req.connection.emit "close"
      server.write new Buffer 8192

      expect(server.listenerCount "data").to.equal 0
      done()

  describe "##setMetadata", ->
    it "should set the metadata", ->
      metadata = "testmeta"
      server.setMetadata metadata
      expect(server.metadata).to.equal metadata
