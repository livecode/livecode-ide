script "com.livecode.pi.action.behavior"
/**
This editor simply consists of a button. Its label is set to the
label of the property to which it is associated. Clicking the 
button forces the 'setter' for the property to be called. 

The editor does not get or set any actual values - it should be
used for actions triggerable in the property inspector.

For example, the refresh data grid action is declared in the 
property definition file as:

refresh::revIDEDataGridAction	Refresh Data Grid	Data Grid	com.livecode.pi.action
 
When the button is clicked, revIDEDataGridAction is called
with the parameters <target object>, "refresh".
*/

on editorInitialize
   set the label of button 1 of me to the editorLabel of me
   set the rowShowLabel of me to false
end editorInitialize

on editorUpdate

end editorUpdate

on editorResize
   lock screen
   lock messages
   set the width of button 1 of me to the width of me
   set the topleft of button 1 of me to the topleft of me
   unlock messages
   unlock screen
end editorResize

on mouseUp
   updateProperty true	
end mouseUp
