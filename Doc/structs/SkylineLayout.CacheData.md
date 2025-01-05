**STRUCT**

# `SkylineLayout.CacheData`

**Contents**

- [Properties](#properties)
  - `skyline`
  - `rects`

```swift
public struct CacheData
```

Caching structure to avoid re-calculations

## Properties
### `skyline`

```swift
var skyline : SkylinePacking
```

result of the previous run of the algorithm

### `rects`

```swift
var rects : [CGRect]
```

assuming the views haven't changed order, their rectangles
