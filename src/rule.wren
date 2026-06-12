// rule.wren — Rule configuration with fluent builder + property access.
// Supports both `rule.classDef` (getter) and `rule.classDef = x` (setter)
// and `rule.classDef(X).params(Y)` (fluent builder).

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
  
  // === Traditional getters / setters ===
  classDef { _classDef }
  classDef=(cls) { _classDef = cls }
  
  params { _params }
  params=(p) { _params = p }
  
  calls { _calls }
  calls=(c) { _calls = c }
  
  lazyCalls { _lazyCalls }
  lazyCalls=(c) { _lazyCalls = c }
  
  shared { _shared }
  shared=(s) { _shared = s }
  
  singleton { _singleton }
  singleton=(s) { _singleton = s }
  
  asyncResolve { _asyncResolve }
  asyncResolve=(a) { _asyncResolve = a }
  
  substitutions { _substitutions }
  substitutions=(s) { _substitutions = s }
  
  inheritInstanceOf { _inheritInstanceOf }
  inheritInstanceOf=(i) { _inheritInstanceOf = i }
  
  inheritPrototype { _inheritPrototype }
  inheritPrototype=(i) { _inheritPrototype = i }
  
  inheritMixins { _inheritMixins }
  inheritMixins=(m) { _inheritMixins = m }
  
  // === Fluent builder methods (return this) ===
  withClassDef(cls) { _classDef = cls; return this }
  withParams(p) { _params = p; return this }
  withCalls(c) { _calls = c; return this }
  withLazyCalls(c) { _lazyCalls = c; return this }
  withShared(s) { _shared = s; return this }
  withSingleton(s) { _singleton = s; return this }
  withAsyncResolve(a) { _asyncResolve = a; return this }
  withSubstitutions(s) { _substitutions = s; return this }
  withInheritInstanceOf(i) { _inheritInstanceOf = i; return this }
}
