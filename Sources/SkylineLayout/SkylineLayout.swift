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
@available(macOS 13.0, *)
public struct SkylineLayout : Layout {
  public struct CacheData {
    var skyline : SkylinePacking
    var rects : [CGRect]
  }
  
  public class SkylineConfiguration : ObservableObject {
    @Published public var minGapWidth : CGFloat = 10
    @Published public var minGapHeight : CGFloat = 2
    @Published public var minPitRatio : CGFloat = 0.10
    
    public init() { }
    
    public init(minGapWidth: CGFloat, minGapHeight: CGFloat, minPitRatio: CGFloat) {
      self.minGapWidth = minGapWidth
      self.minGapHeight = minGapHeight
      self.minPitRatio = minPitRatio
    }
  }
  
  public typealias Cache = CacheData
  public func makeCache(subviews: Subviews) -> Cache {
    return CacheData(skyline: SkylinePacking(maxWidth: 0, minGapWidth: configuration.minGapWidth, minGapHeight: configuration.minGapHeight,minPitRatio: configuration.minPitRatio), rects: [])
  }

  
  @State public var maximumWidthRatio : CGFloat = 1.0 { /// Maximum width an individual view is allowed to occupy, width-wise. 1.0 means the whole width, 0.5 means half width, etc
    didSet {
      if maximumWidthRatio <= 0 || maximumWidthRatio > 1 {
        maximumWidthRatio = max(0.01,min(1,maximumWidthRatio)) // make sure we're between 0+ and 1
      }
    }
  }

  var configuration : SkylineConfiguration

  var debugSkyline : Bool = false
  var debugCallBack : ((Path) -> Void)? = nil
  
  public init(maximumWidthRatio: CGFloat, configuration config: SkylineConfiguration = SkylineConfiguration(), debugCallback: ((Path) -> Void)? = nil) {
    self.maximumWidthRatio = maximumWidthRatio
    self.configuration = config
    self.debugCallBack = debugCallback
    self.debugSkyline = (debugCallback != nil)
  }
  
  public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
    let proposedWidth = max(cache.skyline.maxWidth, proposal.width ?? 100)
    var skyline = SkylinePacking(maxWidth: proposedWidth, minGapWidth: configuration.minGapWidth, minGapHeight: configuration.minGapHeight,minPitRatio: configuration.minPitRatio)
    var viewRects : [CGRect] = []
    var maxX : CGFloat = 0
    var maxY : CGFloat = 0
    for (index, subview) in subviews.enumerated() {
      // sizes are stupid
      let possibleSizes : [CGSize] = [subview.sizeThatFits(ProposedViewSize.unspecified), subview.sizeThatFits(ProposedViewSize.zero),subview.sizeThatFits(ProposedViewSize.infinity),subview.sizeThatFits(ProposedViewSize(CGSize(width: proposedWidth*maximumWidthRatio, height: Double.greatestFiniteMagnitude)))].filter({ $0.width > 0 && $0.height > 0 }).sorted(by: { $0.height*$0.width < $1.height*$1.width })
      let viewRect : CGSize
      if let proposedSize = possibleSizes.last(where: { $0.width <= proposedWidth*maximumWidthRatio }) {
        viewRect = CGSize(width: ceil(proposedSize.width),height: ceil(proposedSize.height))
      } else {
        viewRect = CGSize(width: ceil(possibleSizes[0].width),height: ceil(possibleSizes[0].height))
      }
      let skylineRect = skyline.updateSkyline(viewSize: viewRect)
      if debugSkyline {
        let outline = Path { path in
          path.move(to: CGPoint(x: skyline.currentSkyline[0].x,y: skyline.currentSkyline[0].y))
          path.addLine(to: CGPoint(x: skyline.currentSkyline[0].x + skyline.currentSkyline[0].width, y: skyline.currentSkyline[0].y))
          
          if skyline.currentSkyline.count <= 1 {
            return
          }
          if skyline.currentSkyline.count > 2 {
            for idx in 1...skyline.currentSkyline.count-2 {
              path.addLine(to: CGPoint(x: skyline.currentSkyline[idx].x,y: skyline.currentSkyline[idx].y))
              path.addLine(to: CGPoint(x: skyline.currentSkyline[idx].x + skyline.currentSkyline[idx].width, y: skyline.currentSkyline[idx].y))
            }
          }
          
          let last = skyline.currentSkyline.last!
          path.addLine(to: CGPoint(x: last.x,y: last.y))
          path.addLine(to: CGPoint(x: last.x + last.width, y: last.y))
        }
        debugCallBack?(outline)
      }
      viewRects.append(skylineRect)
      maxX = max(maxX, skylineRect.maxX)
      maxY = max(maxY, skylineRect.maxY)
    }
    
    cache.rects = viewRects
    cache.skyline = skyline
    let proposedX = proposal.width ?? 0
    let proposedY = proposal.height ?? 0
    track("proposed \(CGSize(width: maxX, height: maxY))")
    return CGSize(width: maxX, height: maxY)
  }
  
  public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
    for index in subviews.indices {
      let cacheRect = cache.rects[index]
      subviews[index].place(at: CGPoint(x: bounds.minX + cacheRect.minX, y: bounds.minY + cacheRect.minY), anchor: .topLeading, proposal: ProposedViewSize(cacheRect.size))
    }
  }
  
  
}
