
# PEEK YOUR STREAMS

PEEKSTREAM is a simple filtering stream that collects and buffers data inside a configured window
as they're being streamed.

Useful for taking a peek at streaming logs or sampling data at intervals.

Also very useful for testing complex stream interactions.

```sh
npm install --save peekstream
```

```js
var peek = require('peekstream').peek;
```

# EXAMPLE

With your code like this:

```js
child.stdout.pipe(process.stdout);
```

You can peek into the stream by changing it to look like this (with child process piping sample):

```js
var ps = peek(child.stdout, process.stdout);

setInterval(function monitorStreamContent() {
  console.log("PIPE: " + ps.window.toString());
}, 1000);
```

# API

PeekStream inherits from Stream and supports basic read and write operation.

In addition, PeekStream exports a `window` property that is a `Buffer` of the data that has
been filtered.  When source stream emits `data` the data is appended to the end of the `window`
and any excess from the configured size is trimmed from the beginning of the buffer.

### require('peekstream').peek( SRC, [DEST], [SIZE] )

Creates and return a new PeekStream class instance configured to peek data coming from
`SRC`.

`SRC` stream is automatically piped through the returned PeekStream.

Additionallty, if `DEST` stream is specified, the returned PeekStream will be piped
through the destination stream automatically as well.

### new require('peekstream').PeekStream( [SIZE] )

Creates a `PeekStream` with specified windowing size (defaults to 1 kiB)

# LICENSE

BSD

# CONTRIBUTE / DEVELOP / EXTEND

Test with

```sh
make test
make tdd      # spins a loop
```

Compiles to JS with

```sh
make all
```

Something to do:

* Make PeekStream a two-way stream supporting cases where user wants to pipes the destination
  stream back into the source stream as well.
* Returns the destination stream so it is more compatible with how `pipe()` works
  (but then how do we returned the PeekStream instance?)

