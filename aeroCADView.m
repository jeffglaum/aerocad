//
//  aeroCADView.m
//  aeroCAD
//
//  Created by Jeff Glaum on 7/4/10.
//  Copyright 2010 Jeff Glaum. All rights reserved.
//

#import "aeroCADView.h"
#import "aeroCADTypes.h"
#import "aeroCADXform.h"
#import "aeroCADFileIO.h"
#import "aeroCADLighting.h"
#import "aeroCADCurve.h"
#import "aeroCADLoftedSurf.h"
#import "aeroCADCommands.h"
#import "aeroCADAppDelegate.h"


int g_ox, g_oy;
CMDSTATE g_CurrCmdState = CMD_STATE_NONE;

// Primary coordinate system and axix labels
//
POINT3D coordPoints[] =   
{
	{0.0,  0.0,  0.0,  1.0},	// Origin
	{16.0, 0.0,  0.0,  1.0},	// x-Axis
	{0.0,  16.0, 0.0,  1.0},	// y-Axis
	{0.0,  0.0,  16.0, 1.0},	// z-Axis
	{17.0, 0.0,  0.0,  1.0},	// x-Axis label
	{0.0,  17.0, 0.0,  1.0},	// y-Axis label
	{0.0,  0.0,  17.0, 1.0}	    // z-Axis label
};
#define NUM_COORD_POINTS	(sizeof(coordPoints) / sizeof(coordPoints[0]))

// User cursor
//
POINT3D cursorPoints[] =   
{
	{-1.5, 0.0, 0.0, 1.0},	// P1
	{+1.5, 0.0, 0.0, 1.0},	// P2
	{0.0, -1.5, 0.0, 1.0},	// P3
	{0.0, +1.5, 0.0, 1.0},	// P4
	{0.0, 0.0, -1.5, 1.0},	// P5
	{0.0, 0.0, +1.5, 1.0},	// P6
	{0.0, 0.0,  0.0, 1.0}	// Origin
};
#define NUM_CURSOR_POINTS	(sizeof(cursorPoints) / sizeof(cursorPoints[0]))


@implementation aeroCADView
@synthesize primaryXform, cursorXform;


- (id) initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
 
	if (NULL != self)
	{
		[[self window] setContentView: self];

		doShade        = NO;
		showNormals    = NO;
        
		_displayList   = [[NSMutableArray alloc] init];
		_commandLine   = [[NSMutableString alloc] initWithCapacity: 256];

        // Default: Transform set during initialization is isometric view
        //
        viewMode       = ISOMETRIC;
		primaryXform   = [[aeroCADXform alloc] init];
		cursorXform    = [[aeroCADXform alloc] init];
		
		primaryCoord   = [self initPointset: NUM_COORD_POINTS: coordPoints];
		primaryCoordp  = (POINT_SET *)malloc((primaryCoord->points * sizeof(POINT3D)) + sizeof(int));
		primaryCursor  = [self initPointset: NUM_CURSOR_POINTS: cursorPoints];
		primaryCursorp = (POINT_SET *)malloc((primaryCursor->points * sizeof(POINT3D)) + sizeof(int));
		
        // Default: No grid
        gridSpacing    = 0.0f;
        gridArray      = NULL;
        gridArrayp     = NULL;
        
		primaryShader  = [aeroCADLighting alloc];		
	}
	
    return self;
}

- (POINT_SET *)initPointset: (int)numpoints :(POINT3D *)points
{
	POINT_SET *coordSet = (POINT_SET *)(malloc(sizeof(int) + sizeof(POINT3D) * numpoints));
	coordSet->points    = numpoints;
	memcpy(coordSet->pointlist, points, sizeof(POINT3D) * numpoints);				   

	return coordSet;
}
			   
- (BOOL)acceptsFirstResponder 
{
    return YES;
}

- (void) enableShading:(BOOL)fShade
{
	doShade = fShade;
	[self setNeedsDisplay: YES];
}

- (void) toggleNormals
{
	showNormals = !showNormals;
	[self setNeedsDisplay: YES];
}

-(void)defaultKeyHandler: (NSString *) keyEvent
{
	unichar keyChar  = [keyEvent characterAtIndex: 0];
	id appDelegate   = [[NSApplication sharedApplication] delegate];

	switch(keyChar)
	{
		case 127:	// Backspace
			[_commandLine deleteCharactersInRange: NSMakeRange([_commandLine length] - 1, 1)];
			break;
		case 13:	// Enter
			[appDelegate commandHandler: _commandLine];
			[_commandLine deleteCharactersInRange: NSMakeRange(0, [_commandLine length])];
			break;
		default:
			[_commandLine appendString: keyEvent];
			break;
	}
	
	[appDelegate setCommandInputText: _commandLine];
}
	 
- (void)keyDown:(NSEvent *)event
{
	NSString  *keyEvent    = [event charactersIgnoringModifiers];
	unichar    keyChar     = [keyEvent characterAtIndex: 0];
	NSUInteger keyModFlags = [event modifierFlags];
	
    if ( [keyEvent length] != 1 )
		return;

	// Arrow keys (without Function Key despite key mask below)
    if ((keyModFlags & NSEventModifierFlagNumericPad) && (keyModFlags & NSEventModifierFlagFunction))
    {
		switch(keyChar)
		{
            // Translate left
			case NSLeftArrowFunctionKey:
				[primaryXform xlate:-10.0f :0.0f :0.0f];
				[cursorXform  xlate:-10.0f :0.0f :0.0f];
				break;
            // Translate right
			case NSRightArrowFunctionKey:
				[primaryXform xlate:+10.0f :0.0f :0.0f];
				[cursorXform  xlate:+10.0f :0.0f :0.0f];
				break;
            // Translate up
			case NSUpArrowFunctionKey:
				[primaryXform xlate:0.0f :+10.0f :0.0f];
				[cursorXform  xlate:0.0f :+10.0f :0.0f];
				break;
            // Translate down
			case NSDownArrowFunctionKey:
				[primaryXform xlate:0.0f :-10.0f :0.0f];
				[cursorXform  xlate:0.0f :-10.0f :0.0f];
				break;
			default:
				break;
        }
    }   // Function Key combinations
    else if (keyModFlags & NSEventModifierFlagFunction)
    {
		switch(keyChar)
		{
            // Show X-Z plane
			case '1':
				[primaryXform initWithParams:(CGFloat)(DEFAULT_SCALE) :HALF_PI :0.0f :0.0f];
				[cursorXform  initWithParams:(CGFloat)(DEFAULT_SCALE) :HALF_PI :0.0f :0.0f];
                viewMode = XZPLANE;
                if (NULL != gridArray)
                {
                    free(gridArray);
                    gridArray = NULL;
                }
                if (NULL != gridArrayp)
                {
                    free(gridArrayp);
                    gridArrayp = NULL;
                }
				break;
            // Show X-Y plane
			case '2':
				[primaryXform initWithParams:(CGFloat)(DEFAULT_SCALE) :0.0f :0.0f :0.0f];
				[cursorXform  initWithParams:(CGFloat)(DEFAULT_SCALE) :0.0f :0.0f :0.0f];
                viewMode = XYPLANE;
                if (NULL != gridArray)
                {
                    free(gridArray);
                    gridArray = NULL;
                }
                if (NULL != gridArrayp)
                {
                    free(gridArrayp);
                    gridArrayp = NULL;
                }
				break;
            // Show Z-Y plane
			case '3':
				[primaryXform initWithParams:(CGFloat)(DEFAULT_SCALE) :0.0f :-HALF_PI :0.0f];
				[cursorXform  initWithParams:(CGFloat)(DEFAULT_SCALE) :0.0f :-HALF_PI :0.0f];

                viewMode = YZPLANE;
                if (NULL != gridArray)
                {
                    free(gridArray);
                    gridArray = NULL;
                }
                if (NULL != gridArrayp)
                {
                    free(gridArrayp);
                    gridArrayp = NULL;
                }
				break;
            // Show iso X-Y plane
			case '4':
				[primaryXform initWithParams:(CGFloat)(DEFAULT_SCALE) :(CGFloat)(22.5*RADIANS_PER_DEGREE) :(CGFloat)(-22.5*RADIANS_PER_DEGREE) :(CGFloat)(0*RADIANS_PER_DEGREE)];
				[cursorXform  initWithParams:(CGFloat)(DEFAULT_SCALE) :(CGFloat)(22.5*RADIANS_PER_DEGREE) :(CGFloat)(-22.5*RADIANS_PER_DEGREE) :(CGFloat)(0*RADIANS_PER_DEGREE)];
                viewMode = ISOMETRIC;
                if (NULL != gridArray)
                {
                    free(gridArray);
                    gridArray = NULL;
                }
                if (NULL != gridArrayp)
                {
                    free(gridArrayp);
                    gridArrayp = NULL;
                }
				break;
            // Scale up
			case NSPageUpFunctionKey:
				[primaryXform scale:+1.25];
				break;
            // Scale down
			case NSPageDownFunctionKey:
				[primaryXform scale:+0.75];
				break;
			default:
				break;
		}
	}   // Control key combinations
    else if (keyModFlags & NSEventModifierFlagControl)
    {
        switch(keyChar)
		{
            // Rotate around the X axis Anti-Clockwise
			case '1':
				[primaryXform rotatex:(+2.5*RADIANS_PER_DEGREE)];
				[cursorXform  rotatex:(+2.5*RADIANS_PER_DEGREE)];
                viewMode = FREEROTATE;
				break;
            // Rotate around the X axis Anti-Clockwise
			case '2':
				[primaryXform rotatex:(-2.5*RADIANS_PER_DEGREE)];
				[cursorXform  rotatex:(-2.5*RADIANS_PER_DEGREE)];
                viewMode = FREEROTATE;
				break;
            // Rotate around the Y axis Anti-Clockwise
			case '3':
				[primaryXform rotatey:(+2.5*RADIANS_PER_DEGREE)];
				[cursorXform  rotatey:(+2.5*RADIANS_PER_DEGREE)];
                viewMode = FREEROTATE;
				break;
            // Rotate around the Y axis Clockwise
			case '4':
				[primaryXform rotatey:(-2.5*RADIANS_PER_DEGREE)];
				[cursorXform  rotatey:(-2.5*RADIANS_PER_DEGREE)];
                viewMode = FREEROTATE;
				break;
            // Rotate around the Z axis Anti-Clockwise
			case '5':
				[primaryXform rotatez:(+2.5*RADIANS_PER_DEGREE)];
				[cursorXform  rotatez:(+2.5*RADIANS_PER_DEGREE)];
                viewMode = FREEROTATE;
				break;
            // Rotate around the Z axis Clockwise
			case '6':
				[primaryXform rotatez:(-2.5*RADIANS_PER_DEGREE)];
				[cursorXform  rotatez:(-2.5*RADIANS_PER_DEGREE)];
                viewMode = FREEROTATE;
				break;
		}
    }   // Default handler
    else
    {
        [self defaultKeyHandler: keyEvent];
    }
    
	[self setNeedsDisplay:YES];
}

// TODO - the following vector functions are redundant with copies in aeroCADCurve and should be merged/cleaned-up.
//
CGFloat vlDotProduct(VECTOR3D *v0, VECTOR3D *v1)
{
	CGFloat dotprod;
	
	dotprod = (v0 == NULL || v1 == NULL)
	? 0.0f
	: (v0->dx * v1->dx) + (v0->dy * v1->dy);
	
	return(dotprod);
}

VECTOR3D *vlSubtractVectors(VECTOR3D *v0, VECTOR3D *v1, VECTOR3D *v)
{
	if (v0 == NULL || v1 == NULL)
		v = (VECTOR3D *)NULL;
	else
	{
		v->dx = v0->dx - v1->dx;
		v->dy = v0->dy - v1->dy;
	}
	return(v);
}

CGFloat vlVectorMagnitude(VECTOR3D *v0)
{
	CGFloat dMagnitude;
	
	if (v0 == NULL)
		dMagnitude = 0.0f;
	else
		//dMagnitude = sqrt(vVectorSquared(v0));
		dMagnitude = (CGFloat)sqrt(v0->dx*v0->dx + v0->dy*v0->dy);
	
	return (dMagnitude);
}

CGFloat vlGetLengthOfNormal(VECTOR3D *a, VECTOR3D *b)
{
	VECTOR3D c, vNormal;
	//
	//Obtain projection vector.
	//
	//c = ((a * b)/(|b|^2))*b
	//
	c.dx = b->dx * (vlDotProduct(a, b)/vlDotProduct(b, b));
	c.dy = b->dy * (vlDotProduct(a, b)/vlDotProduct(b, b));
	//
	//Obtain perpendicular projection : e = a - c
	//
	vlSubtractVectors(a, &c, &vNormal);
	//
	//Fill PROJECTION structure with appropriate values.
	//
	return (vlVectorMagnitude(&vNormal));
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint mouseCursor = [self convertPoint: [event locationInWindow] fromView: nil];
	POINT3D xformedMouseCursor;
	static aeroCADCurve *pc1 = NULL;
	static aeroCADCurve *pc2 = NULL;
	static aeroCADCurve *dc  = NULL;
	
    // Adjust for view center
    //
	mouseCursor.x -= g_ox;
	mouseCursor.y -= g_oy;
	
	// Get selected object (if any)
    //
	id selectedObj = [self selectObject: mouseCursor];	

	// Translate mouse cursor point into coordinate system
    //
	xformedMouseCursor.pt.x    = mouseCursor.x;
	xformedMouseCursor.pt.y    = mouseCursor.y;
	xformedMouseCursor.pt.z    = 0.0f;
	xformedMouseCursor.pt.rsvd = 1.0f;

	// Input state machine
    //
	switch (g_CurrCmdState)
	{
        case CMD_STATE_CURVE_DELETE:
			if (selectedObj != NULL && [selectedObj isKindOfClass:[aeroCADCurve class]])
			{
				id appDelegate = [[NSApplication sharedApplication] delegate];
				g_CurrCmdState = CMD_STATE_NONE;
				[appDelegate setConsoleOutputText:@""];
                
                aeroCADCurve *c = selectedObj;
                [self removeFromDisplayList: c];
                
                // TODO - What's the right way to free the curve?
                [c release];
                [self setNeedsDisplay:YES];
			}
            break;
        case CMD_STATE_CURVE_INVERT:
			if (selectedObj != NULL && [selectedObj isKindOfClass:[aeroCADCurve class]])
			{
				id appDelegate = [[NSApplication sharedApplication] delegate];
				g_CurrCmdState = CMD_STATE_NONE;
				[appDelegate setConsoleOutputText:@""];
                
                aeroCADCurve *c = selectedObj;
                [c invertSelf];

                [self setNeedsDisplay:YES];
			}
            break;
		case CMD_STATE_LOFT_CURVE1_SELECT:
			if (selectedObj != NULL && [selectedObj isKindOfClass:[aeroCADCurve class]])
			{
				id appDelegate = [[NSApplication sharedApplication] delegate];
				pc1 = selectedObj;
				g_CurrCmdState = CMD_STATE_LOFT_CURVE2_SELECT;
				[appDelegate setConsoleOutputText:@" Select second profile curve"];
			}
			break;
		case CMD_STATE_LOFT_CURVE2_SELECT:
			if (selectedObj != NULL && [selectedObj isKindOfClass:[aeroCADCurve class]])
			{
				pc2 = selectedObj;
				g_CurrCmdState = 0;
				// Read cross-section curve data from file
				id appDelegate = [[NSApplication sharedApplication] delegate];
				[appDelegate setConsoleOutputText:@" Select the cross-section curve file to open"];
				aeroCADFileIO *fileHandler = [aeroCADFileIO alloc];		
				dc = [fileHandler readCurveDataFile: [fileHandler getFileName]];
				
				if (dc != NULL)
				{
					aeroCADLoftedSurf *surf = [[aeroCADLoftedSurf alloc] init];
					[surf loftSurface:pc1 :pc2 :dc];
					[self addToDisplayList: surf];
					
					// Deselect curves
					[pc1 toggleSelected];
					[pc2 toggleSelected];
					[self setNeedsDisplay:YES];
				}
				[appDelegate setConsoleOutputText:@""];
			}
			break;
        case CMD_STATE_INVERT_SURFACE_SELECT:
            {
                id appDelegate = [[NSApplication sharedApplication] delegate];
                if (selectedObj != NULL && [selectedObj isKindOfClass:[aeroCADLoftedSurf class]])
                {
                    aeroCADLoftedSurf *pSurf = selectedObj;
                    [pSurf invertSurface];
                }
                [appDelegate setConsoleOutputText:@""];
            }
            break;
        case CMD_STATE_NONE:
		default:
            if (0.0f != gridSpacing)
            {
                // TODO - merge with the hitTest routine in aeroCADCurve
                //
                int i, j;
            
                // http://msdn.microsoft.com/en-us/library/ms969920.aspx
            
                // Determine which row and column grid lines we hit in order to move the cursor
                //
                for (i=0 ; i<(gridArrayp->points / 2) ; i+=2)
                {
                    POINT3D p1  = gridArrayp->pointlist[i];
                    POINT3D p2  = gridArrayp->pointlist[i+1];
                
                    VECTOR3D v1;
                    v1.dx = p2.pt.x - p1.pt.x;
                    v1.dy = p2.pt.y - p1.pt.y;
                    v1.dz = 0;
                
                    VECTOR3D v2;
                    v2.dx = mouseCursor.x - p1.pt.x;
                    v2.dy = mouseCursor.y - p1.pt.y;
                    v2.dz = 0;
                
                    CGFloat dist = vlGetLengthOfNormal(&v1, &v2);
                
                    if (dist >= (-1 * gridSpacing) && dist <= gridSpacing)
                    {
                        for (j=(gridArrayp->points / 2) ; j<gridArrayp->points ; j+=2)
                        {
                            POINT3D p1  = gridArrayp->pointlist[j];
                            POINT3D p2  = gridArrayp->pointlist[j+1];
                        
                            VECTOR3D v1;
                            v1.dx = p2.pt.x - p1.pt.x;
                            v1.dy = p2.pt.y - p1.pt.y;
                            v1.dz = 0;
                        
                            VECTOR3D v2;
                            v2.dx = mouseCursor.x - p1.pt.x;
                            v2.dy = mouseCursor.y - p1.pt.y;
                            v2.dz = 0;
                        
                            CGFloat dist = vlGetLengthOfNormal(&v1, &v2);
                        
                            if (dist >= (-1 * gridSpacing) && dist <= gridSpacing)
                            {
                                // Found both grid row and column matches, move the cursor to the intersection
                                //
                                switch (viewMode)
                                {
                                case XYPLANE:
                                    [self moveCursorAbs: gridArray->pointlist[j].pt.x: gridArray->pointlist[i].pt.y: 0.0f];
                                    [self setNeedsDisplay:YES];
                                    break;
                                case XZPLANE:
                                case ISOMETRIC:
                                    [self moveCursorAbs: gridArray->pointlist[j].pt.x: 0.0f :gridArray->pointlist[i].pt.z];
                                    [self setNeedsDisplay:YES];
                                    break;
                                case YZPLANE:
                                    [self moveCursorAbs: 0.0f: gridArray->pointlist[j].pt.y: gridArray->pointlist[i].pt.z];
                                    [self setNeedsDisplay:YES];
                                    break;
                                default:
                                    break;
                                }
                            }
                        }
                    }
                }
            }
			break;
	}
}


- (id)selectObject: (NSPoint)mouseCursor
{
	// Walk through the display list looking for a hit
	//
	id obj;
	NSEnumerator *enumerator = [_displayList objectEnumerator];
	while (obj = [enumerator nextObject])
	{
		// TODO - clean-up
        if ([obj isKindOfClass:[aeroCADLoftedSurf class]])
		{
			if ([(aeroCADLoftedSurf *)obj hitTest: mouseCursor] == YES)
			{
				[obj toggleSelected];
				[self setNeedsDisplay:YES];
				return obj;
			}
		}
		else if ([obj isKindOfClass:[aeroCADCurve class]])
		{
			if ([(aeroCADCurve *)obj hitTest: mouseCursor] == YES)
			{
				[obj toggleSelected];
				[self setNeedsDisplay:YES];
				return obj;
			}
		}

	}
	
	return NULL;
}

- (void)magnifyWithEvent:(NSEvent *)event 
{
	static CGFloat mag=1.0f;
	
    mag += [event magnification] / 100;
	NSLog (@"Magnification value is %f",mag);
	[primaryXform scale:mag];
	[self setNeedsDisplay:YES];
}

- (void)rotateWithEvent:(NSEvent *)event 
{
    CGFloat rot = [event rotation];
	NSLog (@"Rotation in degree is %f", rot);
	[primaryXform rotatex:(rot*RADIANS_PER_DEGREE)];
	[cursorXform  rotatex:(rot*RADIANS_PER_DEGREE)];
	[self setNeedsDisplay:YES];
}

- (void)swipeWithEvent:(NSEvent *)event 
{
    CGFloat dx = [event deltaX] * 10.0f;
    CGFloat dy = [event deltaY] * 10.0f;
	
	NSLog (@"Swipe dx=%f dy=%f", dx, dy);

	[primaryXform xlate:dx :dy :0.0f];
	[cursorXform  xlate:dx :dy :0.0f];	
    [self setNeedsDisplay:YES];
}

- (void) moveCursorRel:(CGFloat)dx :(CGFloat)dy :(CGFloat)dz
{
	int i;
	POINT3D *t = primaryCursor->pointlist;
	
	for (i=0 ; i<primaryCursor->points ; i++)
	{	
		t[i].pt.x += dx;
		t[i].pt.y += dy;
		t[i].pt.z += dz;
	}
	
    [self setNeedsDisplay:YES];	
}

- (void) moveCursorAbs:(CGFloat)x :(CGFloat)y :(CGFloat)z
{
	int i;
	POINT3D *t = primaryCursor->pointlist;
	
	for (i=0 ; i<primaryCursor->points ; i++)
	{	
		t[i].pt.x = x + cursorPoints[i].pt.x;
		t[i].pt.y = y + cursorPoints[i].pt.y;
		t[i].pt.z = z + cursorPoints[i].pt.z;
	}
	
    [self setNeedsDisplay:YES];	
}


- (BOOL) addToDisplayList: (id)obj
{	
	[_displayList addObject: obj]; 
	
	return YES;
}

- (BOOL) removeFromDisplayList: (id)obj
{
	[_displayList removeObject: obj];
	
	return YES;
}

- (BOOL) scaleSelectedObjects: (CGFloat)scale
{
  	id obj;
	NSEnumerator *enumerator;
    
    if (scale <= 0.0f)
        return NO;
    
	// Render display list elements
	//
	enumerator = [_displayList objectEnumerator];
	while (obj = [enumerator nextObject])
	{
		if ([obj isKindOfClass:[aeroCADCurve class]])
        {
            aeroCADCurve *c = obj;
            if (YES == [c isSelected])
            {
                [c xformCurve: 0.0f :0.0f :0.0f :scale :0.0f :0.0f :0.0f];
            }
        }
        // TODO
		//else if ([obj isKindOfClass:[aeroCADLoftedSurf class]])
		//	[(aeroCADLoftedSurf *)obj drawSelf: doShade];
	}
    
    [self setNeedsDisplay:YES];

    return YES;
}

- (BOOL) rotateSelectedObjects: (CGFloat)rotx :(CGFloat)roty :(CGFloat)rotz
{
    id obj;
	NSEnumerator *enumerator;
    
    if (rotx > 180.0f || roty > 180.0f || rotz > 180.0f)
        return NO;
    
	// Render display list elements
	//
	enumerator = [_displayList objectEnumerator];
	while (obj = [enumerator nextObject])
	{
		if ([obj isKindOfClass:[aeroCADCurve class]])
        {
            aeroCADCurve *c = obj;
            if (YES == [c isSelected])
            {
                [c xformCurve: 0.0f :0.0f :0.0f :1.0f :(rotx*RADIANS_PER_DEGREE) :(roty*RADIANS_PER_DEGREE) :(rotz*RADIANS_PER_DEGREE)];
            }
        }
        // TODO
		//else if ([obj isKindOfClass:[aeroCADLoftedSurf class]])
		//	[(aeroCADLoftedSurf *)obj drawSelf: doShade];
	}
    
    [self setNeedsDisplay:YES];

    return YES;
}

- (BOOL) translateSelectedObjects: (CGFloat)dx :(CGFloat)dy :(CGFloat)dz
{
    id obj;
	NSEnumerator *enumerator;
    
	// Render display list elements
	//
	enumerator = [_displayList objectEnumerator];
	while (obj = [enumerator nextObject])
	{
		if ([obj isKindOfClass:[aeroCADCurve class]])
        {
            aeroCADCurve *c = obj;
            if (YES == [c isSelected])
            {
                [c xformCurve: dx :dy :dz :1.0f :0.0f :0.0f :0.0f];
            }
        }
        // TODO
		//else if ([obj isKindOfClass:[aeroCADLoftedSurf class]])
		//	[(aeroCADLoftedSurf *)obj drawSelf: doShade];
	}
    
    [self setNeedsDisplay:YES];

    return YES;
}


- (void) renderDisplayList
{
	id obj;
	NSEnumerator *enumerator;

    
	// Render display list elements
	//
	enumerator = [_displayList objectEnumerator];
	while (obj = [enumerator nextObject])
	{
		if ([obj isKindOfClass:[aeroCADCurve class]])
			[(aeroCADCurve *)obj drawSelf];
		else if ([obj isKindOfClass:[aeroCADLoftedSurf class]])
			[(aeroCADLoftedSurf *)obj drawSelf: doShade];
	}

    // If we're shading, compute surface normals and depth-sort
	//
	if (YES == doShade || YES == showNormals)
	{
		enumerator = [_displayList objectEnumerator];
        
		while (obj = [enumerator nextObject])
		{
			if ([obj isKindOfClass:[aeroCADLoftedSurf class]])
			{
				[primaryShader computeNormals: obj];
				[primaryShader depthSort: obj];
			}
		}
	}
    
	// If we're showing surface normals, display for each surface
	//
	if (YES == showNormals)
	{
		enumerator = [_displayList objectEnumerator];
		
		while (obj = [enumerator nextObject])
		{
			if ([obj isKindOfClass:[aeroCADLoftedSurf class]])
			{
				[obj showNormals];
			}
		}
	}
}

- (POINT3D)getCursor
{
	POINT3D pt;
	
	pt.pt.x    = primaryCursor->pointlist[NUM_CURSOR_POINTS - 1].pt.x;
	pt.pt.y    = primaryCursor->pointlist[NUM_CURSOR_POINTS - 1].pt.y;
	pt.pt.z    = primaryCursor->pointlist[NUM_CURSOR_POINTS - 1].pt.z;
	pt.pt.rsvd = primaryCursor->pointlist[NUM_CURSOR_POINTS - 1].pt.rsvd;

	return pt;
}

- (void)drawCursor
{
	NSBezierPath *bp = [NSBezierPath bezierPath];

	[bp moveToPoint:NSMakePoint((CGFloat)g_ox+primaryCursorp->pointlist[0].pt.x, (CGFloat)g_oy+primaryCursorp->pointlist[0].pt.y)];
	[bp lineToPoint:NSMakePoint((CGFloat)g_ox+primaryCursorp->pointlist[1].pt.x, (CGFloat)g_oy+primaryCursorp->pointlist[1].pt.y)];
	[bp moveToPoint:NSMakePoint((CGFloat)g_ox+primaryCursorp->pointlist[2].pt.x, (CGFloat)g_oy+primaryCursorp->pointlist[2].pt.y)];
	[bp lineToPoint:NSMakePoint((CGFloat)g_ox+primaryCursorp->pointlist[3].pt.x, (CGFloat)g_oy+primaryCursorp->pointlist[3].pt.y)];
	[bp moveToPoint:NSMakePoint((CGFloat)g_ox+primaryCursorp->pointlist[4].pt.x, (CGFloat)g_oy+primaryCursorp->pointlist[4].pt.y)];
	[bp lineToPoint:NSMakePoint((CGFloat)g_ox+primaryCursorp->pointlist[5].pt.x, (CGFloat)g_oy+primaryCursorp->pointlist[5].pt.y)];
	
	[[NSColor magentaColor] set];
	[bp stroke];
}

- (void)drawCoord
{
	int index;
	NSBezierPath *bp = [NSBezierPath bezierPath];
	
	for (index=1; index<=3; index++)  
	{
		[bp moveToPoint:NSMakePoint((CGFloat)g_ox+primaryCoordp->pointlist[0].pt.x,     (CGFloat)g_oy+primaryCoordp->pointlist[0].pt.y)];
		[bp lineToPoint:NSMakePoint((CGFloat)g_ox+primaryCoordp->pointlist[index].pt.x, (CGFloat)g_oy+primaryCoordp->pointlist[index].pt.y)];
	}
    
	[[NSColor greenColor] set];
	[bp stroke];
	
	NSDictionary *attribDict = [NSDictionary dictionaryWithObjectsAndKeys: 
								[NSColor yellowColor], NSForegroundColorAttributeName, 
								[NSFont systemFontOfSize:12], NSFontAttributeName, NULL];
	[@"X" drawAtPoint: NSMakePoint((CGFloat)g_ox+primaryCoordp->pointlist[4].pt.x, (CGFloat)g_oy+primaryCoordp->pointlist[4].pt.y) withAttributes: attribDict];
	[@"Y" drawAtPoint: NSMakePoint((CGFloat)g_ox+primaryCoordp->pointlist[5].pt.x, (CGFloat)g_oy+primaryCoordp->pointlist[5].pt.y) withAttributes: attribDict];
	[@"Z" drawAtPoint: NSMakePoint((CGFloat)g_ox+primaryCoordp->pointlist[6].pt.x, (CGFloat)g_oy+primaryCoordp->pointlist[6].pt.y) withAttributes: attribDict];
}

- (void) drawGrid
{
    int i;
    
    NSColor *myStrokeColor = [NSColor colorWithDeviceWhite: (CGFloat)0.30f alpha: (CGFloat)1.0f];
    [myStrokeColor set];
    
    for (i=0 ; i<gridArray->points ; i+=2)
    {
        NSBezierPath *bp = [NSBezierPath bezierPath];
        
        [bp moveToPoint:NSMakePoint((CGFloat)g_ox+gridArrayp->pointlist[i].pt.x, (CGFloat)g_oy+gridArrayp->pointlist[i].pt.y)];
        [bp lineToPoint:NSMakePoint((CGFloat)g_ox+gridArrayp->pointlist[i+1].pt.x, (CGFloat)g_oy+gridArrayp->pointlist[i+1].pt.y)];
        
        [bp stroke];
        
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor blackColor] set];
    NSRectFill(dirtyRect);

	////////////////

	// Load the image.
	//NSImage *anImage = [NSImage imageNamed:@"B787_planform"];
		
	// Find the point at which to draw it.
	//NSPoint backgroundCenter;
	//backgroundCenter.x = [self bounds].size.width / 2;
	//backgroundCenter.y = [self bounds].size.height / 2;
		
	//NSPoint drawPoint = backgroundCenter;
	//drawPoint.x -= [anImage size].width / 2;
	//drawPoint.y -= [anImage size].height / 2;
		
	// Draw it.
	//[anImage drawAtPoint:drawPoint
	//			fromRect:NSZeroRect
	//		   operation:NSCompositeSourceOver
	//			fraction:0.5];

	////////////////
    
    // If we're displaying the grid and the view is one of the standard views (XY, YZ, XZ, or ISOMETRIC)
	// first check to see whether we have a point set for the grid array otherwise create it, then transform
    // the pointset and display
    if (gridSpacing != 0.0f && (XYPLANE == viewMode || XZPLANE == viewMode || YZPLANE == viewMode || ISOMETRIC == viewMode))
    {
        // If we haven't prepared the grid array point set yet, do it here.
        //
        if (NULL == gridArray)
        {
            // TODO: figure out out how to limit the grid array to only the lines that will be visible after clipping
            // TODO: also figure out how to keep the grid centered on the coordinate axis regardless of grid spacing
#define GRID_SIZE_LIMIT  400.0f  // width and height of the grid
            CGFloat gridSize = GRID_SIZE_LIMIT - fmodl(GRID_SIZE_LIMIT, gridSpacing);
            if (fmodl(gridSize, 2.0f) != 0.0f)
            {
                gridSize += gridSpacing;
            }
            
            CGFloat s, v;

            int i;
            int numGridLines  = (int)(gridSize / gridSpacing) + 1;
            
            // x2 (two end points per line) and x2 (s and v directions)
            //
            int numGridEndpoints = numGridLines * 2 * 2;
                        
            gridArray = malloc(sizeof(POINT_SET) + (sizeof(POINT3D) * numGridEndpoints));
            assert(NULL != gridArray);
            gridArrayp = malloc(sizeof(POINT_SET) + (sizeof(POINT3D) * numGridEndpoints));
            assert(NULL != gridArrayp);

            gridArray->points = numGridEndpoints;
            
            switch (viewMode)
            {
                case XYPLANE:
                    s = -1.0f * (gridSize / 2.0f);
                    v = -1.0f * (gridSize / 2.0f);
                    for (i=0 ; i<numGridLines ; i++, v+=gridSpacing)
                    {
                
                        // xy - rows
                        gridArray->pointlist[i * 2].pt.x        = s;
                        gridArray->pointlist[i * 2].pt.y        = v;
                        gridArray->pointlist[i * 2].pt.z        = 0.0f;
                        gridArray->pointlist[i * 2].pt.rsvd     = 1.0f;
                
                        gridArray->pointlist[i * 2 + 1].pt.x    = s + gridSize;
                        gridArray->pointlist[i * 2 + 1].pt.y    = v;
                        gridArray->pointlist[i * 2 + 1].pt.z    = 0.0f;
                        gridArray->pointlist[i * 2 + 1].pt.rsvd = 1.0f;
                    }
                    v = -1.0f * (gridSize / 2.0f);
                    for (; i<(numGridLines * 2) ; i++, s+=gridSpacing)
                    {
                        // xy - columns
                        gridArray->pointlist[i * 2].pt.x        = s;
                        gridArray->pointlist[i * 2].pt.y        = v;
                        gridArray->pointlist[i * 2].pt.z        = 0.0f;
                        gridArray->pointlist[i * 2].pt.rsvd     = 1.0f;

                        gridArray->pointlist[i * 2 + 1].pt.x    = s;
                        gridArray->pointlist[i * 2 + 1].pt.y    = v + gridSize;
                        gridArray->pointlist[i * 2 + 1].pt.z    = 0.0f;
                        gridArray->pointlist[i * 2 + 1].pt.rsvd = 1.0f;
                    }
                    break;
                case XZPLANE:
                case ISOMETRIC:
                    s = -1.0f * (gridSize / 2.0f);
                    v = -1.0f * (gridSize / 2.0f);
                    for (i=0 ; i<numGridLines ; i++, v+=gridSpacing)
                    {
                        
                        // xz - rows
                        gridArray->pointlist[i * 2].pt.x        = s;
                        gridArray->pointlist[i * 2].pt.y        = 0.0f;
                        gridArray->pointlist[i * 2].pt.z        = v;
                        gridArray->pointlist[i * 2].pt.rsvd     = 1.0f;
                        
                        gridArray->pointlist[i * 2 + 1].pt.x    = s + gridSize;
                        gridArray->pointlist[i * 2 + 1].pt.y    = 0.0f;
                        gridArray->pointlist[i * 2 + 1].pt.z    = v;
                        gridArray->pointlist[i * 2 + 1].pt.rsvd = 1.0f;
                    }
                    v = -1.0f * (gridSize / 2.0f);
                    for (; i<(numGridLines * 2) ; i++, s+=gridSpacing)
                    {
                        // xz - columns
                        gridArray->pointlist[i * 2].pt.x        = s;
                        gridArray->pointlist[i * 2].pt.y        = 0.0f;
                        gridArray->pointlist[i * 2].pt.z        = v;
                        gridArray->pointlist[i * 2].pt.rsvd     = 1.0f;
                        
                        gridArray->pointlist[i * 2 + 1].pt.x    = s;
                        gridArray->pointlist[i * 2 + 1].pt.y    = 0.0f;
                        gridArray->pointlist[i * 2 + 1].pt.z    = v + gridSize;
                        gridArray->pointlist[i * 2 + 1].pt.rsvd = 1.0f;
                    }
                    break;
                case YZPLANE:
                    s = -1.0f * (gridSize / 2.0f);
                    v = -1.0f * (gridSize / 2.0f);
                    for (i=0 ; i<numGridLines ; i++, v+=gridSpacing)
                    {
                        
                        // yz - rows
                        gridArray->pointlist[i * 2].pt.x        = 0.0f;
                        gridArray->pointlist[i * 2].pt.y        = s;
                        gridArray->pointlist[i * 2].pt.z        = v;
                        gridArray->pointlist[i * 2].pt.rsvd     = 1.0f;
                        
                        gridArray->pointlist[i * 2 + 1].pt.x    = 0.0f;
                        gridArray->pointlist[i * 2 + 1].pt.y    = s + gridSize;
                        gridArray->pointlist[i * 2 + 1].pt.z    = v;
                        gridArray->pointlist[i * 2 + 1].pt.rsvd = 1.0f;
                    }
                    v = -1.0f * (gridSize / 2.0f);
                    for (; i<(numGridLines * 2) ; i++, s+=gridSpacing)
                    {
                        // yz - columns
                        gridArray->pointlist[i * 2].pt.x        = 0.0f;
                        gridArray->pointlist[i * 2].pt.y        = s;
                        gridArray->pointlist[i * 2].pt.z        = v;
                        gridArray->pointlist[i * 2].pt.rsvd     = 1.0f;
                        
                        gridArray->pointlist[i * 2 + 1].pt.x    = 0.0f;
                        gridArray->pointlist[i * 2 + 1].pt.y    = s;
                        gridArray->pointlist[i * 2 + 1].pt.z    = v + gridSize;
                        gridArray->pointlist[i * 2 + 1].pt.rsvd = 1.0f;
                    }
                    break;
                default:
                    break;
            }
        }
        
        [primaryXform transform:YES :gridArray :gridArrayp];
        [self drawGrid];
    }
    
	[self renderDisplayList];
	
	[primaryXform transform:YES :primaryCoord :primaryCoordp];
	[self drawCoord];
		
	[cursorXform transform:YES :primaryCursor :primaryCursorp];
	[self drawCursor];
}

- (BOOL) setGridSpacing: (CGFloat)Spacing;
{
    
    if ((Spacing != 0.0f && Spacing < 1.0f) || Spacing > 100.0f)
        return FALSE;
    
    gridSpacing = Spacing;
    
    if (NULL != gridArray)
    {
        free(gridArray);
        gridArray = NULL;
    }
    if (NULL != gridArrayp)
    {
        free(gridArrayp);
        gridArrayp = NULL;
    }
    
    [self setNeedsDisplay:YES];

    return TRUE;
}

@end
