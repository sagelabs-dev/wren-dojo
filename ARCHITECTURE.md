# Wren Dojo — Architecture Document

> Runtime-resolved dependency injection for Wren. Fiber-based async. Composition-Root IoC.

## 1. Design Principles

1. **Composition-Root only.** No decorators, no magic. All wiring at the top.
2. **Runtime resolution.** Import-time is irrelevant. The container lives and breathes at runtime.
3. **Fibers for async.** No Promises. Cooperative multitasking via Wren fibers.
4. **Professional naming.** Container, Rule, Resolver — no ninjas in the codebase.
5. **Minimal surface.** di-ninja had ~30 source files. We target ~8 core files.
6. **Idiomatic Wren.** Class-based, underscore fields, block arguments, `is` for type checking.

## 2. Module Layout

```
wren-dojo/
├── src/
│   ├── dojo.wren          # Public API — import "dojo" for Dojo
│   ├── container.wren     # Container class — rule registry, entry point
│   ├── rule.wren          # Rule value object + builder
│   ├── resolver.wren      # Recursive dependency walker + instance builder
│   ├── lifecycle.wren     # Shared, Singleton, Instance lifecycle managers
│   ├── seal.wren          # Seal base + Interface, Value, Factory, ClassFactory
│   └── fiber_scheduler.wren # Fiber coordination for parallel async resolution
├── test/
│   ├── test_runner.wren   # Minimal test harness (Wren has no built-in test lib)
│   ├── test_container.wren
│   ├── test_resolver.wren
│   ├── test_lifecycle.wren
│   └── test_async.wren
├── ARCHITECTURE.md        # This document
├── README.md              # User-facing documentation
└── LICENSE
```

## 3. Core Types

### Container
The dojo itself. Holds rules, instances, and resolves dependencies.

```wren
var container = Container.new()
container.addRule("Logger", Rule.new().classDef(ConsoleLogger))
container.addRule("Service", Rule.new().classDef(MyService).params(["Logger"]))
var svc = container.get("Service")  // returns MyService instance, Logger injected
```

### Rule
Immutable(ish) configuration for how to resolve a dependency.

Fields (all nullable, all default to null/false):
- `classDef` — the Wren class to instantiate
- `params` — list of params: Seal objects, strings (rule keys), or literal values
- `calls` — list of [methodName, params] to call after construction
- `lazyCalls` — same as calls, but deferred until first access
- `shared` — if true, resolve once and cache instance
- `singleton` — a pre-built instance to return directly
- `asyncResolve` — if true, resolution may yield via fiber
- `substitutions` — map of param keys to replacement values
- `inheritInstanceOf` — inherit from another rule by key
- `inheritPrototype` — inherit prototype/mixins (Wren: not applicable)
- `inheritMixins` — list of mixin classes (Wren: not applicable in v1)

### Seal
A typed marker that tells the resolver how to treat a param.

```wren
// Seal hierarchy:
Seal                          # base — never instantiated directly
├── Interface                 # resolve by rule key: Interface.new("Logger")
├── Value                     # pass through as-is: Value.new("hello")
├── Factory                   # call function: Factory.new(fn)
└── ClassFactory              # instantiate class: ClassFactory.new(MyClass)
```

### Resolver
Recursive dependency graph walker. Takes a rule key, produces an instance.

Responsibilities:
1. Look up rule by key
2. Resolve params (recursively)
3. Instantiate (classDef or factory callback)
4. Execute calls (post-construction wiring)
5. Cache if shared/singleton
6. Return instance

### FiberScheduler
Internal. When a rule has `asyncResolve: true`, the resolver spins up a fiber.
The scheduler collects all async fibers for a given `get()` call and resumes them.
If any fiber yields, the scheduler yields to Wren's VM. When all fibers complete,
the result is assembled and returned.

For params: if multiple params have `asyncResolve: true`, they resolve in parallel
(via separate fibers). If `asyncCallsSerie: true`, calls execute serially.

### Lifecycle
Manages instance caching:
- `InstanceCache` — stores resolved instances by rule key
- `SharedManager` — lazy singleton per rule
- `SingletonManager` — pre-built instance

## 4. Async Model (The Big One)

Wren fibers are cooperative, not preemptive. Our async strategy:

**Phase 1: Internal parallel resolution**
When `container.get("Service")` is called:
1. Look up rule for "Service"
2. For each param: if param is an `Interface` seal, recursively resolve
3. If any param rule has `asyncResolve: true`, spin up a fiber for it
4. The container's `get()` method blocks (runs fibers to completion) and returns the value
5. Internally, independent params resolve in parallel via fiber switching

**Phase 2: Explicit async access (optional v1.5)**
`container.get_async("Service")` returns a fiber. Caller decides when to call/try.

**Why blocking by default?**
Wren's Fiber API is lightweight. A "blocking" `get()` that internally fiber-swaps
is still cooperative — it doesn't block the OS thread. It just blocks the calling
fiber until the dependency tree is ready. This is the right default: 90% of use
cases want the value, not a fiber handle.

## 5. Rule Inheritance

Rules can inherit from other rules:

```wren
container.addRule("BaseService", Rule.new().shared(true).classDef(BaseService))
container.addRule("MyService", Rule.new().inheritInstanceOf("BaseService").classDef(MyService))
```

Inheritance merges: child fields override parent. `params`, `calls`, `lazyCalls`
are concatenated (child appended to parent), not replaced. `classDef`, `shared`,
`singleton` are replaced if child defines them.

## 6. Error Handling

Wren has no exceptions. Runtime errors halt the fiber. Our approach:

1. **Validation errors** (missing rule, cyclic dependency) → abort via `Fiber.abort()`
2. **Resolution errors** (factory returns null, class construction fails) → `Fiber.abort()`
3. **Type checking** (interface mismatch) → `Fiber.abort()` with descriptive message

Test harness catches aborts with `fiber.try()` and reports them.

## 7. API Surface (User-Facing)

```wren
import "dojo" for Dojo

var container = Dojo.container()

// Rule DSL (fluent)
container.addRule("Logger", Rule.new()
  .classDef(ConsoleLogger)
  .shared(true))

container.addRule("Service", Rule.new()
  .classDef(MyService)
  .params([DoJo.interface("Logger"), Dojo.value("production")]))

// Resolve
var svc = container.get("Service")

// Query
if (container.has("Logger")) {
  System.print("Logger is registered")
}

// Factory helper
container.addRule("Config", Rule.new()
  .factory(Dojo.factory { |env|
    return Config.new(env)
  }))
```

## 8. Test Strategy

Wren has no built-in test framework. We'll write a minimal runner:

```wren
class TestRunner {
  static run(name, fn) {
    var fiber = Fiber.new(fn)
    var error = fiber.try()
    if (error != null) {
      System.print("FAIL: %(name) — %(error)")
    } else {
      System.print("PASS: %(name)")
    }
  }
}
```

Tests cover:
- Basic resolution (class, factory, value)
- Recursive resolution (A depends on B depends on C)
- Shared/singleton lifecycle
- Calls/lazyCalls post-construction
- Async resolution with fibers
- Rule inheritance
- Error cases (cyclic deps, missing rules)

## 9. v1 Scope

| Feature | In v1? |
|---------|--------|
| Container + Rule + Seal | ✅ |
| Recursive resolution | ✅ |
| Shared / Singleton | ✅ |
| Calls / lazyCalls | ✅ |
| Async via fibers | ✅ |
| Rule inheritance (merge) | ✅ |
| Interface type checking (is) | ✅ |
| Substitutions | ✅ |
| sharedInTree | ❌ v1.5 |
| Directory loader | ❌ v2 |
| Decorators | ❌ never |
| Autoload | ❌ never |
| Global container key | ❌ never |
