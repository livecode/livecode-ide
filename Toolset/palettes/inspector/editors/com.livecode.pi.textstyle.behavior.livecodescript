script "com.livecode.pi.textstyle.behavior"
on editorInitialize
   set the editorMinWidth of me to 210
   set the editorMaxWidth of me to 0
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   local tSelected
   repeat for each item tItem in tValue
      get itemOffset(tItem, the segmentNames of widget 1 of me)
      if tSelected is empty then 
         put it into tSelected
      else
         put comma & it after tSelected
      end if
   end repeat
   set the selectedSegment of widget 1 of me to tSelected
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the height of widget 1 of me to 21
   set the width of widget 1 of me to 210
   set the left of widget 1 of me to the left of me
   set the top of widget 1 of me to the top of me
   unlock messages
   unlock screen
end editorResize

on valueChanged
   if the selectedSegment of widget 1 of me is empty then
      set the editorValue of me to empty
   else
      local tValue
      repeat for each item tItem in the selectedSegment of widget 1 of me
         get item tItem of the segmentNames of widget 1 of me
         if tValue is empty then 
            put it into tValue
         else
            put comma & it after tValue
         end if
      end repeat
      set the editorValue of me to tValue
   end if
   updateProperty
end valueChanged
