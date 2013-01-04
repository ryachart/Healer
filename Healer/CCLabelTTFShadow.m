//
//  CCLabelTTFShadow.m
//  Healer
//
//  Created by Ryan Hart on 1/3/13.
//  Copyright (c) 2013 Apple. All rights reserved.
//

#import "CCLabelTTFShadow.h"

@interface CCLabelTTFShadow ()
@property (nonatomic, retain) CCLabelTTF *superLabel;
@end

@implementation CCLabelTTFShadow
@synthesize shadowOffset=_shadowOffset, shadowOpacity=_shadowOpacity;

- (void)dealloc {
    [_superLabel release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        [self addChild:self.superLabel];
        self.shadowOffset = CGPointMake(-2, -2);
        self.shadowColor = ccBLACK;
    }
    return self;
}

- (id) initWithString:(NSString*)str dimensions:(CGSize)dimensions hAlignment:(CCTextAlignment)alignment vAlignment:(CCVerticalTextAlignment) vertAlignment lineBreakMode:(CCLineBreakMode)lineBreakMode fontName:(NSString*)name fontSize:(CGFloat)size
{
    if (self = [super initWithString:str dimensions:dimensions hAlignment:alignment vAlignment:vertAlignment lineBreakMode:lineBreakMode fontName:name fontSize:size]) {
        [self.superLabel setString:str];
        [self.superLabel setDimensions:dimensions];
        [self.superLabel setHorizontalAlignment:alignment];
        [self.superLabel setVerticalAlignment:vertAlignment];
        [self.superLabel setFontName:name];
        [self.superLabel setFontSize:size];
        [self addChild:self.superLabel];
        self.shadowOffset = CGPointMake(-2, -2);
        self.shadowColor = ccBLACK;
    }
    return self;
}

- (CCLabelTTF *)superLabel
{
    if (!_superLabel) {
        _superLabel = [[CCLabelTTF alloc] init];
    }
    return _superLabel;
}

- (void)setFontSize:(float)fontSize
{
    [super setFontSize:fontSize];
    [self.superLabel setFontSize:fontSize];
}

- (void)setFontName:(NSString *)fontName
{
    [super setFontName:fontName];
    [self.superLabel setFontName:fontName];
}

- (void)setString:(NSString *)str
{
    [super setString:str];
    [self.superLabel setString:str];
    [self setShadowOffset:_shadowOffset];
}

- (void)setDimensions:(CGSize)dimensions
{
    [super setDimensions:dimensions];
    [self.superLabel setDimensions:dimensions];
}

- (void)setHorizontalAlignment:(CCTextAlignment)horizontalAlignment
{
    [super setHorizontalAlignment:horizontalAlignment];
    [self.superLabel setHorizontalAlignment:horizontalAlignment];
}

- (void)setVerticalAlignment:(CCVerticalTextAlignment)verticalAlignment
{
    [super setVerticalAlignment:verticalAlignment];
    [self.superLabel setVerticalAlignment:verticalAlignment];
}

- (CGPoint)shadowOffset
{
    return _shadowOffset;
}

- (void)setPosition:(CGPoint)position
{
    [super setPosition:ccpAdd(position, CGPointMake(self.shadowOffset.x, self.shadowOffset.y))];
}

- (void)setShadowOffset:(CGPoint)shadowOffset
{
    _shadowOffset = shadowOffset;
    
    CGSize dims = CGSizeEqualToSize(self.dimensions, CGSizeZero) ? self.contentSize : self.dimensions;
    [self.superLabel setPosition:CGPointMake(dims.width / 2 - shadowOffset.x, dims.height / 2 - shadowOffset.y)];
}

- (ccColor3B)color
{
    return self.superLabel.color;
}

- (void)setColor:(ccColor3B)color
{
    [self.superLabel setColor:color];
}

- (void)setShadowColor:(ccColor3B)shadowColor
{
    [super setColor:shadowColor];
}

- (ccColor3B)shadowColor
{
    return [super color];
}
@end
