// resolver.wren — Recursive dependency resolver.
// Walks the rule graph, resolves params, instantiates classes/factories.
// NOTE: calls/lazyCalls are NOT supported in v1 — Wren has no dynamic
// method invocation. Use Factory seal for post-construction setup.

import "rule" for Rule
import "seal" for Seal, Interface, Value, Factory, ClassFactory

class Resolver {
  construct new(container) {
    _container = container
  }
  
  // Public: resolve a dependency by key.
  resolve(key) { resolveWithStack(key, []) }
  
  // Internal: resolve with cycle-detection stack.
  resolveWithStack(key, stack) {
    if (stack.contains(key)) {
      Fiber.abort("Cyclic dependency detected: key '%(key)' already in stack %(stack)")
    }
    
    var rule = _container.rule(key)
    if (rule == null) {
      Fiber.abort("No rule found for key: %(key)")
    }
    
    rule = mergeInheritedRule(rule)
    
    // Singleton: pre-built instance, return as-is
    if (rule.singleton != null) {
      return rule.singleton
    }
    
    // Shared: check cache
    var cache = _container.cache
    if (rule.shared && cache.has(key)) {
      return cache.get(key)
    }
    
    var resolvedParams = resolveParams(rule.params, stack + [key])
    
    if (rule.substitutions.count > 0) {
      resolvedParams = applySubstitutions(resolvedParams, rule.substitutions)
    }
    
    var instance = instantiate(rule, resolvedParams)
    
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
      return resolveWithStack(param, stack)
    } else if (param is Interface) {
      return resolveWithStack(param.key, stack)
    } else if (param is Value) {
      return param.value
    } else if (param is Factory) {
      // Factory callback receives resolved params if configured
      return param.callback.call()
    } else if (param is ClassFactory) {
      return instantiateClass(param.classDef, [])
    } else {
      return param
    }
  }
  
  // Instantiate based on rule configuration.
  instantiate(rule, params) {
    if (rule.classDef != null) {
      return instantiateClass(rule.classDef, params)
    }
    return null
  }
  
  // Wren has no spread operator — handle arities 0–4.
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
      Fiber.abort("Instantiation supports max 4 params, got %(params.count). Use Factory seal instead.")
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
    // calls/lazyCalls retained on Rule for v1.5, not processed by resolver v1
    merged.inheritMixins = parent.inheritMixins + rule.inheritMixins
    
    // Substitutions: child overwrites parent keys
    for (entry in parent.substitutions) {
      merged.substitutions[entry.key] = entry.value
    }
    for (entry in rule.substitutions) {
      merged.substitutions[entry.key] = entry.value
    }
    
    // Preserve parent's inheritance chain
    merged.inheritInstanceOf = parent.inheritInstanceOf
    
    return merged
  }
  
  applySubstitutions(params, substitutions) {
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
