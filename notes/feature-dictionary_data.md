# Dictionary data build location

Previously the IDE would try to build dictionary data internally, which 
was a problem for the installed application on Windows and Linux (as the 
location was not necessarily writable).

Now the data is built and modified in an appropriate 'Application 
Support' folder, or equivalent. This also allows direct navigation to
specific dictionary entries via the 'launch documentation' button / 
'Find in Docs' contextual menu item in the script editor, and the 
'Show Documentation' contextual object menu item, in an external browser
window on platforms where the browser widget is not available.