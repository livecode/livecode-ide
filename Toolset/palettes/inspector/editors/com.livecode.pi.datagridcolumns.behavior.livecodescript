script "com.livecode.pi.datagridcolumns.behavior"
on editorInitialize
   set the rowShowLabel of me to false
end editorInitialize

on editorUpdate
   lock screen
   local tHilited
   put the hilitedLines of field "columns" of me into tHilited
   
   local tArray, tColumns, tCount
   put the editorValue of me into tArray
   repeat with x = 1 to the number of elements in tArray
      if tColumns is empty then
         put tArray[x]["name"] into tColumns
      else
         put return & tArray[x]["name"] after tColumns
      end if
      
      if tArray[x]["current"] then
         put x into tHilited
      end if
   end repeat
   
   put tColumns into field "columns" of me
   
   if tHilited is 0 or tHilited is empty or tHilited > the number of lines in tColumns then
      put 1 into tHilited
   end if
   set the hilitedLines of field "columns" of me to tHilited
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   
   set the right of button "New Column" of me to the right of me
   set the right of button "Delete Column" of me to the left of button "New Column" of me
   
   local tLeft
   put the left of field "columns" of me into tLeft
   set the width of field "columns" of me to the right of me - tLeft
   set the left of field "columns" of me to tLeft
   unlock messages
   unlock screen
end editorResize

on mouseUp
   switch the short name of the target
      case "New Column"
         doNewColumn
         break
      case "Delete Column"
         doDeleteColumn
         break
      case "Move Up"
      case "Move Down"
         doMove word -1 of the short name of the target
         break
   end switch
end mouseUp

on selectionChanged
   valueChanged
end selectionChanged

private command doNewColumn
   local tColumns, tLineNo
   put field "columns" of me into tColumns
   put the number of lines in tColumns + 1 into tLineNo
   put "Col" && tLineNo into line tLineNo of tColumns
   put tColumns into field "columns" of me
   set the hilitedLines of field "columns" of me to tLineNo
   valueChanged
end doNewColumn

private command doDeleteColumn
   local tLineNo, tName
   set the caseSensitive to true
   put the hilitedLines of field "columns" of me into tLineNo
   put line tLineNo of field "columns" of me into tName
   
   if the number of words in tName is 0 then exit doDeleteColumn
   if the optionKey is not down then
      answer warning "Really delete column" && quote & tName & quote & "?" with "Cancel" or "Delete"
      if it is "Cancel" then exit doDeleteColumn
   end if
   delete line tLineNo of field "columns" of me
   set the hilitedLines of field "columns" of me to tLineNo -1
   valueChanged
end doDeleteColumn

private command doMove pWhich
   local tLineNo
   put the hilitedLines of field "columns" of me into tLineNo
   if tLineNo is 0 or tLineNo is empty then
      exit doMove
   end if
   
   if pWhich is "down" and tLineNo is the number of lines in field "columns" of me then 
      exit doMove
   end if
   
   if pWhich is "up" and tLineNo is 1 then 
      exit doMove
   end if
   
   local tColumns
   put field "columns" of me into tColumns
   
   local tMoved, tNumber
   if pWhich is "down" then
      put tLineNo + 1 into tNumber
   else
      put tLineNo -1 into tNumber
   end if
   put line tNumber of tColumns into tMoved
   put line tLineNo of tColumns into line tNumber of tColumns
   put tMoved into line tLineNo of tColumns
   
   put tColumns into field "columns" of me
   
   set the hilitedLines of fld "columns" to tNumber
   valueChanged
end doMove

on valueChanged pTargetName
   local tColumns, tCount, tArray
   put field "columns" into tColumns
   repeat for each line tColumn in tColumns
      add 1 to tCount
      if tCount is the hilitedLines of field "columns" then
         put true into tArray[tCount]["current"]
      end if
      put tColumn into tArray[tCount]["name"]
   end repeat
   set the editorValue of me to tArray
   updateProperty
end valueChanged

on doChangeName
   local tNewColumn, tOldColumn, tLineNo
   put the text of field "column name" of me into tNewColumn
   put the hilitedLines of fld "columns" into tLineNo
   if tLineNo is 0 or tLineNo is empty then
      put 1 into tLineNo
   end if
   put line tLineNo of of fld "columns" into tOldColumn
   
   local tValue
   put the editorValue of me into tValue
   
   local tColumnsList
   put fld "columns" into tColumnsList
   delete line tLineNo of tColumnsList
   if tNewColumn is among the lines of tColumnsList then
      answer error "This column already exists." with "Cancel"
      put tOldColumn into field "column name" of me
   end if
   
   if tValue[tOldColumn]["column behavior"] is not empty then 
      local tTemplate, tTemplateCard, tStackWord
      put tValue[tOldColumn]["record template"] into tTemplate
      put wordoffset("card",tTemplate) into tStackWord
      put word tStackWord to -1 of tTemplate into tTemplateCard
      if there is a control tOldColumn of tTemplateCard then
         set the name of control tOldColumn of tTemplateCard to tNewColumn
         if word 1 of the name of control tNewColumn of tTemplateCard is "group" and \
               there is a field 1 of group tNewColumn of tTemplateCard and \
               the text of field 1 of group tNewColumn of tTemplateCard is tOldColumn then
            set the text of field 1 of group tNewColumn of tTemplateCard to tNewColumn
         end if 
      end if
   end if
   local tOldButton
   put tOldColumn && "Behavior" into tOldButton
   if there is a button tOldButton of tTemplateCard then 
      set the name of btn tOldButton of tTemplateCard to (tNewColumn && "Behavior")
   end if
   set the editorValue["columns"] of me to tColumnsList
   updateProperty
end doChangeName
