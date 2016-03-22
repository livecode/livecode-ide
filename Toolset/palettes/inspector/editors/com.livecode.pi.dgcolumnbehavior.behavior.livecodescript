script "com.livecode.pi.dgcolumnbehavior.behavior"
on editorInitialize
   
end editorInitialize

constant kControlGap = 6
on editorResize
   local tRight
   set the right of button "New Behavior" of me to the right of me
   put the left of button "New Behavior" of me - kControlGap into tRight
   
   set the width of button "Column Behavior..." of me to tRight - the left of me
   set the left of button "Column Behavior..." of me to the left of me
end editorResize

on editorUpdate
   local tValue
   put the editorValue of me into tValue
   set the enabled of button "Column Behavior..." of me to tValue is not empty
end editorUpdate

on mouseUp
   switch the short name of the target 
      case "Column Behavior..."
         goToBehavior
         break
      case "New Behavior"
         newBehavior
         break
   end switch
end mouseUp

on goToBehavior
   local tValue
   put the editorValue of me into tValue
   edit the script of the behavior of tValue
end goToBehavior 

on newBehavior
   set the editorValue of me to "newBehavior"
   updateProperty
end newBehavior
