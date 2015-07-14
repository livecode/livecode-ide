script "revInspectorPopupStackBehavior"
local sTarget

on setAsBehavior pTarget
   dispatch "setAsBehavior" to revIDEInspectorBehavior() with the long id of this me
   set the behavior of pTarget to the long id of this me
end setAsBehavior

on preOpenStack
   create button "OK"
   set the maxheight of me to the height of me + 30
   set the height of me to the maxheight of me
   set the rect of button "OK" to the width of me - 40,the height of me - 26,the width of me - 8,the height of me - 4
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
