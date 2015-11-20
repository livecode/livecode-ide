# Property data files

The IDE uses the files in this directory to store information on object properties 
so that they can be controlled appropriately by IDE palettes (notably the 
property inspector).

The file `propertyInfo.txt` contains all the base information about object properties.
Each of the files `com.livecode.interface.classic.<objtype>` contain information on
object properties in the context of the given object type.

# Structure

Excluding some optional information about object types, the property data file consists
of lines of tab-delimited data, one line for each property.

The items are, in order:

## Property name
The property name may also contain information about what getter and setter to use for
the property in case it shouldn't use the IDE's default method. If these are present, 
they should be separated from the property name by colons, eg
`propname:customGetter:customSetter`

If the custom getters and setters are present, they will be used by the property inspector 
automatically. Note the setter must be a command taking parameters `<objectLongID>`, `<propertyName>`, `<propertyValue>`, and the getter must be a function taking parameters 
`<objectLongID>`, `<propertyName>`.

## Label

This is the label that will be used in the property inspector if the user prefers to use 
readable labels instead of the property name.

## Section

This is the section that the property data will appear under. These correspond to the 
tabs in the property inspector.

## Editor

This is the editor to be used to edit the property. See the [Extending LiveCode](../../../../Documentation/guides/Extending Livecode.md) guide for more information
on property editors.

## User Visible

Controls whether the property appears in the property inspector.

## Read Only

Controls whether the property can be modified in the property inspector.

## Group

Properties can be grouped in the inspector so that they appear in the same row. If there is more
than one property in a group, their editors will be arranged side-by-side if possible.

## Default

The default value for the property. When the object is created in the IDE (eg by dragging from
the Tools palette), all properties are set to their defaults. 

Default values may use the `execute:` syntax. If they do, the script is executed, and the
default value for the property is whatever is in the `it` variable afterward.

Occurrences of \n in not-executable default values are replaced by return characters.

## Options

The options for an enum or set property. These should be comma delimited.

If the `display value` of an option differs from its actual value, this can be achieved by
using colon separation, eg
`opt1:Option 1,opt2:Option 2,...`

Option values may use the `execute:` syntax. If they do, the script is executed, and the
options for the property are whatever is in the `it` variable afterward.

## Subsection

Not currently used, but may be in the future to specify a level of grouping between group and
section.

## Min

The minimum value of a numeric property. 

## Max

The maximum value of a numeric property. 

## Step

The amount by which a numeric property should be incremented/decremented by any numeric twiddle.
