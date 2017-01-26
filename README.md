
# Arguments v1.0.0 ![stable](https://img.shields.io/badge/stability-stable-4EBA0F.svg?style=flat)

#### Properties
- `types : Array | Object` The expected constructors/validators that must be matched
- `defaults : Array | Object` The values used when an optional key is undefined
- `required : Array | Object | Boolean` Which values (if any) must be defined
- `strict : Boolean` Set to true if unfamiliar keys should return errors
- `create : Function` An "initialize" hook called before default values are merged

#### Methods
- `initialize(values) : Array | Object` Merges default values, and any custom initialization
- `validate(values) : Error | null` Returns an error if a value has an unexpected type

#### Usage / Notes
- If all keys must be defined, set `required` to `true`.
- If all keys can be undefined, set `required` to `false`.
- The `required` property defaults to `true` for arrays.
