moment = require 'moment'
# {LogStmt} = require 'who-do-it'

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

chalk = require 'chalk'

color_candidates = "red,green,yellow,blue,magenta,cyan" # ,redBright,greenBright,yellowBright,blueBright,magentaBright,cyanBright"
color_candidates = shuffleArray color_candidates.split ','

createVTWriter = (conf = {})->  
  next_candidate = 0
  keyword_color_table = {}
  colored = (section)->
    unless keyword_color_table[section]
      keyword_color_table[section] = color_candidates[next_candidate]
      next_candidate++
      next_candidate = 0 if next_candidate is color_candidates.length 
    clr = keyword_color_table[section]
    # console.log 'clr=', clr
    return chalk.bold[clr] section

  _formatSentence = (log_stmt_ml)->

    [tag, attr, childs...] = log_stmt_ml
    if tag isnt 'log_stmt'
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

    line.push colored attr.pid 

    if actor
      # console.log 'actor', actor
      ns = actor.map (scope)-> colored scope
      line.push '[' + ns.join(':') + ']' 
 
    for word in story  
      # console.log 'word =', word
      [ _x, attr, str ] = word
      if attr
        str = chalk.bold str
        if attr.color?
          str = chalk[attr.color] str 
        if attr.keyword is true
          str = colored str
      line.push str  


    text = line.join ' '
 
    lines = []
    lines.addLine = (args...)-> lines.push args
    lines.addLine text

    for dump_item in dump
      [_x, attrs, value] = dump_item
      # console.log 'dump_item', dump_item
      if attrs.type is 'error' 
        value = chalk.bold.red value

      lines.addLine "#{chalk.bold.cyan attrs.name} =>", value
 
    return lines 
  return _writer = (log_args...)-> 
    if Array.isArray log_args[0]
      lines = _formatSentence log_args[0]
    else 
      lines = [ log_args.map (x)-> x.toString() ] 

    for ln in lines
      console.log ln... 
 
  
module.exports = exports = createVTWriter