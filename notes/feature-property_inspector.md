# Property Inspector

The property inspector has been rewritten to allow properties of widgets to be inspected and edited. It has been implemented with flexibility and extensibility in mind, since it must be able to control the values of widget properties in any way required by the widget developer. Each property now has a number of attributes which affect how it appears in the inspector.

## Property Attributes

The following is the list of property attributes:

### default
The default value of the property. If there is no default value (for example the 'loc' property does not have one), the string "no_default" can be used. The property inspector pops up a contextual menu when editors are right-clicked allowing the user to set the property back to a default value.

### editor
The editor that will be used to display the value of the property and allow it to be edited. See the dedicated section below for details on property inspector editors. 

### group
Properties are grouped by themselves in the inspector by default. If a particular group name is specified for a set of properties, their editors are placed next to each other in the inspector.

### label
The label to use for this property.

### options
For properties whose value is a choice from a set of options, that set should be specified as a comma delimited list for the options attribute. Default editors are provided for 'enum' type properties (choice of exactly one from a set) and 'set' type properties (choice of zero or more from a set). 

Lists of options can be generated using LiveCode Script for the inspector at run-time, by using the 'execute' syntax - for example the options for the textFont property are generated using
`execute: get the fontNames; sort it`
Whatever remains in the 'it' variable after executing the specified script is used as the list of options.

### section
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

### user_visible
Properties are visible in the property inspector by default. Set the user_visible attribute to false to hide a given property from the user.

### read_only
Read only properties will be displayed in the property inspector but the corresponding editor will have its "editorEnabled" property set to false. See the Editors section below for more details on enabled/disabled editors.

## Widget Properties

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

## Script Object Properties
Script-level properties of objects (including widgets) are specified in files in the Toolset/resources/supporting_files/property_definitions folder. The propertyInfo.txt file specifies the default values for all the property attributes. Each object type then has a specification of which properties should be displayed in the inspector when it is the selected object, and any options/default/group values which override the defaults.

## Editors

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