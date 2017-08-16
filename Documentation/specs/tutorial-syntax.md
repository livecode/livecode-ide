# LiveCode IDE Tutorial Syntax
A tutorial consists of a declaration of the name, a prologue, some
steps, an epilogue and optional skip points.

	Tutorial
	  : "tutorial" <Name: STRING> SEPARATOR
		Prologue SEPARATOR
		[ "skip" "point" ]
		{ Step SEPARATOR }
		Epilogue

The prologue and epilogue consist only of text between their declaration
and end. 

	Prologue
	  : "prologue" SEPARATOR
		  TEXT SEPARATOR
		"end" "prologue"

	Epilogue
	  : "epilogue" SEPARATOR
		  TEXT SEPARATOR
		"end" "prologue"

A step consists of some text describing the step, optionally some other 
components associated with the step, and actions associated with the step.

	Step
	  : "step" <Name: STRING>
		  <Info: TEXT>
		[ (“script” |  "image" | "url") SEPARATOR
		   TEXT SEPARATOR  ]
		[ "value" SEPARATOR
		   TEXT SEPARATOR  ]
		[ "file" SEPARATOR
		   STRING SEPARATOR  ]   
		"action"
		  { Command SEPARATOR }
		"end" "step"

Components can be included for the following purposes:
- "script": Displays a field with colorised script in the tutorial stack.
Also causes a "Copy Script to Editor" button to be added to the tutorial
stack.
- "image": Displays an image in the tutorial stack. The image must be 
located in an _resources folder next to the tutorial's lessons folder.
- "url": Displays a browser set to the specified url.
- "value": Causes occurrences of the string "<value>" within the tutorial
instruction text to be replaced with the specified value.
- "file": Specifies the desired file target of a step's 'Import as' 
action. Must be located in the resources folder next to the tutorial's 
lessons folder. Also causes occurrences of the string "<file>" within 
the tutorial instruction text to be replaced with the specified value.

The possible actions are as follows:

	Command
	  : "highlight" ( <Target: Object> | <Target: Tool> | <Target: Property> 
	  				| <Target : IDEPalette> | <Target: IDEComponent> | “guide” <Guide:STRING> 
	  				| "line" <Line: STRING> of "script" "editor" "for" <Target: Object>)
	  | "capture" <Target: CaptureTarget>
	  | "wait" "until" <Condition: WaitCondition>
	  | "go" "to" "step" <Name: STRING>
	  | "add" "guide" <Name: STRING> "with" "rect" <Rect: RECT> "to" <Target: Object>
	  | “interlude”
	  | "load" ("lesson" | "stack") <Source: STRING>

The highlight action causes the tutorial stack to point at the relevant
object on the screen. If there is no highlight action, the tutorial stack
remains in the center of the screen.

	ObjectType
	  : "stack"
	  | "graphic"
	  | “button”
	  | “field”
	  | “image”
	  | “widget”
	  | “card”
	  | "set"

	Object
	  : <Type: ObjectType> <Name: STRING>

	ObjList
	: <Reference: Object> [ , <Next: ObjList> ]

	ObjPalette
	: “inspector”
	| “script” “editor”

	Palette
	: "dictionary"
	| “tools”
	| “menubar”
	| "message" "box"
	| "project" "browser"
	| "extension" "builder"
	| "preferences"
	| "standalone" "settings"
	| "start" "center"
	
	Tool
	  : [<Item: MenuItem>] "menu" <Menu: STRING>
	  | "toolbar" <Tool: STRING>
	  | "tool" <Name: STRING>

	MenuItem
	: "menu" "item" <Item: STRING> "of" [ <SubItem: MenuItem> ]

	Property
	: “property” <Property: STRING> “of” “section” <Section: STRING>

	IDEPalette
	: <Target: Palette> 
	| <Target: ObjPalette> "for" <Associated: Object>

	IDEComponent
	: <Component: STRING> of <Target: IDEPalette> 

The capture action enables the tutorial to refer to an object or set of 
objects later on in the tutorial. It can be used to tag the next object 
of a given type created, or a set of previously tagged objects.

	CaptureTarget
	: "the" "next" "new" <Type: ObjectType> [ “of” <Target: Object> ] "as" <Name: STRING>
	| “set” <Target: ObjList> “as” <Name: STRING>

The wait action causes the tutorial to wait until a given condition is 
satisfied before continuing.

	Condition
	  : "there" "is" ( "a" | "an" ) <Target: Object>
	  | <Target: Object> "fits" "guide" <Guide: STRING> [ "with" "tolerance" <Tolerance: INTEGER> ]
	  | "there" "is" ( "a" | "an" ) <Target: Palette>
	  | "there" "is" ( "a" | "an" ) <Target: ObjPalette> "for" <TargetObject: Object>
	  | <Target: Object> "is" ("clicked" | "selected" | "scripted" | "focused" | "grouped")
	  | "the" "tool" "is" ("edit" | "run" | "graphic")
	  | "the" <Property: PROPERTY> "of" <Target: Object> "is" <Value: STRING>
	  | "the" <Property: PROPERTY> "of" <Target: Object> "is" "changed" "with" "default" <Value: STRING>
	  | <Target: Object> "pops" "up" "answer" "dialog"
	  | "this" "card" "is" <Card: STRING>

The load action causes tutorial state to be loaded. If the "lesson" Source
is used, the tutorial runner will find the lesson with name Source in the
same lessons folder as the current tutorial, and run it to completion. The
resulting stack will then be available to use in the current tutorial.

If the "stack" Source is used, a stack will be loaded from the internal 
resources folder of the tutorial (_resources/). Any `cTutorialTag` custom
property of objects on the stack will be converted to tags for objects 
which can subsequently be used in the current tutorial.
