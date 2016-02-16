script "com.livecode.pi.editorList.behavior"
local sComponentSize, sNumChildren

constant kComponentSpacing = 6

on editorInitialize
   set the editorMinWidth of me to sNumChildren * sComponentSize
   set the editorMaxWidth of me to 0
end editorInitialize

on editorGenerate
   local tEditorType
   put editorPropertyGet("subeditor") into tEditorType
   
   if tEditorType is "com.livecode.pi.integer" then
      put "com.livecode.pi.number" into tEditorType
   end if
   
   if there is not a stack tEditorType then
      put "com.livecode.pi.string" into tEditorType
   end if
   
   local tEditorBehavior
   put tEditorType & ".behavior" into tEditorBehavior
   
   local tDelimiter
   put editorPropertyGet("delimiter") into tDelimiter
   local tValueArray
   put the editorValue of me into tValueArray
   split tValueArray by tDelimiter
   
   put the number of elements of tValueArray into sNumChildren
   
   local tPropertyInfo
   put the editorPropertyInfo of me into tPropertyInfo
   
   lock screen
   lock messages
   repeat for each line tLine in the childControlIDs of me
      delete group id tLine of me
   end repeat
   unlock messages
   local tGroupLongID
   repeat with x = 1 to sNumChildren
      lock messages
      copy group "template" of stack tEditorType to me
      put it into tGroupLongID
      set the name of it to "editor" & x
      set the behavior of stack tEditorBehavior to the long id of stack revIDEPaletteResourcePath("behaviors/revinspectoreditorbehavior.livecodescript", the long ID of stack "revInspector")
      set the behavior of tGroupLongID to the long ID of stack tEditorBehavior
      unlock messages
      set the editorPropertyInfo of tGroupLongId to tPropertyInfo
      dispatch "editorInitialize" to tGroupLongID
   end repeat
   unlock screen
end editorGenerate

on updateSubeditors
   local tDelimiter
   put editorPropertyGet("delimiter") into tDelimiter
   local tValueArray
   put the editorValue of me into tValueArray
   split tValueArray by tDelimiter
   
   local tMinWidth
   repeat with x =1 to sNumChildren
      set the editorValue of group ("editor" & x) of me to tValueArray[x]
      dispatch "editorUpdate" to group ("editor" & x) of me
      local tEditorMinWidth
      put the formattedwidth of group ("editor" & x) of me into tEditorMinWidth
      add (tEditorMinWidth + kComponentSpacing) to tMinWidth	    
   end repeat
   
   set the editorMinWidth of me to tMinWidth
end updateSubeditors

on editorUpdate
   lock screen
   editorGenerate
   updateSubeditors
   editorResize
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   
   local tLeft, tTop
   put the left of me into tLeft
   put the top of me into tTop
   
   local tHeight
   repeat with x = 1 to sNumChildren
      dispatch "editorResize" to group ("editor" & x) of me
      set the left of group ("editor" & x) of me to tLeft
      set the top of group ("editor" & x) of me to tTop
      add the effective width of group ("editor" & x) of me to tLeft
      put max(the effective height of group ("editor" & x) of me, tHeight) into tHeight
   end repeat
   unlock messages
   set the editorHeight of me to tHeight
   unlock screen
end editorResize

// Dispatched by the subeditors when their value changes
on editorValueChanged
   if the long id of the target is the long id of me then 
      pass editorValueChanged
   end if
   
   local tDelimiter
   put editorPropertyGet("delimiter") into tDelimiter
   local tValueArray
   
   repeat with x =1 to sNumChildren
      put the editorValue of group ("editor" & x) of me into tValueArray[x]
   end repeat
   combine tValueArray with tDelimiter
   set the editorValue of me to tValueArray
   dispatch "updateProperty"
end editorValueChanged
