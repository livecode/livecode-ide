script "com.livecode.pi.multiplechoice.behavior"
constant kMaxWidth = 500
constant kRadioHeight = 21
constant kControlGap = 5
on editorInitialize
   set the editorMaxWidth of me to kMaxWidth
   local tOptions
   put the editorOptions of me into tOptions
   local tDefault
   put the editorDefault of me into tDefault
   lock messages
   
   local tChoices, tProps
   set the itemdelimiter to ":"
   put item 1 of tOptions into tChoices
   put item 2 to -1 of tOptions into tProps
   
   set the itemdelimiter to "|"
   
   set the radioBehavior of the templateGroup to true
   set the behavior of the templateGroup to the long id of button "group behavior" of stack "com.livecode.pi.multiplechoice"
   set the visible of the templateGroup to true
   
   set the autohilite of the templatebutton to false
   set the threed of the templatebutton to false
   set the showfocusborder of the templatebutton to false
   set the borderwidth of the templatebutton to 0
   set the style of the templatebutton to "radiobutton"
   set the script of the templatebutton to ("on mouseUp; dispatch" && quote & "valueChosen" & quote & ";end mouseUp")
   set the height of the templatebutton to kRadioHeight
   set the width of the templatebutton to the width of me
   
   local tGroup,tMinWidth
   repeat for each line tLine in tProps
      if item 2 of tLine is not empty then
         create group item 2 of tLine in me
      else
         create group item 1 of tLine in me
      end if
      put the long id of it into tGroup
      
      create field "label" in tGroup
      set the text of it to item 1 of tLine
      set the width of it to the width of me
      
      local tFormattedWidth, tFieldWidth
      put the formattedWidth of it into tFieldWidth
      put (the number of lines in tChoices + 1) * tFieldWidth into tMinWidth
      
      repeat for each line tChoice in tChoices
         if item 2 of tChoice is not empty then
            create button item 2 of tChoice in tGroup
         else
            create button item 1 of tChoice in tGroup
         end if
         set the label of it to item 1 of tChoice
         put the formattedwidth of it + kControlGap into tFormattedWidth
         if (the number of lines in tChoices + 1) * tFormattedWidth + tFieldWidth > tMinWidth then
            put (the number of lines in tChoices + 1) * tFormattedWidth + tFieldWidth into tMinWidth
         end if
      end repeat
      
      if there is a button tDefault of tGroup then
         set the hilite of button tDefault of tGroup to true
      end if
   end repeat
   
   reset the templatebutton
   reset the templategroup
   unlock messages
   set the editorMinWidth of me to tMinWidth
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled, tDefault
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   put the editorDefault of me into tDefault
   lock messages
   repeat for each key tKey in tValue
      if there is a group tKey of me then
         if there is a button tValue[tKey] then
            set the hilite of button tValue[tKey] of group tKey of me to true
         else if tDefault is not empty then
            set the hilite of button tDefault of group tKey of me to true
         end if
      end if
   end repeat
   unlock messages
   repeat for each line tSubgroup in the childControlNames of me
      dispatch "setEnabled" to group tSubgroup of me with tEnabled
   end repeat
   unlock screen
end editorUpdate

on editorResize
   lock screen
   local tOptions
   put the editorOptions of me into tOptions
   lock messages
   local tTop, tLeft
   put the top of me into tTop
   put the left of me into tLeft
   
   local tChoices, tProps
   set the itemdelimiter to ":"
   put item 1 of tOptions into tChoices
   put item 2 to -1 of tOptions into tProps
   
   local tGroup, tHeight
   set the itemdelimiter to "|"
   repeat for each line tLine in tProps
      if the number of items in tLine is 2 then
         put item 2 of tLine into tGroup
      else
         put tLine into tGroup
      end if
      
      set the rect of group tGroup of me to the rect of me
      set the lockLoc of group tGroup of me to true
      unlock messages
      dispatch "resizeGroup" to group tGroup of me with tChoices
      lock messages
      set the height of group tGroup of me to the formattedheight of group tGroup of me
      set the width of group tGroup of me to the formattedWidth of group tGroup of me
      set the topleft of group tGroup of me to tLeft,tTop
      add kRadioHeight + kControlGap to tTop
      add kRadioHeight + kControlGap to tHeight
   end repeat
   unlock messages
   set the editorHeight of me to tHeight + kRadioHeight
   unlock screen
end editorResize

on valueChanged pGroup
   local tValue
   put the editorValue of me into tValue
   get the hilitedButtonName of group pGroup of me 
   if it is "n/a" then
      delete variable tValue[pGroup]
   else
      put it into tValue[pGroup]
   end if
   set the editorValue of me to tValue
   updateProperty
end valueChanged
