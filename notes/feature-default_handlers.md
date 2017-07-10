# Default handlers
Objects no longer have default scripts that appear in the script
editor when their empty scripts are edited. Instead, all the 
associated message handlers for the object type now appear in a 
list underneath the list of handlers that are present in the 
script. When clicked, these lines add the selected default 
handler to the end of the current script.

If there is a default script for this handler and object type  
in the appropriate location 
(Toolset/resources/supporting_files/default_scripts/ for 
'classic' objects, <widget_path>/support/ for widgets), the 
content of the handler is obtained from that script (including
preceding comments)

If there is no default script for this handler and object type,
the handler is constructed using information from the 
documentation, namely the Summary element is used as a preceding 
comment to describe the handler, and then the handler declared
with all the specified parameters.
