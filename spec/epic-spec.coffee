process.env.DEBUG = "*"
epic = require '../src'

# debug = require('debug')('spec')


describe 'spec', ()->    
  it 'default ', (done)->    
    cnt = 0
    epic.configure
      writer:
        console: true
        test: (lv, dt, scope, args)->
          cnt++
          if cnt is 1 
            expect lv 
              .toBe 'log '
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
            done()

    spec = epic.create 'spec'
    spec.log 'test'
    sub = spec.create 'sub'
    sub.info 'text'
    sub = spec.create 'sub'
    sub.warn 'crash?'


  it 'disable pattern 2 ', (done)->    
    cnt = 0
    epic.configure
      consoleFilter: '*, -all:spec'   
      writer:
        console: true 
        test: (lv, dt, scope, args)->
          if lv in ['log ', 'verb'] and not epic.filter.enabled scope
            return
          cnt++
          if cnt is 1 
            expect args[0] 
              .toBe 'info text'
          if cnt is 3 
            expect args[0]
              .toBe 'warn last'
            done()

    console.log 'pattern', epic.filter
    all = epic.create 'all'

    spec = all.create 'spec'
    spec.log 'disable log'  # not print
    sub = spec.create 'sub' 
    sub.info 'info text'         # print info
    sub.log 'log sub'       # not
    sub2 = spec.create 'sub2'
    sub2.warn 'crash?'      # print warn
    sub2.log 'log 2'        # not

    all.warn 'warn last'    # print 


  it 'disable log ', (done)->    
    cnt = 0
    epic.configure
      consoleFilter: '*, -spec:*'   
      writer:
        console: true 
        test: (lv, dt, scope, args)->
          if lv in ['log ', 'verb'] and not epic.filter.enabled scope
            return
          cnt++
          if cnt is 1 
            expect args[0] 
              .toBe 'disable log'
          else if cnt is 4             
            expect lv 
              .toBe 'warn'
            expect args[0]
              .toBe 'warn last'
            done()

    spec = epic.create 'spec'
    spec.log 'disable log'  # print
    sub = spec.create 'sub'
    sub.info 'text'         # print info
    sub = spec.create 'sub2'
    sub.warn 'crash?'       # print warn
    sub.log 'log not '      # not

    spec.warn 'warn last'   # print


  # return
  it 'file log ', (done)->    
    cnt = 0
    epic.configure
      consoleFilter: '-*'  
      file:
        prefix: 'log-'
      writer:
        file: true

    spec = epic.create 'spec'
    spec.log 'disable log'
    sub = spec.create 'sub'
    sub.info 'text'
    sub = spec.create 'sub'
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

 
  it 'file log - long ', (done)->    
    cnt = 0
    epic.configure 
      file:
        prefix: 'log-'
      consoleFilter: 'long4'   
      writer:
        console: true  
        file: true

    for i in [0...10]

      spec = epic.create 'long' + i
      spec.log 'file log - long', Array(60).join '='
      sub = spec.create 'sub'
      sub.info 'text'
      sub = spec.create 'sub'
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