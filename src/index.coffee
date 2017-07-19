events = require('events')
moment = require 'moment'
# _ = require 'lodash'
util = require 'util'
fs = require 'fs'

_isNumeric = (obj)->
    return !_isArray( obj ) && (obj - parseFloat( obj ) + 1) >= 0;
_isString = (obj)->
  typeof obj == 'string' || obj instanceof String 
_isArray = Array.isArray or (obj) ->
  Object.prototype.toString.call(obj) is "[object Array]"
_isDate = (obj)->
  Object.prototype.toString.call(obj) is '[object Date]'
_isFunction = (obj)->
  return !!(obj && obj.constructor && obj.call && obj.apply);
_isObject = (obj)->
  return (!!obj && obj.constructor is Object); 
_isError = (obj)-> 
  # _toString.call(obj) is "[object Error]" # Error을 상속받으면 부정확.
  return obj instanceof Error

emitter = new events.EventEmitter()

EpicLog = (section, args... )-> 

  now = moment()
  # tzoffset = now.getTimezoneOffset() * 60000; #offset in milliseconds
  # localISOTime = (new Date(now.getTime() - tzoffset)).toISOString().slice(0,-1).replace 'T', ' ';

  emitter.emit 'write', section, now, args


EpicLog.configure = (conf)-> 
  # Clear
  emitter.removeAllListeners()
  for own k, v of conf.writer
    if v is false
      continue
    else 
      if EpicLog.writerFactory[k]
        EpicLog.setWriter EpicLog.writerFactory[k] v


EpicLog.setWriter = (writer)->
  emitter.on 'write', writer
 

createConsoleWriter = (conf = {})->
  chalk = require('chalk');  
  _writer = (section, time,  log_args)->
    # dt = time.format("YY-MM-DD hh:mm:ss.SSSS")
    dt = time.format("hh:mm:ss.SSSS")
    line = []
    attach = [] 
    line.push "[#{dt}]"
    line.push chalk.bold.yellow(section) 
    for val in log_args
      if not ('object' is typeof val ) and not ('function' is typeof val )
        line.push val

      else if _isDate val
        line.push val.toISOString()
      else
        attach_inx = attach.length
        line.push "$#{attach_inx}" 
        if _isError val 
          attach_data = val.stack
          attach_data = chalk.bold.red attach_data
        else if _isFunction val 
          attach_data = val.toString(2) 
          attach_data = chalk.green attach_data
        else
          attach_data = util.inspect val, showHidden: false, depth: 10 #, colors: opt.inspectColor

          # msg = opt.decoErr msg if opt.decoErr
          # stack = opt.decoErr stack if opt.decoErr
          # attach_data += "\n$attach_inx:= \n" + stack  
        
        attach.push "$#{attach_inx}:= " + attach_data
        # attach_data += "\n$#{attach_inx}:= " + str
        # attach_inx++
      # else
      #   if _isFunction val 
      #     str = val.toString(2) 
      #   else
      #     str = util.inspect val, showHidden: false, depth: 10 #, colors: opt.inspectColor

      #   # if lv isnt LV_DEBUG and opt.limitAttachLine 
      #   #   lines = str.split("\n")
      #   #   if lines.length > opt.limitAttachLine
      #   #     ll = lines.length
      #   #     str = lines[0...opt.limitAttachLine].join("\n") + "\n------  MORE (#{opt.limitAttachLine} of #{ll} lines)  ------"


      #   attach_data += "\n$#{attach_inx}:= " + str
      #   attach_inx++
      # text.push val.toString()
    text = line.join ' '
    console.log text
    for appendix in attach
      console.log appendix

    # fs.appendFile './log.txt', text
  return _writer

EpicLog.writerFactory = 
  console: createConsoleWriter
  # file: createFileWriter



module.exports = exports = EpicLog