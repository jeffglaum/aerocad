//
//  aeroCADAppDelegate.m
//  aeroCAD
//
//  Created by Jeff Glaum on 7/4/10.
//  Copyright 2010 Jeff Glaum. All rights reserved.
//

#import "aeroCADAppDelegate.h"
#import "aeroCADCommands.h"
#import "aeroCADView.h"
#import "aeroCADCurve.h"
#import "aeroCADFileIO.h"


CMDELEMENT commandList[] = 
{
    {	@"d.g",	CMD_DISP_GRID         },
    {	@"t.s",	CMD_XFRM_SCALE        },
    {	@"t.r",	CMD_XFRM_ROTATE       },
    {	@"t.t",	CMD_XFRM_TRANSLATE    },
	{	@"f.o",	CMD_FILE_OPEN		  },
	{	@"g.s", CMD_GRFX_SHADE		  },
	{	@"g.w", CMD_GRFX_WIREFRAME	  },
	{	@"g.n", CMD_GRFX_NORMALS	  },
	{	@"c.m", CMD_CURS_MOVEABS	  },
	{	@"c.n", CMD_CURV_NEW          },
	{	@"c.a", CMD_CURV_APPEND       },
	{	@"c.e", CMD_CURV_END		  },
    {	@"c.o", CMD_CURV_OPEN		  },
    {	@"c.d", CMD_CURV_DELETE		  },
    {	@"c.f", CMD_CURV_INVERT		  },
	{	@"s.l", CMD_SURF_LOFT         },
    {	@"s.i", CMD_SURF_INVERTNORMAL },
	{	@"q",	CMD_QUIT			  },
	{	NULL,	0					  }     // Terminator - must be last
};

extern int g_ox, g_oy;
extern CMDSTATE g_CurrCmdState;


@implementation aeroCADAppDelegate
@synthesize window, consoleOutputField, commandInputField;

- (void) awakeFromNib
{
	NSRect desktopSize = [[NSScreen mainScreen] visibleFrame];
	[[self window] setFrame: desktopSize display: YES];
	
	aeroCADView *myView = [[[[self window] contentView] subviews] objectAtIndex: 0];
	NSRect viewRect     = [myView frame];
	g_ox = (viewRect.size.width  / 2);
	g_oy = (viewRect.size.height / 2);
	
	[[self window] makeFirstResponder: myView];
}

-(void) setConsoleOutputText:(NSString *)text
{
	[consoleOutputField setStringValue: text];
}

-(void) setCommandInputText:(NSString *)text;
{
	[commandInputField setStringValue: text];
}

-(void) newLineHandler
{
    aeroCADView *myview = [[[[self window] contentView] subviews] objectAtIndex:0];

    // TODO - Bezier?
    constructionCurve = [[aeroCADCurve alloc] init: CURVE_TYPE_LINE];
    [constructionCurve setStartPoint: [myview getCursor]];
    [myview addToDisplayList: constructionCurve];
    g_CurrCmdState = CMD_STATE_CURVE_CREATE;
    [myview setNeedsDisplay:YES];
}

-(void) appendLineHandler
{
    aeroCADView *myview = [[[[self window] contentView] subviews] objectAtIndex:0];

    if (g_CurrCmdState == CMD_STATE_CURVE_CREATE)
    {
        // TODO - Bezier?
        [constructionCurve appendSegment: [myview getCursor]];
        [myview setNeedsDisplay:YES];
    }
}

-(void) endLineHandler
{
    [self appendLineHandler];
    g_CurrCmdState = CMD_STATE_NONE;
}

-(void) fetchCurveHandler
{
    aeroCADCurve *dc  = NULL;
    aeroCADView *myview = [[[[self window] contentView] subviews] objectAtIndex:0];

    // Read curve data from file
    id appDelegate = [[NSApplication sharedApplication] delegate];
    [appDelegate setConsoleOutputText:@" Select the curve file to open"];
    aeroCADFileIO *fileHandler = [aeroCADFileIO alloc];
    dc = [fileHandler readCurveDataFile: [fileHandler getFileName]];
    
    if (dc != NULL)
    {
        [myview addToDisplayList: dc];
        g_CurrCmdState = CMD_STATE_NONE;
        [myview setNeedsDisplay:YES];
    }
    [appDelegate setConsoleOutputText:@""];

}

-(void) deleteCurveHandler
{
    id appDelegate = [[NSApplication sharedApplication] delegate];
    [appDelegate setConsoleOutputText:@" Select the curve to delete"];
    
    g_CurrCmdState = CMD_STATE_CURVE_DELETE;
}


-(void) invertCurveHandler
{
    id appDelegate = [[NSApplication sharedApplication] delegate];
    [appDelegate setConsoleOutputText:@" Select the curve to invert"];
    
    g_CurrCmdState = CMD_STATE_CURVE_INVERT;
}

// UI button handlers --- START ---
-(IBAction) button_newLine:(id)sender             { [self newLineHandler];     }
-(IBAction) button_appendLine:(id)sender          { [self appendLineHandler];  }
-(IBAction) button_endLine:(id)sender             { [self endLineHandler];     }
-(IBAction) button_fetchCurveFile:(id)sender      { [self fetchCurveHandler];  }
-(IBAction) button_invertCurve:(id)sender         { [self invertCurveHandler]; }
-(IBAction) button_deleteCurve:(id)sender         { [self deleteCurveHandler]; }
-(IBAction) button_drawShaded: (id)sender
{
    aeroCADView *myview = [[[[self window] contentView] subviews] objectAtIndex:0];
    [myview enableShading: YES];
}
-(IBAction) button_drawWireframe: (id)sender
{
    aeroCADView *myview = [[[[self window] contentView] subviews] objectAtIndex:0];
    [myview enableShading: NO];
}
-(IBAction) button_drawSurfaceNormals: (id)sender
{
    aeroCADView *myview = [[[[self window] contentView] subviews] objectAtIndex:0];
    [myview toggleNormals];
}
// UI button handlers --- END ---

-(void) commandHandler: (NSString *)cmdline
{
	int i;
	NSRange range;
	aeroCADView *myview = [[[[self window] contentView] subviews] objectAtIndex:0];
	
	// Look up the command
	//
	for (i=0 ; NULL!=commandList[i].cmdString ; i++)
	{
		range = [cmdline rangeOfString : commandList[i].cmdString];
		if (range.location == 0)
			break;
	}
	
	if (NULL == commandList[i].cmdString)
		return;
	
	// Collect the command's arguments (if any)
	//
	NSString *cmdargs = [cmdline substringFromIndex: range.length];

	// Command Handler
	//
	switch (commandList[i].cmdType)
	{
		case CMD_QUIT:
			[NSApp terminate: self];
			break;
        case CMD_DISP_GRID:
        {
            CGFloat gridSpacing;
            sscanf([cmdargs UTF8String], "%lf", &gridSpacing);
            [myview setGridSpacing: gridSpacing];
        }
			break;
        case CMD_XFRM_SCALE:
            {
                CGFloat scale;
                sscanf([cmdargs UTF8String], "%lf", &scale);
                [myview scaleSelectedObjects: scale];
            }
			break;
        case CMD_XFRM_ROTATE:
            {
                CGFloat rotx, roty, rotz;
                sscanf([cmdargs UTF8String], "%lf,%lf,%lf", &rotx, &roty, &rotz);
                [myview rotateSelectedObjects: rotx: roty: rotz];
            }
			break;
        case CMD_XFRM_TRANSLATE:
            {
                CGFloat dx, dy, dz;
                sscanf([cmdargs UTF8String], "%lf,%lf,%lf", &dx, &dy, &dz);
                [myview translateSelectedObjects: dx: dy: dz];
            }
			break;
		case CMD_FILE_OPEN:
			[consoleOutputField setStringValue:@"Select the file to open"];
            aeroCADFileIO *fileHandler = [aeroCADFileIO alloc];
			[fileHandler getFileName];
			break;
		case CMD_GRFX_SHADE:
			[myview enableShading: YES]; 
			break;
		case CMD_GRFX_WIREFRAME:
			[myview enableShading: NO]; 
			break;
		case CMD_GRFX_NORMALS:
			[myview toggleNormals]; 
			break;
		case CMD_CURS_MOVEABS:
			{
				float x, y, z;
                x = y = z = 0.0f;
				sscanf([cmdargs UTF8String], "%f,%f,%f", &x, &y, &z);
				[myview moveCursorAbs: x: y: z];
			}
			break;
		case CMD_CURV_NEW:
            [self newLineHandler];
			break;
		case CMD_CURV_APPEND:
            [self appendLineHandler];
			break;	
		case CMD_CURV_END:
            [self endLineHandler];
			break;
        case CMD_CURV_OPEN:
            [self fetchCurveHandler];
			break;
        case CMD_CURV_DELETE:
            [self deleteCurveHandler];
			break;
        case CMD_CURV_INVERT:
            [self invertCurveHandler];
			break;
        case CMD_SURF_INVERTNORMAL:
			[consoleOutputField setStringValue:@" Select surface to invert"];
			g_CurrCmdState = CMD_STATE_INVERT_SURFACE_SELECT;
            break;
		case CMD_SURF_LOFT:
			[consoleOutputField setStringValue:@" Select first profile curve"];
			g_CurrCmdState = CMD_STATE_LOFT_CURVE1_SELECT;
			break;
		default:
			// Do nothing.
			break;
	}
}

@end
