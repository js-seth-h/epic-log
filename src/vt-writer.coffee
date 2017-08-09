moment = require 'moment'


#####################################################################
# Console
shuffleArray = (a) ->
  i = a.length
  while i
    j = Math.floor(Math.random() * i)
    x = a[i - 1]
    a[i - 1] = a[j]
    a[j] = x
    i--
  return a

_isString = (obj)->
  typeof obj == 'string' || obj instanceof String
_isArray = Array.isArray or (obj) ->
  Object.prototype.toString.call(obj) is "[object Array]"
# _isDate = (obj)->
#   Object.prototype.toString.call(obj) is '[object Date]'
_isFunction = (obj)->
  Object.prototype.toString.call(obj) is '[object Function]'
_isObject = (obj)->
  return !!(typeof obj is 'object' and obj isnt null)
_isPlainObject= (obj)->
  return obj != null and typeof obj == 'object' and Object.getPrototypeOf(obj) == Object.prototype

_isError = (obj)->
  return obj instanceof Error


chalk = require 'chalk'

color_candidates = "red,green,yellow,blue,magenta,cyan" # ,redBright,greenBright,yellowBright,blueBright,magentaBright,cyanBright"
color_candidates = shuffleArray color_candidates.split ','



next_asigned_index = 0
asigned_colored = {}
colored = (section)->
  unless asigned_colored[section]
    asigned_colored[section] = color_candidates[next_asigned_index]
    next_asigned_index++
    next_asigned_index = 0 if next_asigned_index is color_candidates.length
  clr = asigned_colored[section]
  # console.log 'clr=', clr
  return chalk.bold[clr] section


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
  _str ml

_byTag = (tag, attr, child_txts)->
  if formatML[tag]
    return formatML[tag] tag, attr, child_txts 
  return child_txts.join ' '

 
formatML.log_stmt = (tag, attr, child_txts)->
  time = moment attr.when
  dt = time.format("hh:mm:ss.SSSS")
  words = []
  words.push "[#{dt}]" 
  words.push chalk.cyan attr.pid
  words.push child_txts...
  return words.join(' ') + '\n'

formatML.who = (tag, attr, child_txts)->
  child_txts = child_txts.map (str)-> colored str
  return '[' + child_txts.join(':') + ']'

formatML.text = (tag, attr, child_txts)->
  str = child_txts.join ' '
  if attr.color
    str = chalk[attr.color] str
    # str = "[#{str}](#{JSON.stringify attr })"
  return str 
  
formatML.dump = (tag, attr, child_txts)->
  str = '\n'
  str += chalk.cyan(attr.name) + ' => '
  body = child_txts.join '\n'
  if attr.type is 'error'
    body = chalk.red body
  str += body
  return str 


createVTWriter = (conf = {})->
  # next_candidate = 0
  # keyword_color_table = {}
  # colored = (section)->
  #   unless keyword_color_table[section]
  #     keyword_color_table[section] = color_candidates[next_candidate]
  #     next_candidate++
  #     next_candidate = 0 if next_candidate is color_candidates.length
  #   clr = keyword_color_table[section]
  #   # console.log 'clr=', clr
  #   return chalk.bold[clr] section

  _formatSentence = (log_stmt_ml)->
    return formatML log_stmt_ml

    # [tag, attr, childs...] = log_stmt_ml
    # if tag isnt 'log_stmt'
    #   throw new Error 'Wrong Json ML data'

    # actor = null
    # story = []
    # dump = []
    # for child in childs
    #   if Array.isArray child
    #     [el_type, oth...] = child
    #     if el_type is 'subject'
    #       actor = child
    #     if el_type is 'text'
    #       story.push child
    #     if el_type is 'var'
    #       dump.push child
    #   else
    #     story.push ['text', null, child]

    # line = []

    # time = moment attr.when
    # dt = time.format("hh:mm:ss.SSS")
    # line.push "[#{dt}]"

    # line.push colored attr.pid

    # if actor
    #   # console.log 'actor', actor
    #   [_x, strs...] = actor
    #   strs = strs.map (scope)-> colored scope
    #   line.push '[' + strs.join(':') + ']'

    # for word in story
    #   # console.log 'word =', word
    #   [ _x, attr, str ] = word
    #   if attr
    #     str = chalk.bold str
    #     if attr.color?
    #       str = chalk[attr.color] str
    #     if attr.keyword is true
    #       str = colored str
    #   line.push str


    # text = line.join ' '

    # lines = []
    # lines.addLine = (args...)-> lines.push args
    # lines.addLine text

    # for dump_item in dump
    #   [_x, attrs, value] = dump_item
    #   # console.log 'dump_item', dump_item
    #   if attrs.type is 'error'
    #     value = chalk.bold.red value

    #   lines.addLine "#{chalk.bold.cyan attrs.name} =>", value

    # return lines

  return _writer = (log_args...)->
    if Array.isArray log_args[0]
      lines = _formatSentence log_args[0]
    else
      lines = [ log_args.map (x)-> x.toString() ]

    for ln in lines
      console.log ln...


createVTWriter.formatML = formatML
module.exports = exports = createVTWriter