
# test/peekstream.coffee - Test for the PeekStream exports
do ->

  { expect, log, spy, TestStream } = require './helper' # infect Object.prototype
  { Stream } = require 'stream'

  STR = 'peek-a-boo!'
  DATA = new Buffer STR, 'ascii'
  SIZE = STR.length

  SRC = new TestStream
  DEST = new TestStream


  describe 'PeekStream module', ->
    before -> @PS = source 'peekstream'
    after -> delete @PS

    afterEach ->
      SRC.removeAllListeners()
      DEST.removeAllListeners()

    it 'should exports a class', ->
      @PS.should.be.a 'function'

    it 'should exports itself as PeekStream property alias', ->
      @PS.should.have.property 'PeekStream'
      @PS.PeekStream.should.be.a 'function'

    it 'should exports a DEFAULT_WINDOW_SIZE property', ->
      @PS.should.have.property 'DEFAULT_WINDOW_SIZE'
      @PS.DEFAULT_WINDOW_SIZE.should.be.a 'number'


    describe 'peek() function', ->
      before -> @peek = @PS.peek
      after -> delete @peek

      it 'should be exported', ->
        @peek.should.be.a 'function'

      it 'should throws if called without any argument', ->
        (=> @peek()).should.throw /source/

      it 'should throws if source does not looks like a Stream', ->
        (=> @peek true).should.throw /source/
        (=> @peek 123).should.throw /source/
        (=> @peek 'asdf').should.throw /source/
        (=> @peek { }).should.throw /source/

      it 'should throws if second argument does not looks like a Stream or number', ->
        (=> @peek SRC, true).should.throw /(destination|size)/i
        (=> @peek SRC, 'asdf').should.throw /(destination|size)/i
        (=> @peek SRC, { }).should.throw /(destination|size)/i

      it 'should returns an instance of PeekStream when given the source', ->
        (@peek SRC).should.be.instanceof @PS

      it 'should returns a PeekStream with default window size', ->
        (@peek SRC).size.should.eq @PS.DEFAULT_WINDOW_SIZE

      it 'should returns an instance of PeekStream when given source and window size', ->
        (@peek SRC, 1024).should.be.instanceof @PS

      it 'should returns a PeekStream with correct size when given source and window size', ->
        stream = @peek SRC, 123
        stream.should.be.instanceof @PS
        stream.size.should.eq 123

      it 'should returns instanceof PeekStream itself when given both source and destination', ->
        (@peek SRC, DEST).should.be.instanceof @PS

      it 'should returns a PeekStream with default window size when given both source and destination', ->
        stream = @peek SRC, DEST
        stream.should.be.instanceof @PS
        stream.size.should.eq @PS.DEFAULT_WINDOW_SIZE

      it 'should returns a PeekStream with correct size when all arguments is given', ->
        stream = @peek SRC, DEST, 123
        stream.should.be.instanceof @PS
        stream.size.should.eq 123

      it 'should pipes the source stream into the resulting PeekStream', ->
        spy SRC, 'pipe'
        stream = @peek SRC
        SRC.pipe.should.have.been.calledWith stream

      it 'should pipes the resulting PeekStream into the destination stream if it was given', (done) ->
        stream = @peek SRC, DEST

        DEST.once 'data', (data) ->
          data.should.eql DATA
          done()

        SRC.write DATA


    describe 'PeekStream instances created with peek()', ->
      beforeEach -> @ps = @PS.peek SRC, DEST, SIZE
      afterEach -> delete @ps

      it 'should be writable', ->
        @ps.writable.should.be.true
        @ps.should.respondTo 'write'

      it 'should be readable', ->
        @ps.readable.should.be.true

      it 'should be instance of Stream', ->
        @ps.should.be.instanceof Stream

      it 'should exports `source` stream property', ->
        @ps.should.have.property 'source'
        @ps.source.should.eq SRC

      it 'should exports `destination` stream property', ->
        @ps.should.have.property 'destination'
        @ps.destination.should.eq DEST

      it 'should exports a `window` property with configured size', ->
        @ps.should.have.property 'window'
        @ps.window.should.be.instanceof Buffer

      it 'should exports a zero-ed `window` buffer', ->
        zeroes = new Buffer @ps.window.length
        zeroes.fill 0
        @ps.window.should.be.eql zeroes

      it 'should emits `end` when source emits `end`', (done) ->
        DEST.once 'end', done
        SRC.end()


      # data test template
      writeExpectWindow = (chunk, action) -> (done) ->
        DEST.once 'data', =>
          action @ps.window, chunk
          done()

        SRC.write chunk

      it 'should collects and handles short strings correctly',
        writeExpectWindow (STR.slice 5), (window, chunk) ->
          chunk_ = window.slice window.length - chunk.length
          chunk_.should.eql new Buffer chunk

      it 'should copies string content when source emits string exactly the window size',
        writeExpectWindow STR, (window, chunk) ->
          window.toString().should.eq STR

      it 'should collects later parts of the string when source emits a large string',
        writeExpectWindow (STR + STR.slice 5), (window, chunk) ->
          part = chunk.slice chunk.length - STR.length
          window.toString().should.eq part

      it 'should collects bytes at the end of the buffer when source emits small data',
        writeExpectWindow (DATA.slice 5), (window, chunk) ->
          chunk_ = window.slice window.length - chunk.length
          chunk_.should.eql chunk

      it 'should copies the entire buffer content when source emits data exactly the window size',
        writeExpectWindow DATA, (window, chunk) ->
          window.should.eql DATA

      it 'should collects later parts of the buffer when source emits a large data',
        writeExpectWindow (Buffer.concat [DATA, DATA.slice 5]), (window, chunk) ->
          window.should.eql chunk.slice chunk.length - DATA.length

