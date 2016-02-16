script "com.livecode.pi.script.behavior"
on editorInitialize
   set the editorMinWidth of me to 230
   set the editorMaxWidth of me to 0
      disable button "edit script" of me
      disable button "inspect object" of me
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   put tValue into field 1 of me
   if exists(tValue) then
      enable button "edit script" of me
      enable button "inspect object" of me
   end if
   set the enabled of field 1 of me to tEnabled
   if tEffective is true then
      set the textcolor of field 1 of me to "150,150,150"
   else
      set the textcolor of field 1 of me to empty
   end if
   unlock messages
   unlock screen
end editorUpdate

getProp editorMinWidth
   return 140
end editorMinWidth

constant kFieldHeight = 21
constant kButtonHeight = 23
constant kControlGap = 5
on editorResize
   lock screen
   lock messages
   
   local tFieldHeight
   put the formattedheight of field 1 of me into tFieldHeight
   set the width of field 1 of me to the width of me - kControlGap - tFieldHeight
   set the height of field 1 of me to tFieldHeight
   set the topleft of field 1 of me to the topleft of me
   
   set the rect of widget 1 of me to 0,0,tFieldHeight,tFieldHeight
   set the topright of widget 1 of me to the topright of me	
   
   local tButtonWidth
   put (the width of me - kControlGap) / 2 into tButtonWidth
   set the rect of button "Edit script" of me to 0,0,tButtonWidth,kButtonHeight
   set the rect of button "Inspect object" of me to 0,0,tButtonWidth,kButtonHeight
   
   local tButtonTop
   put the top of me + tFieldHeight + kControlGap into tButtonTop
   set the topleft of button "Edit script" of me to the left of me, tButtonTop
   set the topright of button "Inspect object" of me to the right of me, tButtonTop
   unlock messages
   unlock screen
end editorResize

on valueChanged
   local tBehaviorScript
   put field 1 of me into tBehaviorScript
   set the editorValue of me to tBehaviorScript
   if exists(tBehaviorScript) then
      enable button "edit script" of me
      enable button "inspect object" of me
   else
      disable button "edit script" of me
      disable button "inspect object" of me
   end if
   updateProperty
end valueChanged

on editorEditScript
   local tObj
   put field 1 of me into tObj
   try
      edit the script of tObj
   catch tError
      answer "Object" && tObj && "not found"
   end try
end editorEditScript

on mouseUp
   switch the short name of the target
      case "Select"
         popupMenu
         break
      case "Edit Script"
         editorEditScript
         break
      case "Inspect object"
         editorGoToObject
   end switch
end mouseUp

on editorGoToObject
   dispatch "lockInspector" to stack ideStackOfObject(the long id of me)
   local tObject
   put field 1 of me into tObject
   put the long id of tObject into tObject
   if word 1 of tObject is "stack" then
      go tObject
   else
      go revIdeCardOfObject(tObject) 
   end if
   
   revIDESelectObjects tObject
end editorGoToObject

on popupMenu
   set the text of button "Menu" of me to "Select Behavior" & return & revIDEObjectSelectionMenu("", "button,stack")
   popup button "Menu" of me at the mouseLoc
end popupMenu

on menuPick pObject
   set the itemdelimiter to "|"
   put the last item of pObject into field 1 of me
   valueChanged
end menuPick
