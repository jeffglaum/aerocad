//
//  aeroCADPointVector3D.m
//  aeroCAD
//
//  Created by Jeff Glaum on 1/10/11.
//  Copyright 2011 Jeff Glaum. All rights reserved.
//

#import "aeroCADPointVector3D.h"


@implementation PointVector3D

- (id) init
{
	_x = _y = _z = _w = 0.0f;
	return self;
}

- (id) initWithParam: (PointVector3D *)ptv
{
	_x = ptv->_x;
	_y = ptv->_y;
	_z = ptv->_z;
	_w = ptv->_w;
	return self;
}

- (id) initWithParam: (CGFloat)x :(CGFloat)y :(CGFloat)z :(CGFloat)w
{
	_x = x;
	_y = y;
	_z = z;
	_w = w;
	return self;
}

-(CGFloat) ptvGetX
{
    return _x;
}

-(CGFloat) ptvGetY
{
    return _y;
}

-(CGFloat) ptvGetZ
{
    return _z;
}

-(CGFloat) ptvGetLength
{
    return sqrt(pow(_x, 2) + pow(_y, 2) + pow(_z, 2) + pow(_w, 2));
}

-(void) ptvNormalize
{
	CGFloat length = sqrt(pow(_x, 2) + pow(_y, 2) + pow(_z, 2) + pow(_w, 2));

    // TODO
	if (length > 0.00001f)
	{
		_x /= length;
		_y /= length;
		_z /= length;
		_w /= length;
	}
}

-(void) ptvMultScalar: (CGFloat)scalar
{
	
	_x *= scalar;
	_y *= scalar;
	_z *= scalar;
	_w *= scalar;
}

-(void) ptvDotProduct: (PointVector3D *)ptv :(CGFloat *)angleOut
{
	*angleOut = sqrt((_x * ptv->_x) + (_y * ptv->_y) + (_z * ptv->_z) + (_w * ptv->_w));
}

-(void) ptvCrossProduct: (PointVector3D *)ptv :(PointVector3D *)ptvOut
{
    ptvOut->_x = (_y*ptv->_z - _z*ptv->_y);
    ptvOut->_y = (_z*ptv->_x - _x*ptv->_z);
    ptvOut->_z = (_x*ptv->_y - _y*ptv->_x);
    ptvOut->_w = 0.0f;
}

@end
