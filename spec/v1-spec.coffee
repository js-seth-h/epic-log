process.env.DEBUG = "*"
elog = require '../src'

describe 'spec', ()->    
  it 'default ', (done)->    
    elog.configure
      sections : [
          name: 'ALPHA'
          min_lv: 5
          enable: off
          log_life: 7
        , 
          name: 'RELEASE'
          min_lv: 9
          enable: off
          log_life: 7 # days 
          # post_task:
      ]
      writer: 
        console : true
        test: (lv, dt, args)->
          # cnt++
          # switch args[0]
          #   when 'test'
          #     expect lv 
          #       .toEqual 'log'
          #   when 'text with type'
          #     expect args.length
          #       .toEqual 9
          #   when 'done'
          #     done()

    elog 'ALPHA', 'print test'
    done()




  it 'error ', (done)->    
    elog.configure
      sections : [
          name: 'ALPHA'
          min_lv: 5
          enable: off
          log_life: 7
        , 
          name: 'RELEASE'
          min_lv: 9
          enable: off
          log_life: 7 # days 
          # post_task:
      ]
      writer: 
        console : true
        file: 
          filepath: "./log/{{YYYYMMDD}}-SECTION.txt"
        test: (lv, dt, args)->
          # cnt++
          # switch args[0]
          #   when 'test'
          #     expect lv 
          #       .toEqual 'log'
          #   when 'text with type'
          #     expect args.length
          #       .toEqual 9
          #   when 'done'
          #     done()

    f = (x)-> console.log x
    elog 'ALPHA', 'print date', new Date
    elog 'ALPHA', f
    elog 'ALPHA', new Error 'JUST'
    done()










