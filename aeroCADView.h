//
//  aeroCADView.h
//  aeroCAD
//
//  Created by Jeff Glaum on 7/4/10.
//  Copyright 2010 Jeff Glaum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "aeroCADTypes.h"
#import "aeroCADXform.h"
#import "aeroCADLighting.h"
#import "aeroCADLoftedSurf.h"


// Currently-selected viewing mode
//
typedef enum
{
    XYPLANE = 0,        // Perpendicular to the XY Plane
    XZPLANE,            // Perpendicular to the XZ Plane
    YZPLANE,            // Perpendicular to the YZ Plane
    ISOMETRIC,          // Isometric view
    FREEROTATE          // Not one of the above (free rotation view)
} VIEWMODE;

@interface aeroCADView : NSView
{
    VIEWMODE viewMode;                              // Current view mode (i.e., XY-plane, Isometric, etc.)
    CGFloat  gridSpacing;                           // Display grid spacing interval

	BOOL doShade;                                   // Enable surface shading (Yes/No)
	BOOL showNormals;                               // Display surface normals (Yes/No)
	aeroCADXform *primaryXform;                     // Primary/Master display transform
	aeroCADXform *cursorXform;                      // Cursor display transform
	aeroCADLighting *primaryShader;                 // Primary/Master shader
	POINT_SET *primaryCoord, *primaryCoordp;        // Coordinate axis pointset
	POINT_SET *primaryCursor, *primaryCursorp;      // Cursor pointset
    POINT_SET *gridArray, *gridArrayp;              // Display grid pointset
	NSMutableArray *_displayList;                   // Display list
	NSMutableString *_commandLine;                  // Command line string
}

@property(assign) aeroCADXform *primaryXform;
@property(assign) aeroCADXform *cursorXform;

// Function prototypes
//
- (POINT_SET *) initPointset: (int)numpoints :(POINT3D *)pointlist;
- (void) enableShading: (BOOL)Shade;
- (void) toggleNormals;
- (void) drawCursor;
- (BOOL) addToDisplayList: (id)obj;
- (BOOL) removeFromDisplayList: (id)obj;
- (void) renderDisplayList;
- (void) drawGrid;
- (void) moveCursorRel: (CGFloat)dx :(CGFloat)dy :(CGFloat)dz;
- (void) moveCursorAbs: (CGFloat)x :(CGFloat)y :(CGFloat)z;
- (POINT3D) getCursor;
- (id) selectObject: (NSPoint)mouseCursor;
- (void) defaultKeyHandler: (NSString *)keyEvent;

- (BOOL) scaleSelectedObjects: (CGFloat)scale;
- (BOOL) rotateSelectedObjects: (CGFloat)rotx :(CGFloat)roty :(CGFloat)rotz;
- (BOOL) translateSelectedObjects: (CGFloat)dx :(CGFloat)dy :(CGFloat)dz;

- (BOOL) setGridSpacing: (CGFloat)Spacing;

@end
