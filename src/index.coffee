events = require('events')
debug = require('debug') 'epic-log'

_isNumeric = (obj)->
    return !_isArray( obj ) && (obj - parseFloat( obj ) + 1) >= 0;
_isString = (obj)->
  typeof obj == 'string' || obj instanceof String 
_isArray = Array.isArray or (obj) ->
  Object.prototype.toString.call(obj) is "[object Array]"
_isFunction = (obj)->
  return !!(obj && obj.constructor && obj.call && obj.apply);
_isObject = (obj)->
  return (!!obj && obj.constructor == Object); 
_isError = (obj)-> 
  # _toString.call(obj) is "[object Error]" # Error을 상속받으면 부정확.
  return obj instanceof Error

LV_ERR = 'err'
LV_WARN = 'warn'
LV_INFO = 'info'
LV_VERB = 'verb'
LV_LOG  = 'log' 
LV_DEBUG = 'dbg'


emitter = new events.EventEmitter()

fixStr = (str, emptyStr)->
  t = str + emptyStr
  return t[0...emptyStr.length]

createFilter = ()->
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
        namespace = split[i].replace(/\*/g, '.*?')
        # namespace = split[i]

        pat = filter.names 
        if namespace[0] == '-'
          pat = filter.skips
          namespace = namespace.substr(1)

        pat.push new RegExp '^' + namespace + '$'

        # if namespace.indexOf('*') >= 0 
        #   namespace = namespace.replace(/\*/g, '.*?')
        #   pat.push new RegExp '^' + namespace + '$'
        # else 
        #   pat.push new RegExp '^' + namespace + '$'
        #   pat.push new RegExp '^' + namespace + ':.*?$'
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
      debug 'check enabled', name, filter.cached_enabled[name]
      return filter.cached_enabled[name]
  return filter



CODE_SPACE = 'ABCDEFGHJKMNPQRSTVWXYZ1234567890'
randomCode = (size)->
  result = ''
  for inx in [0...size]
    at = Math.floor CODE_SPACE.length * Math.random()
    result += CODE_SPACE[at]
  return result

_createScope = (parentScope = null, subScope = null, useId = false)-> 
  if subScope is null
    subScope = randomCode 4
    useId = false
  if useId is true  
    subScope += "(#{randomCode 4})" 

  newScope = parentScope + ':' + subScope
  unless parentScope
    newScope = subScope
  scopeLog = EpicLog newScope    
  return scopeLog

EpicLog = (scope)->

  _createLoggingFn = (lv)->
    _fn = (args...)-> 
      EpicLog.write lv, scope, args  
    for v, inx in '-=*'
      do (v, inx)->
        _fn['hr'+(inx)] = (title = '', barLen = 25)->
          bar = new Array(barLen).join v 
          unless title
            title = new Array(10).join(v)
          else 
            title = "  #{title}  "
          _fn bar + title + bar
    return _fn

  epic = 
    err : _createLoggingFn LV_ERR
    warn: _createLoggingFn LV_WARN
    info: _createLoggingFn LV_INFO
    verb: _createLoggingFn LV_VERB
    log : _createLoggingFn LV_LOG
    debug: _createLoggingFn LV_DEBUG
    indent: (subScope = null)-> # deprecated, legacy
      if scope is null
        return EpicLog subScope
      if subScope is null
        subScope = randomCode 4
      return EpicLog scope + ':' + subScope
    scope: (subScope = null, useId = false)-> 
      return _createScope scope, subScope, useId
    using: (fnInScope)->
      fnInScope epic

  return epic

EpicLog.fixStr = fixStr

EpicLog.create = (scope)-> # deprecated, legacy
  EpicLog scope

EpicLog.scope = (scope, useId)->
  return _createScope null, scope, useId

EpicLog.configure = (conf)->
  debug 'configure'
  if conf.filepath
    # EpicLog.conf = require conf.filepath   
    fs = require 'fs'
    EpicLog.watcher = fs.watch conf.filepath, (evt, fn)-> 
      fs.readFile conf.filepath, (err, data)->
        EpicLog.conf =  JSON.parse data
        EpicLog.build()
      return
    cfg = fs.readFileSync conf.filepath
    EpicLog.conf = JSON.parse cfg
  else
    EpicLog.conf = conf
  EpicLog.build()


EpicLog.build = ()->
  debug 'build'
  conf = EpicLog.conf
  # Clear
  emitter.removeAllListeners()
  # filter.clear()
  # Set Writer
  for own k, v of conf.writer
    if v is false
      continue
    if v is true and EpicLog.writerFactory[k]
      # console.log 'set writer', k
      EpicLog.setWriter EpicLog.writerFactory[k] conf[k]
    else 
      EpicLog.setWriter v 

  # conf.consoleFilter = conf.consoleFilter || '*'
  # filter.build conf.consoleFilter
  # EpicLog.filter = filter

EpicLog.setWriter = (writer)->
  emitter.on 'write', writer

EpicLog.write = (lv, scope, args)-> 
  # if filter.enabled scope
  now = new Date()
  tzoffset = now.getTimezoneOffset() * 60000; #offset in milliseconds
  localISOTime = (new Date(now.getTime() - tzoffset)).toISOString().slice(0,-1).replace 'T', ' ';

  emitter.emit 'write', lv, localISOTime, scope, args



EpicLog.toText = (lv, dt, scope, args, opt ={})->
  util = require 'util'  
  # lv = fixStr lv, '    '

  padLen = 4 - lv.length
  pad = '      '[0...padLen]
  if opt.decoLv
    lv = opt.decoLv lv
  if opt.decoScope
    scope = opt.decoScope scope
  header = "[#{lv}]#{pad} [#{dt}] [#{scope}] "
  body = ''
  attach = ''
  aInx = 0
  # console.log 'to Text args', args
  for a in args
    if not ('object' is typeof a ) and not ('function' is typeof a )
      body += " " + a 
    else if _isError a
      msg = a.toString()
      stack = a.stack
      # msg = opt.decoErr msg if opt.decoErr
      stack = opt.decoErr stack if opt.decoErr
      body += msg
      attach += "\n$err:= \n" + stack 
    else
      body += " $" + aInx


      if _isFunction a 
        str = a.toString(2) 
      else
        str = util.inspect a, showHidden: true, depth: 10

      if lv isnt 'dbg' and opt.limitAttachLine 
        lines = str.split("\n")
        if lines.length > opt.limitAttachLine
          ll = lines.length
          str = lines[0...opt.limitAttachLine].join("\n") + "\n------  MORE (#{opt.limitAttachLine} of #{ll} lines)  ------"


      attach += "\n$#{aInx}:= " + str
      aInx++

  body = body + attach
  body = body.split("\n").map((l)-> "     " + l).join("\n").trim()
  if opt.decoBody
    body = opt.decoBody body
  return header + body

yyyymmdd = (dt)-> 
  yyyy = dt.getFullYear().toString();
  mm = (dt.getMonth()+1).toString(); # getMonth() is zero-based
  dd  = dt.getDate().toString();
  mm = "0" + mm if mm.length is 1
  dd = "0" + dd if dd.length is 1
  return yyyy + mm + dd

createFileWriter = ()->
  fs = require 'fs'
  debug 'createFileWriter'
  bufLine = []
  lock = false

  truncated = false  

  _appendToFile = ()->
    return if lock 
    return if bufLine.length is 0

    lock = true


    # console.log 'truncating', EpicLog.conf.file.truncate
    if EpicLog.conf.file.truncate is true and truncated is false
      fileYMD = yyyymmdd new Date()
      filename = EpicLog.conf.file.prefix + fileYMD + ".txt"
      if fs.existsSync filename
        # console.log 'truncating', filename
        fs.truncateSync filename, 0
      truncated = true

    data = ''
    fileYMD = null

    loop
      line = bufLine.shift()
      [lv, dt, scope, args] = line

      YMD = dt.slice(0,10).replace /-/gi, ''
      if fileYMD is null
        fileYMD = YMD
      else if fileYMD != YMD
        bufLine.unshift line
        break 


      text = EpicLog.toText lv, dt, scope, args 

      data += text + "\n"

      break if bufLine.length is 0 


    # console.log 'appendFile', 'go'
    filename = EpicLog.conf.file.prefix + fileYMD + ".txt"
    fs.appendFile filename, data, (err)->
      # console.log 'appendFile', err
      lock = false
      _appendToFile()


  _writer = (lv, dt, scope, args)->
    # date = new Date(dt)  
    # yymmdd = dt.slice(0,10).replace '-', ''
    bufLine.push [lv, dt, scope, args]
    _appendToFile()

  return _writer

createConsoleWriter = (conf = {})->
  colors = require 'colors/safe'

  conf.filter = conf.filter || '*'
  filter = createFilter()
  filter.build conf.filter
  debug 'filter', filter
  # EpicLog.filter = filter


  # colArr = 'black,red,green,yellow,blue,magenta,cyan,white'.split ','
  colArr = 'cyan,red,green,yellow,magenta'.split ','
  colMap = {}
  inx = 0
  _coloredScope = (scope)->
    # seed = scope.split(':')[0]
    seed = scope

    if not colMap[seed]
      colMap[seed] = colArr[inx]
      inx++
      inx = 0 if inx is colArr.length
    
    return colors[colMap[seed]] colors.bold scope
    # console.log 'colored' , escape colored
    # return colored

  # fnMap =
  #   'err,warn,info,verb,log'

  _coloredLv = (lv)-> 
    cMap =
      err : 'red'  
      warn: 'yellow' 
      info: 'cyan' 
      verb: 'grey' 
      log : 'grey'  
      dbg : 'white'
    c = cMap[lv.trim()]
    # console.log '_coloredLv', lv, c 
    return colors[c] colors.bold lv

  _writer = (lv, dt, scope, args)->
    # console.log 'filter', filter.enabled scope
    if lv in [LV_LOG, LV_VERB] and not filter.enabled scope
      return

    opt = 
      decoLv : _coloredLv
      decoScope: _coloredScope 
      decoErr: (str)-> colors.red colors.bold str 
      limitAttachLine: EpicLog.conf?.console?.limitAttachLine or 5 

    if lv is LV_DEBUG
      opt.decoBody = (body)->  colors.cyan  body
    console.log EpicLog.toText lv, dt, scope, args, opt
  return _writer

# EpicLog.createFileWriter = createFileWriter
# EpicLog.createConsoleWriter = createConsoleWriter

EpicLog.writerFactory = 
  console: createConsoleWriter
  file: createFileWriter


module.exports = exports = EpicLog