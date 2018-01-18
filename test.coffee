
# process.env.DEBUG = "*,-ficent"
elog = require './src'
debug = require('debug') 'spec'




err = new Error 'JUST'
fn = (x)-> x * x

plan = 'test'
ml = [ 'testimony',
  { dump: true },
  'test',
  [ 'variable', { name: 'a', ref: 1 }, '#a' ],
  [ 'variable', { name: 'b', ref: 2 }, '#b' ],
  [ 'variable',
    { name: 'dt', ref: null },
    '#dt' ],
  ['id', '@who-do-it']
  ['id', '@Writer']
  [ 'variable', { name: 'fn', ref: null }, '#fn' ],
  [ 'dump', { name: 'a', type: 'number' }, '1' ],
  [ 'dump', { name: 'b', type: 'number' }, '2' ],
  [ 'dump',
    { name: 'dt', type: 'date' },
    '2018-01-18T09:04:20.641Z' ],
  [ 'dump',
    { name: 'fn', type: 'function' },
    'function (a) {\n        return alert(1);\n      }' ]
  ['dump', {name: 'Error', type: 'error'}, err.stack.toString() ]
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

file = require './src/file-writer'
file_FormatML = file.formatML
vt = require './src/vt-writer'
vt_FormatML = vt.formatML

console.log file_FormatML ml_old
console.log '-------------------------------------------'
console.log file_FormatML ml
