process.env.DEBUG = "*"
elog = require '../src'

# debug = require('debug')('spec')


describe 'spec', ()->    
  it 'default ', (done)->    
    cnt = 0
    elog.configure
      writer:
        console: true
        test: (lv, dt, scope, args)->
          cnt++
          switch args[0]
            when 'test'
              expect lv 
                .toEqual 'log'
            when 'text with type'
              expect args.length
                .toEqual 9
            when 'done'
              done()

    spec = elog.scope 'spec'
    spec.log 'test'
    sub = spec.scope 'sub2'
    sub.info 'text with type', 1, true, false, 'string', new Date(), [1..4], { label:'this is object'}, ()-> console.log 'good'
    sub = spec.scope 'sub'
    sub.info.hr1()
    sub.debug.hr2()

    sub.log.hr0()
    sub.log.hr1()
    sub.log.hr2 'STAR'
    sub.warn 'done'


  it 'indent ramdom ', (done)->    
    cnt = 0
    elog.configure
      writer:
        console: true
        test: (lv, dt, scope, args)->
          cnt++
          if cnt is 1 
            expect lv 
              .toBe 'log'
          else if cnt is 2
            # expect scope
            #   .toBe 'spec:sub'
            expect lv 
              .toBe 'info'
            expect args[0]
              .toBe 'text'
          else             
            expect lv 
              .toBe 'warn'
            done()

    spec = elog.scope 'spec'
    spec.log 'test'
    sub = spec.scope()
    sub.info 'text'
    sub2 = spec.scope()
    sub2.warn 'crash?'


  it 'disable pattern 2', (done)->    
    # cnt = 0
    elog.configure
      console:
        filter: '*, -all:spec*'   
      writer:
        console: true 
        test: (lv, dt, scope, args)->
          # if lv in ['log', 'verb'] and not elog.filter.enabled scope
            # return
          # cnt++
          # if cnt is 1 
          #   expect args[0] 
          #     .toBe 'info text'
          # if cnt is 3 
          #   expect args[0]
          #     .toBe 'warn last'
          #   done()
          if args[0] is 'print warn last'
            done()


    console.log 'pattern', elog.filter
    all = elog.scope 'all'
    all.info 'disable pattern 2'
    spec = all.scope 'spec'
    spec.log 'not print'  # not print
    sub = spec.scope 'sub' 
    sub.info 'print'         # print info
    sub.log 'not print'       # not
    sub2 = spec.scope 'sub2'
    sub2.warn 'print'      # print warn
    sub2.log 'not print'        # not

    all.warn 'print warn last'    # print 

  it 'Error ', (done)->    
    cnt = 0
    elog.configure
      file:
        prefix: './test/err-'
      writer:
        file: true
        console: true
        test: (lv, dt, scope, args)->
          if lv in ['log', 'verb'] and not elog.filter.enabled scope
            return
          cnt++
          if cnt is 1 
            expect lv 
              .toBe 'err'
          else if cnt is 2
            expect scope
              .toBe 'spec:sub'
            expect lv 
              .toBe 'info'
            expect args[0]
              .toBe 'text truncate?'
          else             
            expect lv 
              .toBe 'warn'
            done()

    spec = elog.scope 'spec'
    spec.err new Error 'Fake Err'
    sub = spec.scope 'sub'
    sub.info 'text truncate?', Math.random()
    sub = spec.scope 'sub'
    sub.warn 'crash?'
   
  it 'disable log ', (done)->    
    # cnt = 0
    elog.configure
      console:
        filter: '*, -spec:*'   
      writer:
        console: true 
        test: (lv, dt, scope, args)->
          # if lv in ['log', 'verb'] and not elog.filter.enabled scope
            # return
          # cnt++
          # if cnt is 1 
          #   expect args[0] 
          #     .toBe 'disable log'
          # else if cnt is 4             
          #   expect lv 
          #     .toBe 'warn'
          #   expect args[0]
          #     .toBe 'warn last'
          if args[0] is 'warn last'
            done()

    spec = elog.scope 'spec'
    spec.log 'disable log'  # print
    sub = spec.scope 'sub'
    sub.info 'text'         # print info
    sub = spec.scope 'sub2'
    sub.warn 'crash?'       # print warn
    sub.log 'log not '      # not

    spec.warn 'warn last'   # print

  it 'fileWriter seperate by date', (done)->

    elog.configure 
      file:
        prefix: './test/test-seperate-' 
    writer = elog.writerFactory.file()
    writer 'info', '2015-07-01 10:10:10', 's', '1'
    writer 'info', '2015-07-02 10:10:10', 's', '2'
    setTimeout (()-> done()), 1000

  # return
  it 'file log', (done)->    
    cnt = 0
    elog.configure
      # console:
      #   filter: '-*'  
      file:
        prefix: './test/log-'
      writer:
        file: true

    spec = elog.scope 'file-log'
    spec.info 'file log', Math.random()
    sub = spec.scope 'sub'
    sub.info 'text'
    sub = spec.scope 'sub2'
    sub.warn 'crash?'

    spec.warn 'warn with data', {a: 'value', b:123123}
    spec.info 'params = ',
      "totalCount": 74,
      "list": [
        {
          "_id": "55a64010e9c24355270836e4",
          "_key": "rxw0cdaaaap03wcp4",
          "linkage_key": "1000056260317611",
          "type": "reader",
          "sub_type": "dummy-reader",
          "diagram_svg": "reader",
          "name": "1000056316601182",
          "group": "",
          "desc": "Montana",
          "command": [
            {
              "svg": "clear_alarm",
              "command_id": "clear_alarm",
              "receiver": "server"
            }
          ],
          "subsystem": {
            "id": "dev-dummy",
            "type": "dummy"
          }
        },
        {
          "_id": "55a64010e9c24355270836e8",
          "_key": "rxw0cdaaaap03wcp8",
          "linkage_key": "1000064091903297",
          "type": "reader",
          "sub_type": "dummy-reader",
          "diagram_svg": "reader",
          "name": "1000068424698711",
          "group": "",
          "desc": "Armed Forces Europe",
          "command": [
            {
              "svg": "clear_alarm",
              "command_id": "clear_alarm",
              "receiver": "server"
            }
          ],
          "subsystem": {
            "id": "dev-dummy",
            "type": "dummy"
          }
        }]
      , {a: 'value', b:123123}
    spec.info 'arr =', [1,2,3]
    spec.info 'func =', (x)-> console.log 'test fn'

    spec.info """
The Function object overrides the toString method inherited from Object;
it does not inherit Object.prototype.toString. For Function objects, 
the toString method returns a string representation of the object 
in the form of a function declaration. That is, toString decompiles the function,
and the string returned includes the function keyword, the argument list, 
curly braces, and the source of the function body.

JavaScript calls the toString method automatically when a

    """
    done()

 
  it 'watch ', (done)->    
    cnt = 0
    conf = 
      filepath: './test-conf.json'
    elog.configure conf


    elog.setWriter (lv, dt, scope, args)->
      cnt++
      if cnt is 1 
        expect lv 
          .toBe 'log'
      else if cnt is 2
        expect scope
          .toBe 'spec:sub'
        expect lv 
          .toBe 'info'
        expect args[0]
          .toBe 'text'
      else             
        expect lv 
          .toBe 'warn'

        elog.watcher.close()
        done()

    spec = elog.scope 'spec'
    spec.log 'test'
    sub = spec.scope 'sub'
    sub.info 'text'
    sub = spec.scope 'sub'
    sub.warn 'crash?'
 
  it 'long-file-log', (done)->    
    cnt = 0
    conf = 
      file:
        truncate: true
        prefix: './test/log-'
      console:
        filter: '*long4*'
        limitAttachLine: 3   
      writer:
        console: true  
        file: true

    elog.configure conf
    logConf = elog.scope 'long-file-log'
    logConf.info 'json', JSON.stringify conf, null, 4

    for i in [0...10]

      spec = logConf.scope 'long' + i, true
      spec.log Array(80).join '='
      spec.log 'print only long4'
      spec.log 'file log - long'
      sub = spec.scope 'sub', true
      sub.info 'text'
      sub = spec.scope 'sub'
      sub.warn 'crash?'

      spec.warn 'warn with data', {a: 'value', b:123123}
      spec.debug 'params = ',
        "totalCount": 74,
        "list": [
          {
            "_id": "55a64010e9c24355270836e4",
            "_key": "rxw0cdaaaap03wcp4",
            "linkage_key": "1000056260317611",
            "type": "reader",
            "sub_type": "dummy-reader",
            "diagram_svg": "reader",
            "name": "1000056316601182",
            "group": "",
            "desc": "Montana",
            "command": [
              {
                "svg": "clear_alarm",
                "command_id": "clear_alarm",
                "receiver": "server"
              }
            ],
            "subsystem": {
              "id": "dev-dummy",
              "type": "dummy"
            }
          },
          {
            "_id": "55a64010e9c24355270836e8",
            "_key": "rxw0cdaaaap03wcp8",
            "linkage_key": "1000064091903297",
            "type": "reader",
            "sub_type": "dummy-reader",
            "diagram_svg": "reader",
            "name": "1000068424698711",
            "group": "",
            "desc": "Armed Forces Europe",
            "command": [
              {
                "svg": "clear_alarm",
                "command_id": "clear_alarm",
                "receiver": "server"
              }
            ],
            "subsystem": {
              "id": "dev-dummy",
              "type": "dummy"
            }
          }]
        , {a: 'value', b:123123}
      spec.info 'arr =', [1,2,3]
      spec.info 'func =', (x)-> console.log 'test fn'

      spec.debug """
          The Function object overrides the toString method inherited from Object;
          it does not inherit Object.prototype.toString. For Function objects, 
          the toString method returns a string representation of the object 
          in the form of a function declaration. That is, toString decompiles the function,
          and the string returned includes the function keyword, the argument list, 
          curly braces, and the source of the function body.

          JavaScript calls the toString method automatically when a 
      """
    done()

  it 'scope shadowing ', (done)->    
    cnt = 0
    elog.configure
      file: 
        prefix: './test/log-' 

      writer:
        file: true
        console: true
        test: (lv, dt, scope, args)-> 
          if args[0] is 'test'
            expect lv
              .toBe 'log'
          
          if args[0] is 'done'
            done()
    elog.scope('spec').using (elog)->
      elog.log 'test'
      elog.warn 'crash?'
      elog.warn 'done', 'scope shadowing'

