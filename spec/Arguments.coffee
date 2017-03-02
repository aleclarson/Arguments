
Shape = require "Shape"

Arguments = require ".."

describe "Arguments", ->

  expectValidArgs = (args, values) ->
    expect args.validate values
      .toBe null

  expectInvalidArgs = (args, values) ->
    error = args.validate values
    expect error instanceof Error
      .toBe yes
    return error

  describe "validating arrays", ->

    it "does NOT allow undefined values by default", ->
      args = Arguments [Number, String]
      expectInvalidArgs args, [0]

    it "returns null if all values are valid", ->
      args = Arguments [Number, Boolean]
      expectValidArgs args, [0, no]

    it "returns an error if a value has an unexpected type", ->
      args = Arguments [Boolean]
      expectInvalidArgs args, [1]

    it "returns an error for undefined values with required types", ->
      args = Arguments [Number]
      args.required = [yes]
      expectInvalidArgs args, []

  describe "validating objects", ->

    it "returns null if all values are valid", ->
      args = Arguments {foo: Number, bar: Boolean}
      expectValidArgs args, {foo: 0, bar: no}

    it "allows undefined values by default", ->
      args = Arguments {foo: Number, bar: String}
      expectValidArgs args, {}
      expectValidArgs args, {foo: 0}

    it "returns an error if a value has an unexpected type", ->
      args = Arguments {foo: Number, bar: String}
      expectInvalidArgs args, {foo: 1, bar: 2}
      expectInvalidArgs args, {foo: yes, bar: "yellow"}

    it "returns an error if an undefined key is required", ->
      args = Arguments {foo: Number}
      args.required = {foo: yes}
      expectInvalidArgs args, {}

  describe "required keys", ->

    it "supports arrays", ->
      args = Arguments [Number, String, Boolean]
      args.required = [yes, no, yes]
      expectValidArgs args, [5, undefined, yes]
      expectInvalidArgs args, [undefined, "green", undefined]
      expectInvalidArgs args, []

    it "supports objects", ->
      args = Arguments {foo: Number, bar: String}
      args.required = {foo: yes}
      expectValidArgs args, {foo: 1}
      expectInvalidArgs args, {bar: "blue"}
      expectInvalidArgs args, {}

    it "can allow all array indexes to be undefined", ->
      args = Arguments [Number, Number, Number]
      args.required = no
      expectValidArgs args, [1, 2, 3]
      expectValidArgs args, []

    it "can force all object keys to be defined", ->
      args = Arguments {foo: Number, bar: Number}
      args.required = yes
      expectValidArgs args, {foo: 1, bar: 0}
      expectInvalidArgs args, {bar: 0}

  describe "assigning default values", ->

    it "supports arrays", ->
      args = Arguments [Number, Number]
      args.defaults = [0, 1]
      values = args.initialize()
      expect values
        .toEqual args.defaults
      expect values
        .not.toBe args.defaults

    it "supports objects", ->
      args = Arguments {foo: Number, bar: Number}
      args.defaults = {foo: 0}
      values = args.initialize [bar: 1]
      expect values.foo
        .toBe 0
      expect values.bar
        .toBe 1

  describe "nested validation", ->

    it "works with object literals", ->
      args = Arguments {user: {online: Boolean}}
      expectValidArgs args, {user: {online: yes}}
      expectInvalidArgs args, {user: {online: 20}}
      expectInvalidArgs args, {user: null}
      expectValidArgs args, {}
      args.required = yes
      expectInvalidArgs args, {}

    it "works with the 'Shape' validator", ->
      MyShape = Shape {foo: Number}
      args = Arguments [MyShape]
      expectValidArgs args, [{foo: 1}]
      expectInvalidArgs args, [{}]
      expectInvalidArgs args, []
