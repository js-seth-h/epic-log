events = require('events')
moment = require 'moment'
# _ = require 'lodash'
util = require 'util'
fs = require 'fs'
ficent = require 'ficent'
glob = require 'glob'
path = require 'path'

chalk = require 'chalk'

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

debug = (args...)-> 
  # console.log args... 


###

# OK 로그 레벨을 사용해서 on/off .
# OK 개별 항목을 사용한 on/off
# OK 삭제 기능
# (opt)후처리 호출

로그 출력시 이를테면 JSON-ML로의 변환을 통해서 
Color처리와 같은 것을 개입할 여지가 있게 하자

lv 중요도
lv 10 : 무조건 찍어야 하는 로그
lv 0 : 
###
conf = {}
section_map = {}
CUT_LV = 5


ANOTATERS = [
  test: (val)-> val instanceof AnotatedStr
  anotate: (val)->
    return item =
      type: 'anotated'
      raw: val
      str: val.toString() 
      anotate_str: val.toAnotatedDesc()
,
  test: (val)-> val instanceof Scope
  anotate: (val)->
    return item =
      type: 'scope'
      raw: val
      str: val.toString() 
,
  test: (val)-> _isDate val
  anotate: (val)->
    return item =
      type: 'date'
      raw: val
      str: val.toISOString()
,
  test: (val)-> _isString val
  anotate: (val)->
    return item =
      type: 'string'
      raw: val
      str: val.toString()
,
  test: (val)-> _isError val 
  anotate: (val, inx)-> 
    return item =
      type: 'error'
      raw: val
      str: val.toString()
      ref_data: val.stack 
,
  test: (val)-> _isFunction val 
  anotate: (val, inx)-> 
    return item =
      type: 'function'
      raw: val
      str: '[function]'
      ref_data: val.toString(2) 
,
  # LITERALs 
  test: (val)-> not ('object' is typeof val ) and not ('function' is typeof val )
  anotate: (val)-> 
    return item =
      type: 'literals'
      raw: val.toString()
      str: val
,
  test: (val)-> true
  anotate: (val, inx)->   
    return item =
      type: 'ref'
      raw: val
      str: "[ref_data]"
      ref_data: util.inspect val, showHidden: false, depth: 10 #, colors: opt.inspectColor 
]

EpicLog = (section, args... )->  
  now = moment() 
  return unless section_map[section]
  sec = section_map[section]
  return if sec.level < CUT_LV
  return if not sec.enable is on


  log_args =  args.map (val)-> 
    for fmt, inx in ANOTATERS
      if fmt.test val
        return fmt.anotate val, inx 

  emitter.emit 'write', section, now, log_args


EpicLog.setLogLv = (new_lv)->
  CUT_LV = new_lv
 
EpicLog.configure = (new_conf)-> 
  # Clear 
  emitter.removeAllListeners() 
  conf = new_conf
  EpicLog.Writers = {} 

  for sec in conf.sections
    section_map[sec.name] = sec

  for own writer_id, v of conf.writer 
    EpicLog.setWriter writer_id, v


EpicLog.setWriter = (writer_id, writer_conf)-> 
  return if writer_conf is false
  if EpicLog.writerFactory[writer_id]
    writer_conf = {} if writer_conf is true 
    writer = EpicLog.writerFactory[writer_id] writer_conf

    emitter.on 'write', writer._write
    emitter.on 'dead', writer._dead
    EpicLog.Writers[writer_id] = writer
  else 
    writer_fn = writer_conf
    emitter.on 'write', writer_fn 


EpicLog.deleteDead = ()->
  for section in conf.sections 
    mmt_dead = moment().add(-section.log_life, 'days').startOf('day')
    debug 'emit desc', section.name, mmt_dead
    emitter.emit 'dead', section.name, mmt_dead

 


class Scope 
  ns: []
  constructor: (args...) ->
    @ns = args
  sub: (sub_str = undefined)-> 
    sub_str = @_randomCode(4) unless sub_str
    return new Scope @ns..., sub_str

  toString: ()->
    str = @ns.join(':')
    return "[#{str}]"
  
  _randomCode: (size)->
    CODE_SPACE = 'ABCDEFGHJKMNPQRSTVWXYZ1234567890'
    result = ''
    for inx in [0...size]
      at = Math.floor CODE_SPACE.length * Math.random()
      result += CODE_SPACE[at]
    return result

  log: (section, args...)->
    EpicLog section, this, args...

class AnotatedStr 
  constructor: (@value, @anotate)-> 
  toString: ()-> @value
  toAnotatedDesc: ()->
    desc = []
    for own key, value of @anotate
      desc.push value
    desc.join ','

EpicLog.anotate = (word, anotate = {})->
  new AnotatedStr word, anotate


clrs = 'red,green,yellow,blue,magenta,cyan,redBright,greenBright,yellowBright,blueBright,magentaBright,cyanBright'.split ','
clrs.map (clr)->
  EpicLog[clr] = (word)->
    new AnotatedStr word, {color: clr}


EpicLog.scope = (name)->
  new Scope name

EpicLog.hr = (char = '=', count = 25)->
  hr = new Array(count).join char

#####################################################################
# writer 코드
 
createFileWriter = (conf = {})-> 
  # debug = require('debug') 'createFileWriter' 
  section_writers = {}

  createSectionWriter = (section)->
    truncated = false  
    lock = false 
    bufLogs = []

    _getFilepath = (file_ymd)->  
      path.join conf.dir, "#{file_ymd}-#{section}" + conf.postfix
      # name = conf.filepath
      # name = name.replace(/\{\{YYYYMMDD\}\}/g, file_ymd) 
      # name = name.replace(/\{\{SECTION\}\}/g, section) 
      # return name
    _getFilePattern = ()->  
      path.join conf.dir, "*-#{section}" + conf.postfix
      # name = conf.filepath
      # name = name.replace(/\{\{.+?\}\}/g, '*')  
      # return name

    _printFormat = (dt, log_args)->
      line = []
      attach = [] 
      line.push "[#{dt}]"

      # file name is Section, so not print section
      for log_item in log_args
        attach_inx = attach.length 
        if log_item.type is 'anotated'
          str = log_item.str 
          anotate_str = log_item.anotate_str
          line.push "[#{str}](#{anotate_str})"
        else if log_item.ref_data?
          line.push   "$#{attach_inx}" 
          attach.push "$#{attach_inx} := " + log_item.ref_data
        else 
          line.push log_item.str 

      text = line.join ' '
      
      fmt_txt = text + "\n" 
      for appendix in attach
        fmt_txt += appendix + "\n" 
      return fmt_txt

    _appendToFile = ()->
      return if lock 
      return if bufLogs.length is 0 
      lock = true 
      data_to_fs = ''
      file_ymd = null
      loop 
        break if bufLogs.length is 0 

        [section, time, log_args] = bufLogs[0]

        ymd = time.format("YYYYMMDD")
        dt = time.format("hh:mm:ss.SSSS") 
        file_ymd = file_ymd or ymd 

        if file_ymd isnt ymd
          break # 추출한 것까지 저장하고 다음 파일로감
        bufLogs.shift()

        data_to_fs += _printFormat dt, log_args 

      filepath = _getFilepath file_ymd 
      # debug 'fs.appendFile', filepath, data_to_fs
      fs.appendFile filepath, data_to_fs, (err)-> 
        lock = false
        _appendToFile()

    _deleteFile = (section, dead_time)-> 
      log_file_pattern = _getFilePattern()
      debug 'log_file_pattern', log_file_pattern
      (ficent [
        (_toss)-> 
          glob log_file_pattern, {nodir: true}, _toss.storeArgs 'files'
        (_toss)->
          {files} = _toss.vars()
          debug 'log files', files 
          
          _delete_file = ficent [
            (filepath, _toss)->
              filename = path.basename filepath
              toks = filename.split '-'
              date = toks[0]
              # log.debug 'date =', date
              debug 'check del', filepath
              if moment(date, 'YYYYMMDD').isBefore dead_time
                debug 'delete file', filepath
                fs.unlink filepath, _toss
              else
                _toss null
          ]

          args_list = files.map (f)-> [f]
          # _toss null
          ficent.ser(_delete_file) args_list, _toss
      ]) (err)-> 
        if err
          console.error err
          throw err
    return sectionWriter =
      _write: (time, log_args)->
        bufLogs.push [section, time, log_args]
        _appendToFile() 
      _deleteFile: (time)-> _deleteFile time

 
  return obj =
    _write : (section, time,  log_args)->
      unless section_writers[section]
        section_writers[section] = createSectionWriter section 
      section_writers[section]._write time, log_args 

    _dead: (section, time)->
      unless section_writers[section]
        section_writers[section] = createSectionWriter section 
      section_writers[section]._deleteFile time 


 


createConsoleWriter = (conf = {})->  
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

  _writer = (section, time, log_args)->
    # dt = time.format("YY-MM-DD hh:mm:ss.SSSS")
    dt = time.format("hh:mm:ss.SSSS")
    line = []
    attach = [] 
    line.push "[#{dt}]"
    line.push colored(section) 
    for log_item in log_args
      attach_inx = attach.length
      if log_item.type is 'anotated'
        str = chalk.bold log_item.str
        if log_item.raw.anotate?.color?
          str = chalk[log_item.raw.anotate.color] str
        line.push str
      else if log_item.type is 'scope'
        toks = log_item.str[1...-1].split ':'
        toks = toks.map (tok)-> colored tok 
        line.push '[' + toks.join(':') + ']' 

      else if log_item.type is 'error'
        line.push   "$#{attach_inx}" 
        attach.push "$#{attach_inx} := " + chalk.bold.red log_item.ref_data
      else if log_item.type is 'function' 
        line.push   "$#{attach_inx}" 
        attach.push "$#{attach_inx} := " + chalk.bold.green log_item.ref_data
      else 
        line.push log_item.str
 
    text = line.join ' '
    console.log text
    for appendix in attach
      console.log appendix
    # debug 'keyword_color_table', keyword_color_table
  return obj =
    _write : _writer
    _dead: ()->

EpicLog.writerFactory = 
  console: createConsoleWriter
  file: createFileWriter



module.exports = exports = EpicLog

