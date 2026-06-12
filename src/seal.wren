// seal.wren — Typed markers for dependency parameters.
// Tell the resolver how to treat a param: resolve, pass through, instantiate, etc.

class Seal {
  // Base marker. Never instantiated directly.
}

class Interface is Seal {
  construct new(key) {
    _key = key
  }
  key { _key }
}

class Value is Seal {
  construct new(value) {
    _value = value
  }
  value { _value }
}

class Factory is Seal {
  construct new(callback) {
    _callback = callback
  }
  callback { _callback }
}

class ClassFactory is Seal {
  construct new(classDef) {
    _classDef = classDef
  }
  classDef { _classDef }
}
