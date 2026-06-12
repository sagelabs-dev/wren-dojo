// rule.wren — Rule configuration value object.
//
// A Rule tells the resolver how to construct a dependency:
//   - classDef: the Wren class to instantiate
//   - params: constructor arguments (Seals, strings, or literals)
//   - shared: resolve once, cache forever
//   - singleton: a pre-built instance to return directly
//   - inheritInstanceOf: inherit from another rule by key
//   - substitutions: map of param overrides
//   - asyncResolve: fiber-based async (v1.5)
//   - inheritPrototype, inheritMixins: prototype/mixin inheritance (deferred)
//
// Booleans that participate in inheritance (shared, asyncResolve,
// inheritPrototype) default to null so the merge logic can distinguish
// "never set" from "explicitly false".

class Rule {
  construct new() {
    _classDef = null
    _params = []
    _calls = []
    _lazyCalls = []
    _shared = null      // null = not set (inherit from parent)
    _singleton = null
    _asyncResolve = null // null = not set (inherit from parent)
    _substitutions = {}
    _inheritInstanceOf = null
    _inheritPrototype = null // null = not set (inherit from parent)
    _inheritMixins = []
  }

  // classDef — the class to instantiate
  classDef { _classDef }
  classDef=(cls) { _classDef = cls }

  // params — constructor arguments
  params { _params }
  params=(p) { _params = p }

  // calls — post-construction method calls (deferred to v1.5)
  calls { _calls }
  calls=(c) { _calls = c }

  // lazyCalls — deferred post-construction calls (deferred to v1.5)
  lazyCalls { _lazyCalls }
  lazyCalls=(c) { _lazyCalls = c }

  // shared — if true, resolve once and cache
  shared { _shared == true }
  shared=(s) { _shared = s }
  sharedRaw { _shared }  // null-aware getter for inheritance merge

  // singleton — pre-built instance, returned directly
  singleton { _singleton }
  singleton=(s) { _singleton = s }

  // asyncResolve — fiber-based async resolution (v1.5)
  asyncResolve { _asyncResolve == true }
  asyncResolve=(a) { _asyncResolve = a }
  asyncResolveRaw { _asyncResolve }

  // substitutions — param overrides as a map
  substitutions { _substitutions }
  substitutions=(s) { _substitutions = s }

  // inheritInstanceOf — parent rule key to merge from
  inheritInstanceOf { _inheritInstanceOf }
  inheritInstanceOf=(i) { _inheritInstanceOf = i }

  // inheritPrototype — inherit prototype chain (deferred)
  inheritPrototype { _inheritPrototype == true }
  inheritPrototype=(i) { _inheritPrototype = i }
  inheritPrototypeRaw { _inheritPrototype }

  // inheritMixins — list of mixin classes (deferred)
  inheritMixins { _inheritMixins }
  inheritMixins=(m) { _inheritMixins = m }
}
