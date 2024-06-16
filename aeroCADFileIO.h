//
//  aeroCADFileIO.h
//  aeroCAD
//
//  Created by Jeff Glaum on 7/10/10.
//  Copyright 2010 Jeff Glaum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "aeroCADCurve.h"

// Preprocessor constants
//
#define FILE_MAX_LINE_LEN   81


@interface aeroCADFileIO : NSObject
{
}

- (NSString *) getFileName;
- (aeroCADCurve *) readCurveDataFile:(NSString *) fileName;

@end
