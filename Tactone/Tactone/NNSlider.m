
//
//  NNSlider.m
//
//  Copyright (c) 2015 Cady Holmes. All rights reserved.
//

#import "NNSlider.h"

@implementation NNSlider

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setDefaults];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [self draw];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setDefaults];
        [self draw];
    }
    return self;
}

- (void)setDefaults {
    
    self.backgroundColor = [UIColor clearColor];
    self.textColor = [UIColor blackColor];
    //self.textColor = [UIColor flatDarkBlackColor];
    self.knobColor = [UIColor blackColor];
    self.lineColor = [UIColor blackColor];
    self.segmentColor = [UIColor grayColor];
    self.shouldDoCoolAnimation = YES;
    self.startupAnimationDuration = 1.0;
    
    self.isDial = NO;
    self.isClockwise = YES;
    self.shouldFlip = NO;
    self.snapsBack = YES;
    
    self.isString = NO;
    self.stringFlex = 3; // Input values 0 or greater, then scale down to hundredths in draw method
    self.clipsAltValues = YES;
    
    self.hasLabel = YES;
    self.hasPopup = YES;
    self.isSegmented = NO;
    self.segments = 5;
    
    self.minimumValue = 0;
    
    self.value = 0;
    normalizedValue = self.value;
    self.valueScale = 1;
    self.altValue = 0;
    
    if (self.frame.size.width > self.frame.size.height) {
        isVertical = NO;
    } else {
        isVertical = YES;
    }
    
    if (self.isDial == NO) {
        if (isVertical == NO) {
            //horizontal drawing
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y-self.bounds.size.height/2, self.frame.size.width, self.frame.size.height);
            self.lineWidth = self.bounds.size.height*0.9;
            self.knobRadius = self.bounds.size.height*0.6;
            knobCenter = CGPointMake(self.bounds.origin.x, self.bounds.origin.y+self.bounds.size.height/2);
        } else {
            //vertical drawing
            self.frame = CGRectMake(self.frame.origin.x-self.bounds.size.width/2, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
            self.lineWidth = self.bounds.size.width*0.9;
            self.knobRadius = self.bounds.size.width*0.6;
            knobCenter = CGPointMake(self.bounds.origin.x+self.bounds.size.width/2, self.bounds.size.height);
        }
    }
}

- (void)draw {
    self.stringFlex = self.stringFlex * .01;
    [self updateValueTo:self.value];
    if (!self.textBubbleColor) {
        self.textBubbleColor = self.lineColor;
    }
    if (!self.textColor) {
        self.textColor = [UIColor grayColor];
    }
    if (self.isDial == NO) {
        [self drawLine];
        [self drawKnob];
    } else {
        [self drawDial];
    }
}

- (void)drawDial {

    self.lineWidth = self.bounds.size.width/4;
    knobCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.knobRadius = self.bounds.size.width/2.8;
    float startAngle;
    float endAngle;
    
    if (self.shouldFlip == YES) {
        startAngle = M_PI;
        endAngle = -M_PI;
    } else {
        startAngle = 0;
        endAngle = 2*M_PI;
    }
    
    UIGraphicsBeginImageContext(self.frame.size);
    
    if (knobLayer == nil)
    {
        UIBezierPath *knobPath = [UIBezierPath bezierPath];
        [knobPath addArcWithCenter:knobCenter radius:self.knobRadius startAngle:startAngle endAngle:endAngle clockwise:self.isClockwise];
        
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = [knobPath CGPath];
        layer.strokeColor = [self.lineColor CGColor];           // M_PI     2*M_PI   - half circle
        layer.fillColor = [self.knobColor CGColor];             // M_PI     -M_PI   - rotate 180
        layer.lineWidth = .5;                                   // -M_PI/2  2*M_PI   - rotate 90
        layer.lineJoin = kCALineJoinBevel;                      // 2/-M_PI  2*M_PI   - rotate 45
        layer.strokeEnd = 0;                                    // 2*M_PI   M_PI     - upside down half circle
        layer.drawsAsynchronously = YES;                         // 2*M_PI   -M_PI/2  - upside down 3/4 rotated circle
                                                                // 2*M_PI   2/-M_PI  - Near complete circle
        knobLayer = layer;
        [self.layer addSublayer:knobLayer];
        
        if (self.shouldDoCoolAnimation == YES) {
            
            [CATransaction begin];
            [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
            [CATransaction setCompletionBlock:^{
            }];
            
                CABasicAnimation *fillAnimation = [CABasicAnimation animationWithKeyPath:@"fillColor"];
                fillAnimation.duration = self.startupAnimationDuration;
                fillAnimation.fromValue = (id)[UIColor clearColor].CGColor;
                fillAnimation.toValue = (id)self.knobColor.CGColor;
                fillAnimation.removedOnCompletion = YES;
                
                CABasicAnimation *lineAnimation = [CABasicAnimation animationWithKeyPath:@"strokeColor"];
                lineAnimation.duration = self.startupAnimationDuration/2.5;
                lineAnimation.fromValue = (id)[UIColor clearColor].CGColor;
                lineAnimation.toValue = (id)self.lineColor.CGColor;
                lineAnimation.removedOnCompletion = YES;
                
                CABasicAnimation *dialAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
                dialAnimation.duration = self.startupAnimationDuration;
                if (self.value == 0) {
                    dialAnimation.fromValue = @(1.0f);
                    dialAnimation.toValue = @(normalizedValue);
                } else {
                    dialAnimation.fromValue = @(0.0f);
                    dialAnimation.toValue = @(normalizedValue);
                }
                dialAnimation.removedOnCompletion = YES;
                knobLayer.strokeEnd = normalizedValue;
                
                [knobLayer addAnimation:lineAnimation forKey:@"strokeColor"];
                [knobLayer addAnimation:dialAnimation forKey:@"strokeEnd"];
                [knobLayer addAnimation:fillAnimation forKey:@"fillColor"];
            
            [CATransaction commit];
        }
    }
    
    UIGraphicsEndImageContext();
    
    if (self.hasLabel == YES) {
        [self makeLabel];
    }
}

- (void)makeLabel {
    label = [[UILabel alloc] initWithFrame:self.frame];
    label.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:self.knobRadius/2];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.cornerRadius = 4;
    label.textColor = self.textColor;
    
    if (isVertical == NO) {
        label.center = CGPointMake(knobCenter.x+knobCenterOffset, knobCenter.y);
    } else {
        label.center = CGPointMake(knobCenter.x, knobCenter.y-knobCenterOffset);
    }
    
    if (label.font.pointSize < 6) {
        label.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:0];
    }
    
    float value = self.value + self.minimumValue;
    if (self.isString == YES) {
        NSString *str = [NSString stringWithFormat:@"%.2f | %.2f",value,self.altValue];
        if (self.isInt) {
            str = [NSString stringWithFormat:@"%.0f | %.0f",value,self.altValue];
        }
        label.text = str;
    } else {
        NSString *str = [NSString stringWithFormat:@"%.2f",value];
        if (self.isInt) {
            str = [NSString stringWithFormat:@"%.0f",value];
        }
        label.text = str;
    }
    
    [self addSubview:label];
    [self bringSubviewToFront:label];
    
//    if (self.isDial == NO) {
//        if (isVertical == NO) {
//            float x = self.bounds.origin.x+knobCenterOffset;
//            float y = self.bounds.size.height/2;
//            [self animateLabelTo:CGPointMake(x, y)];
//            label.center = CGPointMake(x, self.bounds.size.height/2);
//        } else {
//            float x = self.bounds.size.width/2;
//            float y = self.bounds.origin.y+knobCenterOffset;
//            [self animateLabelTo:CGPointMake(x, y)];
//            label.center = CGPointMake(self.bounds.size.width/2, y);
//        }
//        
//        label.font = [UIFont fontWithName:@"AmericanTypewriter-Bold" size:self.knobRadius/3];
//        label.layer.backgroundColor = [UIColor clearColor].CGColor;
//        
//        if (label.font.pointSize < 6) {
//            label.font = [UIFont fontWithName:@"AmericanTypewriter-Bold" size:0];
//        }
//    }
}

- (void)drawKnob {
    UIGraphicsBeginImageContext(self.bounds.size);
    
    if (knobLayer == nil)
    {
        CGPoint center;
        if (isVertical == NO) {
            knobCenterOffset = self.bounds.size.width*normalizedValue;
            center = CGPointMake(knobCenter.x+knobCenterOffset, knobCenter.y);
        } else {
            knobCenterOffset = self.bounds.size.height*normalizedValue;
            center = CGPointMake(knobCenter.x, knobCenter.y-knobCenterOffset);
        }
        
        UIBezierPath *knobPath = [UIBezierPath bezierPath];
        [knobPath addArcWithCenter:center radius:self.knobRadius startAngle:0 endAngle:2 * M_PI clockwise:YES];
        
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = [knobPath CGPath];
        layer.strokeColor = [UIColor blackColor].CGColor;
        layer.fillColor = [self.knobColor CGColor];
        layer.lineWidth = .75;
        layer.lineJoin = kCALineJoinBevel;
        layer.strokeEnd = 1;
        layer.drawsAsynchronously = YES;
        
        knobLayer = layer;
        [self.layer addSublayer:knobLayer];
        
        if (self.shouldDoCoolAnimation == YES) {

            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"fillColor"];
            animation.duration = self.startupAnimationDuration/2;
            animation.fromValue = (id)[UIColor clearColor].CGColor;
            animation.toValue = (id)self.knobColor.CGColor;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            animation.removedOnCompletion = YES;
            [knobLayer addAnimation:animation forKey:@"fillColor"];
        }
    }
    
    UIGraphicsEndImageContext();
    
    if (self.hasLabel == YES) {
        [self makeLabel];
    }
}

- (void)drawLine
{
    UIGraphicsBeginImageContext(self.bounds.size);
    
    if (lineLayer == nil)
    {
        if (self.isString == YES) {
            CAShapeLayer *layer = [CAShapeLayer layer];
            
            layer.path = [[self linePath] CGPath];
            layer.strokeColor = [self.lineColor CGColor];
            layer.fillColor = nil;
            layer.lineWidth = self.lineWidth;
            layer.lineJoin = kCALineJoinBevel;
            layer.drawsAsynchronously = YES;
            layer.lineCap = kCALineCapRound;
            layer.opacity = .2;
            [self.layer addSublayer:layer];
        }
        
        CAShapeLayer *layer = [CAShapeLayer layer];
        
        layer.path = [[self linePath] CGPath];
        layer.strokeColor = [self.lineColor CGColor];
        layer.fillColor = nil;
        layer.lineWidth = self.lineWidth;
        layer.lineJoin = kCALineJoinBevel;
        layer.drawsAsynchronously = YES;
        layer.lineCap = kCALineCapRound;
        [self.layer addSublayer:layer];
        
        if (self.isSegmented == YES) {
            for (int i = 1; i < self.segments; i++) {
                CAShapeLayer *segments = [CAShapeLayer layer];
                segments.path = [[self segmentPathFor:i] CGPath];
                segments.strokeColor = [self.segmentColor CGColor];
                segments.lineWidth = self.bounds.size.height*.01;
                segments.lineJoin = kCALineJoinBevel;
                segments.drawsAsynchronously = YES;
                segments.lineCap = kCALineCapRound;
                [self.layer addSublayer:segments];
            }
        }
        lineLayer = layer;
    }
    
    if (self.shouldDoCoolAnimation == YES) {
    
        CABasicAnimation *strokeAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        strokeAnimation.duration = self.startupAnimationDuration/2;
        strokeAnimation.fromValue = @(0.0f);
        strokeAnimation.toValue = @(1.0f);
        strokeAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        strokeAnimation.removedOnCompletion = YES;
        
        CABasicAnimation *colorAnimation = [CABasicAnimation animationWithKeyPath:@"strokeColor"];
        colorAnimation.duration = self.startupAnimationDuration;
        colorAnimation.fromValue = (id)[UIColor clearColor].CGColor;
        colorAnimation.toValue = (id)self.lineColor.CGColor;
        colorAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        colorAnimation.removedOnCompletion = YES;
        
        [lineLayer addAnimation:strokeAnimation forKey:@"strokeEnd"];
        [lineLayer addAnimation:colorAnimation forKey:@"strokeColor"];
    }
    
    UIGraphicsEndImageContext();
}

- (UIBezierPath *)segmentPathFor:(int)loop
{
    UIBezierPath* path = [UIBezierPath bezierPath];

    if (isVertical == NO) {
        float endX = self.bounds.size.width;
        float deltaX = (endX/self.segments)*loop;
        float originY = (self.bounds.origin.y+self.bounds.size.height/2)-(self.bounds.size.height*.2);
        float originX = self.bounds.origin.x+deltaX;
        [path moveToPoint: CGPointMake(originX, originY)];
        [path addLineToPoint:CGPointMake(originX, self.bounds.size.height*.7)];
        [path stroke];
    } else {
        float endY = self.bounds.size.height;
        float deltaY = (endY/self.segments)*loop;
        float originY = self.bounds.origin.y+deltaY;
        float originX = (self.bounds.origin.x+self.bounds.size.width/2)-(self.bounds.size.width*.2);
        [path moveToPoint: CGPointMake(originX, originY)];
        [path addLineToPoint:CGPointMake(self.bounds.size.width*.7, originY)];
        [path stroke];
    }
    
    return path;
}

- (UIBezierPath *)linePath
{
    UIBezierPath* path = [UIBezierPath bezierPath];
    
    if (isVertical == NO) {
        float originY = self.bounds.origin.y+self.bounds.size.height/2;
        float originX = self.bounds.origin.x;
        float endX = self.bounds.size.width;
        [path moveToPoint: CGPointMake(originX, originY)];
        //[path addCurveToPoint: CGPointMake(endX*.5, originY) controlPoint1: CGPointMake(endX*.25, originY) controlPoint2: CGPointMake(endX*.5, originY)];
        [path addCurveToPoint: CGPointMake(endX, originY) controlPoint1: CGPointMake(endX*.25, originY) controlPoint2: CGPointMake(endX*.75, originY)];
//        [path addCurveToPoint: CGPointMake(116.5, originY) controlPoint1: CGPointMake(7.5, originY) controlPoint2: CGPointMake(108.37, originY)];
//        [path addCurveToPoint: CGPointMake(endX, originY) controlPoint1: CGPointMake(124.63, originY) controlPoint2: CGPointMake(208.5, originY)];
        [path stroke];
    } else {
        float originY = self.bounds.origin.y;
        float originX = self.bounds.origin.x+self.bounds.size.width/2;
        float endY = self.bounds.size.height;
        [path moveToPoint: CGPointMake(originX, originY)];
        //[path addCurveToPoint: CGPointMake(originX, 100) controlPoint1: CGPointMake(originX, 120) controlPoint2: CGPointMake(originX, 130)];
        [path addCurveToPoint: CGPointMake(originX, endY) controlPoint1: CGPointMake(originX, endY*.25) controlPoint2: CGPointMake(originX, endY*.75)];
        [path stroke];
    }
    
    return path;
}

- (void)stringBendPath:(CGPoint)touch
{
    UIGraphicsBeginImageContext(self.bounds.size);
    
    UIBezierPath* path = [UIBezierPath bezierPath];
    
    if (isVertical == NO) {
        float originY = self.bounds.origin.y+self.bounds.size.height/2;
        float originX = self.bounds.origin.x;
        float endX = self.bounds.size.width;
        float x = touch.x;
        float y = touch.y;
        
        if (self.clipsAltValues == YES) {
            x = MIN(x, self.bounds.size.width);
            x = MAX(x, self.bounds.origin.x);
            y = MIN(y, self.bounds.size.height+(self.bounds.size.height*.5));
            y = MAX(y, self.bounds.origin.y-(self.bounds.size.height*.5));
        }
        
        [path moveToPoint: CGPointMake(originX, originY)];
        [path addCurveToPoint: CGPointMake(x, y) controlPoint1: CGPointMake(originX, originY) controlPoint2: CGPointMake(x-(endX*self.stringFlex), y)];
        [path addCurveToPoint: CGPointMake(endX, originY) controlPoint1: CGPointMake(x+(endX*self.stringFlex), y) controlPoint2: CGPointMake(endX, originY)];
        [path stroke];
        
    } else {
        
        float originY = self.bounds.origin.y;
        float originX = self.bounds.origin.x+self.bounds.size.width/2;
        float endY = self.bounds.size.height;
        float x = touch.x;
        float y = touch.y;
        
        if (self.clipsAltValues == YES) {
            x = MIN(x, self.bounds.size.width+(self.bounds.size.width*.2));
            x = MAX(x, self.bounds.origin.x-(self.bounds.size.width*.2));
            y = MIN(y, self.bounds.size.height);
            y = MAX(y, self.bounds.origin.y);
        }
        
        [path moveToPoint: CGPointMake(originX, originY)];
        [path addCurveToPoint: CGPointMake(x, y) controlPoint1: CGPointMake(originX, originY) controlPoint2: CGPointMake(x, y-(endY*self.stringFlex))];
        [path addCurveToPoint: CGPointMake(originX, endY) controlPoint1: CGPointMake(x, y+(endY*self.stringFlex)) controlPoint2: CGPointMake(originX, endY)];
        [path stroke];
    }
    
    self.bendPath = path.CGPath;
    [self animateBend:lineLayer];
    UIGraphicsEndImageContext();
}

- (void)animateBend:(CAShapeLayer *)layer {
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.duration = 0.01f;
    animation.fromValue = (__bridge id)layer.path;
    animation.toValue = (__bridge id)self.bendPath;
    layer.path = self.bendPath;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.removedOnCompletion = YES;
    [layer addAnimation:animation forKey:@"path"];
}

- (void)animateKnob:(CAShapeLayer *)layer to:(CGPoint)point {
    
    float x = point.x;
    float y = point.y;
    float offset;
    if (self.isString == YES) {
        if (isVertical == NO) {
            offset = self.bounds.size.height*self.stringFlex;
            y = y-(self.bounds.size.height/2);
            
            if (self.clipsAltValues == YES) {
                y = MIN(y, self.bounds.size.height+offset);
                y = MAX(y, ((self.bounds.origin.y-self.bounds.size.height/2)-offset)-(self.knobRadius/2));
                x = MIN(x, self.bounds.size.width);
                x = MAX(x, self.bounds.origin.x);
            }
            point = CGPointMake(x-knobCenterOffset, y);
        } else {
            offset = self.bounds.size.width*self.stringFlex;
            y = y-(self.bounds.size.height);
            
            if (self.clipsAltValues == YES) {
                y = MIN(y, self.bounds.size.height-self.bounds.size.height/2);
                y = MAX(y, self.bounds.origin.y-self.bounds.size.height/2);
                x = MIN(x, self.bounds.size.width-(self.bounds.size.width/2)+offset+(self.knobRadius/2));
                x = MAX(x, self.bounds.origin.x-(self.bounds.size.width/2)-offset-(self.knobRadius/2));
            }
            point = CGPointMake(x, y+knobCenterOffset);
        }
    }
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.duration = 0.05;
    animation.fromValue = [layer valueForKey:@"position"];
    animation.toValue = [NSValue valueWithCGPoint:point];
    layer.position = point;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.removedOnCompletion = YES;
    [layer addAnimation:animation forKey:@"position"];
}

- (void)animateDial:(CAShapeLayer *)layer to:(float)value {
    value = MAX(.01, value);
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    animation.duration = 0.6f;
    animation.fromValue = [layer valueForKey:@"strokeEnd"];
    animation.toValue = @(value);
    layer.strokeEnd = value;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.removedOnCompletion = YES;
    [layer addAnimation:animation forKey:@"strokeEnd"];
}

#pragma mark - UIControl touch event tracking

-(BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    //[self touchHandling:[touch locationInView:touch.view]];
    return [super beginTrackingWithTouch:touch withEvent:event];
}

-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [self touchHandling:[touch locationInView:touch.view]];
    return [super continueTrackingWithTouch:touch withEvent:event];
}

-(void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
}

-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    //[self touchHandling:[touch locationInView:touch.view]];
    [self endAnimation:touch];
    [super endTrackingWithTouch:touch withEvent:event];

}

- (void)endAnimation:(UITouch *)touch {
    CGPoint stringPoint;
    CGPoint knobPoint;
    CGPoint loc = [touch locationInView:touch.view];
    float stringEnd;
    float knobEnd;
    float y = loc.y;
    float x = loc.x;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    if (self.isString == YES) {
        if (isVertical == NO) {
            stringEnd = self.bounds.origin.y+(self.bounds.size.height/2);
            stringPoint = CGPointMake(self.bounds.size.width/2, stringEnd);
            x = MIN(x, self.bounds.size.width);
            x = MAX(x, self.bounds.origin.x);
            
            if (self.clipsAltValues == YES) {
                if (self.snapsBack == YES) {
                    [self stringBendPath:stringPoint];
                    knobEnd = self.bounds.origin.y+(self.bounds.size.height/2);
                    knobPoint = CGPointMake(x, knobEnd);
                } else {
                    knobPoint = CGPointMake(x, y);
                }
            } else {
                [self stringBendPath:stringPoint];
                knobEnd = self.bounds.origin.y+(self.bounds.size.height/2);
                knobPoint = CGPointMake(x, knobEnd);
            }
            [self animateKnob:knobLayer to:knobPoint];

            // finish animations
        } else {
            stringEnd = self.bounds.origin.x+(self.bounds.size.width/2);
            stringPoint = CGPointMake(stringEnd, self.bounds.size.height/2);
            y = MIN(y, self.bounds.size.height);
            y = MAX(y, self.bounds.origin.y);
            
            if (self.clipsAltValues == YES) {
                if (self.snapsBack == YES) {
                    [self stringBendPath:stringPoint];
                    knobEnd = self.bounds.origin.x;
                    knobPoint = CGPointMake(knobEnd, y);
                } else {
                    knobPoint = CGPointMake(x, y);
                }
            } else {
                [self stringBendPath:stringPoint];
                knobEnd = self.bounds.origin.x;
                knobPoint = CGPointMake(knobEnd, y);
            }
            [self animateKnob:knobLayer to:knobPoint];

            // finish animations
        }
        [self updateAltValueTo:.5];
    }
    
    
    //TODO
    // add bouncing end animation for string
    // auto release if pulled too far --- maybe
    // resistance to initial pull
    // pluckable?
    
    
    if (self.hasLabel == YES) {
        if (self.isDial == NO) {
            if (isVertical == NO) {
                x = [touch locationInView:touch.view].x;
                x = MIN(self.bounds.size.width, x);
                x = MAX(self.bounds.origin.x, x);
                if (self.isSegmented == YES) {
                    x = x/self.bounds.size.width;
                    x = roundf(x*self.segments);
                    x = x/self.segments;
                    x = x*self.bounds.size.width;
                }
                label.center = CGPointMake(x, self.bounds.size.height/2);
            } else {
                y = [touch locationInView:touch.view].y;
                y = MIN(self.bounds.size.height, y);
                y = MAX(self.bounds.origin.y, y);
                if (self.isSegmented == YES) {
                    y = y/self.bounds.size.height;
                    y = roundf(y*self.segments);
                    y = y/self.segments;
                    y = y*self.bounds.size.height;
                }
                label.center = CGPointMake(self.bounds.size.width/2, y);
            }
            
            label.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:self.knobRadius/2];
            label.layer.backgroundColor = [UIColor clearColor].CGColor;
            
            if (label.font.pointSize < 6) {
                label.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:0];
            }
        }
    }
    
    [UIView commitAnimations];
}

- (void)touchHandling:(CGPoint)loc {

    CGPoint touch2D = loc;
    CGPoint touch1D;
    float x;
    float y;
    float value;
    float altValue;
    
    if (self.isDial == NO) {
        if (isVertical == NO) {
            // FOR HORIZONTAL
            x = touch2D.x;
            x = x/self.bounds.size.width;
            y = touch2D.y/self.bounds.size.height;
            
            if (self.clipsAltValues == YES) {
                x = MIN(1, x);
                x = MAX(0, x);
                y = MIN(1, y);
                y = MAX(0, y);
                y = fabsf(y-1);
            }
            
            if (self.isSegmented == YES) {
                x = roundf(x*self.segments);
                x = x/self.segments;
            }
            
            touch1D = CGPointMake((x*self.bounds.size.width)-knobCenterOffset, knobLayer.position.y);
            value = x;
            altValue = y-knobCenterOffset;
            
        } else {
            // FOR VERTICAL
            x = touch2D.x/self.bounds.size.width;
            y = touch2D.y;
            y = y/self.bounds.size.height;
            
            if (self.clipsAltValues == YES) {
                y = MIN(1, y);
                y = MAX(0, y);
                x = MIN(1, x);
                x = MAX(0, x);
            }
            
            if (self.isSegmented == YES) {
                y = roundf(y*self.segments);
                y = y/self.segments;
            }
            
            touch1D = CGPointMake(knobLayer.position.x, (((y*self.bounds.size.height)-self.bounds.size.height)+knobCenterOffset));
            value = fabsf(1-y);
            altValue = x;
        }
        
        if (self.isString == NO) {
            [self animateKnob:knobLayer to:touch1D];
        } else {
            [self animateKnob:knobLayer to:touch2D];
            [self stringBendPath:touch2D];
            [self animateBend:lineLayer];
            [self updateAltValueTo:altValue];
        }
    } else {
        y = touch2D.y;
        y = y/self.bounds.size.height;
        y = MIN(1, y);
        y = MAX(0, y);
        
        value = fabsf(1-y);
        [self animateDial:knobLayer to:value];
    }
    [self updateValueTo:value];
    
    
    if (self.hasLabel == YES) {
        if (self.isDial == NO) {
            [self animateLabelTo:touch2D];
        }
    }
}

- (void)animateLabelTo:(CGPoint)point {
    float x;
    float y;
    float offset = 0;
    
    if (self.hasPopup == YES) {
        offset = 60;
        label.layer.backgroundColor = self.textBubbleColor.CGColor;
        if (label.font.pointSize < 14) {
            label.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:14];
        }
    }
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    if (self.isString == NO) {
        if (isVertical == NO) {
            x = point.x;
            x = MIN(self.bounds.size.width, x);
            x = MAX(self.bounds.origin.x, x);
            if (self.isSegmented == YES) {
                x = x/self.bounds.size.width;
                x = roundf(x*self.segments);
                x = x/self.segments;
                x = x*self.bounds.size.width;
            }
            label.center = CGPointMake(x, (self.bounds.size.height/2)-offset);
        } else {
            y = point.y;
            y = MIN(self.bounds.size.height, y);
            y = MAX(self.bounds.origin.y+35, y);
            if (self.isSegmented == YES) {
                y = y/self.bounds.size.height;
                y = roundf(y*self.segments);
                y = y/self.segments;
                y = y*self.bounds.size.height;
            }
            label.center = CGPointMake(self.bounds.size.width/2, y-offset);
        }
    } else {
        x = point.x;
        y = point.y;
//        x = MIN(self.bounds.size.width, x);
//        x = MAX(self.bounds.origin.x, x);
//        y = MIN(self.bounds.size.height, y);
        //y = MAX(35, y);
        label.center = CGPointMake(x, y-offset);
    }

    [UIView commitAnimations];
}

- (void)updateValueTo:(float)value {
    //NSLog(@"%f",value);
    self.value = value*self.valueScale;
    normalizedValue = value;
    if (self.isInt) {
        self.value = (int)self.value;
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    [self updateLabel];
    [self animateUpdateValue:value];
}

- (void)animateUpdateValue:(float)value {
    if (self.isDial) {
        [self animateDial:knobLayer to:value];
    } else {
        float x;
        float y;
        if (!isVertical) {
            y = self.center.y;
            x = self.frame.size.width*value;
        } else {
            y = self.frame.size.height*value;
            x = self.center.x;
        }
        [self touchHandling:CGPointMake(x, y)];
    }
}

- (void)updateAltValueTo:(float)value {
    self.altValue = value;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    [self updateLabel];
}

- (void)updateLabel {
    float value = self.value + self.minimumValue;
    //NSLog(@"%f labelvalue",value);
    if (self.isString == YES) {
        NSString *str = [NSString stringWithFormat:@"%.2f | %.2f",value,self.altValue];
        if (self.isInt) {
            str = [NSString stringWithFormat:@"%.0f | %.0f",value,self.altValue];
        }
        label.text = str;
    } else {
        NSString *str = [NSString stringWithFormat:@"%.2f",value];
        if (self.isInt) {
            str = [NSString stringWithFormat:@"%.0f",value];
        }
        label.text = str;
    }
    [label sizeToFit];
    if (self.isDial == YES) {
        label.center = knobCenter;
    }
    //label.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
}

#pragma Accessibility methods

- (void)makeDial {
    self.isDial = YES;
}

@end
