path = require 'path'
fs = require 'fs'
util = require 'util'
moment = require 'moment'


_isArray = Array.isArray or (obj) ->
  Object.prototype.toString.call(obj) is "[object Array]"
_isPlainObject= (obj)->
  return obj != null and typeof obj == 'object' and Object.getPrototypeOf(obj) == Object.prototype


formatML = (ml)->
  _str = (ml_node)->
    # txts = []
    tag = ml_node[0]
    attr = null
    child_start_inx = 1
    if _isPlainObject ml_node[child_start_inx]
      attr = ml_node[1]
      child_start_inx++
    child_txts = ml_node[child_start_inx...].map (child)->
      return _str(child) if _isArray child
      return child

    _byTag tag, attr, child_txts
    # txts.join ' '
  _str ml


_byTag = (tag, attr, child_txts)->
  if formatML[tag]
    return formatML[tag] tag, attr, child_txts
  return child_txts.join ' '

formatML.text = (tag, attr, child_txts)->
  str = child_txts.join ' '
  if attr
    str = "[#{str}](#{JSON.stringify attr })"
  return str

formatML.who = (tag, attr, child_txts)->
  return '[' + child_txts.join(':') + ']'

formatML.testimony =
formatML.log_stmt = (tag, attr, child_txts)->
  time = moment attr.when
  dt = time.format("hh:mm:ss.SSSS")
  words = []
  words.push "[#{dt}]"

  words.push "PID=", attr.pid
  words.push child_txts...
  return words.join(' ') + '\n'
formatML.dump = (tag, attr, child_txts)->
  str = '\n'
  str += attr.name + ' => '
  str += child_txts.join '\n'
  return str
 

createFileWriter = (conf = {})->
  truncated = false
  lock = false
  bufLogs = []


  _formatLog = (log_args...)->
    if Array.isArray log_args[0]
      return formatML log_args[0]

    strs = log_args.map (x)-> x.toString()
    return strs.join(' ') + '\n'


  _getFilepath = (file_ymd)->
    path.join conf.dir, "#{file_ymd}" + conf.postfix


  _appendToFile = ()->
    return if lock
    return if bufLogs.length is 0
    lock = true
    data_to_fs = ''
    file_ymd = null
    loop
      break if bufLogs.length is 0
      log_args = bufLogs[0]

      if Array.isArray log_args[0]
        # JsonML
        # console.log 'log_args[0]', log_args[0]
        [el_type, attrs, els...] = log_args[0]
        time = moment attrs.when
        ymd = time.format("YYYYMMDD")
      else
        ymd = moment().format "YYYYMMDD"

      if file_ymd isnt null and file_ymd isnt ymd
        break # 추출한 것까지 저장하고 다음 파일로감
      file_ymd = ymd
      bufLogs.shift()

      data_to_fs += _formatLog log_args...

    filepath = _getFilepath file_ymd
    fs.appendFile filepath, data_to_fs, (err)->
      lock = false
      _appendToFile()

  return _writer = (log_args...)->
    bufLogs.push log_args
    _appendToFile()


createFileWriter.formatML = formatML
module.exports = exports = createFileWriter
