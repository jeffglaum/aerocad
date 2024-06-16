/*
 *  aeroCADCommands.h
 *  aeroCAD
 *
 *  Created by Jeff Glaum on 7/15/10.
 *  Copyright 2010 Jeff Glaum. All rights reserved.
 *
 */

typedef enum
{
	CMD_QUIT = 0,                       // Exit program
    CMD_DISP_GRID,                      // Show display grid (only for standard views)
    CMD_XFRM_SCALE,                     // Scale the selected object
    CMD_XFRM_ROTATE,                    // Rotate the selected object
    CMD_XFRM_TRANSLATE,                 // Translate the selected object
	CMD_FILE_OPEN,                      // TBD
	CMD_FILE_SAVE,                      // TBD
	CMD_GRFX_SHADE,                     // Draw objects with shading
	CMD_GRFX_WIREFRAME,                 // Draw objects as wireframes
	CMD_GRFX_NORMALS,                   // Display surface normals
	CMD_CURS_MOVEABS,                   // Move the cursor to a specific location
	CMD_CURV_NEW,                       // Start a new curve/line
	CMD_CURV_APPEND,                    // Append a segment to the current curve/line
	CMD_CURV_END,                       // End (complete) the curve/line
    CMD_CURV_OPEN,                      // Create a new curve using pointset data from a file
    CMD_CURV_DELETE,                    // Delete the selected curve
    CMD_CURV_INVERT,                    // Invert (flip) the curve end-for-end
	CMD_SURF_INVERTNORMAL,              // Invert the surface normal
    CMD_SURF_LOFT                       // Create a lofted surface
} CMDTYPE;


typedef enum
{
	CMD_STATE_NONE = 0,                 // Normal (modeless) state
	CMD_STATE_LOFT_CURVE1_SELECT,       // Create a lofted surface: select first curve
	CMD_STATE_LOFT_CURVE2_SELECT,       // Create a lofted surface: select second curve
    CMD_STATE_INVERT_SURFACE_SELECT,    // Invert the selected surface (normal)
	CMD_STATE_CURVE_CREATE,             // Create a new curve/line
    CMD_STATE_CURVE_DELETE,             // Delete the selected curve/line
    CMD_STATE_CURVE_INVERT              // Invert the selected curve/line

} CMDSTATE;


typedef struct
{
	NSString    *cmdString;             // Command string (entered by user)
	CMDTYPE		 cmdType;               // Associated command type ID
} CMDELEMENT;