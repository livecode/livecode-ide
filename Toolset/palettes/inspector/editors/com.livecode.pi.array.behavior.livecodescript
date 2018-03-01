script "com.livecode.pi.array.behavior"
local sHilitePath

on editorInitialize
   set the editorMinWidth of me to 250
   set the editorMaxWidth of me to 0
end editorInitialize

local sDontUpdate
on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   local tPath
   put the hilitedElement of widget 1 of me into tPath
   set the arrayData of widget 1 of me to tValue
   set the pathDelimiter of widget 1 of me to numToCodepoint(0)
   unlock messages
   updateEditorFields tPath
   lock messages
   set the visible of field "value" of me to tEnabled
   set the visible of field "key" of me to tEnabled
   set the visible of field "value label" of me to tEnabled
   set the visible of field "key label" of me to tEnabled
   set the readOnly of widget "array" of me to not tEnabled
   if tEffective is true then
      set the textcolor of field "value" of me to "150,150,150"
      set the textcolor of field "key" of me to "150,150,150"
   else
      set the textcolor of field "value" of me to empty
      set the textcolor of field "key" of me to empty
   end if
   unlock messages
   unlock screen
end editorUpdate

on updateEditorFields pPath
   local tValue
   set the itemdelimiter to the pathDelimiter of widget 1 of me
   put the editorValue of me into tValue
   if pPath is empty then
      put empty into field "key" of me
      put empty into field "value" of me
   else
      local tKey
      fetchArrayDataOnPath pPath, tValue, tKey 
      if the result is empty then
         put tKey into field "value" of me
         put item -1 of pPath into field "key" of me
      else
         put empty into field "key" of me
         put empty into field "value" of me
      end if
   end if
end updateEditorFields

constant kControlGap = 5
constant kKeyFieldHeight = 21
constant kValueFieldHeight = 63
constant kLabelSize = 50

on editorResize
   lock screen
   lock messages
   local tRect
   put the rect of me into tRect
   put item 4 of tRect - (2 * kControlGap + kKeyFieldHeight + kValueFieldHeight) into item 4 of tRect 
   set the rect of widget 1 of me to tRect
   
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

on setValue pArray
   set the editorValue of me to pArray
   updateProperty
end setValue

on setArrayDataOnPath pValue, pPath, @xArray
   local tKey
   set the itemdelimiter to the pathDelimiter of widget 1 of me
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
   set the itemdelimiter to the pathDelimiter of widget 1 of me
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
   set the itemdelimiter to the pathDelimiter of widget 1 of me
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
   set the itemdelimiter to the pathDelimiter of widget 1 of me
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
   set the itemdelimiter to the pathDelimiter of widget 1 of me
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

on dataChanged
   setValue the arrayData of widget 1 of me
end dataChanged

on valueChanged
   local tPath
   set the itemdelimiter to the pathDelimiter of widget 1 of me
   put the hilitedElement of widget 1 of me into tPath
   if tPath is empty then
      # Don't update anthing
   else
      local tArray
      put the arrayData of widget 1 of me into tArray
      setArrayDataOnPath field "value" of me, tPath, tArray
      setValue tArray
   end if
end valueChanged

on keyChanged
   lock screen
   local tPath
   set the itemdelimiter to the pathDelimiter of widget 1 of me
   put the hilitedElement of widget 1 of me into tPath
   
   local tArray, tNewKey
   put field "key" of me into tNewKey
   put the arrayData of widget 1 of me into tArray
   
   if tPath is not empty then
      # If there is a hilited element then change it
      setArrayKeyOnPath tNewKey, tPath, tArray
   else
      # otherwise add a new key to the current set
      addArrayKeyOnPath tNewKey, tArray
   end if
   
   # Set the new property and hilite the new/changed key
   put tNewKey into item -1 of tPath
   put tPath into sHilitePath
   setValue tArray
   send "updateHIlite" to me in 0 millisecs
   unlock screen
end keyChanged

on hiliteChanged
   if not sDontUpdate then
      put empty into sHilitePath
      # Prevent setting hilite in update causing additional call to editorUpdate
      editorUpdate
   end if
   put false into sDontUpdate
end hiliteChanged

on updateHIlite
   local tPath
   set the itemdelimiter to the pathDelimiter of widget 1 of me
   put the hilitedElement of widget 1 of me into tPath
   
   # Hilite a newly created key
   if sHilitePath is not empty and sHilitePath is not tPath then
      # Signals are posted from the widget after the handler has 
      # executed, so lock messages here doesn't prevent hiliteChanged -
      # use a script local to prevent second update.
      put true into sDontUpdate
      set the hilitedElement of widget 1 of me to sHilitePath
      put sHilitePath into tPath
   end if
   put empty into sHilitePath
   updateEditorFields tPath
end updateHIlite
