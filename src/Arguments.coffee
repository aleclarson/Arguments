
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

ObjectOrArray = Either Object, Array

module.exports =
Arguments = NamedFunction "Arguments", (types) ->
  assertType types, ObjectOrArray

  self = {isArray: Array.isArray types}

  if isDev
    self.types = types
    self.required = self.isArray
    self.strict = no unless self.isArray

  return setType self, Arguments

define Arguments.prototype,

  create: emptyFunction.thatReturnsArgument

  initialize: (values) ->
    assertType values, Array if isDev and values?

    values = @create values ? []

    unless @isArray
      values = values[0]
      values ?= {}

    if values?
      assertType values, if @isArray then Array else Object
      mergeDefaults values, @defaults if @defaults

    return values

  _isArray: (values) ->
    return yes if Array.isArray values
    return values and isType values.length, Number

isDev and
define Arguments.prototype,

  validate: (values, partial = no) ->
    assertType partial, Boolean, "partial"
    @partial = partial

    if @_isArray values
      throw TypeError "Cannot validate arrays!" unless @isArray
      error = @_validateArray values
    else
      throw TypeError "Expected an array!" if @isArray
      throw TypeError "Expected an object!" unless isType values, Object
      error = @_validateOptions values

    @partial = null

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
      return yes if required[key]
      return isType value, Object

  _validateArray: (array) ->
    {types, shouldValidate} = this

    for type, index in types
      value = array[index]
      continue unless shouldValidate value, index
      continue if @partial and (value is undefined)
      return error if error = @_validateType value, type, "arguments[#{index}]"

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
      continue if @partial and (value is undefined)
      return error if error = @_validateType value, type, "options." + key

    return null

  _validateTypes: (values, types, keyPath) ->

    if @strict
      for key, value of values
        if types[key] is undefined
          return Error "'#{keyPath}.#{key}' is not supported!"

    keyPath += "." if keyPath
    for key, type of types
      value = values[key]
      continue if @partial and (value is undefined)
      return error if error = @_validateType value, type, keyPath + key
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

  optionTypes =
    types: ObjectOrArray
    defaults: ObjectOrArray
    required: Either Boolean, ObjectOrArray
    strict: Boolean
    create: Function

  Builder = NamedFunction "Arguments_Builder", ->
    return Object.create Builder.prototype

  define Builder.prototype,

    set: (key, value) ->

      if isDev
        if optionType = optionTypes[key]
        then assertType value, optionType, key
        else throw Error "Invalid key: '#{key}'"

      this[key] = value
      return

    build: ->
      args = Arguments @types
      args.defaults = @defaults if @defaults
      args.create = @create if @create
      if isDev
        args.required = @required if @required?
        args.strict = @strict if @strict?
      return args

  return Builder
