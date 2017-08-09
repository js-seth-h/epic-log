
process.env.DEBUG = "*,-ficent"
elog = require '../src'
debug = require('debug') 'spec'


file = require '../src/file-writer'
file_FormatML = file.formatML



vt = require '../src/vt-writer'
vt_FormatML = vt.formatML


describe 'spec', ()->    
  it 'default ', (done)->    

    err = new Error 'JUST'
    fn = (x)-> x * x 

    ml = [ 'log_stmt',
      { pid: 11824, when: '2017-08-09T08:44:02.078Z', lv: 9 },
      [ 'who', 'my-name', 'x' ],
      'type',
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

    str = file_FormatML ml

    debug str

    console.log vt_FormatML ml



    done()