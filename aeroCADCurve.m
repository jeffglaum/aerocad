//
//  aeroCADCurve.m
//  aeroCAD
//
//  Created by Jeff Glaum on 7/30/10.
//  Copyright 2010 Jeff Glaum. All rights reserved.
//
#import "aeroCADCurve.h"
#import "aeroCADView.h"

extern int g_ox, g_oy;

@implementation aeroCADCurve

@synthesize _listp;

- (CGFloat) curveLength
{
	int i;
	CGFloat length=0.0f;
	
	// TODO - handle bezier.
	for(i=1 ; i<_count ; i++)
	{
		length += sqrt(pow((_list[i].pt.x - _list[i-1].pt.x), 2) + pow((_list[i].pt.y - _list[i-1].pt.y), 2) + pow((_list[i].pt.z - _list[i-1].pt.z), 2));
	}
	
	return length;
}

- (id)   init:(CURVE_TYPE)type
{
	return [self initWithParam: type :NULL :0];
}

- (id)   initWithParam:(CURVE_TYPE)type :(POINT3D *)list :(int)count
{
	aeroCADView *myview = [[[[NSApp mainWindow] contentView] subviews] objectAtIndex:0];

	if (NULL != list)
	{
		_list  = (POINT3D *)malloc(count * sizeof(POINT3D));
		memcpy(_list, list, count * sizeof(POINT3D));
		_listp = (POINT3D *)malloc(count * sizeof(POINT3D));		
		_length = [self curveLength];
	}
	_count		= count;
	_type		= type;
	_selected	= NO;
	_xform		= [myview primaryXform];
	_color		= [NSColor whiteColor];
	_paramindex = 0;
	return self;
}

- (BOOL) bindXform:(aeroCADXform *)xform
{
	BOOL rc = YES;
	_xform  = xform;
	return rc;
}

- (BOOL) setColor:(NSColor *)color
{
	BOOL rc = YES;
	_color  = color;
	return rc;	
}

- (BOOL) drawSelf
{
	NSColor *color = _color;
	
	if (_selected == YES)
		color = [NSColor magentaColor];
	
	return [self drawSelf: color];
}

- (BOOL) drawSelf: (NSColor *)color
{
	BOOL rc = YES;
	int index;
	

	if (NULL == _listp)
		return rc;
	
	if (NULL != _xform)
		[_xform transform:YES :_list :_listp :_count];
	else
		memcpy(_listp, _list, _count * sizeof(POINT3D));
	
	NSBezierPath *bp = [NSBezierPath bezierPath];
	[bp moveToPoint:NSMakePoint((CGFloat)g_ox+_listp[0].pt.x, (CGFloat)g_oy+_listp[0].pt.y)];

	switch (_type)
	{
	case CURVE_TYPE_BEZIER:
		for (index=1; index<_count; index+=3)  
		{
			[bp curveToPoint:NSMakePoint((CGFloat)g_ox+_listp[index+2].pt.x, (CGFloat)g_oy+_listp[index+2].pt.y) 
			   controlPoint1:NSMakePoint((CGFloat)g_ox+_listp[index].pt.x,   (CGFloat)g_oy+_listp[index].pt.y)
			   controlPoint2:NSMakePoint((CGFloat)g_ox+_listp[index+1].pt.x, (CGFloat)g_oy+_listp[index+1].pt.y)];
		}					
		break;	
	case CURVE_TYPE_LINE:
	default:
		for (index=1; index<_count; index++)  
		{
			[bp lineToPoint:NSMakePoint((CGFloat)g_ox+_listp[index].pt.x, (CGFloat)g_oy+_listp[index].pt.y)];
		}			
	}

	[color set];
	[bp stroke];
	
	return rc;
}

- (BOOL) setStartPoint:(POINT3D)startpt
{
	BOOL rc = YES;
	
	if (NULL != _listp) 
	{
		free(_listp);
	}
	if (NULL != _list) 
	{
		free(_list);
	}
	
	_list  = (POINT3D*)malloc(sizeof(POINT3D));
	_listp = (POINT3D*)malloc(sizeof(POINT3D));
	memcpy(_list, &startpt, sizeof(POINT3D));
	_count = 1;
	_length = 0.0f;
	return rc;
}

- (BOOL) appendSegment:(POINT3D)endpt
{
	BOOL rc = NO;
	
	if (_type != CURVE_TYPE_LINE)
	{
		return rc;
	}
	
	if (NULL != _list && NULL != _listp)
	{
		memcpy(_listp, _list, _count * sizeof(POINT3D));
		free(_list);
	}
	
	_list = (POINT3D *)malloc(sizeof(POINT3D) * (_count + 1));
	
	if (NULL != _listp) 
	{
		memcpy(_list, _listp, _count * sizeof(POINT3D));
		free(_listp);
	}

	_listp = (POINT3D *)malloc(sizeof(POINT3D) * (_count + 1));
	_count += 1;

	memcpy(&_list[_count-1], &endpt, sizeof(POINT3D));
	_length = [self curveLength];

	rc = YES;
	
	return rc;
}

- (BOOL) appendSegment:(POINT3D)ctl1pt :(POINT3D)ctl2pt :(POINT3D)endpt
{
	BOOL rc = NO;

	if (_type != CURVE_TYPE_BEZIER)
	{
		return rc;
	}
	
	if (NULL != _list && NULL != _listp)
	{
		memcpy(_listp, _list, _count * sizeof(POINT3D));
		free(_list);
	}
	
	_list = (POINT3D *)malloc(sizeof(POINT3D) * (_count + 3));
	
	if (NULL != _listp) 
	{
		memcpy(_list, _listp, _count * sizeof(POINT3D));
		free(_listp);
	}
	
	_listp = (POINT3D *)malloc(sizeof(POINT3D) * (_count + 3));
	_count += 3;
	
	memcpy(&_list[_count-3], &ctl1pt, sizeof(POINT3D));
	memcpy(&_list[_count-2], &ctl2pt, sizeof(POINT3D));
	memcpy(&_list[_count-1], &endpt, sizeof(POINT3D));
	_length = [self curveLength];

	rc = YES;
	
	return rc;
}

- (aeroCADCurve *) copySelf
{
	aeroCADCurve *t = [aeroCADCurve alloc];

    t->_type       = _type;
    t->_selected   = _selected;
    t->_length     = _length;
    t->_count      = _count;
    t->_paramindex = _paramindex;
    
    // TODO!!!  Need to copy the original color?
    t->_color      = [NSColor whiteColor];
    
    // TODO !!!  Need to copy the original transform?
    t->_xform      = _xform;
	
	if (NULL != _list)
	{
		t->_list = (POINT3D *)malloc(_count * sizeof(POINT3D));
		memcpy(t->_list, _list, _count * sizeof(POINT3D));
	}

    if (NULL != _listp)
	{
		t->_listp = (POINT3D *)malloc(_count * sizeof(POINT3D));
		memcpy(t->_listp, _listp, _count * sizeof(POINT3D));
	}

	return t;
}


// Initial AlmostEqualULPs version - fast and simple, but some limitations.
BOOL AlmostEqualUlps(CGFloat A, CGFloat B, int maxUlps)
{
	// TODO
    assert(sizeof(CGFloat) == sizeof(int64_t));
    if (A == B)
        return YES;
    int intDiff = abs(*(int*)&A - *(int*)&B);
    if (intDiff <= maxUlps)
        return YES;
    return NO;
}

// NOTE: type changes to line - okay?
- (aeroCADCurve *) copySelfParam:(CGFloat)t
{
	int i, limit;
    CGFloat step;
    
    // Check that t is less that one (parametric step value)
    //
    // TODO - need to handle the fact that t maybe be ~about 1.0f
    if (t >= 1.00001f)
    {
        // TODO
        return NULL;
    }
    
	aeroCADCurve *curve = [[aeroCADCurve alloc] init: CURVE_TYPE_LINE];
	
	curve->_xform    = self->_xform;
	curve->_color    = self->_color;
	curve->_selected = NO;

	[curve setStartPoint: [self curveParametric: 0.0f]];
	
	// TODO - 1.00001f chosen because t has low-order non-zero values that causes limit to be rounded down.
	step  = t;
    limit = (1.000001f / t);
	for (i=0 ;  i<limit ; i++, step += t)
	{
		[curve appendSegment: [self curveParametric: step]];
	}
	
	return curve;	
}

- (void)xformCurve:(CGFloat)dx :(CGFloat)dy :(CGFloat)dz :(CGFloat)scale :(CGFloat)rotx :(CGFloat)roty :(CGFloat)rotz
{
	aeroCADXform *tempXform = [[aeroCADXform alloc] initWithParams:scale :rotx :roty :rotz];

	[tempXform xlate:dx :dy :dz];
	[tempXform transform: NO: _list :_listp :_count];
	memcpy(_list, _listp, _count*sizeof(POINT3D));

	// Recompute curve length since we might have scaled.
	_length = [self curveLength];

	[tempXform release];
}

- (void )xformCurve:(POINT3D)point :(CGFloat)scale :(CGFloat)rotx :(CGFloat)roty :(CGFloat)rotz
{
    [self xformCurve: point.pt.x: point.pt.y: point.pt.z: scale: rotx: roty: rotz];
}

// 0 <= t <= 1.0
- (POINT3D) curveParametric:(CGFloat)t
{
	int i;
	POINT3D pt = {0.0f, 0.0f, 0.0f, 1.0f};
	CGFloat matchlen = (_length * t);
	
    // TODO - need to handle the fact that t maybe be ~about 1.0f
	if (_count <= 1 || t > 1.00001f)
		return pt;
	
	// If parameter is 0, return first point in the list
	if (AlmostEqualUlps(t, 0.0f, 1000) == YES)
	{
		pt.pt.x = _list[0].pt.x;
		pt.pt.y = _list[0].pt.y;
		pt.pt.z = _list[0].pt.z;
		return pt;
	}
	
	// TODO - handle bezier.
	for(i=1 ; i<_count ; i++)
	{
		CGFloat temp = sqrt(pow((_list[i].pt.x - _list[i-1].pt.x), 2) + pow((_list[i].pt.y - _list[i-1].pt.y), 2) + pow((_list[i].pt.z - _list[i-1].pt.z), 2));

		if (AlmostEqualUlps(matchlen, 0.0f, 1000) == YES || AlmostEqualUlps(matchlen, temp, 1000) == YES)
		{
			pt.pt.x = _list[i].pt.x;
			pt.pt.y = _list[i].pt.y;
			pt.pt.z = _list[i].pt.z;
			break;
		}
		else if (matchlen > temp)
		{
			matchlen -= temp;
		}
		else
		{
			pt.pt.x = _list[i-1].pt.x + ((_list[i].pt.x - _list[i-1].pt.x) * (matchlen / temp));
			pt.pt.y = _list[i-1].pt.y + ((_list[i].pt.y - _list[i-1].pt.y) * (matchlen / temp));
			pt.pt.z = _list[i-1].pt.z + ((_list[i].pt.z - _list[i-1].pt.z) * (matchlen / temp));
			break;			
		}
	}
	
	// TODO - round-off error on last points.
	if (i>=_count && matchlen < 0.0001f)
	{
		pt.pt.x = _list[i-1].pt.x;
		pt.pt.y = _list[i-1].pt.y;
		pt.pt.z = _list[i-1].pt.z;		
	}
	
	return pt;
}

// TODO
CGFloat vDotProduct(VECTOR3D *v0, VECTOR3D *v1)
{
	CGFloat dotprod;
	
	dotprod = (v0 == NULL || v1 == NULL) 
	? 0.0f
	: (v0->dx * v1->dx) + (v0->dy * v1->dy);
	
	return(dotprod);
}

VECTOR3D *vSubtractVectors(VECTOR3D *v0, VECTOR3D *v1, VECTOR3D *v)
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

CGFloat vVectorMagnitude(VECTOR3D *v0)
{
	CGFloat dMagnitude;
	
	if (v0 == NULL)
		dMagnitude = 0.0f;
	else
		//dMagnitude = sqrt(vVectorSquared(v0));
		dMagnitude = (CGFloat)sqrt(v0->dx*v0->dx + v0->dy*v0->dy);
	
	return (dMagnitude);
}

CGFloat vGetLengthOfNormal(VECTOR3D *a, VECTOR3D *b)
{
	VECTOR3D c, vNormal;
	//
	//Obtain projection vector.
	//
	//c = ((a * b)/(|b|^2))*b
	//
	c.dx = b->dx * (vDotProduct(a, b)/vDotProduct(b, b));
	c.dy = b->dy * (vDotProduct(a, b)/vDotProduct(b, b));
	//
	//Obtain perpendicular projection : e = a - c
	//
	vSubtractVectors(a, &c, &vNormal);
	//
	//Fill PROJECTION structure with appropriate values.
	//
	return (vVectorMagnitude(&vNormal));
}


- (BOOL) hitTest:(NSPoint) pt
{
	int i;
	
	// http://msdn.microsoft.com/en-us/library/ms969920.aspx
	
	for (i=0 ; i<(self->_count - 1) ; i++)
	{
		POINT3D p1  = self->_listp[i];
		POINT3D p2  = self->_listp[i+1];
        
		VECTOR3D v1;
		v1.dx = p2.pt.x - p1.pt.x;
		v1.dy = p2.pt.y - p1.pt.y;
		v1.dz = 0;
        
		VECTOR3D v2;
		v2.dx = pt.x - p1.pt.x;
		v2.dy = pt.y - p1.pt.y;
		v2.dz = 0;
        
        // TODO: If the length of the mouse click-point vector is longer than the
        // line segment vector than a projection won't make sense and it's not a hit
        //
        if (vVectorMagnitude(&v2) > vVectorMagnitude(&v1))
            return NO;
        
		CGFloat dist = vGetLengthOfNormal(&v1, &v2);
        
		if (dist >= -8.0f && dist <= 8.0f)
		{
			return YES;
		}
	}
	
	return NO;
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

- (CGFloat) getMinX
{
	int i;
	CGFloat ret = 0;
	
	for (i=0, ret=self->_list[i].pt.x ; i<(self->_count - 1) ; i++)
	{
		if (self->_list[i].pt.x < ret)
			ret = self->_list[i].pt.x;
	}
	
	return ret;
}

- (CGFloat) getMaxX
{
	int i;
	CGFloat ret = 0;
	
	for (i=0, ret=self->_list[i].pt.x ; i<(self->_count - 1) ; i++)
	{
		if (self->_list[i].pt.x > ret)
			ret = self->_list[i].pt.x;
	}
	
	return ret;
}

- (BOOL) getFirstParametricPoint: (POINT3D *)pt
{
	_paramindex = 0;

	if (_count == 0 || pt == NULL)
		return NO;
	
	pt->pt.x    = _list[_paramindex].pt.x;
	pt->pt.y    = _list[_paramindex].pt.y;
	pt->pt.z    = _list[_paramindex].pt.z;
	pt->pt.rsvd = _list[_paramindex].pt.rsvd;
	
	return YES;
}

- (BOOL) getNextParametricPoint: (POINT3D *)pt
{
	_paramindex++;
	
	if (0 == _count || NULL == pt || _paramindex > (_count - 1))
		return NO;
	
	pt->pt.x    = _list[_paramindex].pt.x;
	pt->pt.y    = _list[_paramindex].pt.y;
	pt->pt.z    = _list[_paramindex].pt.z;
	pt->pt.rsvd = _list[_paramindex].pt.rsvd;
	
	return YES;
}

- (BOOL) getParametricTangent: (VECTOR3D *)v;
{
    CGFloat dist;
    
    // TODO - compute the tangent at parametric point _paramindex.
    //        For now assume it's a straight line.
    
    v->dx = _list[_count-1].pt.x - _list[0].pt.x;
    v->dy = _list[_count-1].pt.y - _list[0].pt.y;
    v->dz = _list[_count-1].pt.z - _list[0].pt.z;

    dist = sqrt(pow(v->dx, 2) + pow(v->dy, 2) + pow(v->dz, 2));
    v->dx /= dist;
    v->dy /= dist;
    v->dz /= dist;
    
    return YES;
}

- (BOOL) invertSelf
{
    int i, j;
    
    if (_count <= 1)
        return NO;
    
    for (i=(_count-1), j=0 ; i >= 0 ; i--, j++)
    {
        _listp[j] = _list[i];
    }
    memcpy(_list, _listp, _count*sizeof(POINT3D));
    
    return YES;
}

@end