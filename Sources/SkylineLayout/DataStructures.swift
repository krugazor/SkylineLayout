//
//  DataStructures.swift
//  SkylineLayout
//
//   © Zino 2024
//

import SwiftUI

struct SkylinePacking {
  var maxWidth : CGFloat
  var minGapWidth : CGFloat = 10
  var minGapHeight : CGFloat = 2
  var minPitRatio : CGFloat = 0.05

  var currentSkyline : [(x: CGFloat, y: CGFloat, width: CGFloat)] = []
  
  /*
   |----------------------------------
   |     |              |            |
   |     |              |------------|
   |-----|              |
   |     |              |
   |     |--------------|
   |
   |
   |
   |
   */
  
  mutating func updateSkyline(viewSize: CGSize) -> CGRect {
    if viewSize.width <= 0 || viewSize.height <= 0 { /// Weird edge case
      return CGRect.zero
    }
    
    if currentSkyline.isEmpty { // first view
      currentSkyline.append((0,viewSize.height,viewSize.width))
      currentSkyline.append((viewSize.width,0,maxWidth-viewSize.width))
      return CGRect(origin: CGPoint.zero, size: viewSize)
    }
    
    var optimized = false
    // we need to defragment the "base", otherwise we will never find candidates again
    // clear up the small holes (< min hole width)
    while let smallGap = currentSkyline.enumerated().filter({ $0.element.x >= viewSize.width && $0.element.width < minGapWidth }).first {
      let mergeWith = currentSkyline[smallGap.offset-1]
      currentSkyline.replaceSubrange(smallGap.offset-1...smallGap.offset, with: [(mergeWith.x, mergeWith.y, mergeWith.width+smallGap.element.width)])
      optimized = true
    }
    // merge similar heights
    var currentIdx = 0
    while currentIdx < currentSkyline.count-1 {
      let currentItem = currentSkyline[currentIdx]
      var currentMaxY = currentItem.y
      var upToIdx = currentIdx + 1
      while upToIdx < currentSkyline.count && abs(currentSkyline[upToIdx].y - currentItem.y) < minGapHeight {
        currentMaxY = max(currentMaxY,currentSkyline[upToIdx].y)
        upToIdx += 1
      }
      if upToIdx - currentIdx > 1 {
        let upToItem = currentSkyline[upToIdx-1]
        currentSkyline.replaceSubrange(currentIdx..<upToIdx, with: [(currentItem.x,currentMaxY,upToItem.x + upToItem.width - currentItem.x)])
        optimized = true
      } else {
        currentIdx += 1
      }
    }
    // Find "pits" (super narrow and deep holes)
    if currentSkyline.count >= 3 {
      let maxHeightItem = currentSkyline.max(by: { $0.y < $1.y })!.y + viewSize.height
      var pits : [Int] = []
      for item in currentSkyline.enumerated() {
        if item.offset < 1 { // first item, check only right
          let nextitem = currentSkyline[item.offset+1]
          if nextitem.y > item.element.y && item.element.width / (maxHeightItem - item.element.y) <= minPitRatio {
            pits.append(item.offset)
          }
        } else if item.offset == currentSkyline.count - 1 { // last item, check only left
          let previtem = currentSkyline[item.offset-1]
          if previtem.y > item.element.y && item.element.width / (maxHeightItem - item.element.y) <= minPitRatio {
            pits.append(item.offset)
          }
        } else {
          let previtem = currentSkyline[item.offset-1]
          let nextitem = currentSkyline[item.offset+1]
          if previtem.y > item.element.y && nextitem.y > item.element.y && item.element.width / (maxHeightItem - item.element.y) <= minPitRatio {
            pits.append(item.offset)
          }
        }
      }
      for pit in pits.reversed() { // start at the end, otherwise all the indices are fed up
        if pit == 0 {
          let nextitem = currentSkyline[1]
          currentSkyline.replaceSubrange(0...1, with: [(0,nextitem.y, nextitem.x+nextitem.width)])
        } else if pit == currentSkyline.count-1 {
          let previtem = currentSkyline[pit-1]
          currentSkyline.replaceSubrange(pit-1...pit, with: [(previtem.x, previtem.y, previtem.width+currentSkyline[pit].width)])
        } else {
          // merge with the lowest
          let previtem = currentSkyline[pit-1]
          let item = currentSkyline[pit]
          let nextitem = currentSkyline[pit+1]
          if previtem.y < nextitem.y {
            currentSkyline.replaceSubrange(pit-1...pit, with: [(previtem.x, previtem.y, previtem.width+currentSkyline[pit].width)])
          } else {
            currentSkyline.replaceSubrange(pit...pit+1, with: [(item.x, nextitem.y, nextitem.width+currentSkyline[pit].width)])
          }
        }
      }
    }
    
    if currentSkyline.count > 3 && currentSkyline.last!.width < viewSize.width {
      // at some point the algorithm builds a tower, especially if the views are bigger and bigger
      let maxHeightItem = currentSkyline.max(by: { $0.y < $1.y })!
      let averageHeight = currentSkyline.reduce(0, { $0 + $1.y }) / CGFloat(currentSkyline.count)
      if maxHeightItem.y > averageHeight * 1.5 { // seems like a good ratio
        let minHeight = Set(currentSkyline.map({ $0.y })).sorted()[1]
        let items = currentSkyline.enumerated().filter({ $0.element.y < minHeight }).sorted(by: { $1.offset < $0.offset })
        for item in items {
          currentSkyline[item.offset] = (item.element.x,minHeight,item.element.width)
        }
        
        return updateSkyline(viewSize: viewSize)
      }
    }
        
    let candidates = currentSkyline.enumerated().filter({ $0.element.width >= viewSize.width })
    if candidates.isEmpty {
      // Find the biggest gap leaving a smaller hole
      let orderedSkyline = currentSkyline.enumerated().sorted(by: { $0.element.y < $1.element.y })
      for (itemPos, item) in orderedSkyline {
        // look for neighbours to "absorb" in the new floor
        var lookup : (Int,Int) = (itemPos, itemPos)
        var currentLookup = itemPos - 1
        while currentLookup >= 0 {
          if currentSkyline[currentLookup].y > item.y { break }
          currentLookup -= 1
        }
        lookup.0 = max(0,currentLookup+1)
        currentLookup = itemPos + 1
        while currentLookup < currentSkyline.count {
          if currentSkyline[currentLookup].y > item.y { break }
          currentLookup += 1
        }
        lookup.1 = min(currentSkyline.count-1,currentLookup - 1)
        // see if the floor is wide enough
        let cumulativeWidth = currentSkyline[lookup.0...lookup.1].reduce(0, { $0 + $1.width })
        // fill the space
        if cumulativeWidth >= viewSize.width {
          print("yay?")
          let newRect = CGRect(x: currentSkyline[lookup.0].x, y: item.y, width: viewSize.width, height: viewSize.height)
          var replacementSkyline : [(x: CGFloat, y: CGFloat, width: CGFloat)] = [(currentSkyline[lookup.0].x, item.y+viewSize.height, viewSize.width)]
          currentLookup = lookup.0 + 1
          var widthSoFar = currentSkyline[lookup.0].width
          while widthSoFar + currentSkyline[currentLookup].width < viewSize.width { // Not good for some reason
            widthSoFar += currentSkyline[currentLookup].width
            currentLookup += 1
          }
          let remainingWidth = (currentSkyline[currentLookup].x+currentSkyline[currentLookup].width) - newRect.maxX
          if remainingWidth > 0 { replacementSkyline.append((currentSkyline[currentLookup].x+currentSkyline[currentLookup].width-remainingWidth,currentSkyline[currentLookup].y, remainingWidth)) }
          if lookup.1 > currentLookup { replacementSkyline.append(contentsOf: currentSkyline[currentLookup+1...lookup.1]) }
          // sanity check
          assert(cumulativeWidth == replacementSkyline.reduce(0, { $0 + $1.width }), "The widths should remain the samep")
          currentSkyline.replaceSubrange(lookup.0...lookup.1, with: replacementSkyline)
          return newRect
        }
      }
      // wasted space, got to recalculate pretty much everything
      var newSkyline : [(x: CGFloat, y: CGFloat, width: CGFloat)] = []
      let base = currentSkyline.map({ $0.y }).max()!
      newSkyline.append((0,base,viewSize.width))
      
      var below = currentSkyline.filter({ $0.x + $0.width > viewSize.width })
      for item in below {
        if item.x < viewSize.width { // partial cover
          newSkyline.append((viewSize.width,item.y,item.x+item.width-viewSize.width))
        } else {
          newSkyline.append(item)
        }
      }
      currentSkyline = newSkyline
      return CGRect(origin: CGPoint(x: 0, y: base), size: viewSize)
    }
    
    // general case, find the lowest point and recalculate
    if let best = candidates.min(by: { $0.element.y < $1.element.y }) {
      let inserted : (x: CGFloat, y: CGFloat, width: CGFloat) = (best.element.x, best.element.y+viewSize.height, viewSize.width)
      let remaining : (x: CGFloat, y: CGFloat, width: CGFloat) = (best.element.x+viewSize.width, best.element.y, best.element.width-viewSize.width)
      if remaining.width > 0 {
        currentSkyline.replaceSubrange(best.offset...best.offset, with: [inserted,remaining])
      } else {
        currentSkyline.replaceSubrange(best.offset...best.offset, with: [inserted])
      }
      return CGRect(x: best.element.x, y: best.element.y, width: viewSize.width, height: viewSize.height)
    }
    
    return CGRect.zero
  }
  
}
