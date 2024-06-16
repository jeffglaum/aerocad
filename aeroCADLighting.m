//
//  aeroCADLighting.m
//  aeroCAD
//
//  Created by Jeff Glaum on 7/10/10.
//  Copyright 2010 Jeff Glaum. All rights reserved.
//

#import "aeroCADLighting.h"
#import "aeroCADTypes.h"
#import "aeroCADLoftedSurf.h"

POINT3D lightSource =   
{
	{-10.0, 10.0, 0.0, 0.0}
};

@implementation aeroCADLighting

// This routine computes the three dimentional surface normal for each wing panel.
//
- (void) computeNormals:(void *)surf
{
	int i;
	aeroCADLoftedSurf *loft = surf;
	int triangleCount = [loft _triangleCount];
	TRIANGLE *t = [loft _shadeTriangles];
	CGFloat dx1, dx2, dy1, dy2, dz1, dz2, nx, ny, nz, mag_normal;
	CGFloat lx, ly, lz;
	
	// Normalize light source vector
	//
	mag_normal = (CGFloat)sqrt(pow(lightSource.pt.x, 2) + pow(lightSource.pt.y, 2) + pow(lightSource.pt.z, 2));
	lx = lightSource.pt.x;
	ly = lightSource.pt.y;
	lz = lightSource.pt.z;	
	if (0.0f != mag_normal)
	{
		lx /= mag_normal;
		ly /= mag_normal;
		lz /= mag_normal;			
	}
	
	for (i=0 ; i<triangleCount ; i++)
	{
		// Left-handed.
		//
		dx1 = t[i].v2->pt.x - t[i].v1->pt.x;
		dy1 = t[i].v2->pt.y - t[i].v1->pt.y;
		dz1 = t[i].v2->pt.z - t[i].v1->pt.z;
		dx2 = t[i].v3->pt.x - t[i].v1->pt.x;
		dy2 = t[i].v3->pt.y - t[i].v1->pt.y;
		dz2 = t[i].v3->pt.z - t[i].v1->pt.z;

		// Compute the normal to the panel surface.
		//
		nx = dy1*dz2 - dz1*dy2;
		ny = dz1*dx2 - dx1*dz2;
		nz = dx1*dy2 - dy1*dx2;
		
		// Normalize the surface normal
		//
		mag_normal = (CGFloat)sqrt(pow(nx, 2) + pow(ny, 2) + pow(nz, 2));
		if (0.0f != mag_normal)
		{
			nx /= mag_normal;
			ny /= mag_normal;
			nz /= mag_normal;
		}
		t[i].nx = nx;
		t[i].ny = ny;
		t[i].nz = nz;
		
		// Compute angles between eye view and normal (eye is at 0,0,1)
		//
		// TODO: This is wrong - the eye view changes depending on how coordinate system is transformed
		//
		t[i].eyeang = (CGFloat)acos(-1 * nz);
		if (t[i].eyeang > PI) 
		{
			t[i].eyeang -= (2*PI);
		}
		
		// Light angle is acos of dot product between light vector and surface normal
		//
		t[i].lightang = (CGFloat)acos(lx*nx + ly*ny + lz*nz);
        if (t[i].lightang > PI)
		{
			t[i].lightang -= (2*PI);
		}
		
		// Determine the max z-depth (i.e., furthest to the back of the screen) for each triangle
		//
		t[i].max_z = t[i].v1->pt.z;
		if (t[i].v2->pt.z > t[i].max_z) t[i].max_z = t[i].v2->pt.z;
		if (t[i].v3->pt.z > t[i].max_z) t[i].max_z = t[i].v3->pt.z;
	}
}

// This routine sorts the wing panels by z-depth = hidden surface removal when shading.
//
- (void) depthSort:(void*)surf
{	
	BOOL flag = YES;
	aeroCADLoftedSurf *loft = surf;
	TRIANGLE *t = [loft _shadeTriangles];
	int triangleCount = [loft _triangleCount];

	while(YES == flag)
	{
		flag = NO;
		for (int i=0; i<triangleCount-1; i++)
		{
			if (t[i].max_z < t[i+1].max_z)
			{
				TRIANGLE temp;
				memcpy(&temp, &t[i], sizeof(TRIANGLE));
				memcpy(&t[i], &t[i+1], sizeof(TRIANGLE));
				memcpy(&t[i+1], &temp, sizeof(TRIANGLE));
				flag = YES;
			}
		}
	}
}

@end
