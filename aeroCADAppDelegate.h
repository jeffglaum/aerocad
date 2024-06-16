//
//  aeroCADAppDelegate.h
//  aeroCAD
//
//  Created by Jeff Glaum on 7/4/10.
//  Copyright 2010 Jeff Glaum. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "aeroCADCurve.h"


@interface aeroCADAppDelegate : NSObject <NSApplicationDelegate>
{
    NSWindow    *window;
	NSTextField *consoleOutputField;	
	NSTextField *commandInputField;
	
	aeroCADCurve *constructionCurve;    // Used to keep track of a new curve/line under construction
}

@property (assign) IBOutlet NSWindow    *window;
@property (assign) IBOutlet NSTextField *consoleOutputField;
@property (assign) IBOutlet NSTextField *commandInputField;

// Button handlers
//
-(IBAction) button_newLine:             (id) sender;
-(IBAction) button_appendLine:          (id) sender;
-(IBAction) button_endLine:             (id) sender;
-(IBAction) button_fetchCurveFile:      (id) sender;
-(IBAction) button_invertCurve:         (id) sender;
-(IBAction) button_deleteCurve:         (id) sender;
-(IBAction) button_drawShaded:          (id) sender;
-(IBAction) button_drawWireframe:       (id) sender;
-(IBAction) button_drawSurfaceNormals:  (id) sender;

-(void) setConsoleOutputText:   (NSString *) text;
-(void) setCommandInputText:    (NSString *) text;
-(void) commandHandler:         (NSString *) cmd;

-(void) newLineHandler;
-(void) appendLineHandler;
-(void) endLineHandler;
-(void) fetchCurveHandler;
-(void) deleteCurveHandler;

@end
