# Interactive Tutorial syntax
The syntax `load stack <FileName>` has been added to interactive
tutorials. This allows prepared stacks to be imported as operating
stacks in the current tutorial.

The prepared stack will be loaded from the internal resources folder 
of the tutorial (i.e. from `_resources/<FileName>`). Any `cTutorialTag` 
custom property of objects on the stack will be converted to tags for 
objects which can subsequently be used in the current tutorial.
