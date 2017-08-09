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


_isArray = Array.isArray or (obj) ->
  Object.prototype.toString.call(obj) is "[object Array]"
_isPlainObject= (obj)->
  return obj != null and typeof obj == 'object' and Object.getPrototypeOf(obj) == Object.prototype


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
  return words.join(' ')

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
 
  return _writer = (log_args...)->
    if Array.isArray log_args[0]
      console.log formatML log_args[0]
    else
      words = log_args.map (x)-> x.toString()
      console.log words.join ' '
      

createVTWriter.formatML = formatML
module.exports = exports = createVTWriter