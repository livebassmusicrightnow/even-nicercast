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

    it "should set status 200", ->
      await
        res.status = defer status
        server.playlistEndpoint null, res

      expect(status).to.equal 200

    it "should set contenttype", ->
      await
        res.set = defer header, value
        server.playlistEndpoint null, res

      expect(header).to.equal "Content-Type"
      expect(value).to.equal "audio/x-mpegurl"

    it "should send the stream URI", ->
      {address, port, mount} = server

      await
        res.send = defer uri
        server.playlistEndpoint null, res

      expect(uri).to.equal "http://#{address}:#{port}/#{mount}"

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

    it "should write statusCode and headers", ->
      defaults =
        "Content-Type": "audio/mpeg"
        "Connection":   "close"

      await
        res.writeHead = defer statusCode, headers
        server.listener req, res

      expect(statusCode).to.eql 200
      expect(headers).to.eql defaults

    it "should write icy-metaint header", ->
      defaults =
        "Content-Type": "audio/mpeg"
        "Connection":   "close"
        "icy-metaint":  8192

      req.headers = "icy-metadata": 1

      await
        res.writeHead = defer statusCode, headers
        server.listener req, res

      expect(headers).to.eql defaults

    it "should pipe data through an Icy.Writer", ->
      res           = new stream.PassThrough decodeStrings: false
      res.writeHead = ->
      req.headers   = "icy-metadata": 1
      reader        = new Icy.Reader server.metaint

      server.listener req, res
      res.pipe reader

      await
        reader.once "metadata", defer metadata
        server.write "test"

      expect(metadata).to.equal server.name