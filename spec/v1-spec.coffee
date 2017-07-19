process.env.DEBUG = "*,-ficent"
elog = require '../src'

describe 'spec', ()->    
  it 'default ', (done)->    
    elog.configure
      sections : [
          name: 'ALPHA'
          min_lv: 5
          enable: on
          log_life: 7
        , 
          name: 'RELEASE'
          min_lv: 9
          enable: on
          log_life: 7 # days 
          # post_task:
      ]
      writer: 
        console : true
        test: (lv, dt, args)->  
    elog 'ALPHA', 'print test'
    done()




  it 'error ', (done)->    
    elog.configure
      sections : [
          name: 'ALPHA'
          min_lv: 5
          enable: on
          log_life: 7
        , 
          name: 'RELEASE'
          min_lv: 9
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
          name: 'ALPHA'
          min_lv: 5
          enable: on
          log_life: 1
        , 
          name: 'BETA'
          min_lv: 9
          enable: on 
          log_life: 0
      ]
      writer: 
        console : true
        file: 
          dir: './log'
          postfix: ".txt"

    f = (x)-> console.log x 
    elog 'ALPHA', "delete target"

    elog.deleteDead()
    process.nextTick ()->
      done()










