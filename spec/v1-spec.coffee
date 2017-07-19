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
    # done()




  it 'error ', (done)->    
    elog.configure
      sections : [
          name: 'ALPHA'
          level: 5
          enable: on
          log_life: 7
        , 
          name: 'RELEASE'
          level: 5
          enable: on
          log_life: 7 # days 
          # post_task:
      ]
      writer: 
        console : true
        file: 
          dir: './log'
          postfix: ".txt"
          # filepath: "./log/{{YYYYMMDD}}-{{SECTION}}.txt" 

    f = (x)-> console.log x
    elog 'ALPHA', 'print date', new Date
    elog 'ALPHA', f
    elog 'ALPHA', new Error 'JUST'
    elog 'BETA', 'this is beta', 'ver', 1
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










