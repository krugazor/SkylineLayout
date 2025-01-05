**CLASS**

# `SkylineLayout.SkylineConfiguration`

**Contents**

- [Properties](#properties)
  - `minGapWidth`
  - `minGapHeight`
  - `minPitRatio`
- [Methods](#methods)
  - `init()`
  - `init(minGapWidth:minGapHeight:minPitRatio:)`

```swift
public class SkylineConfiguration : ObservableObject
```

Animatable configuration for the layout

## Properties
### `minGapWidth`

```swift
@Published public var minGapWidth : CGFloat = 10
```

horizontal gap between neighboring views under which the algorithm considers them having a commin border

### `minGapHeight`

```swift
@Published public var minGapHeight : CGFloat = 2
```

vertical gap between neighboring views under which the algorithm considers them having a commin border

### `minPitRatio`

```swift
@Published public var minPitRatio : CGFloat = 0.10
```

after a while, towers of views form, leaving "pits" where no view can ultimately go. When the width/height ration becomes extreme, the algorithm will consider this wasted space and "fill" it

## Methods
### `init()`

```swift
public init()
```

Mandatory initializer

### `init(minGapWidth:minGapHeight:minPitRatio:)`

```swift
public init(minGapWidth: CGFloat, minGapHeight: CGFloat, minPitRatio: CGFloat)
```

Complete initializer  
See instance variable documentations for details
