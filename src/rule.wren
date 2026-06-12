// rule.wren — Immutable(ish) rule configuration.
// Fluent builder for dependency resolution rules.

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
  
  // Fluent setters
  classDef(cls) { _classDef = cls; return this }
  params(p) { _params = p; return this }
  calls(c) { _calls = c; return this }
  lazyCalls(c) { _lazyCalls = c; return this }
  shared(s) { _shared = s; return this }
  singleton(s) { _singleton = s; return this }
  asyncResolve(a) { _asyncResolve = a; return this }
  substitutions(s) { _substitutions = s; return this }
  inheritInstanceOf(i) { _inheritInstanceOf = i; return this }
  inheritPrototype(i) { _inheritPrototype = i; return this }
  inheritMixins(m) { _inheritMixins = m; return this }
  
  // Getters
  classDef { _classDef }
  params { _params }
  calls { _calls }
  lazyCalls { _lazyCalls }
  shared { _shared }
  singleton { _singleton }
  asyncResolve { _asyncResolve }
  substitutions { _substitutions }
  inheritInstanceOf { _inheritInstanceOf }
  inheritPrototype { _inheritPrototype }
  inheritMixins { _inheritMixins }
}
