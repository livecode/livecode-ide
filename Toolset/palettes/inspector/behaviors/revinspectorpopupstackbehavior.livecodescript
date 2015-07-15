script "revInspectorPopupStackBehavior"
local sTarget

on setAsBehavior pTarget
   dispatch "setAsBehavior" to revIDEInspectorBehavior() with the long id of this me
   set the behavior of pTarget to the long id of this me
end setAsBehavior

on preOpenStack
   set the style of the templatebutton to "standard"
   set the width of the templatebutton to "82"
   set the height of the templatebutton to "22"
   set the traversalon of the templatebutton to true
   set the default of the templatebutton to true
   create button "OK"
   
   set the topright of button "OK" to the width of me -  the palettemargin of me, the height of me
   set the resizable of me to false
   set the height of me to the height of me + the height of button "OK" of me + the palettemargin of me
   
   reset the templatebutton
end preOpenStack

on openStack
   set the left of me to the right of stack "revInspector" + 5
end openStack

on editorValueChanged pProperty, pValue, pLockUpdates
   dispatch "valueChanged" to sTarget with pProperty, pValue
end editorValueChanged

on mouseUp
   if the long id of the target is the long id of button "OK" of me then
      send "popupDismissed" to sTarget in 0 millisecs
   end if
end mouseUp

setProp editorTarget pTarget
   put pTarget into sTarget
end editorTarget
