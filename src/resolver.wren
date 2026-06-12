// resolver.wren — Recursive dependency resolver.
//
// Walks the rule graph, resolves params, instantiates classes/factories.
// Supports: classDef params, String/Interface resolution, Value pass-through,
// Factory callbacks, ClassFactory instantiation, rule inheritance, substitutions,
// shared/singleton lifecycles, cyclic dependency detection, and fiber-based async
// resolution for params marked with asyncResolve.
//
// NOTE: calls/lazyCalls are NOT supported in v1 — Wren has no dynamic
// method invocation by string. Use Factory seal for post-construction setup.

import "./rule" for Rule
import "./seal" for Seal, Interface, Value, Factory, ClassFactory

class Resolver {
  construct new(container) {
    _container = container
  }

  // Public: resolve a dependency by key.
  // Delegates to resolveWithStack with an empty cycle-detection stack.
  resolve(key) { resolveWithStack(key, []) }

  // Internal: resolve with cycle-detection stack.
  // Tracks visited keys to detect circular dependencies.
  resolveWithStack(key, stack) {
    if (stack.indexOf(key) != -1) {
      Fiber.abort("Cyclic dependency detected: key '%(key)' already in stack %(stack)")
    }

    var rule = _container.rule(key)
    if (rule == null) {
      Fiber.abort("No rule found for key: %(key)")
    }

    // Merge inherited rules before resolution
    rule = mergeInheritedRule(rule)

    // Singleton: pre-built instance, return as-is (highest priority)
    if (rule.singleton != null) {
      return rule.singleton
    }

    // Shared: check cache before instantiating
    var cache = _container.cache
    if (rule.shared && cache.has(key)) {
      return cache.get(key)
    }

    // Resolve all params recursively through the dependency graph.
    // If asyncResolve is enabled, params are resolved in parallel via fibers.
    var resolvedParams = resolveParams(rule.params, stack + [key], rule.asyncResolve)

    // Apply substitution overrides if configured
    if (rule.substitutions.count > 0) {
      resolvedParams = applySubstitutions(resolvedParams, rule.substitutions)
    }

    // Instantiate the dependency with resolved params
    var instance = instantiate(rule, resolvedParams)

    // Cache if shared lifecycle is enabled
    if (rule.shared) {
      cache.set(key, instance)
    }

    return instance
  }

  // Resolve a list of params.
  // If async is true, each param is resolved in its own fiber for parallel execution.
  resolveParams(params, stack, async) {
    if (!async) {
      // Synchronous path: resolve each param sequentially
      var resolved = []
      for (param in params) {
        resolved.add(resolveParam(param, stack))
      }
      return resolved
    }

    // Async path: spin up a fiber per param, run them cooperatively
    return resolveParamsAsync(params, stack)
  }

  // Parallel param resolution via fibers.
  // Creates one fiber per param. Each fiber resolves its param independently.
  // Fibers are resumed round-robin until all complete.
  resolveParamsAsync(params, stack) {
    var fibers = []
    var results = List.filled(params.count, null)

    // Spawn a fiber for each param
    for (i in 0...params.count) {
      var param = params[i]
      var fiber = Fiber.new {
        results[i] = resolveParam(param, stack)
      }
      fiber.call()  // start the fiber
      fibers.add(fiber)
    }

    // Round-robin resume until all fibers are done
    var pending = true
    while (pending) {
      pending = false
      for (fiber in fibers) {
        if (!fiber.isDone) {
          fiber.transfer()  // resume this fiber
          pending = true
        }
      }
    }

    return results.toList
  }

  // Resolve a single param based on its type.
  // Handles: String (resolve as rule key), Interface (resolve by key),
  // Value (pass-through), Factory (call function), ClassFactory (instantiate class),
  // and any other value (pass through as-is).
  resolveParam(param, stack) {
    if (param is String) {
      // String params are treated as Interface shortcuts
      return resolveWithStack(param, stack)
    } else if (param is Interface) {
      return resolveWithStack(param.key, stack)
    } else if (param is Value) {
      return param.value
    } else if (param is Factory) {
      return param.callback.call()
    } else if (param is ClassFactory) {
      return instantiateClass(param.classDef, [])
    } else {
      return param
    }
  }

  // Instantiate based on rule configuration.
  // If classDef is set, instantiate with arity-dispatched constructor.
  instantiate(rule, params) {
    if (rule.classDef != null) {
      return instantiateClass(rule.classDef, params)
    }
    return null
  }

  // Wren has no spread operator — handle arities 0–8 explicitly.
  // For constructors needing >8 params, use a Map (config object) as a single
  // param and destructure inside the constructor. The Factory seal is also
  // available for arbitrary-arity creation via closure.
  instantiateClass(classDef, params) {
    var n = params.count
    if (n == 0) {
      return classDef.new()
    } else if (n == 1) {
      return classDef.new(params[0])
    } else if (n == 2) {
      return classDef.new(params[0], params[1])
    } else if (n == 3) {
      return classDef.new(params[0], params[1], params[2])
    } else if (n == 4) {
      return classDef.new(params[0], params[1], params[2], params[3])
    } else if (n == 5) {
      return classDef.new(params[0], params[1], params[2], params[3], params[4])
    } else if (n == 6) {
      return classDef.new(params[0], params[1], params[2], params[3], params[4], params[5])
    } else if (n == 7) {
      return classDef.new(params[0], params[1], params[2], params[3], params[4], params[5], params[6])
    } else if (n == 8) {
      return classDef.new(params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7])
    } else {
      Fiber.abort("Instantiation supports max 8 params, got %(n). " +
        "Use a Map (config object) as a single param, or the Factory seal for arbitrary arity.")
    }
  }

  // Merge inherited rule into child.
  // Parent fields are defaults; child overrides. Collections concatenate.
  // Recursively merges grandparent chains.
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

    // Scalar fields: child overrides parent (use ternary with null-check for nullable booleans)
    merged.classDef = rule.classDef != null ? rule.classDef : parent.classDef
    merged.shared = (rule.sharedRaw != null ? rule.sharedRaw : parent.sharedRaw) == true
    merged.singleton = rule.singleton != null ? rule.singleton : parent.singleton
    merged.asyncResolve = (rule.asyncResolveRaw != null ? rule.asyncResolveRaw : parent.asyncResolveRaw) == true
    merged.inheritPrototype = (rule.inheritPrototypeRaw != null ? rule.inheritPrototypeRaw : parent.inheritPrototypeRaw) == true

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

  // Apply substitution overrides to the first param if it's a Map.
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
