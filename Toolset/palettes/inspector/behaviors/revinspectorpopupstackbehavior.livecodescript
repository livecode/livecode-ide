script "revInspectorPopupStackBehavior"
local sTarget

on setAsBehavior pTarget
   dispatch "setAsBehavior" to revIDEInspectorBehavior() with the long id of this me
   set the behavior of pTarget to the long id of this me
end setAsBehavior

on preOpenStack
   local tMargin
   put the paletteMargin of me into tMargin
   lock messages
   set the style of the templatebutton to "standard"
   set the width of the templatebutton to "82"
   set the height of the templatebutton to "22"
   set the traversalon of the templatebutton to true
   set the default of the templatebutton to true
   create button "OK"
   
   set the topright of button "OK" to the width of me -  tMargin, the height of me
   set the resizable of me to false
   set the height of me to the height of me + the height of button "OK" of me + tMargin
   
   reset the templatebutton
   unlock messages
end preOpenStack

on openStack
   lock screen
   lock messages
   set the left of me to the right of revIDEStackOfObject(sTarget) + 5
   show me
   unlock messages
   unlock screen
end openStack

on closeStack
   send "popupDismissed" to sTarget in 0 millisecs
end closeStack

on editorValueChanged pProperty, pValue, pLockUpdates
   try
      dispatch "valueChanged" to sTarget with pProperty, pValue
   catch tError
      send "popupDismissed" to sTarget in 0 millisecs
   end try
end editorValueChanged

on mouseUp
   if the long id of the target is the long id of button "OK" of me then
      send "popupDismissed" to sTarget in 0 millisecs
   end if
end mouseUp

setProp editorTarget pTarget
   put pTarget into sTarget
end editorTarget
