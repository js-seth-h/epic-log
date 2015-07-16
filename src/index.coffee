events = require('events')


_isString = (obj)->
  typeof obj == 'string' || obj instanceof String
_toString = Object.prototype.toString
_isArray = Array.isArray or (obj) ->
  _toString.call(obj) is "[object Array]"
_isError = (obj)-> 
  return obj instanceof Error
  # _toString.call(obj) is "[object Error]" # Error을 상속받으면 부정확.
_isFunction = (obj)->
  return !!(obj && obj.constructor && obj.call && obj.apply);
_isObject = (obj)->
  return (!!obj && obj.constructor == Object);



emitter = new events.EventEmitter()

filter =
  cached_enabled: {}
  skips: []
  names: []
  clear: ()->
    filter.cached_enabled = {}
    filter.skips = []
    filter.names = []

  build: (namespaces)-> 
    split = (namespaces or '').split(/[\s,]+/)
    len = split.length
    i = 0
    while i < len
      if !split[i]
        i++
        continue
      # ignore empty strings 
      # namespaces = split[i].replace(/\*/g, '.*?')
      namespace = split[i]

      pat = filter.names 
      if namespace[0] == '-'
        pat = filter.skips
        namespace = namespace.substr(1)

      if namespace.indexOf('*') >= 0 
        namespace = namespace.replace(/\*/g, '.*?')
        pat.push new RegExp '^' + namespace + '$'
      else 
        pat.push new RegExp '^' + namespace + '$'
        pat.push new RegExp '^' + namespace + ':.*?$'
      i++

    # console.log 'filter', filter
  enabled : (name) ->
    _enabled = (name)->
      i = undefined
      len = undefined
      i = 0
      len = filter.skips.length
      while i < len
        if filter.skips[i].test(name)
          return false
        i++
      i = 0
      len = filter.names.length
      while i < len
        if filter.names[i].test(name)
          return true
        i++
      false

    if filter.cached_enabled[name] is undefined
      filter.cached_enabled[name] = _enabled name
    return filter.cached_enabled[name]


createEpic = (scope)->
  epic = 
    err : (args...)-> createEpic.write 'err ', scope, args
    warn: (args...)-> createEpic.write 'warn', scope, args
    info: (args...)-> createEpic.write 'info', scope, args
    verb: (args...)-> createEpic.write 'verb', scope, args
    log : (args...)-> createEpic.write 'log ', scope, args 
    create: (subScope)->
      if scope is null
        return createEpic subScope
      return createEpic scope + ':' + subScope
  return epic

createEpic.create = (scope)->
  createEpic scope

createEpic.configure = (conf)->
  # Clear
  emitter.removeAllListeners()
  filter.clear()

  createEpic.conf = conf

  # Set Writer
  for own k, v of conf.writer
    if v is false
      continue
    if v is true and createEpic.writer[k]
      # console.log 'set writer', k
      emitter.on 'write', createEpic.writer[k]
    else 
      emitter.on 'write', v 

  #set scope filter
  conf.consoleFilter = conf.consoleFilter || '*'
  filter.build conf.consoleFilter
  createEpic.filter = filter

createEpic.write = (lv, scope, args)-> 
  # if filter.enabled scope
  now = new Date()
  tzoffset = now.getTimezoneOffset() * 60000; #offset in milliseconds
  localISOTime = (new Date(now.getTime() - tzoffset)).toISOString().slice(0,-1).replace 'T', ' ';

  emitter.emit 'write', lv, localISOTime, scope, args


yyyymmdd = (dt)->
  yyyy = dt.getFullYear().toString();
  mm = (dt.getMonth()+1).toString(); # getMonth() is zero-based
  dd  = dt.getDate().toString();
  return yyyy + (mm[1]?mm:"0"+mm[0]) + (dd[1]?dd:"0"+dd[0]); # padding



createFileWriter = ()->
  fs = require 'fs'
  util = require 'util'
  bufLine = []
  lock = false
  _appendToFile = ()->
    return if lock 
    return if bufLine.length is 0

    lock = true
    data = ''

    fileYMD = null

    loop
      line = bufLine.shift()
      [lv, dt, scope, args] = line
      
      yyyymmdd = dt.slice(0,10).replace /-/gi, ''
      if fileYMD is null
        fileYMD = yyyymmdd
      else if fileYMD != yyyymmdd
        bufLine.unshift line
        break 
      data += "#{lv} [#{dt}] #{scope} "

      body = ''
      attach = ''
      aInx = 0
      for a in args
        if _isString a 
          body += " " + a 
        else
          body += " $" + aInx

          if _isFunction a 
            str = a.toString(2)
          else if _isString a
            str = a.toString()
          else
            str = util.inspect a, showHidden: true, depth: 10
          attach += "\n#{aInx}: " + str
          aInx++

      body = body + attach
      body = body.split("\n").map((l)-> "     " + l).join "\n"
      data += body + "\n"

      break if bufLine.length is 0 


    console.log 'appendFile', 'go'
    filename = createEpic.conf.file.prefix + fileYMD + ".txt"
    fs.appendFile filename, data, (err)->
      console.log 'appendFile', err
      lock = false
      _appendToFile()


  _writer = (lv, dt, scope, args)->
    # date = new Date(dt)  
    # yymmdd = dt.slice(0,10).replace '-', ''
    bufLine.push [lv, dt, scope, args]
    _appendToFile()

  return _writer
createEpic.writer =
  console: (lv, dt, scope, args)->
    # console.log 'filter', filter.enabled scope
    if lv in ['log ', 'verb'] and not filter.enabled scope
      return
    console.log lv, '[' + dt + ']',  scope, args...

  file: createFileWriter()


module.exports = exports = createEpic