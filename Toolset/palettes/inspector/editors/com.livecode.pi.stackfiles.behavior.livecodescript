script "com.livecode.pi.stackfiles.behavior"
constant kColumnHeaderHeight = 17
constant kButtonHeight = 19
constant kControlGap = 5
constant kStackColumnWidth = 185

local sSort

on editorInitialize
   put "stack" into sSort
   put the editorLabel of me into field "label" of me
   set the rowShowLabel of me to false
end editorInitialize

on editorUpdate
   local tValue
   put the editorValue of me into tValue
   lock messages
   replace comma with tab in tValue
   put tValue into field "stackFilesField" of me
   
   if sSort is "stack" then
      sort lines of field "stackFilesField" of me by item 1 of each
   else
      sort lines of field "stackFilesField" of me by item 2 of each
   end if
   unlock messages
end editorUpdate

on editorResize
   lock messages
   local tRect, tFieldRect
   put the rect of me into tRect
   
   put tRect into tFieldRect
   put item 2 of tFieldRect + kButtonHeight + kColumnHeaderHeight + kControlGap into item 2 of tFieldRect
   set the effective rect of field "stackFilesField" of me to tFieldRect
   set the rect of button "Remove key" of me to 0, 0, kButtonHeight, kButtonHeight
   set the topright of button "Remove key" of me to the topright of me
   set the rect of button "New key" of me to 0, 0, kButtonHeight, kButtonHeight
   set the topright of button "New key" of me to the topleft of button "Remove key" of me
   set the rect of button "stack" of me to 0,0,kStackColumnWidth,kColumnHeaderHeight
   set the bottomleft of button "stack" of me to the topleft of field "stackFilesField" of me
   set the rect of button "file path" of me to 0,0,the width of field "stackFilesField" of me - kStackColumnWidth,kColumnHeaderHeight
   set the bottomleft of button "file path" of me to the bottomright of button "stack" of me
   set the topleft of field "label" of me to the topleft of me
   unlock messages
   set the editorHeight of me to the height of field "stackFilesField" of me + kButtonHeight + kColumnHeaderHeight + kControlGap
end editorResize

on mouseUp
   switch the short name of the target
      case "Stack"
         put "stack" into sSort
         editorUpdate
         break
      case "File Path"
         put "file" into sSort
         editorUpdate
         break
      case "Remove key"
         local tHilitedLine
         put the hilitedLine of field "stackFilesField" into tHilitedLine
         if tHilitedLine is not empty then
            lock messages
            delete line tHilitedLine of field "stackFilesField"
            unlock messages
            valueChanged
         end if
         break
      case "New key"
         revIDEAnswerFile "stack"
         
         # Get the path of to the file
         local tStackFilePath
         put the result into tStackFilePath
         
         if tStackFilePath is not empty then
            local tEditorValue, tNewLine
            put the short name of stack tStackFilePath & comma & tStackFilePath into tNewLine
            put the editorValue of me into tEditorValue
            if tEditorValue is empty then
               put tNewLine into tEditorValue
            else
               put return & tNewLine after tEditorValue
            end if
            set the editorValue of me to tEditorValue
            updateProperty
         end if
         break
   end switch
end mouseUp

on valueChanged
   local tValue
   put field "stackFilesField" into tValue
   replace tab with comma in tValue
   set the editorValue of me to tValue
   updateProperty
end valueChanged
