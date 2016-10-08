stream        = require "stream"
EvenNicercast = require "./even-nicercast"


class EncodingServer extends stream.PassThrough
  logPrefix: "(EvenNicercast:EncodingServer)"

  log:   console.log
  error: console.error
  port:  8000

  # 16-bit signed samples
  SAMPLE_SIZE: 16
  CHANNELS:    2
  SAMPLE_RATE: 44100

  constructor: (o) ->
    @[key] = value for key, value of o
    @log "creating"
    super()


    # setup encoder
    Lame     = require "lame"
    @encoder = new Lame.Encoder
      channels:   @CHANNELS
      bitDepth:   @SAMPLE_SIZE
      sampleRate: @SAMPLE_RATE

    @server = new EvenNicercast
      log:   @log
      error: @error
      port:  @port

    @pipe @encoder
    @encoder.pipe @server

  setMetadata: -> @server.setMetadata()
  start: -> @server.start()
  stop: -> @server.stop()


module.exports = EncodingServer
