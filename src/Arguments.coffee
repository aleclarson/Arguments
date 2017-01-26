
NamedFunction = require "NamedFunction"
emptyFunction = require "emptyFunction"
mergeDefaults = require "mergeDefaults"
assertType = require "assertType"
formatType = require "formatType"
setType = require "setType"
Either = require "Either"
isType = require "isType"
define = require "define"
Shape = require "Shape"
isDev = require "isDev"

module.exports =
Arguments = NamedFunction "Arguments", (types) ->
  assertType types, Either(Array, Object)
  self = {types, required: no}
  if Array.isArray types
    self.isArray = yes
    self.required = yes
  else self.strict = no
  return setType self, Arguments

define Arguments.prototype,

  create: (values) ->
    return values if values
    return [] if @isArray
    return {}

  initialize: (values) ->
    values = @create values
    assertType values, @_objType
    mergeDefaults values, @defaults if @defaults
    return values

  _isArray: (values) ->
    return yes if Array.isArray values
    return values and isType values.length, Number

  _objType: get: ->
    if @isArray then Array else Object

isDev and
define Arguments.prototype,

  validate: (values) ->

    if @_isArray values
      throw TypeError "Cannot validate arrays!" unless @isArray
      error = @_validateArray values, "arguments"
    else
      throw TypeError "Expected an array!" if @isArray
      throw TypeError "Expected an object!" unless isType values, Object
      error = @_validateOptions values, @types

    if error
      if isType error, Object
      then TypeError "Expected '#{error.key}' to be #{formatType error.type, yes}!"
      else error
    else null

  shouldValidate: get: ->
    {required} = this

    if required is yes
      return emptyFunction.thatReturnsTrue

    if required is no
      return (value) ->
        return value isnt undefined

    return (value, key) ->
      return required[key] is yes

  _validateArray: (values, keyPath) ->
    {types, shouldValidate} = this

    for type, index in types
      value = values[index]
      continue unless shouldValidate value, index
      return error if error = @_validateType value, type, keyPath + "[#{index}]"

    return null

  _validateOptions: (options) ->
    {types, shouldValidate} = this

    if @strict
      for key, value of options
        if types[key] is undefined
          return Error "'options.#{key}' is not supported!"

    for key, type of types
      value = options[key]
      continue unless shouldValidate value, key
      return error if error = @_validateType value, type, "options." + key

    return null

  _validateTypes: (values, types, keyPath) ->
    keyPath += "." if keyPath
    for key, type of types
      return error if error = @_validateType values[key], type, keyPath + key
    return null

  _validateType: (value, type, key) ->
    if isType type, Object
      return {key, type: Object} unless isType value, Object
      return error if error = @_validateTypes value, type, key
    else if isType type, Shape
      return error if error = type.assert value, key
    else unless isType value, type
      return {key, type}
    return null

isDev or
Object.assign Arguments.prototype,
  validate: emptyFunction

#
# Arguments.Builder
#

Arguments.Builder = do ->

  Builder = NamedFunction "Arguments_Builder", ->
    self = setType {}, Builder
    define self, _args: null
    define self, props
    return setType self, Builder

  props =

    types:
      value: null
      didSet: (newValue) ->
        throw Error "Cannot set 'types' more than once!" if @_args
        assertType newValue, Either(Array, Object)
        @_args = Arguments newValue
        return

    defaults:
      value: null
      didSet: (newValue) ->
        throw Error "Must set 'types' first!" unless @_args
        assertType newValue, @_args._objType
        @_args.defaults = newValue
        return

    required:
      value: null
      didSet: (newValue) ->
        throw Error "Must set 'types' first!" unless @_args
        assertType newValue, Either @_args._objType, Boolean
        @_args.required = newValue
        return

    strict:
      value: null
      didSet: (newValue) ->
        throw Error "Must set 'types' first!" unless @_args
        throw Error "Cannot set 'strict' when 'types' is an array!" if @isArray
        assertType newValue, Boolean
        @_args.strict = newValue
        return

    create:
      value: null
      didSet: (newValue) ->
        throw Error "Must set 'types' first!" unless @_args
        assertType newValue, Function
        @_args.create = newValue
        return

  define Builder.prototype,

    build: -> @_args

  return Builder
