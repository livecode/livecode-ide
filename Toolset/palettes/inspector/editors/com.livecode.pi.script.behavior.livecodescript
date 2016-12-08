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
   set the visible of widget 1 of me to tEnabled
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
   local tEnabled
   put the editorEnabled of me into tEnabled 
   lock messages
   local tFieldHeight, tFieldWidth
   put the formattedheight of field 1 of me into tFieldHeight
   put the width of me into tFieldWidth
   if tEnabled then 
      subtract kControlGap + tFieldHeight from tFieldWidth
   end if
   set the width of field 1 of me to tFieldWidth
   set the height of field 1 of me to tFieldHeight
   set the topleft of field 1 of me to the topleft of me
   
   if tEnabled then
      set the rect of widget 1 of me to 0,0,tFieldHeight,tFieldHeight
      set the topright of widget 1 of me to the topright of me	
   end if
   
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

on mouseDown
   switch the short name of the target
      case "Select"
         popupMenu
         break
   end switch
end mouseDown

on mouseUp
   switch the short name of the target
      case "Edit Script"
         editorEditScript
         break
      case "Inspect object"
         editorGoToObject
         break
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
   local tMenu, tObject
   
   put the cSelectedObjects of this stack into tObject
   
   put "Select Behavior" & return & revIDEObjectSelectionMenu("", "button,stack") into tMenu
   put return & "Create behavior from script only stack/|create behavior" after tMenu   
   put return & tab & "Create stack with empty script/|create empty behavior" & return after tMenu
   if word 1 to -1 of the script of tObject is empty then
      put "(" after tMenu
   end if
   put tab & "Create stack using existing control script/|create behavior from script" after tMenu
   set the text of button "Menu" of me to tMenu
   popup button "Menu" of me at the mouseLoc
end popupMenu

on menuPick pObject
  local tAction
  
  set the itemdelimiter to "|"
  put item -1 of pObject into tAction
  
  switch tAction
    case "create empty behavior"
    case "create behavior from script"
      local tError, tSuggestedName, tStackName
      local tTargetObject, tFilename, tStack
      
      put the cSelectedObjects of this stack into tTargetObject
      put revIDEStackOfObject(tTargetObject) into tStack
      put the effective filename of tStack into tDefaultFilename
      
      ask revIDELocalise("Please enter a name for the script only stack") with the short name of tTargetObject && "Behavior"
      if it is empty then exit menuPick
      put it into tStackName
      put word 1 to -1 of line 1 of tStackName into tStackName
      replace quote with "'" in tStackName
      
      if tDefaultFilename is not empty then
        set the itemDelimiter to "/"
        put tStackName & ".livecodescript" into the last item of tDefaultFilename
      else
        put tStackName & ".livecodescript" into tDefaultFilename
      end if
      
      ask file revIDELocalise("Please specify a location for the script only stack") with tDefaultFilename
      if it is empty then exit menuPick
      put it into tFilename
      
      lock messages
      create invisible stack tStackName
      close stack tStackName
      set the filename of stack tStackName to tFilename
      set the scriptOnly of stack tStackName to true
      
      if tAction is "create behavior from script" then
        set the script of stack tStackName to the script of tTargetObject
      end if
      
      save stack tStackName
      put the result into tError
      unlock messages
      
      if tError is empty then
        local tStackFiles
        
        set the behavior of tTargetObject to the long id of stack tStackName
        put the stackFiles of tStack into tStackFiles
        put tStackName & "," & tFilename into line (the number of lines of tStackFiles + 1) of tStackFiles
        revIDESetStackFilesProperty tStack, empty, tStackFiles
        
        if tAction is "create behavior from script" then
          set the script of tTargetObject to empty
        else
          edit script of stack tStackName
        end if
      end if
      
      if tError is not empty then
        answer error tError
      end if
      break
      
    default
      set the itemdelimiter to "|"
      put the last item of pObject into field 1 of me
      valueChanged
  end switch
end menuPick
