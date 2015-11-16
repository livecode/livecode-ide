script "com.livecode.pi.nudge.behavior"
on editorInitialize
   set the editorMinWidth of me to 0
   set the editorMaxWidth of me to 0
end editorInitialize

on editorUpdate

end editorUpdate

on editorResize
   lock screen
   lock messages
   set the topleft of group "controls" of me to the topleft of me
   unlock messages
   unlock screen
end editorResize

on mouseUp
   local tTarget, tValue
   put the short name of the target into tTarget
   if tTarget is not "Increment" then
      put tTarget into tValue["direction"]
      put the label of button "Increment" of group "controls" of me into tValue["increment"]
   end if
   set the editorValue of me to tValue
   updateProperty
end mouseUp
