
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


    describe 'PeekStream instances', ->
      beforeEach -> @ps = @PS.peek SRC, DEST, SIZE
      afterEach -> delete @ps

      it 'should be writable', ->
        @ps.writable.should.be.true
        @ps.should.respondTo 'write'

      it 'should be readable', ->
        @ps.readable.should.be.true

      it 'should be instance of Stream', ->
        @ps.should.be.instanceof Stream

      it 'should exports a `window` property with configured size', ->
        @ps.should.have.property 'window'
        @ps.window.should.be.instanceof Buffer

      it 'should collects bytes at the end of the buffer when source emits small data', (done) ->
        chunk = DATA.slice 5

        DEST.once 'data', =>
          chunk_ = @ps.window.slice @ps.window.length - chunk.length
          chunk_.should.eql chunk
          done()

        SRC.write chunk

      it 'should copies the entire buffer content when source emits data exactly the window size', (done) ->
        DEST.once 'data', =>
          @ps.window.should.eql DATA
          done()

        SRC.write DATA

      it 'should collects later parts of the buffer when source emits a large data', (done) ->
        chunk = Buffer.concat [DATA, DATA.slice 5]

        DEST.once 'data', =>
          part = chunk.slice chunk.length - DATA.length
          @ps.window.should.eql part
          done()

        SRC.write chunk

      it 'should emits `end` when source emits `end`', (done) ->
        DEST.once 'end', done
        SRC.end()

