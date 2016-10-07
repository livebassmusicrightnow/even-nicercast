stream     = require "stream"
{expect}   = require "chai"
{spy}      = require "sinon"
Lame       = require "lame"
Server     = require "../src/encoding-server"
EvenNicer  = require "../src/even-nicercast"


describe "EncodingServer", ->
  server = null
  log    = ->

  beforeEach ->
    server = new Server {log}

  afterEach ->
    server = null

  describe "##constructor", ->
    it "should set defaults", ->
      defaults = ["log", "error", "port", "SAMPLE_SIZE", "CHANNELS", "SAMPLE_RATE"]
      expect(server[key]).to.exist for key in defaults

    it "should set options", ->
      options =
        log:     ->
        error:   ->
        port:  8001

        # 16-bit signed samples
        SAMPLE_SIZE: 16
        CHANNELS:    1
        SAMPLE_RATE: 88200

      server = new Server options

      expect(server[key]).to.equal value for key, value of options

    it "should create a Lame encoder", ->
      expect(server.encoder).to.be.an instanceof Lame.Encoder

    it "should create an EvenNicercast server", ->
      expect(server.server).to.be.an instanceof EvenNicer

    it "should pass options to the EvenNicercast server", ->
      expect(server.server.log).to.equal server.log
      expect(server.server.error).to.equal server.error
      expect(server.server.port).to.equal server.port
