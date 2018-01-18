
# process.env.DEBUG = "*,-ficent"
elog = require './src'
debug = require('debug') 'spec'


file = require './src/file-writer'
file_FormatML = file.formatML



vt = require './src/vt-writer'
vt_FormatML = vt.formatML


err = new Error 'JUST'
fn = (x)-> x * x

plan = 'test'
ml = ['testimony',
  {
    lv: 9,
    about: 'BT'
    debug_ns: 'test'
    when: '2017-08-09T08:44:02.078Z'
  },
  'test', ['variable', {
    ref: 1
  }, '#a'],
  ['variable', {
    ref: 2
  }, '#b'],
  'tes2', ['variable', {
    ref: 'test'
  }, '#plan'],
  'test', ['variable', {
    ref: 'x'
  }, '#x'],
  ['variable', {
    ref: 'yy'
  }, '#y'],
  'tes2', ['variable', {
    ref: 'test'
  }, '#plan'],
  ['id', '@who-do-it:D8S2']
  ['id', '@Writer']
]

ml_old = [ 'log_stmt',
  { pid: 11824, when: '2017-08-09T08:44:02.078Z', lv: 9 },
  [ 'who', 'my-name', 'x' ],
  'type',
  'for',
  [ 'who', 'your-name', 'Y' ],
  'a text',
  'that',
  [ 'text', { color: 'red' }, 'emphasized', 'red' ]
  'with'
  [ 'unkown', 'unkown data' ]
  ['dump', {name: 'a'}, 'null' ]
  ['dump', {name: 'b'}, 'undefined' ]
  ['dump', {name: 'c'}, 'true' ]
  ['dump', {name: 'Error', type: 'error'}, err.stack.toString() ]
  ['dump', {name: 'fn', type: 'function'}, fn.toString() ]
]

# str = file_FormatML ml

console.log vt_FormatML ml_old
console.log '-------------------------------------------'
console.log vt_FormatML ml
