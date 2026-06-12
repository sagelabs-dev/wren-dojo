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
git clone https://your-gitea/wren-dojo.git
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
- **Scalar fields**: child overrides parent (`classDef`, `shared`, etc.)
- **Collections**: concatenated (`params`, `inheritMixins`)
- **Maps**: child overwrites parent keys (`substitutions`)

## Error Handling

The resolver uses Wren's fiber-based error handling:

- **Missing rule** → `Fiber.abort("No rule found for key: ...")`
- **Cyclic dependency** → `Fiber.abort("Cyclic dependency detected: ...")`
- **Constructor arity mismatch** → `Fiber.abort("Instantiation supports max 4 params...")`

Wrap resolution in `Fiber.new { ... }.try()` to capture errors gracefully.

## Async Resolution (v1.5)

Wren has no Promises.  Instead, wren-dojo v1.5 will use Wren's native
fibers for cooperative multitasking during resolution.  For now,
resolution is synchronous and blocking — appropriate for Wren's
single-threaded execution model.

## Module Layout

```
wren-dojo/
├── src/
│   ├── dojo.wren          # Public API — Dojo static helpers
│   ├── container.wren     # Container class — registry + entry point
│   ├── rule.wren          # Rule value object
│   ├── resolver.wren      # Recursive dependency walker + builder
│   ├── lifecycle.wren     # InstanceCache for shared/singleton
│   └── seal.wren          # Seal markers: Interface, Value, Factory, ClassFactory
├── test/
│   ├── test_container.wren     # Core container tests
│   ├── test_seals.wren         # Seal type tests
│   ├── test_lifecycle.wren     # Shared, singleton, cache tests
│   ├── test_inheritance.wren   # Rule inheritance tests
│   ├── test_resolver.wren      # Deep resolution + error tests
│   ├── test_dojo_api.wren      # Public API tests
│   ├── test_error_handling.wren # Error condition tests
│   └── test_e2e.wren           # Full application simulation
├── README.md
└── LICENSE
```

## Testing

Tests use [wren-testie](https://github.com/joshgoebel/wren-testie), a
lightweight test framework for Wren Console.

```bash
cd wren-dojo
wrenc test/test_container.wren
```

## Acknowledgements

This library is a love letter to [di-ninja](https://github.com/di-ninja/di-ninja),
a JavaScript DI container of remarkable elegance and depth.  di-ninja
taught me that dependency injection is not merely a pattern but a
practice — a dojo.  Everything good here traces back to that lineage;
all errors and omissions are my own.

Built for Wren, built with love. 🪷
