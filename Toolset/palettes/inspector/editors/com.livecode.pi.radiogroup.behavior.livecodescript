script "com.livecode.pi.radiogroup.behavior"
constant kMaxWidth = 500
constant kRadioHeight = 21
on editorInitialize
   set the editorMaxWidth of me to kMaxWidth
   local tOptions
   put the editorOptions of me into tOptions
   lock messages
   set the radioBehavior of me to true
   set the autohilite of the templatebutton to false
   set the threed of the templatebutton to false
   set the showfocusborder of the templatebutton to false
   set the borderwidth of the templatebutton to 0
   set the style of the templatebutton to "radiobutton"
   set the script of the templatebutton to ("on mouseUp; dispatch" && quote & "valueChanged" & quote & ";end mouseUp")
   set the height of the templatebutton to kRadioHeight
   set the width of the templatebutton to the width of me
   set the itemdelimiter to "|"
   local tMinWidth
   repeat for each line tLine in tOptions
      if the number of items in tLine is 2 then
         create button item 2 of tLine in me
      else
         create button tLine in me
      end if
      set the label of it to item 1 of tLine
      if the formattedwidth of it > tMinWidth then
         put the formattedwidth of it into tMinWidth
      end if
   end repeat
   reset the templatebutton
   unlock messages
   
   local tDefault
   put the editorDefault of me into tDefault
   if there is a button tDefault of me then
      set the hilite of button tDefault of me to true
   end if
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
   if there is a button tValue then
      set the hilite of button tValue of me to true
   else if tDefault is not empty then
      set the hilite of button tDefault of me to true
   end if
   
   repeat for each line tControl in the childControlNames of me
      if tEnabled is not true then
         set the enabled of control tControl of me to false
      else
         set the enabled of control tControl of me to true
      end if
   end repeat
   
   
   unlock messages
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
   local tLastButton, tButton, tHeight
   set the itemdelimiter to "|"
   repeat for each line tLine in tOptions
      if the number of items in tLine is 2 then
         put item 2 of tLine into tButton
      else
         put tLine into tButton
      end if
      set the width of button tButton of me to 1000
      set the height of button tButton of me to kRadioHeight
      set the width of button tButton of me to the formattedWidth of button tButton of me
      set the topleft of button tButton of me to tLeft,tTop
      add the formattedWidth of button tButton of me to tLeft
      if tLeft > kMaxWidth then
         if tLastButton is not empty then
            add kRadioHeight to tTop
            add kRadioHeight to tHeight
            set the topleft of button tButton of me to the left of me,tTop
            put the formattedWidth of button tButton of me into tLeft
         end if
      end if
      put tButton into tLastButton
   end repeat
   if tLastButton is not empty then
      add kRadioHeight to tHeight
   end if
   unlock messages
   set the editorHeight of me to tHeight
   set the editorMinWidth of me to tLeft - the left of me
   unlock screen
end editorResize

on valueChanged
   hilite the target
   set the itemdelimiter to "|"
   set the editorValue of me to the hilitedButtonName of me
   updateProperty
end valueChanged
