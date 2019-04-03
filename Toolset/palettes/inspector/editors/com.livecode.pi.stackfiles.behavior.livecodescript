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
   
   if the editorEnabled of me then
      show button "Remove key" of me
      show button "New key" of me
   else
      hide button "Remove key" of me
      hide button "New key" of me
   end if
   set the editorExpandVertical of me to true
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
   
   local tManualHeight, tManualGroupHeight
   put getManualHeight() into tManualHeight
   if tManualHeight is not empty then
      put tManualHeight - the height of group "background" - kControlGap - 2 into tManualGroupHeight
      set the height of me to tManualGroupHeight
      set the height of the owner of me to tManualGroupHeight
   end if
   
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
         local tStackFilePaths
         put the result into tStackFilePaths
         
         if tStackFilePaths is not empty AND tStackFilePaths is not "cancel" then
            addStacks tStackFilePaths
         end if
         break
   end switch
end mouseUp


on dragEnter
   if the short name of the target is "stackFilesField" then
      if the dragData["files"] is not empty then
         local tExtensions, tFile
         
         set the wholematches to true
         put revIDEAcceptedTypes("stack") into tExtensions
         repeat for each line tFile in the dragData["files"]
            if fileExtension(tFile) is among the items of tExtensions then
               set the dragAction to "copy"
               exit repeat
            end if
         end repeat
      end if
   else
      pass dragEnter
   end if
end dragEnter


on dragDrop
   if the short name of the target is "stackFilesField" then
      addStacks the dragData["files"]
   else
      pass dragDrop
   end if
end dragDrop


private command addStacks pStackFilePaths
   local tEditorValue, tNewLine
   
   put the editorValue of me into tEditorValue
   
   repeat for each line tStackFilePath in pStackFilePaths
      put the short name of stack tStackFilePath & comma & tStackFilePath into tNewLine
      if tEditorValue is empty then
         put tNewLine into tEditorValue
      else
         put return & tNewLine after tEditorValue
      end if
   end repeat
   set the editorValue of me to tEditorValue
   updateProperty
end addStacks

private function fileExtension pFilename
   set the itemDelimiter to "/"
   put the last item of pFilename into pFilename
   set the itemDelimiter to "."
   if the number of items of pFilename > 1 then
      return the last item of pFilename
   else
      return empty
   end if
end fileExtension


on valueChanged
   local tValue
   put field "stackFilesField" into tValue
   replace tab with comma in tValue
   set the editorValue of me to tValue
   updateProperty
end valueChanged
