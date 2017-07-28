path = require 'path'
fs = require 'fs'
util = require 'util'
moment = require 'moment'

createFileWriter = (conf = {})->  
  truncated = false  
  lock = false 
  bufLogs = []

  _getFilepath = (file_ymd)->  
    path.join conf.dir, "#{file_ymd}" + conf.postfix
    # name = conf.filepath
    # name = name.replace(/\{\{YYYYMMDD\}\}/g, file_ymd) 
    # name = name.replace(/\{\{SECTION\}\}/g, section) 
    # return name
  # _getFilePattern = ()->  
  #   path.join conf.dir, "*-#{section}" + conf.postfix
    # name = conf.filepath
    # name = name.replace(/\{\{.+?\}\}/g, '*')  
    # return name

  _formatLog = (log_args...)->
    if Array.isArray log_args[0]
      return _formatSentence log_args[0]

    strs = log_args.map (x)-> x.toString()
    return strs.join(' ') + '\n'



  _formatSentence = (log_sentence_ml)->
    [tag, attr, childs...] = log_sentence_ml
    if tag isnt 'log_sentence'
      throw new Error 'Wrong Json ML data'

    actor = null
    story = []
    dump = []
    for child in childs      
      if Array.isArray child
        [el_type, oth...] = child
        if el_type is 'subject'
          actor = child
        if el_type is 'text'
          story.push child
        if el_type is 'var'
          dump.push child
      else 
        story.push ['text', null, child] 

    line = [] 

    time = moment attr.when 
    dt = time.format("hh:mm:ss.SSSS")
    line.push "[#{dt}]"

    if actor
      line.push  '[' + actor.join(':') + ']' 

    for word in story   
      [_x, attrs, str ] = word
      if attrs
        anotate_str = JSON.stringify attrs
        line.push "[#{str}](#{anotate_str})"  
      else 
        line.push str

    text = line.join ' '
    
    fmt_txt = text + "\n" 

    for dump_item in dump
      [_x, attrs, value] = dump_item
      fmt_txt +=  "  #{attrs.name} => #{value}\n"
    
    return fmt_txt

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

 
module.exports = exports = createFileWriter