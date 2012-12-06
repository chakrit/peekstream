
# test/helper.coffee - Test initializer / helpers
module.exports = do ->

  _ = require 'underscore'
  chai = require 'chai'
  sinon = require 'sinon'
  { Stream } = require 'stream'

  SRC_FOLDER = unless process.env.COVER
    "../src/"
  else
    "../lib-cov/"

  chai.use require 'sinon-chai'
  chai.should() # infect Object.prototype

  return _.extend global or exports or this,
    source: (path) -> require "#{SRC_FOLDER}#{path}"
    log: console.log

    expect: chai.expect

    # function testing stuff
    sinon: sinon
    spy: _.bind sinon.spy, sinon
    stub: _.bind sinon.stub, sinon

    TestStream: class TestStream extends Stream
      constructor: ->
        @readable = true
        @writable = true

      write: (data, encoding) ->
        @emit 'data', data, encoding

      end: ->
        @emit 'end'

