stream     = require "stream"
{expect}   = require "chai"
{spy}      = require "sinon"
Lame       = require "lame"
Server     = require "../src/encoding-server"
EvenNicer  = require "../src/even-nicercast"


describe "EncodingServer", ->
  server = null
  log    = ->
  port   = 7999
  bitRate = 96

  beforeEach ->
    server = new Server {port, log}, {bitRate}

  afterEach ->
    server = null

  describe "##constructor", ->
    it "should set defaults", ->
      defaults = ["channels", "bitDepth", "sampleRate", "bitRate"]
      expect(server.defaults[key]).to.exist for key in defaults

    it "should set options", ->
      options =
        # 16-bit signed samples
        bitDepth:    16
        channels:    1
        sampleRate:  88200
        bitRate:     bitRate

      server = new Server null, options

      expect(server[key]).to.equal value for key, value of options

    it "should be a Lame encoder", ->
      expect(server).to.be.an instanceof Lame.Encoder

    it "should create an EvenNicercast server", ->
      expect(server.server).to.be.an instanceof EvenNicer

    it "should pass options to the EvenNicercast server", ->
      expect(server.server.log).to.equal log
      expect(server.server.port).to.equal port
      expect(server.server.buffer).to.equal bitRate * 125 * 30

    it "should receive errors from the EvenNicercast server", (done) ->
      err = new Error "test"

      await
        server.once "error", defer _err
        server.server.emit "error", err

      expect(_err).to.equal err
      done()
