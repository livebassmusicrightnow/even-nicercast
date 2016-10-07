{expect}   = require "chai"
{spy}      = require "sinon"
express    = require "express"
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


