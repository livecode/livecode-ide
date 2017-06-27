script "com.livecode.pi.set.behavior"
on editorInitialize
   set the editorMinWidth of me to 40
   set the editorMaxWidth of me to 0
   
   local tText, tOptions
   put the editorOptions of me into tOptions
   set the itemdelimiter to "|"
   repeat for each line tLine in tOptions
      if tText is empty then
         put item 1 of tLine into tText
      else
         put return & item 1 of tLine after tText
      end if
   end repeat
   set the text of field 1 of me to tText
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   local tHilitedLines, tOptions
   put the editorOptions of me into tOptions
   lock messages
   set the wholematches to false
   repeat for each item tItem in tValue
      get lineOffset(tItem, tOptions)
      if it is 0 then next repeat
      if tHilitedLines is empty then
         put it into tHilitedLines
      else
         put comma & it after tHilitedLines
      end if
   end repeat
   set the hilitedlines of field 1 of me to tHilitedLines
   
   set the enabled of me to tEnabled
   if tEffective is true then
      set the textcolor of field 1 of me to "150,150,150"
   else
      set the textcolor of field 1 of me to empty
   end if
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the lockLoc of me to true
   local tRect
   put the rect of me into tRect
   put item 2 of tRect + the formattedHeight of field 1 of me into item 4 of tRect
   set the rect of field 1 of me to tRect
   unlock messages
   unlock screen
end editorResize

on valueChanged
   local tHilitedLines, tOptions, tValue
   put the hilitedLines of field 1 of me into tHilitedLines
   put field 1 of me into tOptions
   repeat for each item tItem in tHilitedLines
      if tValue is empty then
         put line tItem of tOptions into tValue
      else
         put comma & line tItem of tOptions after tValue
      end if
   end repeat
   set the editorValue of me to tValue
   updateProperty
end valueChanged

on selectionChanged
   valueChanged
end selectionChanged
