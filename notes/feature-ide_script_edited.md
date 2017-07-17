# ideScriptEdited message

A new IDE message has been added:

    ideScriptEdited pScript, pObj

This message is sent when the script of an object as displayed
in the script editor is changed. pScript contains the current
contents of the script editor field for pObj, which, until applied, 
is not necessarily the same as `the script of pObj`.
