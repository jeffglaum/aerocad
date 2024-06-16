//
//  aeroCADPointVector3D.h
//  aeroCAD
//
//  Created by Jeff Glaum on 1/10/11.
//  Copyright 2011 Jeff Glaum. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// The PointVector3D class is used to represent both points and vectors in 3D.
// Using a single class for both types simplifies function interfaces.

@interface PointVector3D : NSObject 
{
	CGFloat _w;	// homogenous coordinate
	CGFloat _x;	// X coordinate
	CGFloat _y;	// Y coordinate
	CGFloat _z;	// Z coordinate
}

- (id) init;
- (id) initWithParam: (PointVector3D *)ptv;
- (id) initWithParam: (CGFloat)x :(CGFloat)y :(CGFloat)z :(CGFloat)w;

-(CGFloat) ptvGetLength;
-(CGFloat) ptvGetX;
-(CGFloat) ptvGetY;
-(CGFloat) ptvGetZ;

-(void) ptvNormalize;
-(void) ptvMultScalar:(CGFloat)scalar;
-(void) ptvDotProduct: (PointVector3D *)ptv :(CGFloat *)angleOut;
-(void) ptvCrossProduct: (PointVector3D *)ptv :(PointVector3D *)ptvOut;
//-(CGFloat) ptvGetLength;

@end
