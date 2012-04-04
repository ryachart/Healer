//
//  Scale9Sprite.h
//
//   Public domain.  Use in anyway you see fit.  No waranties of any kind express or implied.    
//   Based off work of Steve Oldmeadow and Jose Antonio Andújar Clavell
//
//
//  Creates a 9-slice sprite for cocos2d
//
//  Parameters
//
//  file
//    The name of the texture file
//
//  rect
//    The rectangle that describes the sub-part of the texture that is the whole image.
//    If the shape is the whole texture, set this to the texture's full rect
//
//  
//  centerRegion
//    Defines the inside part of the 9-slice.  This part will scale X and Y.  The top and bottom borders scale X only.
//   The left and right borders scale Y only.  The four outside corners do not scale at all.
//
//    This rectangle must represent a space that is inside what is specified by the rect param
//
//
//  Once the sprite is created, you can then call [mySprite setContentSize:newRect] to resize the
//  the sprite will all it's 9-slice goodness intract.  Respects anchorPoint too.

#import "cocos2d.h"

@interface Scale9Sprite : CCNode <CCRGBAProtocol> {
    
    CGRect  rect_;
    
	CCSpriteBatchNode *scale9Image;
	CCSprite *topLeft;
	CCSprite *top;
	CCSprite *topRight;
	CCSprite *left;
	CCSprite *centre;
	CCSprite *right;
	CCSprite *bottomLeft;
	CCSprite *bottom;
	CCSprite *bottomRight;
    
	// texture RGBA
	GLubyte	opacity;
	ccColor3B color;
	BOOL opacityModifyRGB_;
    
}

-(id) initWithFile:(NSString*)file rect:(CGRect) rect centreRegion:(CGRect)centreRegion;
/** conforms to CocosNodeRGBA protocol */
@property (nonatomic,readwrite) GLubyte opacity;
/** conforms to CocosNodeRGBA protocol */
@property (nonatomic,readwrite) ccColor3B color;

@end