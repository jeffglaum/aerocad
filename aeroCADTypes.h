/*
 *  aeroCADTypes.h
 *  aeroCAD
 *
 *  Created by Jeff Glaum on 7/10/10.
 *  Copyright 2010 Jeff Glaum. All rights reserved.
 *
 */


#define PI					3.14159265
#define HALF_PI				1.570796325
#define RADIANS_PER_DEGREE	0.017453293
#define DEGREES_PER_RADIAN  57.295779579


typedef union
{
	struct
	{
		float x;
		float y;
		float z;
		float rsvd;		// Always 1.
	}pt;
	float mtx[4];
} POINT3D;

typedef struct
{
	int points;
	POINT3D pointlist[];
} POINT_SET;


typedef struct
{
	float dx;
	float dy;
	float dz;
} VECTOR3D;