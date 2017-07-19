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
 
createFileWriter = (conf = {})->

  # debug = require('debug') 'createFileWriter'

  section_writers = {}

  createSectionWriter = (section)->
    truncated = false  
    lock = false 
    bufLogs = []

    _getFilepath = (file_ymd)->  
      name = conf.filepath
      name = name.replace(/\{\{YYYYMMDD\}\}/g, file_ymd) 
      name = name.replace(/\{\{SECTION\}\}/g, section) 
      return name

    _appendToFile = ()->
      return if lock 
      return if bufLogs.length is 0 
      lock = true 
      data_to_fs = ''
      file_ymd = null
      loop 
        break if bufLogs.length is 0 

        [section, time, log_args] = bufLogs[0]

        ymd = time.format("YYMMDD")
        dt = time.format("hh:mm:ss.SSSS") 
        file_ymd = file_ymd or ymd 

        if file_ymd isnt ymd
          break # 추출한 것까지 저장하고 다음 파일로감
        bufLogs.shift()

        line = []
        attach = [] 
        line.push "[#{dt}]"
        # line.push section 
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
              attach_data = attach_data
            else if _isFunction val 
              attach_data = val.toString(2) 
              attach_data = attach_data
            else
              attach_data = util.inspect val, showHidden: false, depth: 10 #, colors: opt.inspectColor 
            attach.push "$#{attach_inx} := " + attach_data 
        text = line.join ' '
        data_to_fs += text + "\n" 
        for appendix in attach
          data_to_fs += appendix + "\n" 

      filepath = _getFilepath file_ymd 
      console.log 'fs.appendFile', filepath, data_to_fs
      fs.appendFile filepath, data_to_fs, (err)-> 
        lock = false
        _appendToFile()

    return _sectionWriter = (time, log_args)->
      bufLogs.push [section, time, log_args]
      _appendToFile()


  _writer = (section, time,  log_args)->
    unless section_writers[section]
      section_writers[section] = createSectionWriter section

    section_writers[section] time, log_args 
    # _appendToFile()
  return _writer
 


createConsoleWriter = (conf = {})->
  if conf is true 
    conf = {}
  chalk = require('chalk');  


  color_candidates = "red,green,yellow,blue,magenta,cyan,redBright,greenBright,yellowBright,blueBright,magentaBright,cyanBright".split ','
  next_candidate = 0
  keyword_color_table = {}
  colored = (section)->
    unless keyword_color_table[section]
      keyword_color_table[section] = color_candidates[next_candidate]
      next_candidate++
      next_candidate = 0 if next_candidate is color_candidates.length 
    clr = keyword_color_table[section]
    return chalk.bold[clr] section

  _writer = (section, time,  log_args)->
    # dt = time.format("YY-MM-DD hh:mm:ss.SSSS")
    dt = time.format("hh:mm:ss.SSSS")
    line = []
    attach = [] 
    line.push "[#{dt}]"
    line.push colored(section) 
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
        attach.push "$#{attach_inx}:= " + attach_data 

    text = line.join ' '
    console.log text
    for appendix in attach
      console.log appendix
 
  return _writer

EpicLog.writerFactory = 
  console: createConsoleWriter
  file: createFileWriter



module.exports = exports = EpicLog


# TODO
# 로그 레벨을 사용해서 on/off 
# 개별 항목을 사용한 on/off
# 삭제 기능
# (opt)후처리 호출
