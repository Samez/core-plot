#import "CPTPlotSymbol.h"

#import "CPTDefinitions.h"
#import "CPTFill.h"
#import "CPTLineStyle.h"
#import "CPTShadow.h"
#import "NSCoderExtensions.h"
#import <tgmath.h>

/// @cond
@interface CPTPlotSymbol()

@property (nonatomic, readwrite, assign) CGPathRef cachedSymbolPath;
@property (nonatomic, readwrite, assign) CGLayerRef cachedLayer;

-(CGPathRef)newSymbolPath;

@end

/// @endcond

#pragma mark -

/** @brief Plot symbols for CPTScatterPlot.
 */
@implementation CPTPlotSymbol

/** @property CGPoint anchorPoint
 *  @brief The anchor point for the plot symbol. Defaults to (@num{0.5}, @num{0.5}) which centers the symbol on the plot point.
 **/
@synthesize anchorPoint;

/** @property CGSize size
 *  @brief The symbol size.
 **/
@synthesize size;

/** @property CPTPlotSymbolType symbolType
 *  @brief The symbol type.
 **/
@synthesize symbolType;

/** @property CPTLineStyle *lineStyle
 *  @brief The line style for the border of the symbol.
 *  If @nil, the border is not drawn.
 **/
@synthesize lineStyle;

/** @property CPTFill *fill
 *  @brief The fill for the interior of the symbol.
 *  If @nil, the symbol is not filled.
 **/
@synthesize fill;

/** @property CPTShadow *shadow
 *  @brief The shadow applied to each plot symbol.
 **/
@synthesize shadow;

/** @property CGPathRef customSymbolPath
 *  @brief The drawing path for a custom plot symbol. It will be scaled to @ref size before being drawn.
 **/
@synthesize customSymbolPath;

/** @property BOOL usesEvenOddClipRule
 *  @brief If @YES, the even-odd rule is used to draw the symbol, otherwise the non-zero winding number rule is used.
 *  @see <a href="http://developer.apple.com/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_paths/dq_paths.html#//apple_ref/doc/uid/TP30001066-CH211-TPXREF106">Filling a Path</a> in the Quartz 2D Programming Guide.
 **/
@synthesize usesEvenOddClipRule;

@dynamic cachedSymbolPath;

@synthesize cachedLayer;

#pragma mark -
#pragma mark Init/Dealloc

/// @name Initialization
/// @{

/** @brief Initializes a newly allocated CPTPlotSymbol object.
 *
 *  The initialized object will have the following properties:
 *  - @ref anchorPoint = (@num{0.5}, @num{0.5})
 *  - @ref size = (@num{5.0}, @num{5.0})
 *  - @ref symbolType = #CPTPlotSymbolTypeNone
 *  - @ref lineStyle = a new default line style
 *  - @ref fill = @nil
 *  - @ref shadow = @nil
 *  - @ref customSymbolPath = @NULL
 *  - @ref usesEvenOddClipRule = @NO
 *
 *  @return The initialized object.
 **/
-(id)init
{
    if ( (self = [super init]) ) {
        anchorPoint         = CPTPointMake(0.5, 0.5);
        size                = CPTSizeMake(5.0, 5.0);
        symbolType          = CPTPlotSymbolTypeNone;
        lineStyle           = [[CPTLineStyle alloc] init];
        fill                = nil;
        shadow              = nil;
        cachedSymbolPath    = NULL;
        customSymbolPath    = NULL;
        usesEvenOddClipRule = NO;
        cachedLayer         = NULL;
    }
    return self;
}

/// @}

/// @cond

-(void)dealloc
{
    [lineStyle release];
    [fill release];
    [shadow release];
    CGPathRelease(cachedSymbolPath);
    CGPathRelease(customSymbolPath);
    CGLayerRelease(cachedLayer);

    [super dealloc];
}

-(void)finalize
{
    CGPathRelease(cachedSymbolPath);
    CGPathRelease(customSymbolPath);
    CGLayerRelease(cachedLayer);
    [super finalize];
}

/// @endcond

#pragma mark -
#pragma mark NSCoding Methods

/// @cond

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeCPTPoint:self.anchorPoint forKey:@"CPTPlotSymbol.anchorPoint"];
    [coder encodeCPTSize:self.size forKey:@"CPTPlotSymbol.size"];
    [coder encodeInt:self.symbolType forKey:@"CPTPlotSymbol.symbolType"];
    [coder encodeObject:self.lineStyle forKey:@"CPTPlotSymbol.lineStyle"];
    [coder encodeObject:self.fill forKey:@"CPTPlotSymbol.fill"];
    [coder encodeObject:self.shadow forKey:@"CPTPlotSymbol.shadow"];
    [coder encodeCGPath:self.customSymbolPath forKey:@"CPTPlotSymbol.customSymbolPath"];
    [coder encodeBool:self.usesEvenOddClipRule forKey:@"CPTPlotSymbol.usesEvenOddClipRule"];

    // No need to archive these properties:
    // cachedSymbolPath
    // cachedLayer
}

-(id)initWithCoder:(NSCoder *)coder
{
    if ( (self = [super init]) ) {
        anchorPoint         = [coder decodeCPTPointForKey:@"CPTPlotSymbol.anchorPoint"];
        size                = [coder decodeCPTSizeForKey:@"CPTPlotSymbol.size"];
        symbolType          = (CPTPlotSymbolType)[coder decodeIntForKey : @"CPTPlotSymbol.symbolType"];
        lineStyle           = [[coder decodeObjectForKey:@"CPTPlotSymbol.lineStyle"] retain];
        fill                = [[coder decodeObjectForKey:@"CPTPlotSymbol.fill"] retain];
        shadow              = [[coder decodeObjectForKey:@"CPTPlotSymbol.shadow"] copy];
        customSymbolPath    = [coder newCGPathDecodeForKey:@"CPTPlotSymbol.customSymbolPath"];
        usesEvenOddClipRule = [coder decodeBoolForKey:@"CPTPlotSymbol.usesEvenOddClipRule"];

        cachedSymbolPath = NULL;
        cachedLayer      = NULL;
    }
    return self;
}

/// @endcond

#pragma mark -
#pragma mark Accessors

/// @cond

-(void)setSize:(CGSize)newSize
{
    if ( !CGSizeEqualToSize(newSize, size) ) {
        size                  = newSize;
        self.cachedSymbolPath = NULL;
    }
}

-(void)setSymbolType:(CPTPlotSymbolType)newType
{
    if ( newType != symbolType ) {
        symbolType            = newType;
        self.cachedSymbolPath = NULL;
    }
}

-(void)setShadow:(CPTShadow *)newShadow
{
    if ( newShadow != shadow ) {
        [shadow release];
        shadow                = [newShadow copy];
        self.cachedSymbolPath = NULL;
    }
}

-(void)setCustomSymbolPath:(CGPathRef)newPath
{
    if ( customSymbolPath != newPath ) {
        CGPathRelease(customSymbolPath);
        customSymbolPath      = CGPathRetain(newPath);
        self.cachedSymbolPath = NULL;
    }
}

-(CGPathRef)cachedSymbolPath
{
    if ( !cachedSymbolPath ) {
        cachedSymbolPath = [self newSymbolPath];
    }
    return cachedSymbolPath;
}

-(void)setCachedSymbolPath:(CGPathRef)newPath
{
    if ( cachedSymbolPath != newPath ) {
        CGPathRelease(cachedSymbolPath);
        cachedSymbolPath = CGPathRetain(newPath);
        self.cachedLayer = NULL;
    }
}

-(void)setCachedLayer:(CGLayerRef)newLayer
{
    if ( cachedLayer != newLayer ) {
        CGLayerRelease(cachedLayer);
        cachedLayer = CGLayerRetain(newLayer);
    }
}

/// @endcond

#pragma mark -
#pragma mark Class methods

/** @brief Creates and returns a new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeNone.
 *  @return A new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeNone.
 **/
+(CPTPlotSymbol *)plotSymbol
{
    CPTPlotSymbol *symbol = [[self alloc] init];

    symbol.symbolType = CPTPlotSymbolTypeNone;

    return [symbol autorelease];
}

/** @brief Creates and returns a new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeCross.
 *  @return A new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeCross.
 **/
+(CPTPlotSymbol *)crossPlotSymbol
{
    CPTPlotSymbol *symbol = [[self alloc] init];

    symbol.symbolType = CPTPlotSymbolTypeCross;

    return [symbol autorelease];
}

/** @brief Creates and returns a new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeEllipse.
 *  @return A new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeEllipse.
 **/
+(CPTPlotSymbol *)ellipsePlotSymbol
{
    CPTPlotSymbol *symbol = [[self alloc] init];

    symbol.symbolType = CPTPlotSymbolTypeEllipse;

    return [symbol autorelease];
}

/** @brief Creates and returns a new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeRectangle.
 *  @return A new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeRectangle.
 **/
+(CPTPlotSymbol *)rectanglePlotSymbol
{
    CPTPlotSymbol *symbol = [[self alloc] init];

    symbol.symbolType = CPTPlotSymbolTypeRectangle;

    return [symbol autorelease];
}

/** @brief Creates and returns a new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypePlus.
 *  @return A new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypePlus.
 **/
+(CPTPlotSymbol *)plusPlotSymbol
{
    CPTPlotSymbol *symbol = [[self alloc] init];

    symbol.symbolType = CPTPlotSymbolTypePlus;

    return [symbol autorelease];
}

/** @brief Creates and returns a new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeStar.
 *  @return A new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeStar.
 **/
+(CPTPlotSymbol *)starPlotSymbol
{
    CPTPlotSymbol *symbol = [[self alloc] init];

    symbol.symbolType = CPTPlotSymbolTypeStar;

    return [symbol autorelease];
}

/** @brief Creates and returns a new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeDiamond.
 *  @return A new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeDiamond.
 **/
+(CPTPlotSymbol *)diamondPlotSymbol
{
    CPTPlotSymbol *symbol = [[self alloc] init];

    symbol.symbolType = CPTPlotSymbolTypeDiamond;

    return [symbol autorelease];
}

/** @brief Creates and returns a new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeTriangle.
 *  @return A new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeTriangle.
 **/
+(CPTPlotSymbol *)trianglePlotSymbol
{
    CPTPlotSymbol *symbol = [[self alloc] init];

    symbol.symbolType = CPTPlotSymbolTypeTriangle;

    return [symbol autorelease];
}

/** @brief Creates and returns a new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypePentagon.
 *  @return A new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypePentagon.
 **/
+(CPTPlotSymbol *)pentagonPlotSymbol
{
    CPTPlotSymbol *symbol = [[self alloc] init];

    symbol.symbolType = CPTPlotSymbolTypePentagon;

    return [symbol autorelease];
}

/** @brief Creates and returns a new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeHexagon.
 *  @return A new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeHexagon.
 **/
+(CPTPlotSymbol *)hexagonPlotSymbol
{
    CPTPlotSymbol *symbol = [[self alloc] init];

    symbol.symbolType = CPTPlotSymbolTypeHexagon;

    return [symbol autorelease];
}

/** @brief Creates and returns a new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeDash.
 *  @return A new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeDash.
 **/
+(CPTPlotSymbol *)dashPlotSymbol
{
    CPTPlotSymbol *symbol = [[self alloc] init];

    symbol.symbolType = CPTPlotSymbolTypeDash;

    return [symbol autorelease];
}

/** @brief Creates and returns a new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeSnow.
 *  @return A new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeSnow.
 **/
+(CPTPlotSymbol *)snowPlotSymbol
{
    CPTPlotSymbol *symbol = [[self alloc] init];

    symbol.symbolType = CPTPlotSymbolTypeSnow;

    return [symbol autorelease];
}

/** @brief Creates and returns a new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeCustom.
 *  @param aPath The bounding path for the custom symbol.
 *  @return A new CPTPlotSymbol instance initialized with a symbol type of #CPTPlotSymbolTypeCustom.
 **/
+(CPTPlotSymbol *)customPlotSymbolWithPath:(CGPathRef)aPath
{
    CPTPlotSymbol *symbol = [[self alloc] init];

    symbol.symbolType       = CPTPlotSymbolTypeCustom;
    symbol.customSymbolPath = aPath;

    return [symbol autorelease];
}

#pragma mark -
#pragma mark NSCopying Methods

/// @cond

-(id)copyWithZone:(NSZone *)zone
{
    CPTPlotSymbol *copy = [[[self class] allocWithZone:zone] init];

    copy.anchorPoint         = self.anchorPoint;
    copy.size                = self.size;
    copy.symbolType          = self.symbolType;
    copy.usesEvenOddClipRule = self.usesEvenOddClipRule;
    copy.lineStyle           = [[self.lineStyle copy] autorelease];
    copy.fill                = [[self.fill copy] autorelease];
    copy.shadow              = [[self.shadow copy] autorelease];

    if ( self.customSymbolPath ) {
        CGPathRef pathCopy = CGPathCreateCopy(self.customSymbolPath);
        copy.customSymbolPath = pathCopy;
        CGPathRelease(pathCopy);
    }

    return copy;
}

/// @endcond

#pragma mark -
#pragma mark Drawing

/** @brief Draws the plot symbol into the given graphics context centered at the provided point using the cached symbol image.
 *  @param context The graphics context to draw into.
 *  @param center The center point of the symbol.
 *  @param scale The drawing scale factor. Must be greater than zero (@num{0}).
 *  @param alignToPixels If @YES, the symbol position is aligned with device pixels to reduce anti-aliasing artifacts.
 **/
-(void)renderInContext:(CGContextRef)context atPoint:(CGPoint)center scale:(CGFloat)scale alignToPixels:(BOOL)alignToPixels
{
    const CGFloat symbolMargin = CPTFloat(2.0);

    CGPoint symbolAnchor = self.anchorPoint;
    CGSize symbolSize    = self.size;
    CGSize shadowOffset  = CGSizeZero;
    CGFloat shadowRadius = CPTFloat(0.0);
    CPTShadow *myShadow  = self.shadow;

    if ( myShadow ) {
        shadowOffset = myShadow.shadowOffset;
        shadowRadius = myShadow.shadowBlurRadius;
    }

    CGLayerRef theCachedLayer = self.cachedLayer;

    if ( !theCachedLayer ) {
        CGSize layerSize  = symbolSize;
        CGFloat lineWidth = self.lineStyle.lineWidth;

        layerSize.width += (ABS(shadowOffset.width) + shadowRadius) * CPTFloat(2.0) + lineWidth;
        layerSize.width *= scale;
        layerSize.width += symbolMargin;

        layerSize.height += (ABS(shadowOffset.height) + shadowRadius) * CPTFloat(2.0) + lineWidth;
        layerSize.height *= scale;
        layerSize.height += symbolMargin;

        self.anchorPoint = CPTPointMake(0.5, 0.5);

        CGLayerRef newLayer = CGLayerCreateWithContext(context, layerSize, NULL);

        [self renderAsVectorInContext:CGLayerGetContext(newLayer)
                              atPoint:CPTPointMake( layerSize.width * CPTFloat(0.5), layerSize.height * CPTFloat(0.5) )
                                scale:scale];

        self.cachedLayer = newLayer;
        CGLayerRelease(newLayer);
        theCachedLayer   = self.cachedLayer;
        self.anchorPoint = symbolAnchor;
    }

    if ( theCachedLayer ) {
        CGSize layerSize = CGLayerGetSize(theCachedLayer);
        if ( scale != 1.0 ) {
            layerSize.width  /= scale;
            layerSize.height /= scale;
        }

        CGPoint origin = CPTPointMake( center.x - layerSize.width * CPTFloat(0.5) - symbolSize.width * ( symbolAnchor.x - CPTFloat(0.5) ),
                                       center.y - layerSize.height * CPTFloat(0.5) - symbolSize.height * ( symbolAnchor.y - CPTFloat(0.5) ) );

        if ( alignToPixels ) {
            if ( scale == 1.0 ) {
                origin.x = round(origin.x);
                origin.y = round(origin.y);
            }
            else {
                origin.x = round(origin.x * scale) / scale;
                origin.y = round(origin.y * scale) / scale;
            }
        }

        CGContextDrawLayerInRect(context, CPTRectMake(origin.x, origin.y, layerSize.width, layerSize.height), theCachedLayer);
    }
}

/** @brief Draws the plot symbol into the given graphics context centered at the provided point.
 *  @param context The graphics context to draw into.
 *  @param center The center point of the symbol.
 *  @param scale The drawing scale factor. Must be greater than zero (@num{0}).
 **/
-(void)renderAsVectorInContext:(CGContextRef)context atPoint:(CGPoint)center scale:(CGFloat)scale
{
    CGPathRef theSymbolPath = self.cachedSymbolPath;

    if ( theSymbolPath ) {
        CPTLineStyle *theLineStyle = nil;
        CPTFill *theFill           = nil;

        switch ( self.symbolType ) {
            case CPTPlotSymbolTypeRectangle:
            case CPTPlotSymbolTypeEllipse:
            case CPTPlotSymbolTypeDiamond:
            case CPTPlotSymbolTypeTriangle:
            case CPTPlotSymbolTypeStar:
            case CPTPlotSymbolTypePentagon:
            case CPTPlotSymbolTypeHexagon:
            case CPTPlotSymbolTypeCustom:
                theLineStyle = self.lineStyle;
                theFill      = self.fill;
                break;

            case CPTPlotSymbolTypeCross:
            case CPTPlotSymbolTypePlus:
            case CPTPlotSymbolTypeDash:
            case CPTPlotSymbolTypeSnow:
                theLineStyle = self.lineStyle;
                break;

            default:
                break;
        }

        if ( theLineStyle || theFill ) {
            CGPoint symbolAnchor = self.anchorPoint;
            CGSize symbolSize    = self.size;

            CGContextSaveGState(context);
            CGContextTranslateCTM(context, center.x + ( symbolAnchor.x - CPTFloat(0.5) ) * symbolSize.width, center.y + ( symbolAnchor.y - CPTFloat(0.5) ) * symbolSize.height);
            CGContextScaleCTM(context, scale, scale);
            [self.shadow setShadowInContext:context];
            CGContextBeginTransparencyLayer(context, NULL);

            if ( theFill ) {
                // use fillRect instead of fillPath so that images and gradients are properly centered in the symbol
                CGSize halfSize = CPTSizeMake( symbolSize.width * CPTFloat(0.5), symbolSize.height * CPTFloat(0.5) );
                CGRect bounds   = CPTRectMake(-halfSize.width, -halfSize.height, symbolSize.width, symbolSize.height);

                CGContextSaveGState(context);
                if ( !CGPathIsEmpty(theSymbolPath) ) {
                    CGContextBeginPath(context);
                    CGContextAddPath(context, theSymbolPath);
                    if ( self.usesEvenOddClipRule ) {
                        CGContextEOClip(context);
                    }
                    else {
                        CGContextClip(context);
                    }
                }
                [theFill fillRect:bounds inContext:context];
                CGContextRestoreGState(context);
            }

            if ( theLineStyle ) {
                [theLineStyle setLineStyleInContext:context];
                CGContextBeginPath(context);
                CGContextAddPath(context, theSymbolPath);
                [theLineStyle strokePathInContext:context];
            }

            CGContextEndTransparencyLayer(context);
            CGContextRestoreGState(context);
        }
    }
}

#pragma mark -
#pragma mark Private methods

/// @cond

/** @internal
 *  @brief Creates and returns a drawing path for the current symbol type.
 *  @return A path describing the outline of the current symbol type.
 **/
-(CGPathRef)newSymbolPath
{
    CGFloat dx, dy;
    CGSize symbolSize = self.size;
    CGSize halfSize   = CPTSizeMake( symbolSize.width * CPTFloat(0.5), symbolSize.height * CPTFloat(0.5) );

    CGMutablePathRef symbolPath = CGPathCreateMutable();

    switch ( self.symbolType ) {
        case CPTPlotSymbolTypeNone:
            // empty path
            break;

        case CPTPlotSymbolTypeRectangle:
            CGPathAddRect( symbolPath, NULL, CPTRectMake(-halfSize.width, -halfSize.height, symbolSize.width, symbolSize.height) );
            break;

        case CPTPlotSymbolTypeEllipse:
            CGPathAddEllipseInRect( symbolPath, NULL, CPTRectMake(-halfSize.width, -halfSize.height, symbolSize.width, symbolSize.height) );
            break;

        case CPTPlotSymbolTypeCross:
            CGPathMoveToPoint(symbolPath, NULL, -halfSize.width, halfSize.height);
            CGPathAddLineToPoint(symbolPath, NULL, halfSize.width, -halfSize.height);
            CGPathMoveToPoint(symbolPath, NULL, halfSize.width, halfSize.height);
            CGPathAddLineToPoint(symbolPath, NULL, -halfSize.width, -halfSize.height);
            break;

        case CPTPlotSymbolTypePlus:
            CGPathMoveToPoint(symbolPath, NULL, CPTFloat(0.0), halfSize.height);
            CGPathAddLineToPoint(symbolPath, NULL, CPTFloat(0.0), -halfSize.height);
            CGPathMoveToPoint( symbolPath, NULL, -halfSize.width, CPTFloat(0.0) );
            CGPathAddLineToPoint( symbolPath, NULL, halfSize.width, CPTFloat(0.0) );
            break;

        case CPTPlotSymbolTypePentagon:
            CGPathMoveToPoint(symbolPath, NULL, CPTFloat(0.0), halfSize.height);
            CGPathAddLineToPoint( symbolPath, NULL, halfSize.width * CPTFloat(0.95105651630), halfSize.height * CPTFloat(0.30901699437) );
            CGPathAddLineToPoint( symbolPath, NULL, halfSize.width * CPTFloat(0.58778525229), -halfSize.height * CPTFloat(0.80901699437) );
            CGPathAddLineToPoint( symbolPath, NULL, -halfSize.width * CPTFloat(0.58778525229), -halfSize.height * CPTFloat(0.80901699437) );
            CGPathAddLineToPoint( symbolPath, NULL, -halfSize.width * CPTFloat(0.95105651630), halfSize.height * CPTFloat(0.30901699437) );
            CGPathCloseSubpath(symbolPath);
            break;

        case CPTPlotSymbolTypeStar:
            CGPathMoveToPoint(symbolPath, NULL, CPTFloat(0.0), halfSize.height);
            CGPathAddLineToPoint( symbolPath, NULL, halfSize.width * CPTFloat(0.22451398829), halfSize.height * CPTFloat(0.30901699437) );
            CGPathAddLineToPoint( symbolPath, NULL, halfSize.width * CPTFloat(0.95105651630), halfSize.height * CPTFloat(0.30901699437) );
            CGPathAddLineToPoint( symbolPath, NULL, halfSize.width * CPTFloat(0.36327126400), -halfSize.height * CPTFloat(0.11803398875) );
            CGPathAddLineToPoint( symbolPath, NULL, halfSize.width * CPTFloat(0.58778525229), -halfSize.height * CPTFloat(0.80901699437) );
            CGPathAddLineToPoint( symbolPath, NULL, CPTFloat(0.0), -halfSize.height * CPTFloat(0.38196601125) );
            CGPathAddLineToPoint( symbolPath, NULL, -halfSize.width * CPTFloat(0.58778525229), -halfSize.height * CPTFloat(0.80901699437) );
            CGPathAddLineToPoint( symbolPath, NULL, -halfSize.width * CPTFloat(0.36327126400), -halfSize.height * CPTFloat(0.11803398875) );
            CGPathAddLineToPoint( symbolPath, NULL, -halfSize.width * CPTFloat(0.95105651630), halfSize.height * CPTFloat(0.30901699437) );
            CGPathAddLineToPoint( symbolPath, NULL, -halfSize.width * CPTFloat(0.22451398829), halfSize.height * CPTFloat(0.30901699437) );
            CGPathCloseSubpath(symbolPath);
            break;

        case CPTPlotSymbolTypeDiamond:
            CGPathMoveToPoint(symbolPath, NULL, CPTFloat(0.0), halfSize.height);
            CGPathAddLineToPoint( symbolPath, NULL, halfSize.width, CPTFloat(0.0) );
            CGPathAddLineToPoint(symbolPath, NULL, CPTFloat(0.0), -halfSize.height);
            CGPathAddLineToPoint( symbolPath, NULL, -halfSize.width, CPTFloat(0.0) );
            CGPathCloseSubpath(symbolPath);
            break;

        case CPTPlotSymbolTypeTriangle:
            dx = halfSize.width * CPTFloat(0.86602540378); // sqrt(3.0) / 2.0;
            dy = halfSize.height / CPTFloat(2.0);

            CGPathMoveToPoint(symbolPath, NULL, CPTFloat(0.0), halfSize.height);
            CGPathAddLineToPoint(symbolPath, NULL, dx, -dy);
            CGPathAddLineToPoint(symbolPath, NULL, -dx, -dy);
            CGPathCloseSubpath(symbolPath);
            break;

        case CPTPlotSymbolTypeDash:
            CGPathMoveToPoint( symbolPath, NULL, halfSize.width, CPTFloat(0.0) );
            CGPathAddLineToPoint( symbolPath, NULL, -halfSize.width, CPTFloat(0.0) );
            break;

        case CPTPlotSymbolTypeHexagon:
            dx = halfSize.width * CPTFloat(0.86602540378); // sqrt(3.0) / 2.0;
            dy = halfSize.height / CPTFloat(2.0);

            CGPathMoveToPoint(symbolPath, NULL, CPTFloat(0.0), halfSize.height);
            CGPathAddLineToPoint(symbolPath, NULL, dx, dy);
            CGPathAddLineToPoint(symbolPath, NULL, dx, -dy);
            CGPathAddLineToPoint(symbolPath, NULL, CPTFloat(0.0), -halfSize.height);
            CGPathAddLineToPoint(symbolPath, NULL, -dx, -dy);
            CGPathAddLineToPoint(symbolPath, NULL, -dx, dy);
            CGPathCloseSubpath(symbolPath);
            break;

        case CPTPlotSymbolTypeSnow:
            dx = halfSize.width * CPTFloat(0.86602540378); // sqrt(3.0) / 2.0;
            dy = halfSize.height / CPTFloat(2.0);

            CGPathMoveToPoint(symbolPath, NULL, CPTFloat(0.0), halfSize.height);
            CGPathAddLineToPoint(symbolPath, NULL, CPTFloat(0.0), -halfSize.height);
            CGPathMoveToPoint(symbolPath, NULL, dx, -dy);
            CGPathAddLineToPoint(symbolPath, NULL, -dx, dy);
            CGPathMoveToPoint(symbolPath, NULL, -dx, -dy);
            CGPathAddLineToPoint(symbolPath, NULL, dx, dy);
            break;

        case CPTPlotSymbolTypeCustom:
        {
            CGPathRef customPath = self.customSymbolPath;
            if ( customPath ) {
                CGAffineTransform scaleTransform = CGAffineTransformIdentity;

                CGRect oldBounds = CGPathGetBoundingBox(customPath);
                CGFloat dx1      = symbolSize.width / oldBounds.size.width;
                CGFloat dy1      = symbolSize.height / oldBounds.size.height;
                scaleTransform = CGAffineTransformScale(CGAffineTransformIdentity, dx1, dy1);
                scaleTransform = CGAffineTransformConcat( scaleTransform,
                                                          CGAffineTransformMakeTranslation(-halfSize.width, -halfSize.height) );
                CGPathAddPath(symbolPath, &scaleTransform, customPath);
            }
        }
        break;
    }

    return symbolPath;
}

/// @endcond

@end
