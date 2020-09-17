//
//  NNSlider.h
//
//  Created by Cady Holmes on 1/28/15.
//  Copyright (c) 2015 Cady Holmes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NNSlider : UIControl {
    @protected
    BOOL isVertical;
    CAShapeLayer *knobLayer;
    CAShapeLayer *lineLayer;
    CGPoint knobCenter;
    float knobCenterOffset;
    float normalizedValue;
    UILabel *label;
}

@property (nonatomic, weak) UIColor *knobColor;
@property (nonatomic, weak) UIColor *lineColor;
@property (nonatomic, weak) UIColor *dialColor;
@property (nonatomic, weak) UIColor *textColor;
@property (nonatomic, weak) UIColor *segmentColor;
@property (nonatomic, weak) UIColor *textBubbleColor;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic) CGFloat knobRadius;
@property (nonatomic) CGPathRef bendPath;
@property (nonatomic) float value;
@property (nonatomic) float altValue;
@property (nonatomic) float startupAnimationDuration;
@property (nonatomic) float stringFlex;
@property (nonatomic) float valueScale;
@property (nonatomic) float segments;
@property (nonatomic) BOOL shouldDoCoolAnimation;
@property (nonatomic) BOOL clipsAltValues;
@property (nonatomic) BOOL snapsBack;
@property (nonatomic) BOOL isDial;
@property (nonatomic) BOOL isString;
@property (nonatomic) BOOL isSegmented;
@property (nonatomic) BOOL hasLabel;
@property (nonatomic) BOOL hasPopup;
@property (nonatomic) BOOL isClockwise;
@property (nonatomic) BOOL shouldFlip;
@property (nonatomic) BOOL isInt;
@property (nonatomic) float minimumValue;

//- (void)animateUpdateValue:(float)value;
- (void)updateValueTo:(float)value;
- (void)setValueTo:(float)value;

@end
