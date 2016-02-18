# LiveCode IDE Tutorial Syntax
A tutorial consists of a declaration of the name, a prologue, some steps
and an epilogue.

	Tutorial
	  : "tutorial" <Name: STRING> SEPARATOR
		Prologue SEPARATOR
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

A step consists of some text describing the step, optionally some script
associated with the step, and actions associated with the step.

	Step
	  : "step" <Name: STRING>
		  <Info: TEXT>
		[ “script” SEPARATOR
		   TEXT SEPARATOR  ]
		[ "value" SEPARATOR
		   TEXT SEPARATOR  ]
		[ "file" SEPARATOR
		   STRING SEPARATOR  ]   
		"action"
		  { Command SEPARATOR }
		"end" "step"

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
	| "message box"

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
	  | <Target: Object> “is” (“clicked” | “selected” | “scripted” | “focused” | "grouped")
	  | “the” “tool” “is” (“edit” | “run” | “graphic”)
	  | “the” <Property: PROPERTY> “of” <Target: Object> “is” <Value: STRING>
	  | <Target: Object> “pops” “up” “answer” “dialog”
	  | "this" "card" "is" <Card: STRING>