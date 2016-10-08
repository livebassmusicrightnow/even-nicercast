util          = require "util"
EvenNicercast = require "./even-nicercast"
extend        = util._extend


try
  Lame     = require "lame"
catch e
  console.error "lame not installed"


if Lame
  class EncodingServer extends Lame.Encoder
    logPrefix: "(EvenNicercast:EncodingServer)"

    defaults: # 16-bit signed samples
      channels:   2
      bitDepth:   16
      sampleRate: 44100

      bitRate:    128

    constructor: (o = {}, eo = {}) ->
      encodingOptions = extend {}, @defaults
      encodingOptions = extend encodingOptions, eo

      super encodingOptions

      o.buffer or= @bitRate * 125 * 30 # Kbps * 30s
      @server = new EvenNicercast o
      @pipe @server
      @server.on  "error", @passError

    passError: (err) => @emit "error", err

    setMetadata: -> @server.setMetadata()
    start: -> @server.start()
    stop: -> @server.stop()


module.exports = EncodingServer
