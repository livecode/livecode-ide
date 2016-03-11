script "com.livecode.pi.array.behavior"
on editorInitialize
   set the editorMinWidth of me to 200
   set the editorMaxWidth of me to 0
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   set the arrayData of widget 1 of me to tValue
   local tPath
   put the selectedElement of widget 1 of me into tPath
   if tPath is empty then
      put empty into field "key" of me
      put empty into field "value" of me
   else
      put fetchArrayDataOnPath(tPath, tValue) into field "value" of me
      put item -1 of tPath into field "key" of me
   end if
   set the enabled of field "value" of me to tEnabled
   set the enabled of field "key" of me to tEnabled
   if tEffective is true then
      set the textcolor of field "value" of me to "150,150,150"
      set the textcolor of field "key"of me to "150,150,150"
   else
      set the textcolor of field "value" of me to empty
      set the textcolor of field "key" of me to empty
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

function fetchArrayDataOnPath pPath, pArray
   local tKey
   put item 1 of pPath into tKey
   if the number of items in pPath is 1 then
      return pArray[tKey]
   else
      delete item 1 of pPath
      return fetchArrayDataOnPath(pPath, pArray[tKey])
   end if
end fetchArrayDataOnPath

on dataChanged
   set the editorValue of me to the arrayData of widget 1 of me
   updateProperty
end dataChanged

on valueChanged
   local tPath
   put the hilitedElement of widget 1 of me into tPath
   if tPath is empty then
      # Don't update anthing
   else
      local tArray
      put the arrayData of widget 1 of me into tArray
      setArrayDataOnPath field "value" of me, tPath, tArray
      set the editorValue of me to tArray
      updateProperty
   end if
end valueChanged

on keyChanged
   lock screen
   local tPath
   put the hilitedElement of widget 1 of me into tPath
   if tPath is not empty then
      local tArray, tNewKey
      put field "key" of me into tNewKey
      put the arrayData of widget 1 of me into tArray
      setArrayKeyOnPath tNewKey, tPath, tArray
      setPropSet tArray
      put tNewKey into item 1 of tPath
      set the hilitedElement of widget 1 of me to tPath
   end if
   unlock screen
end keyChanged

on hiliteChanged
   editorUpdate
end hiliteChanged
