//
//  CCLabelTTFShadow.m
//  Healer
//
//  Created by Ryan Hart on 1/3/13.
//  Copyright (c) 2013 Ryan Hart Games. All rights reserved.
//

#import "CCLabelTTFShadow.h"

@interface CCLabelTTFShadow ()
@property (nonatomic, retain) CCLabelTTF *shadowLabel;
@end

@implementation CCLabelTTFShadow
@synthesize shadowOffset=_shadowOffset, shadowOpacity=_shadowOpacity;

- (void)dealloc {
    [_shadowLabel release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        [self addChild:self.shadowLabel z:-1];
        self.shadowOffset = CGPointMake(-2, -2);
        self.shadowColor = ccBLACK;
    }
    return self;
}

- (id) initWithString:(NSString*)str dimensions:(CGSize)dimensions hAlignment:(CCTextAlignment)alignment vAlignment:(CCVerticalTextAlignment) vertAlignment lineBreakMode:(CCLineBreakMode)lineBreakMode fontName:(NSString*)name fontSize:(CGFloat)size
{
    if (self = [super initWithString:str dimensions:dimensions hAlignment:alignment vAlignment:vertAlignment lineBreakMode:lineBreakMode fontName:name fontSize:size]) {
        [self.shadowLabel setString:str];
        [self.shadowLabel setDimensions:dimensions];
        [self.shadowLabel setHorizontalAlignment:alignment];
        [self.shadowLabel setVerticalAlignment:vertAlignment];
        [self.shadowLabel setFontName:name];
        [self.shadowLabel setFontSize:size];
        [self addChild:self.shadowLabel z:-1];
        self.shadowOffset = CGPointMake(-2, -2);
        self.shadowColor = ccBLACK;
    }
    return self;
}

- (CCLabelTTF *)shadowLabel
{
    if (!_shadowLabel) {
        _shadowLabel = [[CCLabelTTF alloc] init];
    }
    return _shadowLabel;
}

- (void)setFontSize:(float)fontSize
{
    [super setFontSize:fontSize];
    [self.shadowLabel setFontSize:fontSize];
}

- (void)setFontName:(NSString *)fontName
{
    [super setFontName:fontName];
    [self.shadowLabel setFontName:fontName];
}

- (void)setString:(NSString *)str
{
    [super setString:str];
    [self.shadowLabel setString:str];
    [self setShadowOffset:_shadowOffset];
}

- (void)setDimensions:(CGSize)dimensions
{
    [super setDimensions:dimensions];
    [self.shadowLabel setDimensions:dimensions];
}

- (void)setHorizontalAlignment:(CCTextAlignment)horizontalAlignment
{
    [super setHorizontalAlignment:horizontalAlignment];
    [self.shadowLabel setHorizontalAlignment:horizontalAlignment];
}

- (void)setVerticalAlignment:(CCVerticalTextAlignment)verticalAlignment
{
    [super setVerticalAlignment:verticalAlignment];
    [self.shadowLabel setVerticalAlignment:verticalAlignment];
}

- (CGPoint)shadowOffset
{
    return _shadowOffset;
}

//- (void)setPosition:(CGPoint)position
//{
//    [super setPosition:ccpAdd(position, CGPointMake(self.shadowOffset.x, self.shadowOffset.y))];
//}

- (void)setShadowOffset:(CGPoint)shadowOffset
{
    _shadowOffset = shadowOffset;
    
    CGSize dims = CGSizeEqualToSize(self.dimensions, CGSizeZero) ? self.contentSize : self.dimensions;
    [self.shadowLabel setPosition:CGPointMake(dims.width / 2 + shadowOffset.x, dims.height / 2 + shadowOffset.y)];
}

//- (ccColor3B)color
//{
//    return self.shadowLabel.color;
//}

//- (void)setColor:(ccColor3B)color
//{
//    colorUnmodified_ = color;
//    [self.shadowLabel setColor:color];
//}

- (void)setShadowColor:(ccColor3B)shadowColor
{
    [self.shadowLabel setColor:shadowColor];
}

- (void)setOpacity:(GLubyte)opacity
{
    [super setOpacity:opacity];
    [self.shadowLabel setOpacity:opacity];
}

- (ccColor3B)shadowColor
{
    return [super color];
}
@end
