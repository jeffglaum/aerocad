//
//  aeroCADXform.h
//  aeroCAD
//
//  Created by Jeff Glaum on 7/10/10.
//  Copyright 2010 Jeff Glaum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "aeroCADTypes.h"

//#define DEFAULT_SCALE		30
#define DEFAULT_SCALE		10


@interface aeroCADXform : NSObject 
{
	CGFloat cmpst[4][4];	
	CGFloat invrs[4][4];	
	CGFloat persp[4][4];
	CGFloat invrspersp[4][4];	
}

- (id)   init;
- (id)   initWithParams:(CGFloat)size :(CGFloat)xang :(CGFloat)yang :(CGFloat)zang;

- (void) transform:(BOOL) applypersp :(POINT_SET *)inset : (POINT_SET *)outset;
- (void) transform:(BOOL) applypersp :(POINT3D *)inset : (POINT3D *)outset : (int)count;
- (POINT3D) transform:(BOOL) applypersp :(POINT3D)inpt;

- (void) mtxmult:(CGFloat [4][4])destination :(CGFloat [4][4])source;

- (void) xlate:(CGFloat)dx :(CGFloat)dy :(CGFloat)dz;
- (void) scale:(CGFloat)factor;
- (void) rotatex:(CGFloat)ang;  
- (void) rotatey:(CGFloat)ang;  
- (void) rotatez:(CGFloat)ang;  
- (void) perspective:(POINT3D)eyePos;

@end
