// container.wren — The dependency injection container.
// Holds rules, resolves dependencies recursively, manages lifecycle.

import "./rule" for Rule
import "./resolver" for Resolver
import "./lifecycle" for InstanceCache

class Container {
  construct new() {
    _rules = {}
    _cache = InstanceCache.new()
    _resolver = Resolver.new(this)
  }
  
  // Add a single rule.
  addRule(key, rule) {
    if (!(rule is Rule)) {
      Fiber.abort("Rule must be a Rule instance for key: %(key)")
    }
    _rules[key] = rule
  }
  
  // Add multiple rules at once.
  addRules(rules) {
    for (entry in rules) {
      addRule(entry.key, entry.value)
    }
  }
  
  // Resolve a dependency by key.
  get(key) {
    return _resolver.resolve(key)
  }
  
  // Check if a rule exists.
  has(key) {
    return _rules.containsKey(key)
  }
  
  // Retrieve a raw rule.
  rule(key) { _rules[key] }
  
  // Access the instance cache (used by resolver).
  cache { _cache }
}
