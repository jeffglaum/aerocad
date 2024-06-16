//
//  aeroCADLoftedSurf.h
//  aeroCAD
//
//  Created by Jeff Glaum on 8/5/10.
//  Copyright 2010 Jeff Glaum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "aeroCADCurve.h"
#import "aeroCADLighting.h"
#import "aeroCADTypes.h"
	
@interface aeroCADLoftedSurf : NSObject {

	BOOL			_selected;

	// Lofted surface direction vector.
	VECTOR3D		_direction;
	int				_curveCount;
	
	// Actual curve data is sampled for rendering.
	aeroCADCurve	**_curves;
	CGFloat			_curveSampleStep;
	int				_curveSampleCount;
	aeroCADCurve	**_curveSamples;
	
	// Wireframe rendering connects parameterized curves - coarse stepping (sampling of parameterized curves).
	CGFloat			_curveWireStep;
	int				_curveWireCount;
	
	// Shading requires finer stepping (sampling of parameterized curves).
	CGFloat			_curveShadeStep;
	int				_curveShadeCount;
	int				_triangleCount;
	TRIANGLE		*_shadeTriangles;
}

@property(assign) TRIANGLE *_shadeTriangles;
@property(assign) int _triangleCount;


- (id)   init;
- (void) setDirection:(VECTOR3D)dir;
- (BOOL) addCurve:(aeroCADCurve *)curve;
- (BOOL) finishEditing;
- (BOOL) drawSelf:(BOOL)fShade;
- (BOOL) setColor:(NSColor *)color;
- (void) showNormals;
- (aeroCADLoftedSurf *) copySelf;
- (BOOL) hitTest:(NSPoint) pt;
- (BOOL) loftSurface: (aeroCADCurve *) profc1 :(aeroCADCurve *) profc2 :(aeroCADCurve *) drivec;
- (BOOL) invertSurface;
- (BOOL) toggleSelected;
- (BOOL) isSelected;

@end