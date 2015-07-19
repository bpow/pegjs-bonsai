# pegjs-bonsai

A plugin to produce a "well-pruned" tree from a [pegjs](http://pegjs.org) grammar

# Motivation

The idea is to be able to produce a useful object tree using as
little embedded javascript in the pegjs grammar as possible.
Maybe this is too much messy syntatic magic, I don't know...

# Transformations:

* Rules or expressions with existing actions will not be affected

* If labels are provided for members of a sequence, then the
  returned value, instead of being an array, will be an object
  with the labels being the keys.

  example: `temperature = degrees:$([0-9]+) unit:[CF]`, when
  parsing `32F`, will return `{"degrees": "32", "unit": "F" }`

* By default, key-value pairs with values that are `null` or `undefined`
  are not included in the output (this behavior can be changed with
  the bonsaiPlugin.keepUndefined option).

  example: `temperature = degrees:$([0-9]+) unit:[CF]?`, when
  parsing `32`, will return `{"degrees": "32" }` (but leaving
  out units is a very bad idea...)

* If there is only one element in a sequence with a label, and
  if that label is `_`, then a single value (rather than an object)
  will be returned, and the other values ignored:

  example: `contained = "[" _:[a-z]+ "]"`, when parsing
  `[bracketed]` will return `"bracketed"`

# Use

1. `npm install pegjs pegjs-bonsai`
2. In your javascript file, use something like this:

```javascript
var PEG = require('pegjs')
var bonsai = require('pegjs-bonsai')

var parser = PEG.buildParser('temperature = degrees:$([0-9]+) unit:[CF]',
                             { plugins: [bonsai], bonsaiPlugin: { keepUndefined: true } });

console.log(parser.parse('32F');
```

# Options

Some configuration is available, passed to PEG.buildParser in the
`options.bonsaiPlugin` object:

* `showTransformed` (for debugging purposes) if `true`, writes the
  transformed AST of the grammar to `console.log` after the
  transformation pass is complete

* `keepUndefined` if `true`, does not eliminate key-value pairs where
   the value is `null` or `undefined`.
