// lifecycle.wren — Instance caching for shared and singleton dependencies.

class InstanceCache {
  construct new() {
    _cache = {}
  }
  
  has(key) { _cache.containsKey(key) }
  
  get(key) {
    if (!has(key)) {
      Fiber.abort("InstanceCache.get: no cached instance for key: %(key)")
    }
    return _cache[key]
  }
  
  set(key, instance) {
    _cache[key] = instance
  }
  
  clear() {
    _cache = {}
  }
  
  count { _cache.count }
}
