# Introduction

LiveCode 8.0 is the most exciting release in the history of the technology. It provides a simple way to extend the functionality or control set of LiveCode.

Our focus in LiveCode 8.0 is extensibility. You can now build and share widgets (custom controls) and libraries that are treated by LiveCode as engine level elements.

LiveCode 8.0 can be thought of as a version 7.0 with a new module allowing extensions to be plugged into the engine. As a result, 8.0 should be as functional and stable as LiveCode 7.0.

This guide will take you through the process of installing and using these new widgets and libraries and for the adventurous among you, provide a guide to building and sharing your own extensions. 

## LiveCode Script vs LiveCode Builder
To make it possible to create extensions and plug them into the LiveCode engine we've created a new flavour of our language called ***LiveCode Builder***. LiveCode Builder looks a lot like LiveCode Script so should feel familiar for any seasoned LiveCode developer. There is lots of new syntax which exposes parts of the LiveCode engine that were only previously available to those who were skilled c/c++ developers.

To learn more about LiveCode Builder and creating extensions, read on.

> *Warning:* It is important to stress right at the start that ***no aspect of LiveCode Builder should considered final***. ***Every piece of syntax in LiveCode Builder is subject to change***.

## IDE
A number of palettes have been replaced and new ones added in order to support extensions. The tools palette, message box and property inspector have been rewritten. An extension manager stack has been added to keep track of installed extensions, and a stack added to help users create their own extensions.

## Installers

Installers for the first alpha of LiveCode 8 can be found at:

http://downloads.livecode.com/

# Installing Extensions

## 1) Open the extension manager
To install an extension open the extension manager from the *Tools* menu: ```Tools > Extension Manager```

![](images/extensions-manager.png)

Notice the extension manager has three tabs:

* Widgets - Displays locally widgets
* Libraries - Displays installed libraries
* Extension Store - Displays the extension portal through which you can download any extension shared by another developer

> Note: Only open source (free) extensions can be shared and downloaded in this release. We will be adding commercial (paid) extensions in future releases

## 2) Go to the extension store
Go to the extension by clicking on the extension store tab and wait for it to load (Internet connectivity is required).

![enter image description here](images/extensions-home.png)

You can browse by category or search for an extension.

## 3) Select an extension
Click on any of the extensions to load full details and installation options.

![enter image description here](images/extensions-clock.png)

## 4) Install the extension
Click on the install button to begin the download and installation of the extension. It should only take a matter of seconds to download and install.

![enter image description here](images/extensions-installed.png)

## 5) Try out your extension

**Widgets**
If you downloaded a widget it will appear in your list of installed widgets and also in your Tools Palette. Using the widget is no different from any of the classic LiveCode controls you've been used to. Simply drag it onto a stack and start interacting with it as you could any another control.

![enter image description here](images/extensions-widgets.png)

You can reference the widget in script as a control:

```
set the name of the last control to "clock"
```

Or more specifically as a widget:

```
set the tooltip of widget 1 to "This is my nice new clock widget"
```

**Libraries**
If you downloaded a library it will appear in your list of installed libraries. A library adds new functions and commands to the LiveCode engine which become available automatically to you in LiveCode script, just like the standard syntax. Open the documentation stack to view a full list of the new functions provided by a newly installed extension.

## 6) Extension Documentation
Extensions can provide an API (Dictionary) and User Guide as part of the installed package. They are installed and viewable through the LiveCode Dictionary stack.

**API (Dictionary)**

![enter image description here](images/extensions-documentation.png)

1. Open the documentation stack from the menubar
2. API chooser - Choose which API to view. By default, LiveCode 8.0 comes with the LiveCode Script API and the new LiveCode Builder API. Any extension that contains an API is displayed here.
3. Category Filter - Click on the tags to filter the API entries. 
4. Search Filter - Enter a text string to filter the API entries by a specific search string
5. History - Move back and forward through your API navigation history
6. Entry List - Select the entry to display from this list
7. Entry - The entry describing the syntax

**User Guide**

![enter image description here](images/extensions-guides.jpg)

1. Click on the "Guide" tab at the top of the documentation stack
2. Select the guide you wish to view

> Note: In LiveCode 8.0 we'll be including an updated version of the LiveCode Script User Guide. The version currently included with LiveCode has not yet been updated.

# Creating Extensions

We have provided a new "Extension Builder" stack to help make development and packaging of extensions as easy as possible. 

> **Note:** LiveCode Builder is a different flavour of LiveCode so it is not possible to edit LiveCode Builder scripts in the main LiveCode Script IDE.

## Extension Builder

Open the "Extension Builder" from the tools menu:

```
Tools > Widget Builder
```

![enter image description here](images/extensions-plugin-overview.png)

1. Select the extension you wish the develop or click the "open" icon in the header back to locate an extension you've not loaded before. All LiveCode authored widgets in the application package at: /contents/extensions/. To play with one of these extensions we recommend copying the folder from the application package to your desktop and loading it from there. Changing the extension id in the source code will also mean it doesn't conflict with the existing extension.
2. Data that the builder was able to parse from the directory such as icons, resources, API's the user guides.
3. Console: Shows status, error and log messages.
4. Test: Creates a stack, compiles the extensions and creates an instance.
5. Script: Opens the lcb script in an external default editor.
6. Insall: Installs the extension into the IDE
7. Uninstall: Uninstalls the extension from the IDE
8. Package: Creates a .lce package which can uploaded to the extension store. It is placed in the extension directory

> **Note:** A great way to get started is to tweak the script of one of our widgets examples.
> 
##Create your Own
### Simple Widget
A widget and a library are identical, except that a widget draws to a canvas. As a result, the authoring process is much the same for both extension types.

### Create a .lcb file
We recommend using the Atom text editor, available at https://atom.io/. A LiveCode package is available which provides some colorization as well as indentation. 
If you prefer to use TextWrangler, there is a colorising script here: https://github.com/livecode/livecode/tree/develop/contrib/TextWrangler. It should be placed in /Application Support/TextWrangler/Language Modules/

Start by creating a plain text file in a new directory and save it to disk with the extension "lcb":

```
/Desktop/widgettest/main.lcb
```

> **Note:** The extension builder currently relies on there being only one ***.lcb*** file in a given directory.	

### Declare Type and Identifier
Start by declaring the type of extension, either "widget" or "library" followed by your identifier (See "Select A Developer ID" below).
```
widget community.livecode.beaumont.pinkCircle
   # Code for your widget
end widget
```
This is the unique identifier by which your extension will be referred to by the LiveCode Engine.

### Declare Meta Data
Next, provide meta data to help LiveCode display your product correctly in product and in the online portal.

```
widget community.livecode.beaumont.pinkCircle

metadata title is "My Pink Circle"
metadata author is "Benjamin Beaumont"
metadata version is "1.0.0"

end widget
```

### Importing libraries
The LiveCode builder syntax is broken down into **modules**. There are 3 classes of module:

Type|Description
---|---
Default|The module is part of LiveCode builder and is included by default. Their syntax is always available to you as a LiveCode developer.
Optional|The module is created and distributed by LiveCode Ltd and must be imported by the extension developer in order to make use of the syntax.
Custom|This module is created and distributed through the online portal and must be imported by the extension developer in order to make use of the syntax.

LiveCode builder contains the following modules:

Module|Type|Description
---|---|---
com.livecode.canvas|Optional|Provides the syntax and types for 2D drawing allowing developers to draw to a canvas. Required if creating a widget.
com.livecode.widget|Optional|Contains syntax specific to widget building such as "my width" and "the mouse position".
com.livecode.engine|Optional|Contains syntax for all extension building such as "dispatch" and "log".
com.livecode.arithmetic|Default|Contains syntax for basic mathematical operations.
com.livecode.array|Default|Contains syntax for operations on arrays.
com.livecode.binary|Default|Contains syntax for operations on binary data.
com.livecode.bitwise|Default|Contains syntax for bitwise logical operators.
com.livecode.byte|Default|Contains syntax for operations on byte chunks.
com.livecode.char|Default|Contains syntax for operations on char chunks.
com.livecode.codeunit|Default|Contains syntax for operations on codeunit chunks.
com.livecode.date|Default|Contains syntax for accessing the date and time.
com.livecode.file|Default|Contains syntax for file I/O operations.
com.livecode.foreign|Default|Provides the type bindings for foreign types.
com.livecode.list|Default|Contains syntax for operations on lists.
com.livecode.logic|Default|Contains syntax for logical operators.
com.livecode.mathfoundation|Default|Contains syntax for foundational mathematical operations.
com.livecode.math|Default|Contains syntax for mathematical operations.
com.livecode.sort|Default|Contains syntax for sorting operations.
com.livecode.stream|Default|Contains syntax for stream I/O operations.
com.livecode.string|Default|Contains syntax for operations on strings.
com.livecode.system|Default|Contains syntax for accessing system information.
com.livecode.type|Default|Contains syntax for general operations on types.
com.livecode.typeconvert|Default|Contains syntax for conversions between types.
com.livecode.unittest|Default|Contains syntax for unit testing LiveCode Builder programs.

> **Warning!** Module names are subject to change.

The new LiveCode dictionary has a full list of all available syntax as well as the module each belongs to. As a general rule we recommend importing all three optional module whenever developing widgets.

```
widget community.livecode.beaumont.pinkCircle

use com.livecode.canvas
use com.livecode.widget
use com.livecode.engine

metadata title is "My Pink Circle"
metadata author is "Benjamin Beaumont"
metadata version is "1.0.0"

end widget
```


### Core Handlers

There are three core handlers that any widget developer should implement:

Handler|Description
------|------
OnPaint|The *OnPaint* message is sent to your widget whenever LiveCode requires it to redraw. The performance of you widget is tied primarily to this handler and should be kept as efficient as possible.
OnCreate|The *OnCreate* message is sent to your widget when it is first created by LiveCode. This can be used to initialise default data and where applicable, reduce the burden for calculating constants etc in the onPaint handler.
OnGeometryChanged| The *OnGeometryChanged* message is sent when the control is changed in size.
OnSave| The *OnSave* message is sent when your widget is about to be destroyed and enables the widget to save data set on the widget.
OnLoad| The *OnLoad* message is sent when your widget is created and enables the widget to retrieve data saved on the widget.

For the most basic example, only the OnPaint() handler is required.

```
widget community.livecode.beaumont.pinkCircle

metadata title is "My Pink Circle"
metadata author is "Benjamin Beaumont"
metadata version is "1.0.0"

public handler OnPaint()
   // Draw widget
end handler

end widget
```

### Draw a Pink Circle

```
widget community.livecode.beaumont.pinkCircle

metadata title is "My Pink Circle"
metadata author is "Benjamin Beaumont"
metadata version is "1.0.0"

use com.livecode.canvas

public handler OnPaint()
   // Create a path with a radius of half the width of the canvas
   // Set the paint to a solid pink color
   // Fill the path
   variable tCirclePath as Path
   put circle path centered at point [my width / 2, my height / 2] with radius (my width/2) into tCirclePath
   set the paint of this canvas to solid paint with color [1, 0, 1]
   fill tCirclePath on this canvas
end handler

end widget
```

### Test the Code

Now open the extension builder stack as shown above and click on the load icon to load your ***.lcb*** file into the builder.

![enter image description here](images/extensions-widget-first.png)

Click test. Your widget should be displayed on the new stack. If you can't see it, check behind the extension stack.

### Properties
In order to make a widget useful to end users it is likely that you'll want to expose properties that allow them to specify how your widget should behave. 

To specify a property you must provide a name and the method to get and set the property.
```
property <name> get <variable/handler> set <variable/handler>
```

The simplest properties to get/set are numbers or strings. So lets create a circleMargin property that allows users to define a margin.

```
property circleMargin get mMargin set setMargin
```

In the above example, when the ***circleMargin*** property is requested, the variable "mMargin" is returned, when set, the handler "setMargin" is called. To have LiveCode Builder handle the getting/setting of data, provide the variable name, to take full control over the getting/setting process define handlers. In our case we're taking a mixed approach.

```
private variable mMargin as real
```

We'll define a member variable to store the value for the margin. LiveCode Builder is type so you must also specify the type of your variable. Remember, the canvas you are drawing to has subpixel precision so our margin can be a decimal number. As a result, we've chosen the specify our margin as a real number. For a full list of types available in LiveCode builder please see the [Typing](#Typing) section of the language specification guide below. We also suggest a nameing convension for variable in the section on [variable and case sensitivity](#Case-Sensitivity).

We also need to insatiate our circleMargin to a default value. We do this by adding an onCreate handler which is called when the widget is first created.

```
public handler setMargin(in pMargin as real) as undefined
	put pMargin into mMargin
	redraw all
end handler
```

Finally we have to implement our setMargin handler.
```
public handler onCreate() 
	put 0 into mMargin
end handler
```

Implementing the "setter" ourselves provides us with a little more flexibility. In this case when the property is set we want our pink circle to immediately redraw to reflect the property change. We do this by calling "redraw all".

To test the property click "test" and from the message box set the property.

```
set the cicleMargin of widget 1 to 15
```

**Full Example**
```
widget community.livecode.beaumont.pinkCircle

metadata title is "My Pink Circle"
metadata author is "Benjamin Beaumont"
metadata version is "1.0.0"

use com.livecode.canvas
use com.livecode.widget
use com.livecode.engine

// Properties
property circleMargin get mMargin set setMargin

// Local variables
private variable mMargin as real

public handler onCreate() 
	put 0 into mMargin
end handler

public handler OnPaint()
   // Create a path with a radius of half the width of the canvas
   // Set the paint to a solid pink color
   // Fill the path
   variable tCirclePath as Path
   put circle path centered at point [my width / 2, my height / 2] with radius ((my width - mMargin)/2) into tCirclePath
   set the paint of this canvas to solid paint with color [1, 0, 1]
   fill tCirclePath on this canvas
end handler

public handler setMargin(in pMargin as real) as undefined
	put pMargin into mMargin
	redraw all
end handler
	
end widget
```

### Loading and Saving widget data
When you widget is created you are sent a *OnSave* message. It has the following structure and expects and array return type. You can fill this array with whatever widget data you have. LiveCode saves this data along with instances of the widget in the stack file.

```
public handler OnSave(out rProperties as Array)
	put the empty array into rProperties
	
	put mMargin into rProperties["margin"]
	
	return rProperties
end handler
```

This same array will be returned to you when the widget is next opened.

```
public handler OnLoad(in pProperties as Array)
	put pProperties["margin"] into mMargin
end handler
```

### Understanding Error Messages
Clicking on the "test" button causes the extension builder to compile your source code file (***.lcb***) and produce a compiled module file (***.lcm***). If an error is encountered it is output in the "console" section of the builder:

```
Error: <source path>: <line number>: <char number>: <error message>
```

* *source path* - The path the .lcb file that is being compiled
* *line number* - The line number in the script on which the error occurred.
* *char number* - The character number on which the error occurred. 
* *error message* - The description of the error.

### LiveCode Builder API
To start creating more complex widgets see the LiveCode Builder api in the documentation stack in the IDE.

![enter image description here](images/extensions-canvas-docs.png)

1. Open the dictionary
2. API chooser
3. Choose the "LiveCode Builder" API
4. The list of all the syntax available

### Creating Libraries
A extension library is written in much the same way as the above widget. The only difference is that all the public handlers implemented are loaded into the engine on startup.

### Loading and Creating Widgets Manually
To load a compiled library file call:

```
load extension <filepath.lcm>
```

To create a widget from script call:

```
create widget <name> as <identifier>

e.g.

create widget "myWidget" as "com.livecode.extensions.waddingham.clock" 
```

### Composed Widgets
Widgets can either be 'host' widgets, as in the previous example, created when a widget is directly embedded in a stack, or 'child' widgets which are created when a widget is used as a child widget within another widget.
The syntax for composed widgets is included in the com.livecode.widget module.

### A simple composed widget
This composed widget example composes the clock widget and the selector widget, to create a version of the clock widget with adjustable time zone.
![enter image description here](images/extensions-widget-first.png)
The label at the top of the widget reflects which portion of the widget the mouse is over.

```
widget com.livecode.extensions.example.simplecomposed

use com.livecode.canvas
use com.livecode.widget

metadata title is "Simple Composed Widget"
metadata author is "LiveCode"
metadata version is "1.0.0"

private variable mInsideChild as String
private variable mInside as Boolean

private variable mSelector as Widget
private variable mClock as Widget

public handler OnCreate()
    put false into mInside
    put the empty string into mInsideChild

    put a new widget "com.livecode.extensions.livecode.selector" into mSelector
    set property "numSelections" of mSelector to 6
    set annotation "Name" of mSelector to "Selector"

    put a new widget "com.livecode.extensions.livecode.clock" into mClock
    set annotation "Name" of mClock to "Clock"

    place mSelector
    place mClock
end handler
```
Notice that Widget is a variable type. This widget stores references to its child widgets in private variables.
In the OnCreate handler, the widget objects are created, stored in the private variables and 'placed'. Child widgets can be stored as variables and manipulated without actually being drawn to a canvas if they are unplaced.
Properties implemented by child widgets can be got and set using the ```property <propName> of <child widget>``` syntax.
Placing a widget ensures that they are drawn, in placement order. Setting an annotation of a child widget assigns it a tag so that when an unknown child widget is returned by an operator, its annotation can be used to identify it.

```
public handler OnMouseEnter()
    put true into mInside
    
    if the target is not nothing then
        put annotation "Name" of the target into mInsideChild
    end if

    redraw all
end handler

public handler OnMouseLeave()
    if the target is not nothing then
        put the empty string into mInsideChild
    end if

    put false into mInside

    redraw all
end handler
```

In the *OnMouseEnter* and *OnMouseLeave* handlers, *the target* is used to obtain a reference to the child widget that triggered the *OnMouseEnter* and *OnMouseLeave* events, and the previously assigned annotation put into the mInsideChild variable, which in turn is rendered to the canvas in the *OnPaint* handler.

```
public handler OnPaint()
    set the paint of this canvas to solid paint with color [0.75, 0.75, 0.75]
    fill rectangle path of my bounds on this canvas
    
    if mInside then
        set the paint of this canvas to solid paint with color [1.0, 0.0, 0.0]
        set the stroke width of this canvas to 4.0
        stroke rectangle path of my bounds on this canvas
    end if
    
    if mInsideChild is not the empty string then
        set the paint of this canvas to solid paint with color [0.0, 0.0, 0.0]
        fill text mInsideChild at top of my bounds on this canvas
    end if
end handler
```

The rectangle of each child widget is controlled using the following syntax:
* ```the rectangle of <widget>``` - Enables manipulation of the rectangle property of a child widget.
* ```the width of <widget>``` - Enables manipulation of the width property of a child widget.
* ```the height of <widget>``` - Enables manipulation of the height property of a child widget.
* ```the location of <widget>``` - Enables manipulation of the location property of a child widget.

```
public handler OnGeometryChanged()
    set the rectangle of mSelector to rectangle [ 0, 20, my width, 50 ]
    set the rectangle of mClock to rectangle [ 0, 50, my width, my height ]
end handler
```

Finally, messages posted by child widgets can be handled in the direct parent by handling the appropriate message (prepending 'On'). For example, the selector widget posts *optionChanged* when one of its numbers is selected. This is handled by this composed widget example in an *OnOptionChanged* handler.

```
public handler OnOptionChanged(in pIndex)
    set property "timeZone" of mClock to pIndex - 1
end handler
```
## Documenting Your Extension
### Adding API Markup
Any extension can include an API. To do so, either add a file called *api.lcdoc* to your widget folder alongside the other widget files or markup your source code inline.

Marking up your scripts is simple and follows a similar model to other documentation formats.

Consider the following handler
```
public handler myHandler(in pString as String, in pNumber as Number)
   # Code 
end handler
```

To add an entry to the API for this handler, place a formatted comment above the handler definition:

```
/*
summary: Use this handler to do an action
pString: This parameter does x
pNumber: This parameter does y
description:
# Markdown Title
Here is a full description in markdown for how this function works. Once again, any GitHub flavoured markdown is accepted.
*/
public handler myHandler(in pString as String, in pNumber as Number)
   # Code 
end handler
```

The LiveCode API parser will combine the comment items with other data pulled directly from your handler definition such as name, type and some parameter details.

For a full list of acceptable documentation elements please see the documentation section in the specifications below.

> **Important:** Documentation is only added to the LiveCode dictionary when a full extension package is installed. Currently, this is only possible through the extension manager / online extensions portal.

### Adding a User Guide
Any extension can include a user guide. To do so, add a markdown file called *guide.md* to your widget folder alongside the other widget files.

All GitHub flavoured markdown is accepted.

# Packaging Extensions
Packaging extensions is easy. Simply open the "Extension Builder" stack:

```
Tools > Extension Builder
```

Load your ***.lcb*** file and click "Build Package". A new file will appears in the same directory as your main file with the extension ***.lce***. This is your final package file ready for upload to the extensions portal.

## Package requirements
A valid package can be built from a minimum set of files:

```
widget.lcb // Widget source file
support/icon.png // 20x40 png image
support/icon@extra-high.png // 40x80 png image
```

# Sharing Extensions
Once you've created a ***.lce*** package you are ready to upload it to the extensions portal.

## 1) Login
Go to http://ng.livecode.com/login/ and login. The user credentials are the same ones you use on the main LiveCode website or when activating a commercial LiveCode license.

![enter image description here](images/extensions-site-login.png)

## 2) Select a Developer ID
In order to ensure that every extension publisher has a unique ID we use a reverse domain name notation. You will be required to select a unique developer ID that will be associated with your account:

```
community.livecode.<developer_name>
```

For example:
```
community.livecode.beaumont.pinkcircle.1.0.0
```

When logging in for the first time you will be asked to choose a unique *developer_name*. This is a one time step which will be added to your user account and used for all subsequent visits. 

![enter image description here](images/extensions-id.png)

> **Note:** When uploading a package to the online portal it must have a matching identifier. So if you chose the developer name "mickey", it must start "community.livecode.mickey".

> **Future:** We plan to add the ability to register your own domains in future. This will allow you to upload widgets with custom identifiers: "com.beaumont.pinkcircle.1.0.0".



## 3) Add a New Extension

Once logged in you will be taken to your extensions account page:

![enter image description here](images/extensions-site-account.png)

1. To upload a new package click on the "Add New Extension" button
2. A list of extensions you've previously uploaded are listed here. 

> Note: if you created a new version of an existing extension, follow the same upload steps. Your package will be recognised as a new version of the existing widget.

## 4) Upload Your Package

![enter image description here](images/extensions-site-upload.png)

1. Click to browse to your package file.
2. Drag your package file anywhere within the grey dashed box

## Extending the LiveCode IDE

The LiveCode IDE (integrated development environment) has been written using LiveCode. All the components – the Tools Palette, Property Inspector, Script Editor, Debugger, etc., are implemented as LiveCode stacks. The IDE has a series of library frontScripts and backScripts it uses to provide functionality both for the IDE and for your application. Some of these libraries are used only by the IDE (e.g. the debugger library), others (e.g. the Internet library, libURL) are copied into your standalone by the standalone builder.

This design makes it easy to extend the IDE with plug-ins. If you are an advanced LiveCode developer you can also edit the IDE itself to provide custom functionality.

### Creating Plug-ins

You can create a plug-in to help perform tasks that you need to do regularly in the LiveCode IDE. Plug-ins are written as LiveCode stacks. (If you need to extend LiveCode using a lower level language, see the section on *Externals*, below.)

To create a plug-in, save your stack into the Plugins folder, located within the My LiveCode [Edition] folder, inside your Documents folder.

You can now load your stack by choosing its name from the Development -\> Plugins submenu. By default your plug-in will be loaded as a palette. This allows you to operate the controls in the plug-in while the LiveCode IDE is in pointer tool mode. This allows you to create custom "Property Inspector" style behaviors or other object editing tools.

**The Plugin Settings Screen**

Open the Plugin settings screen from the Development -\> Plugins submenu. Choose the plugin you have created from the Plugin menu at the top of the screen to apply settings to it.

![](images/image118.png)

Figure 84 – The Plugin Settings Screen

**Open plugin when:**

By default your plugin will load when you chose it from the plugins menu. If you want to have your plugin load whenever you start LiveCode select the "LiveCode starts up". Use this if your plugin is used to set up your environment, for example by loading stacks that you are working on or adjusting window layout. To have your plugin load when LiveCode quits choose "LiveCode quits". Use this if your plugin performs clean up tasks that you want to have run whenever you exit.

**Open as:**

Choose the mode you want your plugin to open as. If you choose the invisible option, your plugin stack will be loaded invisible. Use this option to create a plugin that installs a faceless library (for example by inserting a button within it into the front or backscripts) or to perform some other automated task that does not require a visible user interface.

> **Note:** Loading from your plugin will not allow you to edit the plugin itself. If you want to edit the plugin, first load it from the menu then use the Application Browser to make it toplevel by right clicking on it in the list of stacks and choosing Toplevel from the popup menu.

**Send messages to plugin:**

In order to have your plug-in respond as you work in the IDE you need to register it to receive messages. The IDE can send a variety of messages to the current card in your plug-in as you change selection, switch tools, open and close stacks, etc. The messages that can be sent are listed below.

| Message                  | Sent when                                       |
|--------------------------|-------------------------------------------------|
| revCloseStack            | The user closes a stack in the IDE              |
| revEditScript            | The user chooses "edit script"                  |
| revIDChanged             | The ID of an object is changed                  |
| revMouseMove             | The mouse is moved                              |
| revMoveControl           | A control is moved with the pointer tool        |
| revNameChanged           | The name of an object is changed                |
| revNewTool               | A new tool is chosen                            |
| revPreOpenCard           | A preOpenCard message is sent on changing card  |
| revPreOpenStack          | A preOpenStack message is sent on opening stack |
| revResizeControl         | A control is resized using the pointer tool     |
| revResizeStack           | A stack is resized                              |
| revResumeStack           | A stack is activated                            |
| revSaveStackRequest      | The save command is executed                    |
| revSelectedObjectChanged | The selection is changed with the pointer tool  |
| revSelectionChanged      | The text selection is changed                   |
| revShutdown              | LiveCode is quit                                |

> **Tip:** Internally the IDE implements these plugin messages by intercepting system messages sent my LiveCode in the IDE frontScripts and backScripts then sending out a corresponding message to any loaded plugin. You can look up these messages in the LiveCode Dictionary by removing the "rev" in front of the messages above.

For example, to have your plugin update whenever an object is selected with the pointer tool, select the `revSelectedObjectChanged`message. Then insert the following handler into your plugin card script:

```
on revSelectedObjectChanged
	-- store the list of selected objects
	put the selObj into tObjectsList
	repeat for each line l in tObjectsList
		-- insert code to operate on each object here
	end repeat
end revSelectedObjectChanged
```

### Editing the IDE

> **Caution:** Editing the IDE can easily cause LiveCode to become unusable. We recommend that only advanced users attempt to edit the IDE. We recommend you back up the IDE prior to making any changes. We do not recommend attempting to edit the IDE while working on any mission critical project.

To edit the LiveCode IDE, turn on *LiveCode UI Elements in Lists* in the *View* menu. This causes LiveCode to display its own stacks within the Application Browser and other editing screens. You can now load these stacks to edit them. To allow you to edit LiveCode IDE objects with the keyboard shortcuts, turn on the *In LiveCode UI Windows* and *Contextual menus work in LiveCode Windows*, options in the *Preferences*.

The IDE uses the stack *revLibrary* to provide much of its functionality. The scripts are stored as a series of buttons and loaded into the `frontScripts`and backScripts when the IDE is started. To edit these scripts, go to the *Front Scripts* or *Back Scripts* tab within the Message Box and check the "Show LiveCode UI Scripts" checkbox.

> **Caution:** If you make a mistake editing revFrontScript or revBackScript, LiveCode will become non-responsive and you will have to force-quit.

The Code Editor and Property Inspector functionality is provided by two stacks, *revTemplateScriptEditor* and *revTemplatePalette*. These stacks are cloned each time you open a new Script Editor or Inspector. To make permanent changes you need to apply the changes to these stacks and save them.


| &nbsp;| &nbsp;| &nbsp;| &nbsp;|
|------|--------|-------|-------|
|**The Development Environment**                                             | **Windows / Linux** | **Mac OS X** |
| Choose run (browse) tool                       | Control-9                               | Command-9                               |
| Choose edit (pointer) tool                     | Conttrol-0                              | Command-0                               |
| Toogle between run and edit tools              | Control-alt-tab                         | Command-option-tab                      |
| Hide or show palettes                          | Control-tab                             | Command-control-tab                     |
| Display context menus when running             | Control-shift-right click               | Command-control-shift-click             |
| Save all open stacks                           | Control-alt-s                           | Command-option-s                        |
| Apply default button in Save dialog            | Return                                  | Return                                  |
| Apply non-default button in save dialog        | Control-1<sup>st</sup> letter of button | Command-1<sup>st</sup> letter of button |

| **Navigation** |     |    |
|------|--------|-------|
| Go to the first card                           | Control-1                               | Command-1                               |
| Go to the previous card                        | Control-2                               | Command-2                               |
| Go to the next card                            | Control-3                               | Command-3                               |
| Go to the last card                            | Control-4                               | Command-4                               |
| Go to the recent card                          | Control-5                               | Command-5                               |
| Go to the top or bottom of a field             | Control-up/down arrow                   | Command-up/down arrow                   |

| **Objects**  |     |    |
|------|--------|-------|
| Select all                                     | Control-a                               | Command-a                               |
| Duplicate                                      | Control-d                               | Command-d                               |
| Create card                                    | Control-n                               | Command-n                               |
| Nudge control                                  | Arrow keys                              | Arrow keys                              |
| Nudge control by 10 pixels                     | Shift-arrow-keys                        | Shift-arrow-keys                        |
| Open object inspector for selection            | Return                                  | Return                                  |
| Open stack inspector                           | Control-K                               | Command-K                               |
| Remove styles from selected text               | Control-;                               | Command-;                               |
| Equalize heights of selected controls          | Control-shift-=                         | Command-shift-=                         |
| Equalize width of selected controls            | Control-=                               | Command-=                               |
| Magnify image with paint tool                  | Control-right-click                     | Command-click                           |
| Apply transparency with paint tool             | Control-click                           | Control-click                           |
| Constrain paint tool selection to a square     | Shift                                   | Shift                                   |
| Constrain object aspect ratio                  | Shift                                   | Shift                                   |

| **The Code Editor**  |     |    |
|------|--------|-------|
| Edit script of selected object                 | Control-e                               | Command-e                               |
| Edit card script                               | Control-shift-c                         | Command-shift-c                         |
| Edit stack script                              | Control-shift-s                         | Command-shift-s                         |
| Edit script of object under mouse              | Control-alt-click                       | Command-option-click                    |
| Apply changes                                  | Enter                                   | Enter                                   |
| Apply changes and close                        | Enter twice                             | Enter twice                             |
| Apply changes and save stack                   | Control-s                               | Command-s                               |
| Comment out selected lines                     | Control-hyphen                          | Command-hyphen                          |
| Remove comments                                | Control-shift-hyphen                    | Command-shift-hyphen                    |
| Switch to find mode                            | Control-f                               | Command-f                               |
| Find next                                      | Control-g                               | Command-g                               |
| Find selected text                             | Control-Option-f                        | Command-Option-f                        |
| Format current handler                         | Tab                                     | Tab                                     |

| **The Message Box** |     |    |
|------|--------|-------|
| Open/close message box                         | Control-m                               | Command-m                               |
| Switch to first tab in message box             | Control-m                               | Command-m                               |
| Clear message field                            | Control-u                               | Command-u                               |
| Scroll through recent messages (single line)   | Up/down arrow                           | Up/down arrow                           |
| Scroll through recent messages (multiple line) | Alt-up/down arrow                       | Option-up/down arrow                    |
| Execute message (single line)                  | Return                                  | Return                                  |
| Execute message (multiple line)                | Enter                                   
| |                                                                                           
| |                                                  Control-Return                           | Enter                                   
| |                                                                                                                                     
| |                                                                                            Control-Return                           |

| **The Debugger** |     |    |
|------|--------|-------|
| Step Into                                      | F11                                     | F11                                     |
| Step Over                                      | F10                                     | F10                                     |
| Step Out                                       | Shift-F11                               | Shift-F11                               |
| Run                                            | F5                                      | F5                                      |
| Stop                                           | Shift-F5                                | Shift-F5                                |
| Abort                                          | Control-.                               | Command-.                               |




### Property Inspector

The property inspector has been rewritten to allow properties of widgets to be inspected and edited. It has been implemented with flexibility and extensibility in mind, since it must be able to control the values of widget properties in any way required by the widget developer. Each property now has a number of attributes which affect how it appears in the inspector.

#### Property Attributes

The following is the list of property attributes:

##### default
The default value of the property. If there is no default value (for example the 'loc' property does not have one), the string "no_default" can be used. The property inspector pops up a contextual menu when editors are right-clicked allowing the user to set the property back to a default value.

##### editor
The editor that will be used to display the value of the property and allow it to be edited. See the dedicated section below for details on property inspector editors. 

##### group
Properties are grouped by themselves in the inspector by default. If a particular group name is specified for a set of properties, their editors are placed next to each other in the inspector.

##### label
The label to use for this property.

##### options
For properties whose value is a choice from a set of options, that set should be specified as a comma delimited list for the options attribute. Default editors are provided for 'enum' type properties (choice of exactly one from a set) and 'set' type properties (choice of zero or more from a set). 

Lists of options can be generated using LiveCode Script for the inspector at run-time, by using the 'execute' syntax - for example the options for the textFont property are generated using
`execute: get the fontNames; sort it`
Whatever remains in the 'it' variable after executing the specified script is used as the list of options.

##### section
The section attribute controls which tab of the property inspector contains the property in question. Currently this is required to be one of the following
* Basic
* Data Grid 
* Custom 
* Table 
* Colors 
* Effects
* Icons
* Position
* Text
* Advanced

But in the future it may be possible to specify custom sections.

##### user_visible
Properties are visible in the property inspector by default. Set the user_visible attribute to false to hide a given property from the user.

### read_only
Read only properties will be displayed in the property inspector but the corresponding editor will have its "editorEnabled" property set to false. See the Editors section below for more details on enabled/disabled editors.

#### Widget Properties

Widget metadata is used to control the display of widget properties in the inspector. Items of metadata which determine property attributes are of the form:

metadata <property>.<attribute> is "<value>"

These are stored as property data for the widget at load time. The <attribute> can be any of those specified in the Property Attributes section above. If the attributes are not specified, their values are as follows:
* default - "no_default"
* editor - "com.livecode.pi.number" for Integer/Real properties, "com.livecode.pi.<type>" for properties of type <type>.
* group - the name of the property
* label - the name of the property
* options - empty
* section - "Basic"
* user_visible - true
* read_only - true if there is no specified 'set' handler or variable for the property, false otherwise.

#### Script Object Properties
Script-level properties of objects (including widgets) are specified in files in the Toolset/resources/supporting_files/property_definitions folder. The propertyInfo.txt file specifies the default values for all the property attributes. Each object type then has a specification of which properties should be displayed in the inspector when it is the selected object, and any options/default/group values which override the defaults.

#### Editors

Currently an editor must be a stack consisting of a group named "template" and a button named "behavior". The property inspector looks up the specified editor for a given property, clones the template group, and sets its behavior to the long id of the button. 

The behavior script must at a minimum implement the following three handlers:

on editorInitialize
on editorUpdate
on editorResize

There are a number of properties available to any editor:
* editorMinWidth
* editorMaxWidth
* editorEnabled
* editorEffective
* editorValue

These should be set or got appropriately. For example, if an editor consists of a text field, the editorUpdate handler should update the value of the field with 'the editorValue of me'. Similarly, if the content of the field changes, the field should call a function in the behavior which sets 'the editorValue of me' to the content of the field.

The editorEnabled and editorEffective properties are set by the generic behavior depending on the property info and the values of the properties. The editorEffective is true if the value of the property in question is empty but there is an effective value in play. The editor should alter the display of its value accordingly.

Editors can specify their min and max width if required.

The following editors are built-in, and available to use for widget properties with common types:

* com.livecode.pi.array - a Tree View widget
* com.livecode.pi.boolean - a check box
* com.livecode.pi.color - a color swatch and dialog
* com.livecode.pi.colorwithalpha - a color swatch and dialog, and alpha value slider
* com.livecode.pi.enum - an option menu
* com.livecode.pi.file - a file selector
* com.livecode.pi.number - a single-line field with optional increment/decrement twiddle and slider
* com.livecode.pi.pattern - a pattern selector
* com.livecode.pi.script - a text field with an object reference, and an edit script button
* com.livecode.pi.set - a field with multi-select list behavior
* com.livecode.pi.string - a single-line field
* com.livecode.pi.text - a multi-line field

There are also some bespoke editors for particular object properties:

* com.livecode.pi.customprops
* com.livecode.pi.datagrid 
* com.livecode.pi.textalign
* com.livecode.pi.textstyle
* com.livecode.pi.navbar
* com.livecode.pi.graphiceffect
* com.livecode.pi.gradient
* com.livecode.pi.timezone

It is our intention that ultimately a widget alone will be able to function as a property editor, however currently this feature is not available.

# Other ways to extend the Built-in Capabilities

There are many other ways to extend LiveCode. This section explains how to run shell commands, start other applications, read and write to processes, execute AppleScript, VBScript, send and respond to AppleEvents and communicate between multiple LiveCode-based processes. It also tells you where to get information to create external commands and functions (code written in lower level languages).

## Communicating with other process and applications

### Reading and writing to the command shell

Use the **shell** function to run shell commands and return the result. The following example displays a directory listing on Mac OS X:

```
answer shell("ls")
```

And this example stores a directory listing in a variable on Windows:

```
put shell("dir") into tDirectory
```

On Windows systems you can prevent a terminal window from being displayed by setting the **hideConsoleWindows** global property to true.

You can choose a different shell program by setting the **shellPath** global property. By default this is set to "/bin/sh" on Mac OS X and Linux and "command.com" on Windows.

> **Tip:** The shell function blocks LiveCode until it is completed. If you want to run a shell command in the background, write the shell script to a text file then execute it with the `launch`command.

### Launching other applications

Use the **launch** command to launch other applications, documents or URLs. To launch an application, supply the full path to the application. The following example opens a text document with TextEdit on OS X:

```
launch "/Users/someuser/Desktop/text document.rtf" with "/Applications/TextEdit.app"
```

> **Tip:** To get the path to an application, use the `answer file` command to select the application then copy it into your script. Run this in the message box: `answer file "Select an application"; put it`

To open a document with the application it is associated with use the **launch document** command.

```
launch document "C:/My document.pdf"
```

To open a URL in the default web browser, use the **launch URL** command.

launch URL "<http://www.livecode.com/>"

For more information on launching URLs see chapter 12. For details on how to render web pages within LiveCode, see the section on *revBrowser*.

### Closing another application

Use the **kill process** command to send a signal to another application, to close it or to force it to exit. For more details, see the LiveCode Dictionary.

### Communicating with other processes

Use the **open process** command to open an application or process you want to read and write data from. You can then read from the process with the **read from process** command and write to it with the **write to process** command. To close a process you have opened, use the **close process** command. The **openProcesses** returns a list of processes you have opened and the **openProcessIDs** returns the process IDs of each one. For more details see the *LiveCode Dictionary*.

### Using AppleScript and VBScript (Open Scripting Architecture or Windows Scripting Host)

To execute commands using AppleScript on Mac OS or VBScript on Windows, use the **do as** command. **do as** also allows you to use any other *Open Scripting Architecture* languages on Mac OS or languages installed into the *Windows Scripting Host* on Windows. To retrieve a list of the available installed languages, use the **alternateLanguages**.

For example, to execute an AppleScript that brings the Finder on OS X to the front, enter the following into a field:

*tell application "Finder"*
*activate*
*end tell*

Then run:

```
do field 1 as "appleScript"
```

To retrieve a result from commands executed using `do as`, use `the result` function. Any error message will also be returned in `the result`. The following example displays `the result` of an addition performed using VBScript:

```
do "result = 1 + 1" as "vbscript"
answer the result
```

For more information on the do as command, see the LiveCode Dictionary.

### AppleEvents

To send an AppleEvent, use the **send to program** command.

If LiveCode receives an AppleEvent it will send an **appleEvent** message to the current card. Intercept this message to perform actions such as handling a request to quit your application or opening a document. The following example shows how you could handle a request to quit:

```
on appleEvent pClass, pID, pSender
	if pClass & pID is "aevtquit" then
	-- call a function that prompts the user to save changes
	put checkSaveChanges() into tOkToQuit
	-- returns false if the user presses "cancel"
	if tOkToQuit is true then quit
	else exit appleEvent
	end if
end appleEvent
```

To retrive additional information passed with the appleEvent use the **request appleEvent data** command. The following example shows how you could handle a request to open a stack:

```
on appleEvent pClass, pID, pSender
	--appleEvent sent when stack is opened from the finder
	if pClass & pID is " aevtodoc " then
		-- get the file path(s)
		request AppleEvent data
		put it into tFilesList
		repeat for each line l in tFilesList
			go stack l
		end repeat
	end if
end appleEvent
```

For more details see the *LiveCode Dictionary*.

### Using Local sockets

If you want to communicate between local applications a common technique that can be used without code changes on all the platforms LiveCode supports, is to open a local socket and communicate using that. You should choose a port number that is not used by a standard protocol – typically a high number.

This technique is commonly used when you want to create multiple programs that run independently but communicate with each other. It is a viable technique for running background tasks and provides a straightforward way to create an application that behaves as if threaded – i.e. with benefits of multiple threads. You can design your application such that additional instances can be launched to perform processing, data transfer or other intensive activities. Modern OSes will allocate each application to an appropriate processor core. By using socket messaging to communicate with each one you can keep your main application's user interface responsive and display status information. The following example shows you how to open a socket to the local machine:

```
open socket to "127.0.0.1:10000" with message gotConnection
```

A detailed discussion of how to create a protocol using sockets can be found in chapter 12.

> **Tip:** To simplify communication between multiple LiveCode programs, consider writing a simple library that sends and receives a handler name together with parameter data. To call a handler in the other LiveCode program, send the handler name and data to the library. The library will send the data over a socket. In the receiving program intercept the incoming data from the socket and use it to call the appropriate message with the parameter data received.

## Externals – code written in lower level languages

LiveCode provides an external interface which allows you to extend it using a lower level language (often C). For example, if you have preexisting code that performs processing in a lower level language, you can write a user interface in LiveCode and then call this library by writing a simple wrapper around it using LiveCode's externals interface. LiveCode supports transmitting data to and from externals, as well as drawing into image objects within LiveCode windows, manipulating the player object, and more.

> **Note:** Some aspects of the built in functionality are supplied in the form of externals. These include the SSL library, the database library, the revBrowser library, zip library, video grabber and XML libraries. These libraries can be included in a standalone application, or excluded if they are not needed – saving disk space.

### The Externals SDK

We provide a developer kit for writing externals which includes documentation and examples. You may download this kit from:

<http://downloads.runrev.com/resources/externals/revexternalssdk.zip>

The following newsletter articles will also help you get started:

* [External Writing for the Uninitiated – Part 1](http://newsletters.livecode.com/november/issue13/newsletter5.php)

* [External Writing for the Uninitiated – Part 2](http://newsletters.livecode.com/november/issue14/newsletter3.php)

* [Writing Externals for Linux with 2.9 or later](http://newsletters.livecode.com/october/issue34/newsletter1.php)