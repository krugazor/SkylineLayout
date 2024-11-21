//
//  SkylineLayout.swift
//  SkylineLayout
//
//   © Zino 2024
//

import SwiftUI

/// Layout that packs the views starting from the top left as they come
/// Think of newspaper-style rectangle packing
/// WARNING: Will not work correctly if the width isn't "obvious" (set in stone or massively constrained
/// TODO: Cache
@available(macOS 13.0, *)
public struct SkylineLayout : Layout {
  public struct CacheData {
    var skyline : SkylinePacking
    var rects : [CGRect]
  }
  
  public typealias Cache = CacheData
  public func makeCache(subviews: Subviews) -> Cache {
    return CacheData(skyline: SkylinePacking(maxWidth: 0), rects: [])
  }

  
  var maximumWidthRatio : CGFloat = 1.0 { /// Maximum width an individual view is allowed to occupy, width-wise. 1.0 means the whole width, 0.5 means half width, etc
    didSet {
      maximumWidthRatio = max(0.01,min(1,maximumWidthRatio)) // make sure we're between 0+ and 1
    }
  }
  
  public init(maximumWidthRatio: CGFloat) {
    self.maximumWidthRatio = maximumWidthRatio
  }
  
  public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
    let proposedWidth = max(cache.skyline.maxWidth, proposal.width ?? 100)
    var skyline = SkylinePacking(maxWidth: proposedWidth)
    var viewRects : [CGRect] = []
    var maxX : CGFloat = 0
    var maxY : CGFloat = 0
    for (index, subview) in subviews.enumerated() {
      // sizes are stupid
      let possibleSizes : [CGSize] = [subview.sizeThatFits(ProposedViewSize.unspecified), subview.sizeThatFits(ProposedViewSize.zero),subview.sizeThatFits(ProposedViewSize.infinity),subview.sizeThatFits(ProposedViewSize(CGSize(width: proposedWidth, height: Double.greatestFiniteMagnitude)))].filter({ $0.width > 0 && $0.height > 0 }).sorted(by: { $0.height*$0.width < $1.height*$1.width })
      let viewRect = possibleSizes[0]
      let skylineRect = skyline.updateSkyline(viewSize: viewRect)
      viewRects.append(skylineRect)
      maxX = max(maxX, skylineRect.maxX)
      maxY = max(maxY, skylineRect.maxY)
    }
    cache.rects = viewRects
    cache.skyline = skyline
    let proposedX = proposal.width ?? 0
    let proposedY = proposal.height ?? 0
    print("proposed \(CGSize(width: maxX, height: maxY))")
    return CGSize(width: maxX, height: maxY)
  }
  
  public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
    for index in subviews.indices {
      let cacheRect = cache.rects[index]
      subviews[index].place(at: CGPoint(x: bounds.minX + cacheRect.minX, y: bounds.minY + cacheRect.minY), anchor: .topLeading, proposal: ProposedViewSize(cacheRect.size))
    }
  }
  
  
}
