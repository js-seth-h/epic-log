

_isString = (obj)->
  typeof obj == 'string' || obj instanceof String

writers = {}

###

Json ML 규격으로 하자. 그래야 Stream너머로 보내기에 유리함.

입력 가능은..
  1. Strings... 
  2. JsonML
  3. Class Instance..? (이거 너무 의존적.. ) 그러니 JsonML로..

###

EpicLog = (log_args...)->
  attrs = null
  if Array.isArray log_args[0]
    json_ml = log_args[0]
    [tag, attrs, els...] = json_ml
  for own k, [filter_fn, _write_fn] of writers 
    if attrs and filter_fn
      continue if true isnt filter_fn attrs
    # if Array.isArray log_args[0]
    #   json_ml = log_args[0]
    #   if filter_fn and EpicLog._filter_fn
    #     continue if true isnt EpicLog._filter_fn json_ml, filter_fn
    _write_fn log_args...

EpicLog.conf = {}

writer_factory = {}
EpicLog.addWriterFactory = (key, factory_fn)->
  writer_factory[key] = factory_fn
  unless factory_fn
    delete writer_factory[key]
EpicLog.createWriter = (key, conf)->
  return writer_factory[key] conf 

filter_factory = {}
EpicLog.addFilterFactory = (key, factory_fn)->
  filter_factory[key] = factory_fn

EpicLog.setWriter = (key, filter_fn, sub_writer)->
  writers[key] = [filter_fn, sub_writer]
  unless sub_writer
    delete writers[key]

EpicLog.getWriter = (key)->
  writers[key][1]

EpicLog.getWriterIds = ()->
  Object.keys writers

EpicLog.getFilterConf = (key)->
  writers[key][0]

# EpicLog.setFilterFn = (fn)->
#   EpicLog._filter_fn = fn
 

EpicLog.addWriterFactory 'vt', require './vt-writer'
EpicLog.addWriterFactory 'file', require './file-writer'

module.exports = exports = EpicLog