script "revInspectorPopupStackBehavior"
local sTarget

on setAsBehavior pTarget
   dispatch "setAsBehavior" to revIDEInspectorBehavior() with the long id of this me
   set the behavior of pTarget to the long id of this me
end setAsBehavior

on preOpenStack
   create button "OK"
   set the rect of button "OK" to 200,200,250,250
end preOpenStack

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
