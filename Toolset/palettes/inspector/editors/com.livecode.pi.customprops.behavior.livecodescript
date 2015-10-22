script "com.livecode.pi.customprops.behavior"
local sPropSet

on editorInitialize
   put empty into sPropSet
   put the rowLabel of me into field "rowlabel" of me
   set the rowShowLabel of me to false
   set the label of button "customPropertySet" of group "Set buttons" of me to "customKeys"
   set the editorMinWidth of me to 250
   set the editorMaxWidth of me to 0
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   local tKeys
   put the keys of tValue into tKeys
   if tKeys is empty then
      set the text of button "customPropertySet" of group "Set buttons" of me to "customKeys"
   else
      set the wholeMatches to true
      get lineOffset("", tKeys)
      if it is not 0 then
         put "customKeys" into line it of tKeys
      end if
      set the text of button "customPropertySet" of group "Set buttons" of me to tKeys
   end if
   
   if sPropSet is empty or sPropSet is not among the keys of tValue then
      set the label of button "customPropertySet" of group "Set buttons" of me to "customKeys"
   else
      set the label of button "customPropertySet" of group "Set buttons" of me to sPropSet
   end if
   
   set the arrayData of widget 1 of me to tValue[sPropSet]
   local tPath
   put the selectedElement of widget 1 of me into tPath
   if tPath is empty then
      put empty into field "key" of me
      put empty into field "value" of me
   else
      local tKey
      fetchArrayDataOnPath tPath, tValue[sPropSet], tKey 
      if the result is empty then
         put tKey into field "value" of me
         put item -1 of tPath into field "key" of me
      else
         put empty into field "key" of me
         put empty into field "value" of me
      end if
   end if
   set the enabled of field "value" of me to tEnabled
   set the enabled of field "key" of me to tEnabled
   if tEffective is true then
      set the textcolor of field "value"of me to "150,150,150"
      set the textcolor of field "key"of me to "150,150,150"
   else
      set the textcolor of field "value" of me to empty
      set the textcolor of field "key"of me to empty
   end if
   unlock messages
   unlock screen
end editorUpdate

constant kControlGap = 5
constant kKeyFieldHeight = 21
constant kValueFieldHeight = 63
constant kLabelSize = 50

on editorResize
   lock screen
   lock messages
   local tRect
   put the rect of me into tRect
   
   set the width of field "rowlabel" of me to the width of me
   set the height of field "rowlabel" of me to kKeyFieldHeight
   set the left of field "rowlabel" of me to the left of me
   
   set the width of group "Set buttons" of me to the width of me
   set the height of group "Set buttons" of me to 30
   set the top of group "Set buttons" of me to the top of me + kControlGap + kKeyFieldHeight
   set the left of group "Set buttons" of me to the left of me
   set the lockLoc of group "Set buttons" of me to true
   send "groupResize kLabelSize, kControlGap" to group "Set buttons" of me
   
   put item 4 of tRect - (4 * kControlGap + 2 * kKeyFieldHeight + kValueFieldHeight + 30) into item 4 of tRect 
   set the rect of widget 1 of me to tRect
   set the top of widget 1 of me to the bottom of group "Set buttons" of me + kControlGap
   
   set the width of field "key label" of me to kLabelSize
   set the height of field "key label" of me to kKeyFieldHeight
   set the top of field "key label" of me to the bottom of widget 1 of me + kControlGap
   set the left of field "key label" of me to the left of me
   
   set the width of field "key" of me to the width of me - kLabelSize - kControlGap
   set the height of field "key" of me to kKeyFieldHeight
   set the top of field "key" of me to the bottom of widget 1 of me + kControlGap
   set the left of field "key" of me to the right of field "key label" of me + kControlGap
   
   set the width of field "value label" of me to kLabelSize
   set the height of field "value label" of me to kKeyFieldHeight
   set the top of field "value label" of me to the bottom of field "key" of me + kControlGap
   set the left of field "value label" of me to the left of me
   
   set the width of field "value" of me to the width of me - kLabelSize - kControlGap
   set the height of field "value" of me to kValueFieldHeight
   set the top of field "value" of me to the bottom of field "key" of me + kControlGap
   set the left of field "value" of me to the right of field "value label" of me + kControlGap
   
   unlock messages
   unlock screen
end editorResize

on setPropSet pArray
   local tValue
   put the editorValue of me into tValue
   put pArray into tValue[sPropSet]
   set the editorValue of me to tValue
   updateProperty
end setPropSet

on setArrayDataOnPath pValue, pPath, @xArray
   local tKey
   put item 1 of pPath into tKey
   if the number of items in pPath is 1 then
      put pValue into xArray[tKey]
   else
      delete item 1 of pPath
      setArrayDataOnPath pValue, pPath, xArray[tKey]
   end if
end setArrayDataOnPath

on setArrayKeyOnPath pKey, pPath, @xArray
   local tKey
   put item 1 of pPath into tKey
   if the number of items in pPath is 1 then
      local tSubArray
      put xArray[item 1 of pPath] into tSubArray
      delete variable xArray[item 1 of pPath]
      put tSubArray into xArray[pKey]
   else
      delete item 1 of pPath
      setArrayKeyOnPath pKey, pPath, xArray[tKey]
   end if
end setArrayKeyOnPath

on deleteArrayKeyOnPath pPath, @xArray
   local tKey
   put item 1 of pPath into tKey
   if the number of items in pPath is 1 then
      delete variable xArray[item 1 of pPath]
   else
      delete item 1 of pPath
      deleteArrayKeyOnPath pPath, xArray[tKey]
   end if
end deleteArrayKeyOnPath

on addArrayKeyOnPath pPath, @xArray
   local tKey
   put item 1 of pPath into tKey
   if the number of items in pPath is 1 then
      put "" into xArray[item 1 of pPath]
   else
      delete item 1 of pPath
      addArrayKeyOnPath pPath, xArray[tKey]
   end if
end addArrayKeyOnPath

on fetchArrayDataOnPath pPath, pArray, @rData
   local tKey
   put item 1 of pPath into tKey
   if the number of items in pPath is 1 then
      if tKey is not among the keys of pArray then
         return "no such key"
      else
         put pArray[tKey] into rData
         return empty
      end if
   else
      delete item 1 of pPath
      fetchArrayDataOnPath pPath, pArray[tKey], rData
   end if
end fetchArrayDataOnPath

on arrayChanged
   setPropSet the arrayData of widget 1 of me
end arrayChanged

on valueChanged
   local tPath
   put the selectedElement of widget 1 of me into tPath
   if tPath is empty then
      # Don't update anthing
   else
      local tArray
      put the arrayData of widget 1 of me into tArray
      setArrayDataOnPath field "value" of me, tPath, tArray
      setPropSet tArray
   end if
end valueChanged

on keyChanged
   local tPath
   put the selectedElement of widget 1 of me into tPath
   if tPath is not empty then
      local tArray
      put the arrayData of widget 1 of me into tArray
      setArrayKeyOnPath field "key" of me, tPath, tArray
      setPropSet tArray
   end if
end keyChanged

on propSetRenamed pFrom, pTo
   local tArray
   put the editorValue of me into tArray
   setArrayKeyOnPath pTo, pFrom, tArray
   put pTo into sPropSet
   set the editorValue of me to tArray
   updateProperty
end propSetRenamed

on propSetDeleted pSet
   local tArray
   put the editorValue of me into tArray
   deleteArrayKeyOnPath pSet, tArray
   put empty into sPropSet
   set the editorValue of me to tArray   
   updateProperty
end propSetDeleted
   
on propSetAdded pSet
   local tArray
   put the editorValue of me into tArray
   addArrayKeyOnPath pSet, tArray
   put pSet into sPropSet
   set the editorValue of me to tArray
   updateProperty
end propSetAdded

on propSetSelected pWhich
   if pWhich is "customKeys" then
      put empty into sPropSet
   else
      put pWhich into sPropSet
   end if
   editorUpdate
end propSetSelected

function revValidSetName pWhich
   if pWhich is empty then
      beep
      exit to top
   end if
   if char 1 of pWhich is a number then
      local tFailed
      put true into tFailed
      put "_" into char 1 of pWhich
   end if
   repeat with i = 1 to the number of chars in pWhich
      if char i of pWhich is not in "abcdefghijklmnopqrstuvwxyz1234567890_" then
         put true into tFailed
         put "_" into char i of pWhich
      end if
   end repeat
   if tFailed then
      answer "That name is not valid.  You must use a valid variable name.  Should I use this name instead:" & cr & pWhich with "Cancel" or "Yes"
      if it is "Cancel" then exit to top
   end if
   local tUsedNames, tValue
   put the editorValue of me into tValue
   put the keys of tValue into tUsedNames
   replace space with empty in tUsedNames
   if pWhich is among the lines of tUsedNames then
      answer "Set already exists." with "Cancel"
      exit to top
   end if
   return pWhich
end revValidSetName
