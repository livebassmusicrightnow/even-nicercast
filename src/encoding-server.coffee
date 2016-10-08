stream        = require "stream"
EvenNicercast = require "./even-nicercast"


class EncodingServer extends stream.PassThrough
  logPrefix: "(EvenNicercast:EncodingServer)"

  log:   console.log
  error: console.error

  # 16-bit signed samples
  SAMPLE_SIZE: 16
  CHANNELS:    2
  SAMPLE_RATE: 44100


  constructor: (o = {}, encodingOptions) ->
    super

    @[key] = value for key, value of encodingOptions
    @log   = o.log   if o.log
    @error = o.error if o.error

    @server = new EvenNicercast o

    # setup encoder
    Lame     = require "lame"
    @encoder = new Lame.Encoder
      channels:   @CHANNELS
      bitDepth:   @SAMPLE_SIZE
      sampleRate: @SAMPLE_RATE

    @pipe @encoder
    @encoder.pipe @server

  setMetadata: -> @server.setMetadata()
  start: -> @server.start()
  stop: -> @server.stop()


module.exports = EncodingServer
