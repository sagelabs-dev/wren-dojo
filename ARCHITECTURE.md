# Wren Dojo — Architecture Document

> Runtime-resolved dependency injection for Wren. Fiber-based async. Composition-Root IoC.
> Version: 1.5.0

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
│   ├── resolver.wren      # Recursive dependency walker + instance builder + async fiber scheduler
│   ├── lifecycle.wren     # Shared, Singleton, Instance lifecycle managers
│   └── seal.wren          # Seal base + Interface, Value, Factory, ClassFactory
├── test/
│   ├── test_container.wren    # Basic container operations
│   ├── test_dojo_api.wren     # Public API facade
│   ├── test_e2e.wren          # Deep resolution chains, composition root
│   ├── test_error_handling.wren # Cyclic deps, missing rules
│   ├── test_inheritance.wren  # Rule inheritance merging
│   ├── test_lifecycle.wren   # Shared, singleton, InstanceCache
│   ├── test_seals.wren       # All seal types
│   └── test_v15.wren         # Arity 0-8, config objects, async resolution
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
- `calls` — list of [methodName, params] to call after construction (deferred to v2)
- `lazyCalls` — same as calls, but deferred until first access (deferred to v2)
- `shared` — if true, resolve once and cache instance
- `singleton` — a pre-built instance to return directly
- `asyncResolve` — if true, params resolve in parallel via fibers (v1.5)
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
2. Resolve params (recursively, optionally in parallel via fibers)
3. Instantiate with arity-dispatched constructor (0–8 params supported)
4. Cache if shared/singleton
5. Return instance

**Arity dispatch:** Wren has no spread operator. The resolver hardcodes constructor
calls for arities 0 through 8. For constructors needing more than 8 params, use
a Map (config object) as a single param and destructure inside the constructor.
The Factory seal is also available for arbitrary-arity creation via closure.

**Async resolution:** When a rule has `asyncResolve: true`, the resolver creates
one fiber per param. Each fiber resolves its param independently. Fibers are
resumed round-robin until all complete. Results are collected and the instance
is constructed. This is cooperative — it blocks the calling fiber, not the OS thread.

### Lifecycle
Manages instance caching:
- `InstanceCache` — stores resolved instances by rule key
- `SharedManager` — lazy singleton per rule
- `SingletonManager` — pre-built instance

## 4. Async Model

Wren fibers are cooperative, not preemptive. Our async strategy:

**Blocking `get()` with internal fiber parallelism**
When `container.get("Service")` is called and the Service rule has `asyncResolve: true`:
1. Look up rule for "Service"
2. For each param: spin up a `Fiber.new { ... }` that resolves that param
3. Start all fibers with `.call()`
4. Round-robin resume any fiber that isn't `.isDone` using `.transfer()`
5. When all fibers complete, collect results and instantiate
6. Return the value

**Why blocking by default?**
Wren's Fiber API is lightweight. A "blocking" `get()` that internally fiber-swaps
is still cooperative — it doesn't block the OS thread. It just blocks the calling
fiber until the dependency tree is ready. This is the right default: 90% of use
cases want the value, not a fiber handle.

**Why fibers per param?**
When multiple params are independent (e.g., Database and Logger both injected into
Service), they can resolve in parallel. The fiber scheduler interleaves their
execution. If one param's resolution yields (e.g., waiting on I/O in a future
version), the others continue.

**Current limitation:** The async scheduler resolves params in parallel, but the
underlying Wren VM doesn't currently preempt. All resolution is CPU-bound.
The async infrastructure is in place for when Wren gains true fiber yield points
or when foreign methods perform I/O.

## 5. Rule Inheritance

Rules can inherit from other rules:

```wren
container.addRule("BaseService", Rule.new().shared(true).classDef(BaseService))
container.addRule("MyService", Rule.new().inheritInstanceOf("BaseService").classDef(MyService))
```

Inheritance merges: child fields override parent. `params`, `calls`, `lazyCalls`
are concatenated (child appended to parent), not replaced. `classDef`, `shared`,
`singleton`, `asyncResolve` are replaced if child defines them.

## 6. Error Handling

Wren has no exceptions. Runtime errors halt the fiber. Our approach:

1. **Validation errors** (missing rule, cyclic dependency) → abort via `Fiber.abort()`
2. **Resolution errors** (factory returns null, class construction fails) → `Fiber.abort()`
3. **Type checking** (interface mismatch) → `Fiber.abort()` with descriptive message
4. **Arity overflow** (>8 params) → `Fiber.abort()` with guidance to use Map or Factory seal

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
  .params([Dojo.interface("Logger"), Dojo.value("production")]))

// Async resolution (v1.5)
container.addRule("AsyncService", Rule.new()
  .classDef(MyService)
  .params([Dojo.interface("Logger"), Dojo.interface("Config")])
  .asyncResolve(true))

// Resolve
var svc = container.get("Service")

// Query
if (container.has("Logger")) {
  System.print("Logger is registered")
}

// Factory helper
container.addRule("Config", Rule.new()
  .params([Dojo.factory { |env|
    return Config.new(env)
  }]))
```

## 8. Test Strategy

Tests use [wren-testie](https://github.com/joshgoebel/wren-testie), a minimal
Wren test framework.

Coverage:
- Basic resolution (class, factory, value)
- Recursive resolution (A depends on B depends on C)
- Shared/singleton lifecycle
- All seal types (Interface, Value, Factory, ClassFactory)
- Arity dispatch (0–8 params)
- Config object pattern (Map as single param)
- Async resolution with fibers (single param, multiple params, mixed seals, deep chains)
- Rule inheritance
- Error cases (cyclic deps, missing rules, arity overflow)

## 9. Feature Matrix

| Feature | Status | Version |
|---------|--------|---------|
| Container + Rule + Seal | ✅ | v1.0 |
| Recursive resolution | ✅ | v1.0 |
| Shared / Singleton | ✅ | v1.0 |
| Substitutions | ✅ | v1.0 |
| Rule inheritance (merge) | ✅ | v1.0 |
| Interface type checking (`is`) | ✅ | v1.0 |
| Arity 0–8 dispatch | ✅ | v1.5 |
| Config object pattern (Map param) | ✅ | v1.5 |
| Async resolution via fibers | ✅ | v1.5 |
| Calls / lazyCalls | ❌ | v2.0 — blocked on dynamic method invocation |
| sharedInTree | ❌ | v2.0 |
| Directory loader | ❌ | v2.0 |
| Decorators | ❌ | never |
| Autoload | ❌ | never |
| Global container key | ❌ | never |
