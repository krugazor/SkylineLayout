**STRUCT**

# `SkylineLayout`

**Contents**

- [Properties](#properties)
  - `maximumWidthRatio`
  - `configuration`
  - `debugSkyline`
  - `debugCallBack`
- [Methods](#methods)
  - `makeCache(subviews:)`
  - `init(maximumWidthRatio:configuration:debugCallback:)`
  - `sizeThatFits(proposal:subviews:cache:)`
  - `placeSubviews(in:proposal:subviews:cache:)`

```swift
public struct SkylineLayout : Layout
```

Layout that packs the views starting from the top left as they come
Think of newspaper-style rectangle packing
- Warning: Will not work correctly if the width isn't "obvious" (set in stone or massively constrained)

## Properties
### `maximumWidthRatio`

```swift
@State public var maximumWidthRatio : CGFloat = 1.0
```

### `configuration`

```swift
var configuration : SkylineConfiguration
```

Maximum width an individual view is allowed to occupy, width-wise. 1.0 means the whole width, 0.5 means half width, etc

### `debugSkyline`

```swift
var debugSkyline : Bool = false
```

### `debugCallBack`

```swift
var debugCallBack : ((Path) -> Void)? = nil
```

## Methods
### `makeCache(subviews:)`

```swift
public func makeCache(subviews: Subviews) -> Cache
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| subviews | A collection of proxy instances that represent the views that the container arranges. You can use the proxies in the collection to get information about the subviews as you calculate values to store in the cache. |

### `init(maximumWidthRatio:configuration:debugCallback:)`

```swift
public init(maximumWidthRatio: CGFloat, configuration config: SkylineConfiguration = SkylineConfiguration(), debugCallback: ((Path) -> Void)? = nil)
```

### `sizeThatFits(proposal:subviews:cache:)`

```swift
public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| proposal | A size proposal for the container. The container’s parent view that calls this method might call the method more than once with different proposals to learn more about the container’s flexibility before deciding which proposal to use for placement. |
| subviews | A collection of proxies that represent the views that the container arranges. You can use the proxies in the collection to get information about the subviews as you determine how much space the container needs to display them. |
| cache | Optional storage for calculated data that you can share among the methods of your custom layout container. See `makeCache(subviews:)` for details. |

### `placeSubviews(in:proposal:subviews:cache:)`

```swift
public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData)
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| bounds | The region that the container view’s parent allocates to the container view, specified in the parent’s coordinate space. Place all the container’s subviews within the region. The size of this region matches a size that your container previously returned from a call to the `sizeThatFits(proposal:subviews:cache:)` method. |
| proposal | The size proposal from which the container generated the size that the parent used to create the `bounds` parameter. The parent might propose more than one size before calling the placement method, but it always uses one of the proposals and the corresponding returned size when placing the container. |
| subviews | A collection of proxies that represent the views that the container arranges. Use the proxies in the collection to get information about the subviews and to tell the subviews where to appear. |
| cache | Optional storage for calculated data that you can share among the methods of your custom layout container. See `makeCache(subviews:)` for details. |