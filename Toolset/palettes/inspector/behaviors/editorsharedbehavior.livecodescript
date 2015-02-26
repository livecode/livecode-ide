script "editorSharedBehavior"
local sPropertyInfo
setProp editorPropertyInfo pPropertyInfo
   put pPropertyInfo into sPropertyInfo
end editorPropertyInfo

getProp editorProperty
   return sPropertyInfo["property_name"]
end editorProperty

getProp editorOptions
   local tOptions
   put sPropertyInfo["options"] into tOptions
   if tOptions begins with "execute" then
      set the itemdelimiter to ":"
      do item 2 of tOptions
      return it
   end if
   return tOptions
end editorOptions

getProp editorDefault
   return sPropertyInfo["default"]
end editorDefault

local sEditorEffective
setProp editorEffective pStyle
   if pStyle is true then
      put true into sEditorEffective
   else
      put false into sEditorEffective
   end if
end editorEffective

getprop editorEffective
   if sEditorEffective is true then
      return true	
   else
      return false
   end if
end editorEffective

local sMaxWidth
setprop editorMaxWidth pMaxWidth
   if pMaxWidth is not a number then
      put 0 into pMaxWidth
   end if
   put pMaxWidth into sMaxWidth
end editorMaxWidth

getprop editorMaxWidth
   if sMaxWidth is empty then
      return 0
   end if	
   return sMaxWidth
end editorMaxWidth

local sMinWidth
setprop editorMinWidth pMinWidth
   if pMinWidth is not a number then
      put 0 into pMinWidth
   end if
   put pMinWidth into sMinWidth
end editorMinWidth

getprop editorMinWidth
   if sMinWidth is empty then 
      return 0
   end if	
   return sMinWidth
end editorMinWidth

local sDisabled
setProp editorDisabled pDisabled
   if pDisabled is true then
      put true into sDisabled
   else
      put false into sDisabled
   end if
end editorDisabled

getProp editorDisabled 
   if sDisabled is true then
      return true
   else
      return false
   end if
end editorDisabled

local sValue
setProp editorValue pValue
   put pValue into sValue
end editorValue

getProp editorValue
   return sValue
end editorValue

local sLastValue
on updateProperty
   if sValue is not sLastValue or sEditorEffective then 
      put sValue into sLastValue
      editorValueChanged sPropertyInfo["property_name"], sValue
   end if
end updateProperty

before mouseUp pButtonNumber
   if pButtonNumber is 3 then
      editorPopupMenu "Reset to default", the mouseloc
   else
      pass mouseUp
   end if
end mouseUp

on editorPopupMenu pMenuText, pLoc
   # Create the button that we're going to popup on this stack
   lock screen
   lock messages
   if there is a button "inspectMenu" of me then delete button "inspectMenu" of me
   create button "inspectMenu" in me
   set the style of button "inspectMenu" of me to "menu"
   set the menumode of button "inspectMenu" of me to "popup"
   set the visible of button "inspectMenu" of me to false
   set the text of button "inspectMenu" of me to pMenuText
   unlock messages
   unlock screen
   
   popup button "inspectMenu" of me at pLoc
   
   return it
end editorPopupMenu

on menuPick pPick
   lock screen
   set the editorValue of me to the editorDefault of me
   updateProperty
   unlock screen
end menuPick
