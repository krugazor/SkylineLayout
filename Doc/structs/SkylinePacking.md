**STRUCT**

# `SkylinePacking`

**Contents**

- [Properties](#properties)
  - `maxWidth`
  - `minGapWidth`
  - `minGapHeight`
  - `minPitRatio`
  - `currentSkyline`
- [Methods](#methods)
  - `printSkyline()`
  - `updateSkyline(viewSize:)`

```swift
struct SkylinePacking
```

Internal structure used to keep track of the current state of the packing algorithm

## Properties
### `maxWidth`

```swift
var maxWidth : CGFloat
```

maximum allowable width for the packing of the elements

### `minGapWidth`

```swift
var minGapWidth : CGFloat = 10
```

horizontal gap between neighboring views under which the algorithm considers them having a common border

### `minGapHeight`

```swift
var minGapHeight : CGFloat = 2
```

vertical gap between neighboring views under which the algorithm considers them having a common border

### `minPitRatio`

```swift
var minPitRatio : CGFloat = 0.10
```

after a while, towers of views form, leaving "pits" where no view can ultimately go. When the width/height ration becomes extreme, the algorithm will consider this wasted space and "fill" it

### `currentSkyline`

```swift
var currentSkyline : [(x: CGFloat, y: CGFloat, width: CGFloat)] = []
```

## Methods
### `printSkyline()`

```swift
func printSkyline() -> String
```

For debugging purposes, outputs dots for filled space and spaces for empties
- Returns: a printable string
Warning: Super resource intensive, DO NOT USE unless you absolutely need to

### `updateSkyline(viewSize:)`

```swift
mutating func updateSkyline(viewSize: CGSize) -> CGRect
```

Fits an incoming view into the current available space as best as it can, uptating itself in the process
- Parameter viewSize: the size of the view that should be fitted in the structure
- Returns: the view rectangle where the algorithm decided to put it

#### Parameters

| Name | Description |
| ---- | ----------- |
| viewSize | the size of the view that should be fitted in the structure |