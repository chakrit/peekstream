
# src/peekstream.coffee - Peek stream classs
module.exports = do ->

  { Stream } = require 'stream'

  DEFAULT_WINDOW_SIZE = 1024


  return class PeekStream extends Stream
    @DEFAULT_WINDOW_SIZE: DEFAULT_WINDOW_SIZE
    @PeekStream: PeekStream

    @peek: (source, destination, size) ->
      unless source and source instanceof Stream
        throw new Error 'source stream missing or not a Stream'
      if destination
        if typeof destination is 'number'
          size = destination
          destination = null
        else unless destination instanceof Stream
          throw new Error 'destination is not a Stream (or size is not a number)'

      peek = source.pipe new PeekStream size
      peek.source = source

      if destination
        peek.pipe destination
        peek.destination = destination

      return peek


    constructor: (size) ->
      super()
      size ?= DEFAULT_WINDOW_SIZE

      @writable = true
      @readable = true
      @size = size
      @window = new Buffer size
      @window.fill 0

    write: (chunk) =>
      chunk = new Buffer chunk if typeof chunk is 'string'

      if chunk.length > @size
        @window = chunk.slice chunk.length - @size
      else if chunk.length is @size
        @window = new Buffer @size
        chunk.copy @window
      else # chunk.length < @size
        prev = @window.slice @window.length - (@size - chunk.length)
        @window = Buffer.concat [prev, chunk]

      @emit 'data', chunk

    end: =>
      @emit 'end'

