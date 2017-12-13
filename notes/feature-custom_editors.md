# Custom property inspector editors
Extensions may now include their own property inspector editors
for use when editing their properties. The stack containing the 
editor, and the behavior must be named <extension id>.editor.<name>.livecode
and <extension id>.editor.<name>.behavior.livecodescript respectively.

The editor stack must contain one group called "template", which is the 
editor. It is cloned onto the inspector stack when any property that
uses it as an editor is inspected. 

Please see the [property inspector feature note](https://github.com/livecode/livecode-ide/blob/develop/notes/feature-property_inspector.md#editors)
for more details on property inspector editors. 

