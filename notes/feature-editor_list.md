---
version: 8.0.0-dp-8
---
# Property Inspector editorList editor

A new editor has been added to the list of property inspector editors which lays out a 
series of copies of a specified subeditor to control a string property.

For example, the segmented control widget has a property `segmentIcons`, which is a comma
delimited list of names of icons.

In the widget metadata, we have 

```
metadata segmentIcons.editor    is "com.livecode.pi.editorlist"
metadata segmentIcons.subeditor is "com.livecode.pi.svgicon"
metadata segmentIcons.delimiter is ","
```

This tells the property inspector that each icon in the sequence should be controlled by
the svgicon editor, and the property as a whole is delimited by ",".
