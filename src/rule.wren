// rule.wren — Rule configuration value object.
// Getter/setter style (fluent builder deferred to v1.5).

class Rule {
  construct new() {
    _classDef = null
    _params = []
    _calls = []
    _lazyCalls = []
    _shared = false
    _singleton = null
    _asyncResolve = false
    _substitutions = {}
    _inheritInstanceOf = null
    _inheritPrototype = false
    _inheritMixins = []
  }

  // classDef
  classDef { _classDef }
  classDef=(cls) { _classDef = cls }

  // params
  params { _params }
  params=(p) { _params = p }

  // calls
  calls { _calls }
  calls=(c) { _calls = c }

  // lazyCalls
  lazyCalls { _lazyCalls }
  lazyCalls=(c) { _lazyCalls = c }

  // shared
  shared { _shared }
  shared=(s) { _shared = s }

  // singleton
  singleton { _singleton }
  singleton=(s) { _singleton = s }

  // asyncResolve
  asyncResolve { _asyncResolve }
  asyncResolve=(a) { _asyncResolve = a }

  // substitutions
  substitutions { _substitutions }
  substitutions=(s) { _substitutions = s }

  // inheritInstanceOf
  inheritInstanceOf { _inheritInstanceOf }
  inheritInstanceOf=(i) { _inheritInstanceOf = i }

  // inheritPrototype
  inheritPrototype { _inheritPrototype }
  inheritPrototype=(i) { _inheritPrototype = i }

  // inheritMixins
  inheritMixins { _inheritMixins }
  inheritMixins=(m) { _inheritMixins = m }
}
