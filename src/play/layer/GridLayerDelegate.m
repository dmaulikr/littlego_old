// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// -----------------------------------------------------------------------------


// Project includes
#import "GridLayerDelegate.h"
#import "../PlayViewMetrics.h"
#import "../PlayViewModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GridLayerDelegate.
// -----------------------------------------------------------------------------
@interface GridLayerDelegate()
- (void) releaseLineLayers;
@property(nonatomic, assign) CGLayerRef normalLineLayer;
@property(nonatomic, assign) CGLayerRef boundingLineLayer;
@end


@implementation GridLayerDelegate

@synthesize normalLineLayer;
@synthesize boundingLineLayer;


// -----------------------------------------------------------------------------
/// @brief Initializes a GridLayerDelegate object.
///
/// @note This is the designated initializer of GridLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithLayer:(CALayer*)aLayer metrics:(PlayViewMetrics*)metrics model:(PlayViewModel*)model
{
  // Call designated initializer of superclass (PlayViewLayerDelegate)
  self = [super initWithLayer:aLayer metrics:metrics model:model];
  if (! self)
    return nil;
  self.normalLineLayer = nil;
  self.boundingLineLayer = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GridLayerDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self releaseLineLayers];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Releases line layers if they are currently allocated. Otherwise does
/// nothing.
// -----------------------------------------------------------------------------
- (void) releaseLineLayers
{
  if (self.normalLineLayer)
  {
    CGLayerRelease(self.normalLineLayer);
    self.normalLineLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
  if (self.boundingLineLayer)
  {
    CGLayerRelease(self.boundingLineLayer);
    self.boundingLineLayer = NULL;  // when it is next invoked, drawLayer:inContext:() will re-create the layer
  }
}

// -----------------------------------------------------------------------------
/// @brief PlayViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) notify:(enum PlayViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case PVLDEventRectangleChanged:
    {
      self.layer.frame = self.playViewMetrics.rect;
      [self releaseLineLayers];
      self.dirty = true;
      break;
    }
    case PVLDEventGoGameStarted:  // board size possibly changes
    {
      [self releaseLineLayers];
      self.dirty = true;
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief CALayer delegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  GoPoint* pointA1 = [[GoGame sharedGame].board pointAtVertex:@"A1"];
  if (! pointA1)
    return;

  if (! self.normalLineLayer)
  {
    self.normalLineLayer = [self.playViewMetrics lineLayerWithContext:context
                                                            lineColor:self.playViewModel.lineColor
                                                            lineWidth:self.playViewModel.normalLineWidth];
  }
  if (! self.boundingLineLayer)
  {
    self.boundingLineLayer = [self.playViewMetrics lineLayerWithContext:context
                                                              lineColor:self.playViewModel.lineColor
                                                              lineWidth:self.playViewModel.boundingLineWidth];
  }

  for (int lineDirection = 0; lineDirection < 2; ++lineDirection)
  {
    bool isHorizontalLine = (0 == lineDirection) ? true : false;
    GoPoint* previousPoint = nil;
    GoPoint* currentPoint = pointA1;
    while (currentPoint)
    {
      GoPoint* nextPoint;
      if (isHorizontalLine)
        nextPoint = currentPoint.above;
      else
        nextPoint = currentPoint.right;

      CGLayerRef lineLayer;
      bool isBoundingLine = (nil == previousPoint || nil == nextPoint);
      if (isBoundingLine)
        lineLayer = self.boundingLineLayer;
      else
        lineLayer = self.normalLineLayer;
      [self.playViewMetrics drawLineLayer:lineLayer withContext:context horizontal:isHorizontalLine positionedAtPoint:currentPoint];

      previousPoint = currentPoint;
      currentPoint = nextPoint;
    }
  }
}

@end
