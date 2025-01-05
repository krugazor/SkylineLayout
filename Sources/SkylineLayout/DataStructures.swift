//
//  DataStructures.swift
//  SkylineLayout
//
//   © Nicolas Zinovieff (aka Zino) 2024
//

import SwiftUI

/// Used for debugging messages - mostly during development. Il will probably go away at some point, but it's useful while I bang my head against edge-cases
/// - Parameters:
///   - message: the message to print
///   - file: location info - file (defaults to where it is)
///   - function: location info - function (defaults to where it is)
///   - line: location info - line (defaults to where it is)
public func track(_ message: String, file: String = #file, function: String = #function, line: Int = #line ) {
#if false
  print("\(message) called from \(function) \(file):\(line)")
#endif
}

/// Internal structure used to keep track of the current state of the packing algorithm
struct SkylinePacking {
  /// maximum allowable width for the packing of the elements
  var maxWidth : CGFloat
  /// horizontal gap between neighboring views under which the algorithm considers them having a common border
  var minGapWidth : CGFloat = 10
  /// vertical gap between neighboring views under which the algorithm considers them having a common border
  var minGapHeight : CGFloat = 2
  /// after a while, towers of views form, leaving "pits" where no view can ultimately go. When the width/height ration becomes extreme, the algorithm will consider this wasted space and "fill" it
  var minPitRatio : CGFloat = 0.10
  
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
  
  /// For debugging purposes, outputs dots for filled space and spaces for empties
  /// - Returns: a printable string
  /// Warning: Super resource intensive, DO NOT USE unless you absolutely need to
  func printSkyline() -> String {
    var output = ""
    
    let maxY = currentSkyline.max(by: { $0.y < $1.y })!.y
    for y in 0..<Int(maxY) {
      output += (0...Int(self.maxWidth)).map({
        let x = CGFloat($0)
        if let within = currentSkyline.first(where: { $0.x > x }) {
          return within.y >= CGFloat(y) ? "." : " "
        } else {
          let within = currentSkyline.last!
          return within.y >= CGFloat(y) ? "." : " "
        }
      })
      output += "\n"
    }
    
    return output
  }
  
  /// Fits an incoming view into the current available space as best as it can, uptating itself in the process
  /// - Parameter viewSize: the size of the view that should be fitted in the structure
  /// - Returns: the view rectangle where the algorithm decided to put it
  mutating func updateSkyline(viewSize: CGSize) -> CGRect {
    if viewSize.width <= 0 || viewSize.height <= 0 { /// Weird edge case
      return CGRect.zero
    }
    
    if currentSkyline.isEmpty { // first view
      currentSkyline.append((0,viewSize.height,viewSize.width))
      currentSkyline.append((viewSize.width,0,maxWidth-viewSize.width))
      return CGRect(origin: CGPoint.zero, size: viewSize)
    }
    
    // we need to defragment the "base", otherwise we will never find candidates again
    // clear up the small holes (< min hole width)
    while let smallGap = currentSkyline.enumerated().filter({ $0.element.x >= viewSize.width && $0.element.width < minGapWidth }).first {
      let mergeWith = currentSkyline[smallGap.offset-1]
      currentSkyline.replaceSubrange(smallGap.offset-1...smallGap.offset, with: [(mergeWith.x, mergeWith.y, mergeWith.width+smallGap.element.width)])
      track("plugged gap")
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
        let newWidth = (currentIdx..<upToIdx).reduce(0, { $0 + currentSkyline[$1].width })
        currentSkyline.replaceSubrange(currentIdx..<upToIdx, with: [(currentItem.x,currentMaxY,newWidth)])
        // currentSkyline.replaceSubrange(currentIdx..<upToIdx, with: [(currentItem.x,currentMaxY,upToItem.x + upToItem.width - currentItem.x)])
        track("plugged height")
      } else {
        currentIdx += 1
      }
    }
    // Find "pits" (super narrow and deep holes)
    if currentSkyline.count >= 3 {
      let maxHeightItem = currentSkyline.max(by: { $0.y < $1.y })!.y
      var pits : [Int] = []
      
      let areas : [(offset: Int, area: CGFloat)] = currentSkyline.enumerated().map({ ($0.offset, $0.element.width / max(0.001, maxHeightItem - $0.element.y)) })
      let gaps = areas.filter({ $0.area <= minPitRatio }).map({ $0.offset })
      pits.append(contentsOf: gaps )
      if !pits.isEmpty {
        track("plugged pits at \(pits.map({ "\(Int(currentSkyline[$0].x))" }).joined(separator: ", "))")
      }
      for pit in pits.reversed() { // start at the end, otherwise all the indices are fed up
        let item = currentSkyline[pit]
        if pit == 0 {
          let nextitem = currentSkyline[1]
          currentSkyline[pit] = (item.x, nextitem.y, item.width)
        } else if pit == currentSkyline.count-1 {
          let previtem = currentSkyline[pit-1]
          currentSkyline[pit] = (item.x, previtem.y, item.width)
        } else {
          // merge with the lowest
          let previtem = currentSkyline[pit-1]
          let nextitem = currentSkyline[pit+1]
          if previtem.y < nextitem.y {
            currentSkyline[pit] = (item.x, max(previtem.y,item.y), item.width)
            currentSkyline[pit-1] = (previtem.x, max(previtem.y,item.y), previtem.width)
            track("plugged pit before")
          } else {
            currentSkyline[pit] = (item.x, max(nextitem.y,item.y), item.width)
            currentSkyline[pit+1] = (nextitem.x, max(nextitem.y,item.y), nextitem.width)
            track("plugged pitafter")
          }
        }
      }
      
      if !pits.isEmpty {
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
          track("plugged frag")
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
          currentSkyline.replaceSubrange(lookup.0...lookup.1, with: replacementSkyline)
          return newRect
        }
      }
      // wasted space, got to recalculate pretty much everything
      var newSkyline : [(x: CGFloat, y: CGFloat, width: CGFloat)] = []
      let base = currentSkyline.map({ $0.y }).max()!
      newSkyline.append((0,base,viewSize.width))
      
      let below = currentSkyline.filter({ $0.x + $0.width > viewSize.width })
      for item in below {
        if item.x < viewSize.width { // partial cover
          newSkyline.append((viewSize.width,item.y,item.x+item.width-viewSize.width))
        } else {
          newSkyline.append(item)
        }
      }
      currentSkyline = newSkyline
      track("generated holes")
      return CGRect(origin: CGPoint(x: 0, y: base), size: viewSize)
    }
    
    // general case, find the lowest point and recalculate
    if let best = candidates.min(by: { $0.element.y < $1.element.y }) {
      // TODO: shunt left if there's a gap
      let inserted : (x: CGFloat, y: CGFloat, width: CGFloat) = (best.element.x, best.element.y+viewSize.height, viewSize.width)
      let remaining : (x: CGFloat, y: CGFloat, width: CGFloat) = (best.element.x+viewSize.width, best.element.y, best.element.width-viewSize.width)
      if remaining.width > 0 {
        currentSkyline.replaceSubrange(best.offset...best.offset, with: [inserted,remaining])
        track("plugged general w/ remaining")
      } else {
        currentSkyline.replaceSubrange(best.offset...best.offset, with: [inserted])
        track("plugged general w/o remaining")
      }
      return CGRect(x: best.element.x, y: best.element.y, width: viewSize.width, height: viewSize.height)
    }
    
    return CGRect.zero
  }
  
}
