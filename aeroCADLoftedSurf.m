//
//  aeroCADLoftedSurf.m
//  aeroCAD
//
//  Created by Jeff Glaum on 8/5/10.
//  Copyright 2010 Jeff Glaum. All rights reserved.
//

#import "aeroCADLoftedSurf.h"
#import "aeroCADCurve.h"
#import "aeroCADView.h"
#import "aeroCADXform.h"
#import "aeroCADTypes.h"
#import "aeroCADPointVector3D.h"

extern int g_ox, g_oy;


@implementation aeroCADLoftedSurf
@synthesize _shadeTriangles, _triangleCount;


- (id)   init
{
	return self;
}

- (void) setDirection:(VECTOR3D)dir
{
	memcpy(&_direction, &dir, sizeof(VECTOR3D));
}

- (BOOL) setColor:(NSColor *)color
{
	BOOL rc = YES;
	int i;
	
	for (i=0 ; i<_curveCount ; i++)
		[_curves[i] setColor: color];
	
	return rc;	
}

- (BOOL) addCurve:(aeroCADCurve *)curve
{
	BOOL rc = YES;
	
	if (NULL == _curves)
	{
		_curves = (aeroCADCurve **)malloc(sizeof(aeroCADCurve *));
		_curves[0] = [curve copySelf];
		_curveCount = 1;
	}
	else 
	{
		void *t = (void *)malloc(sizeof(aeroCADCurve *) * _curveCount+1);
		memcpy(t, (void *)_curves, sizeof(aeroCADCurve *) * _curveCount);
		free(_curves);
		_curves = (aeroCADCurve **)t;
		_curves[_curveCount] = [curve copySelf];
		_curveCount++;
	}

	return rc;
}

// Done creating the surface - compute derived information for later use.
- (BOOL) finishEditing
{
	BOOL rc = YES;
	int i, j, count;
	
    // TODO - test
	_curveSampleStep    = 0.005f;
	_curveWireStep		= 0.05f;	// Must be integer multiple of curve sampling step.
	_curveShadeStep		= 0.01f;	// Must be integer multiple of curve sampling step.
    
	// Compute number of sample points
	_curveSampleCount   = (1.0f / _curveSampleStep) + 1;
	_curveWireCount     = (1.0f / _curveWireStep)   + 1;
	_curveShadeCount    = (1.0f / _curveShadeStep)  + 1;
	
	// Sample the raw curve data and construct new curves for all drawing operations.
	_curveSamples = (aeroCADCurve **)malloc(_curveCount * sizeof(aeroCADCurve*));
	for (i=0 ; i<_curveCount ; i++)
		_curveSamples[i] = [_curves[i] copySelfParam:_curveSampleStep];
	
	// Must have multiple curves in order to compute shading triangles.
	if (_curveCount <= 1)
		goto Done;
	
	// Build shading triangles.
	int stride = (_curveShadeStep / _curveSampleStep);
	_triangleCount  = (_curveCount - 1) * ((_curveShadeCount - 1) * 2); 
	_shadeTriangles = (TRIANGLE *)malloc(_triangleCount * sizeof(TRIANGLE));
	memset(_shadeTriangles, 0, _triangleCount * sizeof(TRIANGLE));
	for (i=1, count=0 ; i<_curveCount ; i++)
	{
		for (j=0 ; j<(_curveSampleCount-stride); j+=stride)
		{
			// Split each 4-point rectangle into two triangles.
			// TODO - how to handle surfaces that grow in various directions.
			if (_direction.dz > 0)
			{
				// Grows in positive direction.
				_shadeTriangles[count].id = count;
				_shadeTriangles[count].v1 = &_curveSamples[i-1]._listp[j];
				_shadeTriangles[count].v2 = &_curveSamples[i-1]._listp[j+stride];
				_shadeTriangles[count].v3 = &_curveSamples[i]._listp[j];
				count++;
			
				_shadeTriangles[count].id = count;
				_shadeTriangles[count].v1 = &_curveSamples[i]._listp[j+stride];
				_shadeTriangles[count].v2 = &_curveSamples[i]._listp[j];
				_shadeTriangles[count].v3 = &_curveSamples[i-1]._listp[j+stride];	
				count++;
			}
			else
			{
				// Grows in negative direction.
				_shadeTriangles[count].id = count;
				_shadeTriangles[count].v1 = &_curveSamples[i-1]._listp[j];
				_shadeTriangles[count].v3 = &_curveSamples[i-1]._listp[j+stride];
				_shadeTriangles[count].v2 = &_curveSamples[i]._listp[j];
				count++;
				
				_shadeTriangles[count].id = count;
				_shadeTriangles[count].v1 = &_curveSamples[i]._listp[j+stride];
				_shadeTriangles[count].v3 = &_curveSamples[i]._listp[j];
				_shadeTriangles[count].v2 = &_curveSamples[i-1]._listp[j+stride];	
				count++;				
			}
		}
	}

Done:
	return rc;
}

- (void) showNormals
{
	int i;
	NSBezierPath *bp = [NSBezierPath bezierPath];

    // TODO - test
	for (i=0 ; i<_triangleCount ; i++)
	{
		// Draw normal vectors.
		[bp moveToPoint:NSMakePoint((CGFloat)g_ox+_shadeTriangles[i].v1->pt.x, (CGFloat)g_oy+_shadeTriangles[i].v1->pt.y)];
		[bp lineToPoint:NSMakePoint((CGFloat)g_ox+_shadeTriangles[i].v1->pt.x+_shadeTriangles[i].nx*20.0f, (CGFloat)g_oy+_shadeTriangles[i].v1->pt.y+_shadeTriangles[i].ny*20.0f)];
	}
	[[NSColor yellowColor] set];
	[bp stroke];	
}

- (BOOL) drawSelf:(BOOL)fShade
{
	BOOL rc = YES;
	int i, j;
	NSColor *color;
	
	// If the surface is selected, use a special color
	if (_selected == YES)
		color = [NSColor magentaColor];
	else
		color = [NSColor grayColor];

	// TODO - need to draw the parameterized curves in order to apply the transform - better way?
	for (i=0 ; i<_curveCount ; i++)
		[_curveSamples[i] drawSelf: color];
		
	// draw curve-connecting lines - wireframe
	if (YES == fShade)
	{
		// Draw triangles
		for (i=0 ; i<_triangleCount ; i++)
		{
			NSBezierPath *bp = [NSBezierPath bezierPath];

			// Cull any triangles which aren't visible to the eye (based on angle).
			// TODO - better way?
			if (fabs(_shadeTriangles[i].eyeang) > PI/2)
				continue;
			
			[bp moveToPoint:NSMakePoint((CGFloat)g_ox+_shadeTriangles[i].v1->pt.x, (CGFloat)g_oy+_shadeTriangles[i].v1->pt.y)];
			[bp lineToPoint:NSMakePoint((CGFloat)g_ox+_shadeTriangles[i].v2->pt.x, (CGFloat)g_oy+_shadeTriangles[i].v2->pt.y)];
			[bp lineToPoint:NSMakePoint((CGFloat)g_ox+_shadeTriangles[i].v3->pt.x, (CGFloat)g_oy+_shadeTriangles[i].v3->pt.y)];
			[bp closePath];
			
			CGFloat shadeColor = (1.0f - (fabs(_shadeTriangles[i].lightang) / PI));
			
            NSColor *myStrokeColor = [NSColor colorWithDeviceWhite: (CGFloat)shadeColor alpha: (CGFloat)1.0f];
			[myStrokeColor set];
			[bp stroke];
            // TODO - debugging
            //NSColor *myFillColor = [NSColor colorWithDeviceWhite: (CGFloat)0.0f alpha: (CGFloat)1.0f];
            NSColor *myFillColor = [NSColor colorWithDeviceWhite: (CGFloat)shadeColor alpha: (CGFloat)1.0f];
			[myFillColor set];
			[bp fill];
		}
	}
	else
	{
		int stride = (_curveWireStep / _curveSampleStep);

		for (i=0 ; i<_curveSampleCount ; i+=stride)
		{
			NSBezierPath *bp = [NSBezierPath bezierPath];

			[bp moveToPoint:NSMakePoint((CGFloat)g_ox+[_curveSamples[0] _listp][i].pt.x, (CGFloat)g_oy+[_curveSamples[0] _listp][i].pt.y)];

			for (j=1 ; j<_curveCount ; j++)
				[bp lineToPoint:NSMakePoint((CGFloat)g_ox+[_curveSamples[j] _listp][i].pt.x, (CGFloat)g_oy+[_curveSamples[j] _listp][i].pt.y)];

			[color set];
			[bp stroke];
		}
	}
	
	return rc;	
}

- (aeroCADLoftedSurf *) copySelf
{
	return NULL;
}

- (BOOL) hitTest:(NSPoint) pt
{
	int i;
	
	// TODO - check more than just surface curves for hit?
	for (i=0 ; i<_curveCount ; i++)
	{
		if ([_curves[i] hitTest: pt] == YES)
		{
			return YES;
		}
	}
	 
	return NO;
}

- (BOOL) loftSurface: (aeroCADCurve *) profc1 :(aeroCADCurve *) profc2 :(aeroCADCurve *) drivec
{
	
	// TODO
	VECTOR3D dir = {0.0f, 0.0f, +1.0f};					
	[self setDirection:dir];
	
	// I.   Make parameterized copies of pc1 and pc2
	// TODO - select parameterization based on degree of profile line change (ideally it's be dynamic - less
    //        in simpler parts of curve).
	aeroCADCurve *profc1_param = [profc1 copySelfParam:0.05f];
	aeroCADCurve *profc2_param = [profc2 copySelfParam:0.05f];
		
	// II.  Compute width of (closed) drive curve along the x-axis.
    //
    // NOTE: The drive curve is expected to lie in the XY plane.
    //       The drive curve is expected to start at a *positive* normalized point with an angle of 0
    //       degrees and the pointset proceeds in a counter-clockwise fashion to some final angle (possibly
    //       back to the start).
    //
	CGFloat width = [drivec getMaxX] - [drivec getMinX];
	
	// III. Step through each pair of parametric points on both profile curves (pc1 and pc2) and:
	//		1.  Compute distance between pc1 and pc2
    //      2.  Compute the normalized vector between pc1 and pc2 (Vx)
    //      3.  Compute the tangent vector at pc1 (Vtan)
    //      4.  Compute the cross product between Vtan and Vx (Vy)
    //      5.  Compute the cross product between Vx and Vy (Vz)
    //      6.  The three vectors Vx, Vy, and Vz represent a new coordinate system and can be transferred
    //          to a 3x3 rotation matrix representing a rotation from the world coordinate system to this new one
    //      7.  From the rotation matrix, compute the Euler Angles representing the axis rotations between the two
	//		8.  Make a copy of the drive curve
	//		9.  Create transform:
	//			a.  Scale factor to match distance between pc1 and pc2 nodes
	//			b.  Rotation in X, Y, and Z to match direction vector between pc1 and pc2 nodes
	//			c.  Translation in X, Y, and Z to match the appropriate node (pc1 or pc2)
	//		10.  Apply transform to drive curve copy then toss transform
	//		11.  Insert drive curve copy into surface list
    //
    // NOTE: The profile curves must start and point in the same direction.
    //
	POINT3D p1, p2;
	[profc1_param getFirstParametricPoint: &p1];
	[profc2_param getFirstParametricPoint: &p2];
	
    VECTOR3D Vtan;
    CGFloat dist, scale;
    CGFloat theta, phi, psi, temp;
    
    PointVector3D *pVx =   [[PointVector3D alloc] init];
    PointVector3D *pVtan = [[PointVector3D alloc] init];
    PointVector3D *pVy =   [[PointVector3D alloc] init];
    PointVector3D *pVz =   [[PointVector3D alloc] init];

	do
	{
        // Compute non-normalized Vx
        //
        [pVx initWithParam: (p2.pt.x - p1.pt.x) : (p2.pt.y - p1.pt.y) : (p2.pt.z - p1.pt.z) : 0.0f];
		
        // Compute the distance between the two curve's parametric points and determine
        // how much the drive curve needs to be scaled in order to pass through both points.
        //
        dist  = [pVx ptvGetLength];
        scale = (dist / width);
		
        // Normalize Vx
        //
        [pVx ptvNormalize];
        
        // TODO - Should compute the actual tangent of profile curve 1 but for now, assume
        // the profile curve is a straight line
        //
        [profc1_param getParametricTangent: &Vtan];
        [pVtan initWithParam: Vtan.dx : Vtan.dy : Vtan.dz : 0.0f];
        [pVtan ptvNormalize];
        
        // Compute the cross product of Vtan and Vx (Vy)
        //
        [pVtan ptvCrossProduct: pVx : pVy];
        
        // Compute the cross product between Vx and Vy (Vz)
        //
        [pVx ptvCrossProduct: pVy : pVz];
        
        // Rotation vector looks like this:
        //
        //     [ R11  R12  R13]   [ pVx->_x  pVy->_x  pVz->_x]
        // R = [ R21  R22  R23] = [ pVx->_y  pVy->_y  pVz->_y]
        //     [ R31  R32  R33]   [ pVx->_z  pVy->_z  pVz->_z]
        //
        // Computing Euler Angles (note there are two solutions hence the subscripts 1 and 2)
        //
        // if (R31 != ±1)
        //      θ1 = −asin(R31)
        //      θ2 =π−θ1
        //      ψ1 =atan2(R32/cos θ1 , R33/cos θ1)
        //      ψ2 =atan2(R32/cos θ2 , R33/cos θ2)
        //      φ1 =atan2(R21/cos θ1 , R11/cos θ1)
        //      φ2 =atan2(R21/cos θ2 , R11/cos θ2)
        // else
        //      φ = anything; can set to 0
        //      if (R31 = −1)
        //          θ = π/2
        //          ψ = φ + atan2(R12, R13)
        //      else
        //          θ = −π/2
        //          ψ = −φ + atan2(−R12, −R13)
        //      end if
        // end if
        //

        theta = phi = psi = 0.0f;
        
        if (-1.0f != [pVx ptvGetZ] && 1.0f != [pVx ptvGetZ])
        {
            theta = -1 * asinl([pVx ptvGetZ]);
            temp  = cosl(theta);
            psi   = atan2l([pVy ptvGetZ]/temp, [pVz ptvGetZ]/temp);
            phi   = atan2l([pVx ptvGetY]/temp, [pVx ptvGetX]/temp);
        }
        else
        {
            phi   = 0.0f;
            if (-1.0f == [pVx ptvGetZ])
            {
                theta = HALF_PI;
                psi   = phi + atan2l([pVy ptvGetX], [pVz ptvGetX]);
            }
            else
            {
                theta = -1 * HALF_PI;
                psi   = -1 * phi + atan2l(-1 * [pVy ptvGetX], -1 * [pVz ptvGetX]);
            }
        }

        // TODO - not sure this is right but choose the profile curve parametric point (on p1 and p2) that is
        // closest to the origin for the translation calculation
        CGFloat distp1 = sqrt(pow(p1.pt.x, 2) + pow(p1.pt.y, 2) + pow(p1.pt.z, 2));
        CGFloat distp2 = sqrt(pow(p2.pt.x, 2) + pow(p2.pt.y, 2) + pow(p2.pt.z, 2));
        POINT3D *translatePoint = {distp1 <= distp2 ? &p1 : &p2};
        
        // Duplicate the drive curve and transform the copy to fit/align
        //
        aeroCADCurve *tempc = [drivec copySelf];
        [tempc setColor:[NSColor grayColor]];
        [tempc xformCurve: *translatePoint :scale :psi :theta :phi];
        [self addCurve:tempc];

	} while ([profc1_param getNextParametricPoint: &p1] == YES && [profc2_param getNextParametricPoint: &p2] == YES);
	
	[self finishEditing];
	[self setColor:[NSColor grayColor]];				
    
    // Clean-up
    //
    [pVx release];
    [pVtan release];
    [pVy release];
    [pVz release];
	[profc1_param release];
	[profc2_param release];
	
	return YES;
}


- (BOOL) invertSurface
{
	int i;
    aeroCADCurve *pTempCurve;

    // Deselect the surface
    //
    if (YES == [self isSelected])
        [self toggleSelected];
    
    // Clean-up previously computed values...
    //
    for (i=0 ; i<_curveCount ; i++)
		[_curveSamples[i] release];

    free(_curveSamples);
    free (_shadeTriangles);
    
	// TODO - check more than just surface curves for hit?
	for (i=0 ; i<(_curveCount / 2) ; i++)
	{
        pTempCurve = _curves[i];
		_curves[i] = _curves[_curveCount - 1 - i];
        _curves[_curveCount - 1 - i] = pTempCurve;
	}
    
    [self finishEditing];

	return YES;
}


- (BOOL) toggleSelected
{
	BOOL old = _selected;
	
	if (_selected == NO)
		_selected = YES;
	else
		_selected = NO;
	
	return old;
}

- (BOOL) isSelected
{
	return _selected;
}

@end
