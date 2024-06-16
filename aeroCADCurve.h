//
//  aeroCADCurve.h
//  aeroCAD
//
//  Created by Jeff Glaum on 7/30/10.
//  Copyright 2010 Jeff Glaum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "aeroCADXform.h"

typedef enum
{
	CURVE_TYPE_LINE=1,
	CURVE_TYPE_BEZIER
} CURVE_TYPE;

@interface aeroCADCurve : NSObject 
{
	CURVE_TYPE		_type;
	BOOL			_selected;
	int				_count;
	CGFloat			_length;
	int				_paramindex;
	NSColor			*_color;
	POINT3D			*_list;
	POINT3D			*_listp;
	aeroCADXform	*_xform;
}

@property(assign) POINT3D *_listp;


- (id)   init:(CURVE_TYPE)type;
- (id)   initWithParam:(CURVE_TYPE)type :(POINT3D *)list :(int)count;
- (BOOL) bindXform:(aeroCADXform *)xform;
- (BOOL) setColor:(NSColor *)color;
- (BOOL) drawSelf;
- (BOOL) drawSelf:(NSColor *)color;
- (BOOL) invertSelf;
- (BOOL) setStartPoint:(POINT3D)startpt;
- (BOOL) appendSegment:(POINT3D)endpt;
- (BOOL) appendSegment:(POINT3D)ctl1pt :(POINT3D)ctl2pt :(POINT3D)endpt;
- (POINT3D) curveParametric:(CGFloat)t;
- (aeroCADCurve *) copySelf;
- (aeroCADCurve *) copySelfParam:(CGFloat)t;
- (void )xformCurve:(CGFloat)dx :(CGFloat)dy :(CGFloat)dz :(CGFloat)scale :(CGFloat)rotx :(CGFloat)roty :(CGFloat)rotz;
- (void )xformCurve:(POINT3D)point :(CGFloat)scale :(CGFloat)rotx :(CGFloat)roty :(CGFloat)rotz;
- (BOOL) hitTest:(NSPoint) pt;
- (BOOL) toggleSelected;
- (BOOL) isSelected;
- (CGFloat) getMinX;
- (CGFloat) getMaxX;
- (BOOL) getFirstParametricPoint: (POINT3D *)pt;
- (BOOL) getNextParametricPoint: (POINT3D *)pt;
- (BOOL) getParametricTangent: (VECTOR3D *)v;
BOOL AlmostEqualUlps(CGFloat A, CGFloat B, int maxUlps);



@end
