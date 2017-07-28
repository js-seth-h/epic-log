

_isString = (obj)->
  typeof obj == 'string' || obj instanceof String

writers = {}

###

Json ML 규격으로 하자. 그래야 Stream너머로 보내기에 유리함.

[ "log_sentence", 
{
  pid = pid,
  when = ISODateString
  사용자 attrs...
}
["subject", "scope1", ... ]
["story", literal, ["string", attr, string ...], ... ] 
["dump", [key, value], [type, string, ...], ... ] 
]


입력 가능은..
  1. Strings... 
  2. JsonML
  3. Class Instance..? (이거 너무 의존적.. ) 그러니 JsonML로..

###

EpicLog = (log_args...)->
  for own k, [filter_def, _write_fn] of writers 
    if Array.isArray log_args[0]
      json_ml = log_args[0]
      if filter_def and EpicLog.filtering
        continue if true isnt EpicLog.filtering json_ml, filter_def
    _write_fn log_args...

EpicLog.conf = {}

writer_factory = {}
EpicLog.addWriterFactory = (key, factory_fn)->
  writer_factory[key] = factory_fn

filter_factory = {}
EpicLog.addFilterFactory = (key, factory_fn)->
  filter_factory[key] = factory_fn

EpicLog.setWriter = (key, filter_def, sub_writer)->
  writers[key] = [filter_def, sub_writer]
  unless sub_writer
    delete writers[key]

EpicLog.getWriter = (key)->
  writers[key][1]

EpicLog.getFilter = (key)->
  writers[key][0]

# EpicLog.makerArchiver = (new_conf)->
#   # Clear
#   writers = {}
#   conf = new_conf
#   for w_conf in conf.writers
#     continue unless writer_factory[w_conf.type]
#     _w = writer_factory[w_conf.type] w_conf

#     if w_conf.filter_type and filter_factory[w_conf.filter_type]
#       _w = filter_factory[w_conf.filter_type] w_conf, _w
#     EpicLog.addWriter _w


EpicLog.addWriterFactory 'vt', require './vt-writer'
EpicLog.addWriterFactory 'file', require './file-writer'

module.exports = exports = EpicLog