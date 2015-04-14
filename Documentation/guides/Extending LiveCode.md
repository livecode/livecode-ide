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
A number of palettes have been replaced and new ones added in order to support extensions. The tools palette, message box and property inspector have been rewritten. An extension manager stack has been added to keep track of installed extensions, and a plugin added to help users create their own extensions.

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

We have provided a new "Widget Builder" plugin to help make development and packaging of extensions as easy as possible. 

> **Note:** LiveCode Builder is a different flavour of LiveCode so it is not possible to edit LiveCode Builder scripts in the main LiveCode Script IDE.

## Widget Builder Plugin

Open the "Widget Builder" plugin for the development menu:

```
Development > Plugins > Widget Builder
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
Start by creating a plain text file and save it do disk with the extension "lcb":

```
/Desktop/widgettest/main.lcb
```

Now open the plugin as shown above and click on the load icon to load your freshly created ***.lcb*** file into the builder. You can now start authoring your first extension.

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
com.livecode.Widget|Optional|Contains syntax specific to widget building such as "my width" and "the mouse position".
com.livecode.Engine|Optional|Contains syntax for all extension building such as "dispatch" and "log".
com.livecode.stream|Default|
com.livecode.file|Default|
com.livecode.mathfoundation|Default|
com.livecode.array|Default|
com.livecode.list|Default|
com.livecode.arithmetic|Default|
com.livecode.binary|Default|
com.livecode.bitwise|Default|
com.livecode.byte|Default|
com.livecode.char|Default|
com.livecode.date|Default|
com.livecode.logic|Default|
com.livecode.math|Default|
com.livecode.sort|Default|
com.livecode.string|Default|
com.livecode.system|Default|
com.livecode.type|Default|

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
onPaint|The *onPaint* message is sent to your widget whenever LiveCode requires it to redraw. The performance of you widget is tied primarily to this handler and should be kept as efficient as possible.
onCreate|The *onCreate* message is sent to your widget when it is first created by LiveCode. This can be used to initialise default data and where applicable, reduce the burden for calculating constants etc in the onPaint handler.
onGeometryChanged| The *onGeometryChanged* message is sent when the control is changed in size.
onSave| The *onSave* message is sent when your widget is about to be destroyed and enables the widget to save data set on the widget.
onLoad| The *onLoad* message is sent when your widget is created and enables the widget to retrieve data saved on the widget.

For the most basic example, only the onPaint() handler is required.

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

![enter image description here](images/extensions-widget-first.png)

1. Notice that I'm using textWrangler
2. Click test
3. Your widget should be displayed on the new stack. If you can't see it, check behind the extension plugin.

> Note: There is a colorising script for textWrangler here: https://github.com/runrev/livecode/tree/develop/contrib/TextWrangler. It should be placed in /Application Support/TextWrangler/Language Modules/


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
Packaging extensions is easy. Simply open the "Widget Builder" plugin:

```
Development > Plugins > ExtensionBuilder
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

# Specifications
## Documentation Markup

Documentation for a LiveCode API or documentation entry consists of a series of elements and their values, in the following form:

*elementName* : *content*

An API for an extension is automatically added to the library dropdown menu in the dictionary.

There are several standard types of *content*; which one may be used depends on the *elementName*.

### Element names

Elements are optional unless otherwise specified.

#### Name (required)
The name of the API entry. The name must be a single word.
>*Note:* For inline docs, the name element is automatically generated

#### Synonyms
A comma-delimited list of synonyms for this API entry.

#### Type (required)
The type of this API entry. One of the following:
(API-level)
	* command
	* function
	* property
	* message
	* constant
	* keyword
	* control structure
	* operator
	* statement
	* expression
	
(Glossary-level)
	* library
	* widget
	* glossary
	* object

The glossary-level entries have part of their content generated from the API-level entries.

>*Note:* For inline docs, the type element is automatically generated

#### Syntax (required for API-level entries)
A description of how to use or call this facet of the API. May just be the name itself, for keywords etc.
An entry may have a number of Syntax elements, if there are variations within the same entry.

>*Note:* For inline docs, the Syntax elements are automatically generated

#### Summary (required)
A summary of the API entry being documented. The summary should be a single line. Anything more in-depth should be included in the description.

#### Associated
A comma-delimited list of names of other API or docs entries. Each one must be of type **object**, **glossary**, **library**, or **widget**. It is used to generate the docs for the entries to which it is associated.

In particular, every API entry in a library should have that library name in its Associated list.

#### Introduced
The LiveCode version in which the API entry was first available.

#### OS
A comma-delimited list specifying which operating systems the API entry is available for. One or more of the following:

* mac
* windows
* linux
* iOS
* android
* RPi

#### Platforms
A comma-delimited list specifying which platforms the API entry is available for. One or more of the following:

* desktop
* server
* web
* mobile

### Example
Example elements should show how API entries are used in context. Each example with be displayed in the documentation viewer as a multiline code block. Where possible, an example should be entirely self contained, so that it is runnable as a block of code without any additions.

An API entry can have any number of Example elements. 

#### Parameters
The parameters element itself does not do anything, but can be helpful for readability as a precursor to the parameter elements themselves.
Parameter elements are specified in the following way:
*paramName* (*paramType*) : *paramDescription*

The param type is optional, although may be helpful to include, and is required for further formatting of parameter descriptions to take place. The three types that will instigate further formatting are:

* enum
* set
* array

A parameter of **enum** type is one that expects one of a specified list of values. Similarly, a parameter of **set** type is one that expects a comma-delimited list of one or more of a specified list of values. After the param description of the **enum** or **set** type, these values should be listed in the following way
```
	- value1 : description of value1
	- value2 : description of value2
	- ...
```
etc.

After the description parameter of **array** type, the format of the array may optionally be specified in the following way:

```
{ 
	key1 (keyType) : description of key1
	value1 (valueType) : description of value1
	key2 (keyType) : description of key2
	value2 (valueType) : description of value2
	...
}
```
The key type and value type are optional. If one of the values is a sub-array, and the **array** type is specified, then the array specification may be nested as follows:

```
{ 
	key1 (keyType) : description of key1
	value1 (array) : description of value1
	{
		key2 (keyType) : description of key2
		value2 (valueType) : description of value2
		...
	}
	...
}
```
The indentation is not necessary, but is helpful for readability.

#### Value and return parameters
For simple return parameters, i.e. the direct return value of a function, use the Returns element.
When a value is both an input and output value, for example the value of a property, use the Value element.
The Returns and Value elements are mutually exclusive.

Some functions and commands in LiveCode change the value of 'the result' and the 'it' variable. In these cases there are also special return parameter elements It and The result.

All of these elements can have a type specified in brackets before the colon, as for parameter elements. The same comments about formatting apply to return parameters.

#### Description (required)
A full description of the API entry. The description may have markdown elements which will be rendered in the documentation viewer.

### References
A comma-delimited list of other API or docs entries that are referenced. The references element is essential for linking around the documentation viewer.

The references list should be in the form:
>*entryName* (*entryType*), *entryName* (*entryType*), *entryName* (*entryType*), ...

#### Tags
A comma-delimited list of tags for this entry. The documentation viewer can filter entries by tag.

### Other documentation syntax
The Description element is the only one that allows standard markdown. There is only (essentially) one other syntactic form allowed in API documentation, which is enclosing text in angle brackets <>. There are three purposes of the angle brackets syntax:

* Specifying occurrences of the name of the current API entry.
* Specifying occurrences of the names of parameters.
* Specifying links to other API entries or documentation.

In the first two cases, applying the syntax merely consists in enclosing the relevant occurrences in angle brackets, eg to reference a parameter *pParam* in the entry named *thisEntry*,
>This is a sentence in which &lt;pParam&gt; ought to be marked as being a parameter in the API entry for &lt;thisEntry&gt;

To specify a link to another API or docs entry, the latter **must** be included in the References element. If there is only one item in the References element with a matching name, then it suffices to enclose the referencing text in angle brackets.
>This will link correctly to the &lt;other&gt; function's API entry provided the References element contains only one item with the name "other".

If the referencing text is different from the name of the entry, such as if it is pluralised or possessive, include the referenced entry name as a label inside the angle brackets.
> This will also link correctly to &lt;other|other's&gt; API entry, but display as "other's" in the documentation viewer.

If the target name is shared by two references, then the link should be disambiguated by including the type in brackets:
> We might want to link to the &lt;other(function)&gt; function and the &lt;other(command)&gt; command in the same entry, if the references contain "other (function)" and "other (command)".

It is possible to do both of the above at the same time:
> This sentence contains links to &lt;other(function)|other's&gt; and &lt;other(command)|other's&gt; dictionary entries.

### Separate docs files
To specify the documentation for a library in one separate file, it must have the following structure:

Library: *libraryName*

Summary: *librarySummary*

Description:
*libraryDescription*

Name: *entryName*

Type: *entryType*

Syntax: *entrySyntax*

Summary: *entrySummary*

...other elements associated with *entryName*...

Name: *anotherEntryName*
etc.

### Inline documentation
Documentation for LiveCode script and LiveCode extensions can be done in-line. In this case, the Name, Type, Syntax and Associated elements are auto-generated. 

The code-block enclosed in /* */ immediately preceding the handler or syntax definition is used for the other elements of the documentation for that entry. In LiveCode extensions, the types of parameters are also pulled from the associated handler.

### Separate docs files examples

#### Dictionary example
Here is the dictionary document for the *textEncode* function:

```
Name: textEncode

Type: function

Syntax: textEncode(<stringToEncode>, <encoding>)

Summary: Converts from text to binary data.

Introduced: 7.0

OS: mac,windows,linux,ios,android

Platforms: desktop,server,web,mobile

Example:
textEncode("A","UTF16")

Example:
put textEncode(field "output","UTF-8") into tOutput
put tOutput into url ("file:output.txt")

Parameters:
stringToEncode (string): Any string, or expression that evaluates to a string.
encoding (enum): the encoding to be used
- "ASCII"
- "ISO-8859-1": Linux only
- "MacRoman": OS X only
- "Native": ISO-8859-1 on Minux, MacRoman on OS X, CP1252 on Windows
- "UTF-16"
- "UTF-16BE"
- "UTF-16LE"
- "UTF-32"
- "UTF-32BE"
- "UTF-32LE"
- "UTF-8"
- "CP1252"

Returns: Returns the <stringToEncode> as binary data.

Description:
Converts from text to binary data.

The <textEncode> function takes text, and returns it as binary data, encoded with the specified encoding.

It is highly recommended that any time you interface with things outside LiveCode (files, network sockets, processes, etc) that you explicitly textEncode any text you send outside LiveCode and <textDecode> all text received into LiveCode. If this doesn't happen, a platform-dependent encoding will be used (which normally does not support Unicode text).

It is not, in general, possible to reliably auto-detect text encodings so please check the documentation for the programme you are communicating with to find out what it expects. If in doubt, try UTF-8.

References: textDecode.function
```

#### Library example

```
Module: com.livecode.sort

Type: library

Description: This library consists of the sorting operations provided by the standard library of LiveCode Builder


Name: SortListDescendingText

Type: statement

Syntax: sort <Target> in descending [text] order


Summary: Sorts <Target> in descending text order.
Parameters:
Target (inout list): An expression that evaluates to a list of strings. 
Example:     
	variable tTestList as List
    put the empty list into tTestList

    push "abcd" onto tTestList
    push 1 onto tTestList
    push "xyz" onto tTestList
    push 2 onto tTestList

    sort tTestList in descending order -- tTestList is ["xyz", "abcd", 1, 2]


Description: Text sort is performed by comparing string elements on a codepoint by codepoint basis. Non-string elements come after all string elements in the sort order. The sort is stable, so that non-string elements are not re-ordered relative to each other.


Tags: Sorting

Name: SortListAscendingText

Type: statement

Syntax: sort <Target> in ascending [text] order
```
### Inline examples

In general, writing inline docs has fewer requirements since several of the elements are auto-generated.

#### LiveCode Builder syntax example

```
/*  
This library consists of the operations on lists included in the standard library of LiveCode Builder.
*/

module com.livecode.list

/*
Summary:        Returns the first element of <Target>.
Target:         An expression which evaluates to a list.
output:			The first element of <Target>

Example:
	variable tVar as List
	put the empty list into tVar
	push "first element" onto tVar
	
	variable tResult as Boolean
	if the head of tVar is "first element" then
		put "success" into tResult
	end if
	
Description:
Returns the first element of the list <Target> without modifying <Target>.
\`\`\`	the head of tVar\`\`\`
is equivalent to using the <IndexedElementOfList> operator with index -1,
\`\`\`	tVar[1]\`\`\`
	
References: IndexedElementOfList(operator)

Tags: Lists
*/

syntax HeadOfList is prefix operator with precedence 1
    "the" "head" "of" <Target: Expression>
begin
    MCListEvalHeadOf(Target, output)
end syntax

end module
```

#### LiveCode Builder handler example
```
/*
Summary: Logs the result of a test to the <xResults> list

Parameters:
pModule: The name of the module this test comes from.
pTest: The name of the test.
pResult: The result of the test
xResults: The ongoing list of test results

Description:
Pushes either the string "SUCCESS : <pModule>_<pTest>" or the string "FAILURE : <pModule>_<pTest>" onto the results list,
depending on the value of <pResult>

*/

public handler testLog(in pModule as String, in pTest as String, in pResult as Boolean, inout xResults as List)
    variable tStringResult as String
    if pResult then
        put "SUCCESS" into tStringResult
    else
        put "FAILURE" into tStringResult
    end if

    push tStringResult && ":" && pModule & "_" & pTest onto xResults
end handler
```
#### LiveCode script handler example
```
/*
Summary: Extracts the inline docs from a .lcb file

pFile: The path to the .lcb file to extract docs from

Returns (string): A string consisting of all the docs for the library, and the syntax and handlers present in the .lcb file

Description:
<revDocsGenerateDocsFileFromModularFile> is used when packaging a widget to create its API documentation.
It generates the Library and Type elements from the declaration in the <pFile> (either widget or library), and extracts
the comment block that precedes any initial declaration for use as the library-level Description element.
It then extracts the comment blocks that precede syntax and handler definitions in <pFile>, and generates the 
Name, Type, Syntax, and Associated elements for each entry, as well as the parameter types.

Tags: Package building
*/

function revDocsGenerateDocsFileFromModularFile pFile
...
end revDocsGenerateDocsFileFromModularFile
```

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
* com.livecode.pi.enum - an option menu
* com.livecode.pi.file - a file selector
* com.livecode.pi.number - a single-line field with increment/decrement twiddle
* com.livecode.pi.pattern - a pattern selector
* com.livecode.pi.set - a field with multi-select list behavior
* com.livecode.pi.string - a single-line field
* com.livecode.pi.text - a multi-line field

There are also some bespoke editors for particular object properties:

* com.livecode.pi.customprops
* com.livecode.pi.datagrid 
* com.livecode.pi.textalign
* com.livecode.pi.textstyle

It is our intention that ultimately a widget alone will be able to function as a property editor, however currently this feature is not available.

## Livecode Builder Language Guide

### Overview

LiveCode Builder is a variant of the current LiveCode scripting language (LiveCode Script) which has been designed for 'systems' building. It is statically compiled with optional static typing and direct foreign code interconnect (allowing easy access to APIs written in other languages).

Unlike most languages, LiveCode Builder has been designed around the idea of extensible syntax. Indeed, the core language is very small - comprising declarations and control structures - with the majority of the language syntax and functionality being defined in modules.

> **Note:** It is an eventual aim that control structures will also be extensible, however this is not the case in the current incarnation).

The syntax will be familiar to anyone familiar with LiveCode Script, however LiveCode Builder is a great deal more strict - the reason being it is intended that it will eventually be compilable to machine code with the performance and efficiency you'd expect from any 'traditional' programming language. Indeed, over time we hope to move the majority of implementation of the whole LiveCode system over to being written in LiveCode Builder.

> **Note:** One of the principal differences is that type conversion is strict - there is no automatic conversion between different types such as between number and string. Such conversion must be explicitly specified using syntax (currently this is using things like *... parsed as number* and *... formatted as string*.

### Tokens

The structure of tokens is similar to LiveCode Script, but again a little stricter. The regular expressions describing the tokens are as follows:

 - **Identifier**: [A-Za-z_][A-Za-z0-9_.]*
 - **Integer**: [0-9]+
 - **Real**: [0-9]+"."[0-9]+([eE][-+]?[0-9]+)?
 - **String**: "[^\n\r"]*"
 - **Separator**: Any whitespace containing at least one newline

> **Note:** The presence of '.' in identifiers are used as a namespace scope delimiter.

> **Note:** Eventually strings will use '\' as an escaping character allowing things such as \n for newline and \q for quote.

#### Case-Sensitivity

At the moment, due to the nature of the parser being used, identifiers and keywords are all case-sensitive and keywords are reserved. The result of this is that, using all lower-case identifiers for names of definitions should be avoided.

> **Aside:** The current parser and syntax rules for LiveCode Builder are constructed at build-time of the LiveCode Builder compiler and uses *bison* (a standard parser generator tool) to build the parser. Unfortunately, this means that any keywords have to be reserved as the parser cannot distinguish the use of an identifier in context (whether it is a keyword at a particular point, or a name of a definition).

It is highly recommended that the following naming conventions be used for identifiers:

 - **tVar** - for local variables
 - **pVar** - for in parameterns
 - **rVar** - for out parameters
 - **xVar** - for inout parameters
 - **mVar** - for global variables in widgets
 - **sVar** - for global variables in libraries
 - **kConstant** - for constants
 - Use identifiers starting with an uppercase letter for handler and type names.

By following this convention, there will not be any ambiguity between identifiers and keywords. (All keywords are all lower-case).

> **Note:** The intent is that LiveCode Builder scripts will be case-insensitive like LiveCode Script; however this will require the Open Language parser infrastructure which is being developed for the next major version of LiveCode Builder.

### Typing

LiveCode Builder is a typed language, although typing is completely optional in most places (the only exception being in foreign handler declarations). If a type annotation is not specified it is simply taken to be the most general type *optional any* (meaning any value, including undefined).

The range of core types is relatively small, comprising the following:

 - **undefined**: the single value *undefined*
 - **boolean**: one of *true* or *false*
 - **integer**: any integral numeric value (size limitations apply)
 - **real**: any numeric value (size and accuracy limitations apply)
 - **number**: any integer or real value
 - **string**: a sequence of UTF-16 code units
 - **data**: a sequence of bytes
 - **list**: a sequence of any values
 - **array**: a mapping from strings to values
 - **any**: a value of any type

Additionally, all types can be annotated with **optional**. An optional annotation means the value may be the original type or the undefined value.

> **Note:** As it stands *any* does not include the undefined type and so *optional any* makes sense. There is an argument, however, that *any* should be implicitly optional as (technically) the undefined type is also a type. It is possible this aspect might be revised.

> **Note:** The current compiler does not do type-checking; all type-checking happens at runtime. However, this is being worked on so there will soon be a compiler which will give you type errors at compile-time.

### Modules

    Module
        : 'module' <Name: Identifier> SEPARATOR
            { Metadata SEPARATOR }
            { Import SEPARATOR }
            { Definition SEPARATOR }
          'end' 'module'

The smallest compilable unit of LiveCode Builder is the module. Each module is uniquely named using reverse DNS notation, and the names of modules are considered to live in a global namespace.

A module is a collection of public and private definitions, including constants, variables, types and handlers.

A module may depend on another module through import. An imported modules public definitions become accessible to the importing module.

> **Note:** For integration with the existing LiveCode system, there are two module variants which may be used. Widgets (use 'widget' instead of 'module') and Libraries (use 'library' instead of 'module'). A widget appears in LiveCode as a control, whilst a library adds all its public handlers to the bottom of the message path.

### Metadata

    Metadata
        : 'metadata' <Name: Identifier> 'is' <Value: String>

The metadata clauses allow a set of key-values to be encoded in the compiled module. These are not used in compilation or execution, but may be used by the system loading and using the module.

At the moment, the following keys are understood:

 - title: a human-readable name for the module
 - description: a simple description of the module's purpose
 - version: a string in the form X.Y.Z (with X, Y and Z integers) describing the modules version
 - author: the name of the author of the module

> **Note:** The current metadata mechanism is unlikely to remain part of the language. It is intended that it will be replaced by a package description file, which will allow modules to be grouped together with other resources.

### Imports

    Import
        : 'use' <Name: Identifier>

The use clauses allow a module to refer to another module by importing all the target module's public definitions into its namespace.

The name of the module specified must be its full name, e.g. com.livecode.canvas.

A module may use any other module, as long as doing so does not cause a cycle in the dependency graph.

> **Note:** The current IDE and extension installation system does not yet implement arbitrary dependencies - the only dependencies it understands are those which are builtin to the system (e.g. com.livecode.canvas). However, you can still write and test out modules with dependencies locally - they just cannot be uploaded to the extensions portal.

## Definitions

    Definition
      : ( 'public' | 'private' ) ConstantDefinition
      | ( 'public' | 'private' ) TypeDefinition
      | ( 'public' | 'private' ) VariableDefinition
      | ( 'public' | 'private' ) HandlerDefinition
      | ( 'public' | 'private' ) ForeignHandlerDefinition
      | PropertyDefinition
      | EventDefinition

Definitions are what are used to define usable entities in the language. All definitions are named using a unique identifier (so you cannot have two definitions with the same name).

Definitions can be either *public* or *private* (the default is private - so there is no need to explicitly specify that). Public definitions are available when the module is used by another module whereas private definitions can only be used within the module.

> **Note**: Properties and events are, by their nature, always public as they define things which only make sense to access from outside.

> **Note**: When writing a library module, all public handlers are added to bottom of the message path in LiveCode Script.

#### Constants

    ConstantDefinition
      : 'constant' <Name: Identifier> is <Value: Expression>

A constant definition defines a named constant. The value can be any expression which depends on only on constant values to evaluate.

> **Note:** Constants are not currently implemented, although the syntax is recognised.

#### Types

    TypeDefinition
      : 'type' <Name: Identifier> 'is' <TypeOf: Type>

A type definition defines an alias, it names the given type with the given Name, allowing the name to be used instead of the type.

    Type
      : <Name: Identifier>
      | 'optional' <Target: Type>
      | 'any'
      | 'boolean'
      | 'integer'
      | 'real'
      | 'number'
      | 'string'
      | 'data'
      | 'array'
      | 'list'
      | 'undefined'
      | 'pointer'

A type clause describes the kind of value which can be used in a variable or parameter.

If a type is an identifier, then this is taken to be a named type defined in a type definition clause.

An optional type means the value can be either the specified type or undefined.

The remaining types are as follows:

 - **any**: any value
 - **boolean**: a boolean value, either the value *true* or *false*.
 - **integer**: any integer number value
 - **real**: any real number value
 - **number**: any number value
 - **string**: a sequence of UTF-16 code units
 - **data**: a sequence of bytes
 - **array**: a map from string to any value (i.e. an associative array, just like in LiveCode Script)
 - **list**: a sequence of any value
 - **undefined**: a single value *undefined* (this is used to describe handlers with no return value - i.e. void)
 - **pointer**: a low-level pointer (this is used with foreign code interconnect and shouldn't be generally used).

> **Note:** *integer* and *real* are currently the same as *number*.

> **Note:** In a subsequent update you will be able to specify lists and arrays of fixed types. For example, *list of string*.

> **Note:** In a subsequence update you will be able to define record types (named collections of values - like structs in C) and handler types (allowing dynamic handler calls through a variable - like function pointers in C).

#### Variables

    VariableDefinition
      : 'variable' <Name: Identifier> [ 'as' <TypeOf: Type> ]

A variable definition defines a module-scope variable. In a widget module, such variables are per-widget (i.e. instance variables). In a library module, there is only a single instance (i.e. a private global variable).

The type specification for the variable is optional, if it is not specified the type of the variable is *optional any* meaning that it can hold any value, including being undefined.

#### Handlers

    HandlerDefinition
      : 'handler' <Name: Identifier> '(' [ ParameterList ] ')' [ 'as' <ReturnType: Type> ] SEPARATOR
          { Statement }
        'end' 'handler'

Handler definitions are used to define functions which can be called from LiveCode Builder code, invoked as a result of events triggering in a widget module, or called from LiveCode Script if public and inside a library module.

There is no distinction between handlers which return a value and ones which do not, apart from the return type. Handlers can be called either in expression context, or in statement context. If a handler which returns no value (its return type is *undefined*) is called in expression context then its value is *undefined*.

	ParameterList
	  : { Parameter , ',' }

    Parameter
      : ( 'in' | 'out' | 'inout' ) <Name: Identifier> [ 'as' <ParamType: Type>

The parameter list describes the parameters which can be passed to the handler. Handlers must be called with the correct number of parameters, using expressions which are appropriate to the mode.

An in parameter means that the value from the caller is copied to the parameter variable in the callee handler.

An out parameter means that no value is copied from the caller (the parameter variable in the callee handler starts as *undefined*), and the value on exit of the callee handler is copied back to the caller on return.

> **Note:** It is a checked runtime error to return from a handler without ensuring all non-optional 'out' parameters have been assigned a value.

An inout parameter means that the value from the caller is coped to the parameter variable in the callee handler on entry, and copied back out again on exit.

The type of parameter is optional, if no type is specified it is taken to be *optional any* meaning it can be of any type.

> **Note:** Only assignable expressions can be passed as arguments to inout or out parameters. It is a checked compile-time error to pass a non-assignable expression to such a parameter.

#### Foreign Handlers

    ForeignHandlerDefinition
      : 'foreign' 'handler' <Name: Identifier> '(' [ ParameterList ] ')' [ 'as' <ReturnType: Type> ] 'binds' 'to' <Binding: String>

    ForeignType
      : Type
      | 'bool'
      | 'int'
      | 'uint'
      | 'float'
      | 'double'

A foreign handler definition binds an identifier to a handler defined in foreign code.

Foreign handler definitions can contain more types in their parameters than elsewhere - those specified in the ForeignType clause. These allow low-level types to be specified making it easier to interoperate.

Foreign types map to high-level types as follows:

 - bool maps to boolean
 - int and uint map to integer (number)
 - float and double map to real (number)

This mapping means that a foreign handler with a bool parameter say, will accept a boolean from LiveCode Builder code when called.

At present, only C binding is allowed and follow these rules:

 - any type passes an MCValueRef
 - boolean type passes an MCBooleanRef
 - integer type passes an MCNumberRef
 - real type passes an MCNumberRef
 - number type passes an MCNumberRef
 - string type passes an MCStringRef
 - data type passes an MCDataRef
 - array type passes an MCArrayRef
 - list type passes an MCProperListRef
 - undefined type passes an MCNullRef
 - pointer type passes a void *
 - bool type passes a bool (i.e. an int - pre-C99).
 - int type passes an int
 - uint type passes an unsigned int
 - float type passes a float
 - double type passes a double

Modes map as follows:

 - in mode is just pass by value
 - out mode passes a pointer to a variable of one of the above types, the variable is uninitialized on entry
 - inout mode passes a pointer to a variable of one of the above types, the variable is initialized to a value on entry

If the return type is of a Ref type, then it must be a copy.

If an out parameter is of a Ref type, then it must be a copy (on exit)

If an inout parameter is of a Ref type, then its existing value must be released, and replaced by a copy (on exit).
 
The binding string for foreign handlers has the following form:

    [lang:][library>][class.]function[!calling]

Here *lang* specifies the language (must be 'c' at the moment)

Here *library* specifies the name of the library to bind to (if no library is specified a symbol from the engine executable is assumed).

Here *class* is currently unused.

Here *function* specifies the name of the function symbol to bind to (on Windows, the symbol must be unadorned, and so exported from the library by listing it in a DEF module).

Here *calling* specifies the calling convention which can be one of:

 - default
 - stdcall
 - thiscall
 - fastcall
 - cdecl
 - pascal
 - register

All but 'default' are Win32-only, and on Win32 'default' maps to 'cdecl'. If a Win32-only calling convention is specified on a non-Windows platform then it is taken to be 'default'.

Foreign handler's bound symbols are resolved on first use and an error is thrown if the symbol cannot be found.

> **Note:** The current foreign handler definition is an initial version, mainly existing to allow binding to implementation of the syntax present in the standard language modules. It will be expanded and improved in a subsequent version to make it very easy to import and use functions (and types) from other languages including Objective-C (on Mac and iOS) and Java (on Android).

#### Properties

    PropertyDefinition
      : 'property' <Name: Identifier> 'get' <Getter: Identifier> [ 'set' <Setter: Identifier> ]

Property definitions can only appear in widget modules. They define a property which can be accessed from LiveCode Script in the usual way (e.g. *the myProperty of widget 1*).

Both getter and setter clauses can use either a variable or handler identifier. If a variable identifier is used, then the property value is fetched (and stored) from that variable. If a handler identifier is used then a handler is called instead.

A getter handler must take no arguments and return a value. A setter handler must take a single argument and return no value.

The set clause is optional. If it is not present then the property is read-only.

#### Events

    EventDefinition
      : 'event' <Name: Identifier> '(' [ ParameterList ] ')' [ 'as' <ReturnType: Type> ]

Event definitions define a callable handler which calls back to the environment.

> **Note**: Whilst events can be defined they currently cannot be used. To send a message to the LiveCode Script environment use the *dispatch* command which allows sending messages to arbitrary LiveCode Script objects.

### Statements

    Statement
      : VariableStatement
      | IfStatement
      | RepeatStatement
      | ThrowStatement
      | ReturnStatement
      | PutStatement
      | SetStatement
      | GetStatement
      | CallStatement

There are a number of built-in statements which define control flow, variables, and basic variable transfer. The remaining syntax for statement is defined in auxiliary modules.

#### Variable Statements

    VariableStatement
      : 'variable' <Name: Identifier> [ 'as' <TypeOf: Type> ]
      
A variable statement defines a handler-scope variable. Such variables can be used after the variable statement, but not before.

> **Note:** Variables are currently not block-scoped, they are defined from the point of declaration to the end of the handler - this might change in a subsequent revision.

Variables are initially undefined, and if of non-optional type, must be assigned a value before they can be used.

> **Note:** It is a checked runtime error to attempt to use a non-optionally typed variable before it has a value.

The type specification for the variable is optional, if it is not specified the type of the variable is *optional any* meaning that it can hold any value, including being undefined.

#### If Statements

    IfStatement
      : 'if' <Condition: Expression> 'then' SEPARATOR
          { Statement }
        [ { 'else' 'if' <Condition: Expression> 'then' SEPARATOR
            { Statement } ]
        [ 'else' SEPARATOR
            { Statement } ]
        'end' 'if'

The if statement enables conditional execution based on the result of an expression which evaluates to a boolean.

> **Note:** It is a checked runtime error to use an expression which does not evaluate to a boolean in any condition expression.

#### Repeat Statements

    RepeatStatement
      : RepeatHeader SEPARATOR
          { Statement }
        'end' 'repeat'
      | 'next' 'repeat'
      | 'exit' 'repeat'

    RepeatHeader
      : 'repeat' 'forever'
      | 'repeat' <Count: Expression> 'times'
      | 'repeat' 'while' <Condition: Expression>
      | 'repeat' 'until' <Condition: Expression>
      | 'repeat' 'with' <Counter: Identifier> 'from' <Start: Expression> ( 'up' | 'down' ) 'to' <Finish: Expression> [ 'by' <Step: Expression> ]
      | 'repeat' 'for' 'each' <Iterator> 'in' <Container: Expression>

The repeat statements allow iterative execute of a sequence of statements.

The **repeat forever** form repeats the body continually. To exit the loop, either an error must be thrown, or **exit repeat** must be executed.

The **repeat times** form repeats the body Count number times. If Count evaluates to a negative integer, it is taken to be zero.

> **Note:** It is a checked runtime error to use an expression not evaluating to a number as the Count.

The **repeat while** form repeats the body until the Condition expression evaluates to false.

> **Note:** It is a checked runtime error to use an expression not evaluating to a boolean as the Condition.

The **repeat until** form repeats the body until the Condition expression evaluates to true.

> **Note:** It is a checked runtime error to use an expression not evaluating to a boolean as the Condition.

The **repeat with** form repeats the body until the Counter variable reaches or crosses (depending on iteration direction) the value of the Finish expression. The counter variable is adjusted by the value of the Step expression on each iteration. The start, finish and step expressions are evaluated before the loop starts and are not re-evaluated. The Counter variable must be declared before the repeat statement.

> **Note:** It is a checked runtime error to use expressions not evaluating to a number as Start, Finish or Step.

The **repeat for each** form evaluates the Container expression, and then iterates through it in a custom manner depending on the Iterator syntax. For example:

    repeat for each char tChar in "abcdef"
      -- do something with tChar
    end repeat

The **next repeat** statement terminates the current iteration of the enclosing loop and starts the next iteration of the loop, or exits if currently on the last iteration.

The **exit repeat** statement terminates the current iteration of the enclosing loop, continuing execution at the statement after the enclosing loop's **end repeat**.

#### Throw Statements

    ThrowStatement
      : 'throw' <Error: Expression>

The **throw** statement causes an error to be raised. This causes execution to terminate, and the error is passed back to environment.

The Error expression must be an expression that evaluates to a string.

> **Note:** There is currently no try / catch mechanism in LiveCode Builder, so throwing an error will cause the error to be raised in LiveCode Script in the appropriate context.

### Return Statements

    ReturnStatement
      : 'return' [ <Value: Expression> ]

The **return** statement causes execution of the current handler to end, and control return to the caller.

If a Value expression is specified, it is evaluated and returned as the result of the handler call.

> **Note:** It is a checked runtime error for a value returned from a handler to not match the return type of the handler it is in.

#### Transfer Statements

    PutStatement
      : 'put' <Value: Expression> into <Target: Expression>
    
    SetStatement
      : 'set' <Target: Expression> 'to' <Value: Expression>

The **put** and **set** statements evaluate the Value expression and assign the resulting value to the Target expression.

The target expression must be assignable.

> **Note:** It is a checked runtime error for the source value's type to not be compatible with the target expression's type.

    GetStatement
      : 'get' <Value: Expression>

The **get** statement evaluates the Value expression and returns it as the result of the statement. The value is subsequently available by using **the result** expression.

#### Call Statements

    CallStatement
      : <Handler: Identifier> '(' [ <Arguments: ExpressionList> ] ')'

The call statement executes a handler with the given arguments.

The Handler identifier must be bound to either a handler or foreign handler definition.

The Arguments are evaluated from left to right and passed as parameters to the variable.

> **Note:** It is a checked runtime error for the types of 'in' and 'inout' arguments to not match the declared types of the handler's parameters.

Any parameters of 'out' type are not evaluated on entry, but assigned to on exit.

Any parameters of 'inout' type are evaluated on entry, and assigned on exit.

> **Note:** It is a checked compile-time error to pass non-assignable expressions to parameters which are of either 'out' or 'inout' type.

The return value of a handler is subsequently available by using **the result** expression.

> **Note:** All handlers return a value, even if it is undefined. This means that calling a handler will always change **the result**.

### Expressions

    Expression
      : ConstantValueExpression
      | VariableExpression
      | ResultExpression
      | ListExpression
      | CallExpression

There are a number of expressions which are built-in and allow constant values, access to call results, list construction and calls. The remaining syntax for expressions is defined in auxiliary modules.

#### Constant Value Expressions

      ConstantValueExpression
        : 'undefined'
        | 'true'
        | 'false'
        | INTEGER
        | REAL
        | STRING

Constant value expressions evaluate to the specified constant value.

The **undefined** expression evaluates to the undefined value and can be assigned to any optional typed variable.

The **true** and **false** expressions evaluate to boolean values.

The INTEGER and REAL expressions evaluate to numeric values.

The STRING expression evaluates to a string value.

Constant value expressions are not assignable.

#### Variable Expressions

    VariableExpression
      : <Name: Identifier>

Variable expressions evaluate to the value of the specified variable.

Variable expressions are assignable.

#### Result Expressions

    ResultExpression
      : 'the' 'result'

The result expression evaluates to the return value of the previous (executed) non-control structure statement.

Result expressions are not assignable.

### List Expressions

    ListExpression
      : '[' [ <Elements: ExpressionList> ] ']'

A list expression evaluates all the elements in the expression list from left to right and constructs a list value with them as elements.

The elements list is optional, so the empty list can be specified as *[]*.

List expressions are not assignable.

#### Call Expressions

    CallExpression
      : <Handler: Identifier> '(' [ <Arguments: ExpressionList> ] ')'

A call expression executes a handler.

Its use is identical to a call statement, except that the return value of the handler is the value of the expression, rather than being available as **the result**.

> **Note:** Handlers which return no value (i.e. have undefined as their result type) can still be used in call expressions. In this case the value of the call is **undefined**.
