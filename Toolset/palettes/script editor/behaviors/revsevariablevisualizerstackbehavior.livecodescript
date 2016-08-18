script "revSEVariableVisualizerStackBehavior"
on resizeStack
   resize
end resizeStack

setProp cName pName
   set the text of field "Name" of me to pName
end cName

getProp cName
   return the text of field "Name" of me
end cName

setProp cValue pValue
   set the text of field "Value" of me to pValue
end cValue

getProp cValue
   return the text of field "Value" of me
end cValue

command initialize
   disable button "Apply" of me
   resize
end initialize

local sReference

command setReference pReference
   put pReference into sReference
end setReference

command getReference
   return sReference
end getReference

on keyUp pKey
   if the long id of the focusedObject is the long id of field "Value" of me then
      enable button "Apply" of me
   end if
   pass keyUp
end keyUp

on backspaceKey
   if the long id of the focusedObject is the long id of field "Value" of me then
      enable button "Apply" of me
   end if
   pass backspaceKey
end backspaceKey

on deleteKey
   if the long id of the focusedObject is the long id of field "Value" of me then
      enable button "Apply" of me
   end if
   pass deleteKey
end deleteKey

on commandKeyDown pKey
   if pKey is "w" then
      close me
   end if
   pass commandKeyDown
end commandKeyDown

on textChanged
   if the long id of the target is the long id of field "Value" of me then
      enable button "Apply" of me
   end if
end textChanged

command resize
   set the rect of field "Name" of me to 4,4,the width of me - 4,25
   set the rect of field "Value" of me to the 4, the bottom of field "Name" of me + 4, the width of me - 4, the height of me - 30
   set the bottomRight of button "Apply" of me to the width of me -5, the height of me - 4
end resize

private command applyValue
   local tObject, tValue
   put the long id of me into tObject
   put the text of field "Value" of me into tValue
   send "visualizationObjectSetValue tObject, tValue" to the cManager of me
   disable button "Apply" of me
   
   # This is sent in time in order to allow the execution contexts of this stack to be removed
   # from the call stack, otherwise they appear in the debugger, and the update shows the wrong vars.
   send "update" to the cManager of me in 0 milliseconds
end applyValue


on mouseUp
   if the short name of the target is "Apply" then
     applyValue
   end if
end mouseUp

on enterKey
   if the enabled of button "Apply" of me then
      applyValue
   else
      finalize
      close me
   end if
end enterKey

on enterInField
   if the enabled of button "Apply" of me then
      applyValue
   else
      finalize
      close me
   end if
end enterInField

command finalize
   local tObject
   put the long id of me into tObject
   send "visualizationObjectRemove tObject" to the cManager of me in 0
end finalize

on closeStackRequest
   finalize
   pass closeStackRequest
end closeStackRequest
