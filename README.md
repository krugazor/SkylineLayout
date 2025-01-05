# SkylineLayout (aka BricksLayout, aka PuzzleLayout, aka a-bunch-of-trademarked-gamesLayout)

SwiftUI layout that will attempt to fit the views in the least possible space. Nothing is perfect, though, and the algorithm used in this package will not attempt a globally optimal solution (rectangle packing being [NP Hard](https://en.wikipedia.org/wiki/Rectangle_packing)).

Overall, the views will be placed on a first come, first available place basis, and will try to use the best possible fit at the time, plugging unreclaimable holes as they appear (see [the details section](#Details))

![Demo](Doc/demo.gif)

## TL;DR / Usage

### Add the package to your dependencies

In Xcode, under the project global configuration, add this url as a package dependency. Don't forget to add the build phase and the link phase associated with using the library.

In SPM, add `.package(url: "this url", from: "1.0.0"),` to your global dependencies, then `"SkylineLayout"` to your target dependencies.

### Using it in your code

Start by importing the package by adding `import SkylineLayout` to your swift file.  
Then use it as you would another layout, like `HStack`, `VStack`, etc...

Example:
```swift
SkylineLayout(maximumWidthRatio: 0.5) {
	ForEach(currentViews, id: \.id) {
		viewFor(idx: $0.idx, itemid: $0.randomid)
    }
}
```

### Caveats

#### Order

The order in which you add the views matter, as the layout will try to fill available gap, but might *create* gaps in doing so. If you have too many empty spaces in your views, try changing the [parameters](#Parameters), or the orders of the views

#### Performance

SwiftUI is not meant to display thousands of views at once. While this algorithm is relatively efficient, it might create lag by being *too efficient*: Once too many views are on screen at the same time, the engine will slow down. Please profile your code to see where the hangups are coming from before opening an issue regarding poor performance of this layout engine.

## Parameters

`SkylineLayout.init` takes 3 arguments:
- the maximum width ratio ("column number" equivalent) for the views inside
- an observable/interactive `SkylineLayout.SkylineConfiguration` that will contain the knobs and dials of the layout's fine tuning
- a debug callback that is called every time the layout is changed

### `maximumWidthRatio`

Because view sizing in SwiftUI happens as late as possible to accomodate for all the involved constraints, a preemptive case can be made to the system to limit the views inside to a certain ratio of the layout rectangle itself.

For instance, a `maximumWidthRatio` of `1` will allow views to take the whole width, while `0.5` will attempt to limit the views to a maximum of half the whole width, etc. You can see it as an equivalent to `1/columns` in a multi-column setup. 

### `configuration`

#### `minGapWidth`

Horizontal interval between views below which they are considered "touching" (and therefore preventing anything from fitting between them). The default is `10.0` because views that are less wide than that seem extremely improbable.

#### `minGapHeight`

If two neighboring views are "almost at the same height", this limit will consider them to be exactly at the same height. It is mostly used to prevent the "floor fragmentation" problem: a collection of smaller views that amount to an uneven skyline, but very marginally so. The default is `2.0` which is almost imperceptible on modern screens.

#### `minPitRatio`

Just like with the "floor fragmentation" problem, the way the views are placed might leave gaps that will never be filled.  
When the gap reaches a certain height in regards to the width (`minPitRation` will be compared to `width/height`), the space will be considered unusable for practical purposes and "filled" to allow views to be places on top.

## Details

See [the docs](Doc/README.md) if you're looking for code details.

The general idea of the algorithm is as follows:
- look at the "skyline" (the current polyline of highest values of `y` occupied by views)
- find the *lowest* (as in `y`) space that would allow a view of that width
- update the skyline to reflect that that space is now (partially or fully) occupied by something

A few edge cases / problems arise, leading to heuristics that may or may not be the best for your use case

### Why choose the lowest and not the INSERT_OTHER_METHOD ?

So, realistically, there are two ways to pick a spot: lowest and "best fit".  
Best fit would be something like "a space that leaves as little remaining space as possible, ideally zero". The issue with that is that, while this approach leaves smaller *horizontal* gaps and pits, it also encourages tower-building (stacking all the views with the same width on top of each other), defeating the purpose of minimizing wasted space. So you would need a combination of best and lowest and another heuristic on top of it. There are many formal methods to reach an optimal packing solution, but adding another layer of heuristic complexifies performance and maintenance.   
While lowest is perfectible, it has the double advantage of being fast and predictable.

### Why the 3 knobs controlling the layout ?

Demos and tests are great, but real projects probably imply rounding errors, especially when dealing with text. Because of that and the way the algorithm works, it leads to heavy fragmentation of the skyline. Exact fits can happen, if your project have fixed view sizes but this is meant to be a general approach.  
Having some wriggle room as to when to fuse "similar" bits of the skyline allows for more control, and is therefore generally a good idea, despite the performance penalty of checking them out.

The pit ratio threshold is slightly different: there *will* be gaps that can never be used for views (unless you have fixed sized views that are a perfect divider of the width of the window). The space "on top" of these gaps may never be used again. So, the idea is to provide a tipping point: when the pit becomes high enough (denoted by the ratio of its width over its height), it can be considered "unfillable", and written off. Its top then becomes an extension of whatever ledge is around, providing a bit more width for a new view.  
The default value of `10%` feels a bit conservative and on some examples was upped to `20%` or even `33%`. All the more reason to provide access to these controlling variables.  
Plus, with animations, it's just gorgeous.

## Version history

- 0.1.0 : initial release
