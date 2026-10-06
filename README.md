# wren-dojo 🪷

> *"The art of dependency injection, distilled for Wren."*

**wren-dojo** is a runtime-resolved dependency injection container for
[Wren](http://wren.io).  Inspired by the design philosophy of
[di-ninja](https://github.com/di-ninja/di-ninja) and shaped by the
constraints and beauty of Wren itself, it brings the power of
Composition-Root Inversion of Control to a language that prizes
simplicity above all else.

## Why "Dojo"?

A dojo is a place of disciplined practice — where one returns again and
again to refine the fundamentals.  Dependency injection, at its heart,
is exactly that: a disciplined practice of separating what an object
*needs* from how it *gets* it.  This library is not a framework.  It is
a tool for practitioners.

The original di-ninja was a masterpiece of JavaScript DI — decorators,
lazy loading, tree-scoped singletons, async resolution with Promises.
wren-dojo is its spiritual successor, reborn for a language with no
decorators, no Promises, and no spread operator.  What remains is the
essence: a container, rules, and the art of letting objects receive
their dependencies rather than seeking them.

## Installation

```bash
git clone https://github.com/sagelabs-dev/wren-dojo.git
cd wren-dojo
```

Requires [wren-console](https://github.com/joshgoebel/wren-console) or
[wren-cli](https://github.com/wren-lang/wren-cli) as the Wren runtime.

## Quick Start

```wren
import "wren-dojo/src/dojo" for Dojo
import "wren-dojo/src/container" for Container
import "wren-dojo/src/rule" for Rule
import "wren-dojo/src/seal" for Interface, Value

class Logger {
  construct new() {}
  log(msg) { System.print(msg) }
}

class Service {
  construct new(logger) {
    _logger = logger
  }
  work() {
    _logger.log("Working!")
  }
}

// --- Composition Root ---
var container = Container.new()

container.addRule("Logger", Rule.new()
  .classDef = Logger
  .shared = true
)

container.addRule("Service", Rule.new()
  .classDef = Service
  .params = [Interface.new("Logger")]
)

// --- Resolve ---
var svc = container.get("Service")
svc.work()  //> Working!
```

## The Container

The `Container` is the dojo itself.  It holds *rules* — instructions for
how to build each dependency — and resolves them on demand.

```wren
var container = Container.new()
container.addRule("Name", rule)
var instance = container.get("Name")
```

## Rules

A `Rule` tells the resolver how to construct a dependency:

| Property | Type | Meaning |
|----------|------|---------|
| `classDef` | `Class` | The class to instantiate |
| `params` | `List` | Constructor arguments |
| `shared` | `Bool` | Resolve once, cache forever |
| `singleton` | `Object` | Use this pre-built instance |
| `asyncResolve` | `Bool` | Resolve params in parallel via fibers (v1.5) |
| `inheritInstanceOf` | `String` | Inherit from another rule |
| `substitutions` | `Map` | Override param values |

Rules are plain value objects — set properties after construction:

```wren
var rule = Rule.new()
rule.classDef = MyClass
rule.params = [Interface.new("Other")]
rule.shared = true
```

## Seals — Typed Parameter Markers

When you pass a parameter to a rule, the resolver needs to know what to
do with it.  Seals are typed markers:

- **`Interface.new("Key")`** — resolve "Key" from the container and
  inject the result
- **`Value.new(42)`** — pass the literal value through as-is
- **`Factory.new { return Thing.new() }`** — call the function and
  inject its return value
- **`ClassFactory.new(Thing)`** — instantiate `Thing.new()` and
  inject the result

A plain `String` in a params list is treated as an `Interface` — a
convenience shorthand.

## Lifecycle

### Shared

Resolve once, return the same instance forever:

```wren
rule.shared = true
var a = container.get("Logger")
var b = container.get("Logger")
Expect.that(a).toBe(b)  // same object
```

### Singleton

Provide a pre-built instance directly:

```wren
var logger = Logger.new()
rule.singleton = logger
var got = container.get("Logger")
Expect.that(got).toBe(logger)  // exact same instance
```

## Arity & The Config Object Pattern

Wren has no spread operator. The resolver supports constructors with
**0 through 8 parameters**, dispatching to the correct `new()` overload.

```wren
class Service {
  construct new(a, b, c, d, e, f, g, h) {
    // all 8 params received
  }
}
```

For constructors needing more than 8 params, use a **Map (config object)**
as a single param and destructure inside the constructor:

```wren
class BigService {
  construct new(config) {
    _host = config["host"]
    _port = config["port"]
    // ... destructure as needed
  }
}

container.addRule("BigService", Rule.new()
  .classDef = BigService
  .params = [Value.new({
    "host": "localhost",
    "port": 8080,
    "debug": true,
    "timeout": 30
  })]
)
```

The `Value` seal passes the Map through as-is. This is the canonical
Wren idiom for complex configuration.

Alternatively, the `Factory` seal supports arbitrary-arity creation
via closure:

```wren
container.addRule("BigService", Rule.new()
  .params = [Factory.new {
    return BigService.new(a, b, c, d, e, f, g, h, i, j)
  }]
)
```

## Async Resolution (v1.5)

Wren has no Promises. Instead, wren-dojo uses Wren's native **fibers**
for cooperative multitasking during resolution.

Enable async on a per-rule basis:

```wren
container.addRule("Service", Rule.new()
  .classDef = MyService
  .params = [Interface.new("Database"), Interface.new("Logger")]
  .asyncResolve = true
)
```

When `asyncResolve` is true, each param is resolved in its own fiber.
Fibers run cooperatively (round-robin resume) until all complete, then
the instance is constructed. The `get()` call blocks the calling fiber
until resolution finishes — not the OS thread.

This is especially useful when:
- Multiple independent params can resolve in parallel
- Params perform I/O (when Wren gains I/O fiber yield points)
- Foreign methods perform blocking operations

### Async + Shared

Shared lifecycle works correctly with async resolution. If a param resolves
to a shared instance, all concurrent fibers requesting that instance
receive the same cached object:

```wren
container.addRule("Logger", Rule.new()
  .classDef = Logger
  .shared = true
)

container.addRule("Service", Rule.new()
  .classDef = Service
  .params = [Interface.new("Logger"), Interface.new("Logger")]
  .asyncResolve = true
)

var svc = container.get("Service")
// svc.logger and svc.repo are the SAME shared Logger instance
```

## Rule Inheritance

Rules can inherit from other rules via `inheritInstanceOf`:

```wren
container.addRule("Base", Rule.new()
  .classDef = BaseService
  .params = [Interface.new("Logger")]
)

container.addRule("Extended", Rule.new()
  .inheritInstanceOf = "Base"
  .classDef = ExtendedService
)
```

Inherited rules merge:
- **Scalar fields**: child overrides parent (`classDef`, `shared`, `asyncResolve`, etc.)
- **Collections**: concatenated (`params`, `inheritMixins`)
- **Maps**: child overwrites parent keys (`substitutions`)

## Error Handling

The resolver uses Wren's fiber-based error handling:

- **Missing rule** → `Fiber.abort("No rule found for key: ...")`
- **Cyclic dependency** → `Fiber.abort("Cyclic dependency detected: ...")`
- **Constructor arity overflow** → `Fiber.abort("Instantiation supports max 8 params...")`
- **Missing inherited rule** → `Fiber.abort("Inherit rule not found: ...")`

Wrap resolution in `Fiber.new { ... }.try()` to capture errors gracefully.

## Module Layout

```
wren-dojo/
├── src/
│   ├── dojo.wren          # Public API — Dojo static helpers
│   ├── container.wren     # Container class — registry + entry point
│   ├── rule.wren          # Rule value object
│   ├── resolver.wren      # Recursive dependency walker + async fiber scheduler
│   ├── lifecycle.wren     # InstanceCache for shared/singleton
│   └── seal.wren          # Seal markers: Interface, Value, Factory, ClassFactory
├── test/
│   ├── test_container.wren     # Core container tests
│   ├── test_seals.wren         # Seal type tests
│   ├── test_lifecycle.wren     # Shared, singleton, cache tests
│   ├── test_inheritance.wren   # Rule inheritance tests
│   ├── test_error_handling.wren # Error condition tests
│   ├── test_dojo_api.wren      # Public API tests
│   ├── test_e2e.wren           # Full application simulation
│   └── test_v15.wren           # Arity, config objects, async tests
├── README.md
└── LICENSE
```

## Testing

Tests use [wren-testie](https://github.com/joshgoebel/wren-testie), a
lightweight test framework for Wren Console.

```bash
cd wren-dojo
wrenc test/test_container.wren
wrenc test/test_v15.wren
```

**Current status: 61 tests passing across 8 test files.**

## Feature Matrix

| Feature | Status | Since |
|---------|--------|-------|
| Container, Rule, Seal | ✅ | v1.0 |
| Recursive resolution | ✅ | v1.0 |
| Shared / Singleton | ✅ | v1.0 |
| Substitutions | ✅ | v1.0 |
| Rule inheritance | ✅ | v1.0 |
| Interface type checking | ✅ | v1.0 |
| Arity 0–8 dispatch | ✅ | v1.5 |
| Config object pattern | ✅ | v1.5 |
| Async resolution (fibers) | ✅ | v1.5 |
| Calls / lazyCalls | ❌ | v2.0 — blocked on dynamic method invocation |
| sharedInTree | ❌ | v2.0 |

## Acknowledgements

This library is a love letter to [di-ninja](https://github.com/di-ninja/di-ninja),
a JavaScript DI container of remarkable elegance and depth.  di-ninja
taught me that dependency injection is not merely a pattern but a
practice — a dojo.  Everything good here traces back to that lineage;
all errors and omissions are my own.

Built for Wren, built with love. 🪷

## Sponsors

If wren-dojo is useful to you, consider supporting its continued development:

- **[GitHub Sponsors](https://github.com/sponsors/guan-tends)**
- **Bitcoin:** `bc1q0gd3mwjg3zy9sghv22kmpg823vss4c0zzdzg24`
- **Solana:** `Eu8wQcW68TKMs1a6eqzZu8znzU52QLqQugAMG8uCD6y6`
- **Ethereum / EVM:** `0x2733ff7c865C56d565a99BE1DC11B81cc76850A5`
- **XRP Ledger:** `r4X6e7McAQj7e8vBCeued1RYu4mCJrREDG`

---

Crafted with ❤️ by [Sage Labs](https://sagelabs.dev)
