//
//  aeroCADLighting.h
//  aeroCAD
//
//  Created by Jeff Glaum on 7/10/10.
//  Copyright 2010 Jeff Glaum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "aeroCADTypes.h"


typedef struct _TRIANGLE
{
	int id;
	CGFloat nx, ny, nz;
	CGFloat eyeang;
	CGFloat lightang;
	CGFloat max_z;
	POINT3D *v1, *v2, *v3;
} TRIANGLE;


@interface aeroCADLighting : NSObject 
{
}

- (void) depthSort:(void *)surf;
- (void) computeNormals:(void *)surf;

@end
