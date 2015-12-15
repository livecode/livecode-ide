[toc]

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

## IDE Changes

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