// resolver.wren — Recursive dependency resolver.
// Walks the rule graph, resolves params, instantiates classes/factories.

import "rule" for Rule
import "seal" for Seal, Interface, Value, Factory, ClassFactory

class Resolver {
  construct new(container) {
    _container = container
  }
  
  // Resolve a dependency by key.
  // stack: list of keys currently being resolved (for cycle detection).
  resolve(key, stack) {
    // Cycle detection
    if (stack.contains(key)) {
      Fiber.abort("Cyclic dependency detected: %(key) in stack %(stack)")
    }
    
    var rule = _container.rule(key)
    if (rule == null) {
      Fiber.abort("No rule found for key: %(key)")
    }
    
    // Apply rule inheritance
    rule = mergeInheritedRule(rule)
    
    // Singleton: return pre-built instance directly
    if (rule.singleton != null) {
      return rule.singleton
    }
    
    // Shared: check cache first
    var cache = _container.cache
    if (rule.shared && cache.has(key)) {
      return cache.get(key)
    }
    
    // Resolve params recursively
    var resolvedParams = resolveParams(rule.params, stack + [key])
    
    // Apply substitutions to map-style params
    if (rule.substitutions.count > 0) {
      resolvedParams = applySubstitutions(resolvedParams, rule.substitutions)
    }
    
    // Instantiate
    var instance = instantiate(rule, resolvedParams)
    
    // Cache if shared
    if (rule.shared) {
      cache.set(key, instance)
    }
    
    return instance
  }
  
  // Resolve a list of params.
  resolveParams(params, stack) {
    var resolved = []
    for (param in params) {
      resolved.add(resolveParam(param, stack))
    }
    return resolved
  }
  
  // Resolve a single param based on its type.
  resolveParam(param, stack) {
    if (param is String) {
      // Raw string = rule key to resolve recursively
      return resolve(param, stack)
    } else if (param is Interface) {
      return resolve(param.key, stack)
    } else if (param is Value) {
      return param.value
    } else if (param is Factory) {
      // Factory callback takes no args and returns instance
      return param.callback.call()
    } else if (param is ClassFactory) {
      // Instantiate class with no params (ClassFactory is for simple instantiation)
      return instantiateClass(param.classDef, [])
    } else {
      // Pass through as-is (literal values: Num, Bool, List, Map, etc.)
      return param
    }
  }
  
  // Instantiate based on rule configuration.
  instantiate(rule, params) {
    if (rule.classDef != null) {
      return instantiateClass(rule.classDef, params)
    }
    
    // No classDef — return null (use a factory if you need custom instantiation)
    return null
  }
  
  // Instantiate a class with params, handling arity (Wren has no spread operator).
  // Supports 0–4 params. Use a factory function for more.
  instantiateClass(classDef, params) {
    if (params.count == 0) {
      return classDef.new()
    } else if (params.count == 1) {
      return classDef.new(params[0])
    } else if (params.count == 2) {
      return classDef.new(params[0], params[1])
    } else if (params.count == 3) {
      return classDef.new(params[0], params[1], params[2])
    } else if (params.count == 4) {
      return classDef.new(params[0], params[1], params[2], params[3])
    } else {
      Fiber.abort("Class instantiation supports max 4 params, got %(params.count). Use a Factory seal instead.")
    }
  }
  
  // Merge inherited rule into child. Parent fields are defaults; child overrides.
  mergeInheritedRule(rule) {
    if (rule.inheritInstanceOf == null) {
      return rule
    }
    
    var parent = _container.rule(rule.inheritInstanceOf)
    if (parent == null) {
      Fiber.abort("Inherit rule not found: %(rule.inheritInstanceOf)")
    }
    
    // Recursively merge parent (parent may also inherit)
    parent = mergeInheritedRule(parent)
    
    var merged = Rule.new()
    
    // Scalar fields: child overrides parent
    merged.classDef = rule.classDef != null ? rule.classDef : parent.classDef
    merged.shared = rule.shared || parent.shared
    merged.singleton = rule.singleton != null ? rule.singleton : parent.singleton
    merged.asyncResolve = rule.asyncResolve || parent.asyncResolve
    merged.inheritPrototype = rule.inheritPrototype || parent.inheritPrototype
    
    // Collection fields: concatenate (parent first, then child)
    merged.params = parent.params + rule.params
    merged.calls = parent.calls + rule.calls
    merged.lazyCalls = parent.lazyCalls + rule.lazyCalls
    merged.inheritMixins = parent.inheritMixins + rule.inheritMixins
    
    // Substitutions: child overwrites parent keys
    for (entry in parent.substitutions) {
      merged.substitutions[entry.key] = entry.value
    }
    for (entry in rule.substitutions) {
      merged.substitutions[entry.key] = entry.value
    }
    
    // Preserve child's inheritInstanceOf (or inherit from parent's parent)
    merged.inheritInstanceOf = parent.inheritInstanceOf
    
    return merged
  }
  
  // Apply substitutions to map-style params.
  applySubstitutions(params, substitutions) {
    // If first param is a Map, overlay substitution values
    if (params.count > 0 && params[0] is Map) {
      var map = params[0]
      for (entry in substitutions) {
        map[entry.key] = entry.value
      }
      return [map]
    }
    return params
  }
}
