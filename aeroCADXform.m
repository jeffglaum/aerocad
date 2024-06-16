//
//  aeroCADXform.m
//  aeroCAD
//
//  Created by Jeff Glaum on 7/10/10.
//  Copyright 2010 Jeff Glaum. All rights reserved.
//

#import "aeroCADXform.h"
#import "aeroCADTypes.h"


// Eye and Camera positions are the same
POINT3D eyePosition    = {0.0f, 0.0f, 5000.0f, 0.0f};
POINT3D cameraPosition = {0.0f, 0.0f, 5000.0f, 0.0f};


@implementation aeroCADXform

- (id) initWithParams:(CGFloat)size :(CGFloat)xang :(CGFloat)yang :(CGFloat)zang
{
	
	// Initialize composite xform matrix
	//
	memset(cmpst, 0, sizeof(CGFloat)*16);
	cmpst[0][0]=cmpst[1][1]=cmpst[2][2]=cmpst[3][3]=1.0f;
	
	// Set default scale, rotation, translation, and perspective
	//
	[self scale:		size];
	[self rotatex:		xang];
	[self rotatey:		yang];
	[self rotatez:		zang];
    [self xlate:		0.0f: 0.0f: 0.0f];
	[self perspective:	eyePosition];
	
	return self;
}

- (id) init
{
    // Default: Isometric view
    //
	return [self initWithParams:(CGFloat)(DEFAULT_SCALE) :(CGFloat)(22.5*RADIANS_PER_DEGREE) :(CGFloat)(-22.5*RADIANS_PER_DEGREE) :(CGFloat)(0*RADIANS_PER_DEGREE)];

}

- (POINT3D) transform:(BOOL) applypersp : (POINT3D)inpt
{
	int j, k;
	POINT3D pt = {0.0f, 0.0f, 0.0f, 0.0f};

	// Flip the sign on the Z value because we're using a left-handed coordinate system (+Z is "into" the screen).
	//
    // TODO
	//inpt.pt.z *= -1;
	
	// Apply scale, rotation, and translation transform (multiplication)
	//
	for (j=0; j<4; j++)
	{
		for (k=0; k<4; k++)
		{
			pt.mtx[j]+=inpt.mtx[k]*cmpst[j][k];
		}
	}

	// Apply perspective transform:
	// 1. d = a - c (subtract camera location, assume camera is not rotated and anlges are 0)
	// 2. Multiply the perspective matrix (homogeneous coordinates)
	// 3. Divide x and y by results (divide by homogenous coordinate)
	if (applypersp == YES)
	{
		pt.pt.x    -= cameraPosition.pt.x;
		pt.pt.y    -= cameraPosition.pt.y;
		pt.pt.z    -= cameraPosition.pt.z;
		pt.pt.z     = fabs(pt.pt.z);
		pt.pt.rsvd  = 1.0f;
		
		for (j=0; j<4; j++)
		{
			for (k=0; k<4; k++)
			{
				pt.mtx[j]+=pt.mtx[k]*persp[j][k];
			}
		}
		
		pt.pt.x /= pt.pt.rsvd;
		pt.pt.y /= pt.pt.rsvd;
		pt.pt.z /= pt.pt.rsvd;
	}
	
	return pt;
}

- (void) transform:(BOOL) applypersp :(POINT3D *)inset : (POINT3D *)outset : (int)count
{
	int i;
	
	if (NULL==inset || NULL==outset)
	{
		return;
	}
	
	// Clean out the transformed pointset array
	//
	memset(outset, 0, count * sizeof(POINT3D));
	
	// Apply composite transformation to points and put results in transpoints array
	//
	for (i=0; i<count; i++)
	{
		outset[i] = [self transform: applypersp: inset[i]];
	}
}

// This routine transforms the original pointset into a displayed pointset
// TODO: Optimized and support stack-type xform design?
- (void) transform:(BOOL) applypersp : (POINT_SET *)inset : (POINT_SET *)outset
{
	[self transform: applypersp: inset->pointlist: outset->pointlist: inset->points];
	outset->points = inset->points;
}

// This routine multiplies two matrices and puts the answer in destination
- (void) mtxmult: (CGFloat [4][4])destination :(CGFloat [4][4])source
{
	int i, j, k;
	CGFloat temp[4][4];
	
	// Initialize temp matrix
	//
	memset(temp, 0, sizeof(CGFloat)*16);

	// Multiply destination and source matrices and store the results in the temp matrix
	//
	for (i=0; i<4; i++)
	{
		for (j=0; j<4; j++)
		{
			for (k=0; k<4; k++)
				temp[j][i]+=source[k][i]*destination[j][k];
		}
	}
	
	// Replace the contents of the destination matrix with the temp matrix multiplication values
	//
	memcpy(destination, temp, sizeof(CGFloat)*16);

}

// This routine is called to set up a new translation matrix
- (void) perspective:(POINT3D)eyePos
{	
	memset(persp, 0, sizeof(CGFloat)*16);

	persp[0][0]=persp[1][1]=persp[2][2]=1.0f;
	persp[0][3]=(-1   * eyePos.pt.x);
	persp[1][3]=(-1   * eyePos.pt.y);
	persp[3][2]=(1.0f / eyePos.pt.z);
}

// This routine is called to set up a new translation matrix
- (void) xlate:(CGFloat)dx :(CGFloat)dy :(CGFloat)dz
{	
	cmpst[0][3]+=dx;
	cmpst[1][3]+=dy;
	cmpst[2][3]+=dz;
	cmpst[3][3]=1.0f;
}

// This routine is called to set up a new scaling matrix
- (void) scale:(CGFloat)factor
{	
	CGFloat scale[4][4];

	memset(scale, 0, sizeof(CGFloat)*16);
	
	// Fill in matrix with scaling factor
	//
	scale[0][0]=scale[1][1]=scale[2][2]=factor;
	scale[3][3]=1.0f;
	
	// Update the xform matrix
	//
	[self mtxmult:cmpst :scale];
}

// This routine is called to set up a new x-axis rotation matrix
- (void)rotatex:(CGFloat)ang  
{	
	CGFloat rotex[4][4];

	memset(rotex, 0, sizeof(CGFloat)*16);
	
	// Fill in rotation matrix with x-axis rotation values
	//
	rotex[0][0]=1.0f;
	rotex[1][1]=(CGFloat)cos(ang);
	rotex[2][1]=(CGFloat)sin(ang);
	rotex[1][2]=(CGFloat)-sin(ang);
	rotex[2][2]=(CGFloat)cos(ang);
	rotex[3][3]=1.0f;
	
	// Update the xform matrix
	//
	[self mtxmult:cmpst :rotex];
}

// This routine is called to set up a new y-axis rotation matrix
- (void)rotatey:(CGFloat)ang  
{	
	CGFloat rotey[4][4];

	memset(rotey, 0, sizeof(CGFloat)*16);

	// Fill in rotation matrix with y-axis rotation values
	//
	rotey[0][0]=(CGFloat)cos(ang);
	rotey[2][0]=(CGFloat)-sin(ang);
	rotey[1][1]=1.0f;
	rotey[0][2]=(CGFloat)sin(ang);
	rotey[2][2]=(CGFloat)cos(ang);
	rotey[3][3]=1.0f;
	
	// Update the xform matrix
	//
	[self mtxmult:cmpst :rotey];
}

// This routine is called to set up a new z-axis rotation matrix
- (void)rotatez:(CGFloat)ang  
{	
	CGFloat rotez[4][4];

	memset(rotez, 0, sizeof(CGFloat)*16);

	// Fill in rotation matrix with z-axis rotation values
	//
	rotez[0][0]=(CGFloat)cos(ang);
	rotez[1][0]=(CGFloat)sin(ang);
	rotez[0][1]=(CGFloat)-sin(ang);
	rotez[1][1]=(CGFloat)cos(ang);
	rotez[2][2]=rotez[3][3]=1.0f;
	
	// Update the xform matrix
	//
	[self mtxmult:cmpst :rotez];
}

@end
