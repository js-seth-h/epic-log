process.env.DEBUG = "*,-ficent"
elog = require '../src'
debug = require('debug') 'spec'
describe 'spec', ()->    
  it 'default ', (done)->    
    elog.configure
      sections : [
          name: 'ALPHA'
          level: 5
          enable: on
          log_life: 7 
      ]
      writer: 
        console : true
        test: (section, dt, log_args)->  
          debug section
          expect section
            .toEqual 'ALPHA'
          done()
    elog 'ALPHA', 'print test'
    str = str = new String('print test as new String')
    # console.log new String('print test')
    elog 'ALPHA', str
    # done()




  it 'for types ', (done)->    
    elog.configure
      sections : [
          name: 'TYPES'
          level: 5
          enable: on
          log_life: 7 
      ]
      writer: 
        console : true
        file: 
          dir: './log'
          postfix: ".txt"
          # filepath: "./log/{{YYYYMMDD}}-{{SECTION}}.txt" 

    f = (x)-> console.log x
    elog 'TYPES', '--------------------------------'
    elog 'TYPES', 'print date', new Date
    elog 'TYPES', f
    elog 'TYPES', new Error 'JUST'
    elog 'TYPES', 'this is beta', 'ver', 1
    done()


  

  it 'delete ', (done)->    
    elog.configure
      sections : [
          name: 'DEL'
          level: 5
          enable: on
          log_life: 1
        , 
          name: 'BETA'
          level: 5
          enable: on 
          log_life: 0
      ]
      writer: 
        console : true
        file: 
          dir: './log'
          postfix: ".txt"

    f = (x)-> console.log x 
    elog 'DEL', "delete target"

    elog.deleteDead()
    process.nextTick ()->
      done()

 


  it 'log LV ', (done)->    
    elog.configure
      sections : [
          name: 'LV3'
          level: 3
          enable: on
          log_life: 1
        , 
          name: 'LV5'
          level: 5
          enable: on
          log_life: 1
        , 
          name: 'LV5-off'
          level: 5
          enable: off
          log_life: 1
        , 
          name: 'LV9'
          level: 9
          enable: on 
          log_life: 0
      ]
      writer: 
        console : true
        test: (section, dt, log_args)->  
          # debug 'test', section
          if section is 'LV3'
            throw new Error "Lv Wrong"
          if section is 'LV5-off'
            throw new Error "Lv Wrong"
        file: 
          dir: './log'
          postfix: ".txt"

    elog 'LV3', "print"
    elog 'LV5', "print"
    elog 'LV5-off', "print"
    elog 'LV9', "print"

    process.nextTick ()->
      done()












  it 'scope ', (done)->    
    elog.configure
      sections : [ 
          name: 'scope'
          level: 5
          enable: on
          log_life: 1 
      ]
      writer: 
        console : true 
        file: 
          dir: './log'
          postfix: ".txt"
 
    scope = elog.scope 'test'
    scope = scope.sub().sub('call')
    elog 'scope', scope, "print" 
    process.nextTick ()->
      done()




  it 'scope printed ', (done)->    
    elog.configure
      sections : [ 
          name: 'scope.log'
          level: 5
          enable: on
          log_life: 1 
      ]
      writer: 
        console : true 
        file: 
          dir: './log'
          postfix: ".txt"
 
    scope = elog.scope 'test'
    scope2 = scope.sub().sub('call')
    scope3 = scope.sub().sub('call')
    # elog 'LV5-scope', scope, "print" 
    elog 'scope.log', 'no scope'
    scope.log 'scope.log', 'root scope'
    scope2.log 'scope.log', 'is scope printed?'
    scope2.sub().log 'scope.log', 'really?'
    scope3.sub().log 'scope.log', 'color ok?'
    process.nextTick ()->
      done()


  it 'hr', (done)->    
    elog.configure
      sections : [ 
          name: 'HR'
          level: 5
          enable: on
          log_life: 1 
      ]
      writer: 
        console : true 
        file: 
          dir: './log'
          postfix: ".txt"
 
    scope = elog.scope 'test'

    elog 'HR', elog.hr()
    elog 'HR', elog.hr '*'
    elog 'HR', elog.hr '#', 80

    scope.log 'HR', elog.hr()
    scope.log 'HR', elog.hr '%', 10
    process.nextTick ()->
      done()


  it 'anotate', (done)->    
    elog.configure
      sections : [ 
          name: 'anotate'
          level: 5
          enable: on
          log_life: 1 
      ]
      writer: 
        console : true 
        file: 
          dir: './log'
          postfix: ".txt"
 
    scope = elog.scope 'test'

    elog 'anotate', elog.anotate "port : 8080" 
    elog 'anotate', 'port :', elog.anotate("8080", color: 'blue'), 'with blue'
    elog 'anotate', 'port :', elog.cyan("8080"), 'with blue'
    process.nextTick ()->
      done()

