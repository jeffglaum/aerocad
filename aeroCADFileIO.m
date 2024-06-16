//
//  aeroCADFileIO.m
//  aeroCAD
//
//  Created by Jeff Glaum on 7/10/10.
//  Copyright 2010 Jeff Glaum. All rights reserved.
//

#import "aeroCADFileIO.h"
#import "aeroCADTypes.h"


@implementation aeroCADFileIO


-(NSString *) getFileName
{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
 
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    
    if ([openDlg runModal] == NSModalResponseOK)
    {
        for(NSURL* URL in [openDlg URLs])
        {
            return [URL path];
        }
    }
    
	return NULL;
}


- (aeroCADCurve *) readCurveDataFile:(NSString *) fileName
{
	BOOL setStartPoint = FALSE;
	FILE *fp;
	char line[FILE_MAX_LINE_LEN];
	aeroCADCurve *curve = NULL;
    POINT3D pt = {0.0f, 0.0f, 0.0f, 1.0f};
	
	// Open the curve pointset data file
    //
	if (NULL == (fp = fopen([fileName UTF8String], "rt")))
		return NULL;
	
	// Skip the first line - airfoil/curve name
	//
    fgets(line, FILE_MAX_LINE_LEN, fp);

    // Allocate a new curve object
    //
    curve = [[aeroCADCurve alloc] init: CURVE_TYPE_LINE];

	while ((fgets(line, FILE_MAX_LINE_LEN, fp)) != NULL)
	{
        // Skip comments
        //
		if('#' == line[0])
            continue;
        
        // Extract the curve's X and Y points (floats)
        //
        sscanf(line, " %f %f\n", &pt.pt.x, &pt.pt.y);
        
        // Add the point/segment to the curve
        //
        if (FALSE == setStartPoint)
        {
			[curve setStartPoint: pt];
            setStartPoint = TRUE;
        }
        else
        {
            [curve appendSegment: pt];
        }
	}
	
    // Close the curve file
    //
	fclose(fp);
	
	return curve;
}

@end
