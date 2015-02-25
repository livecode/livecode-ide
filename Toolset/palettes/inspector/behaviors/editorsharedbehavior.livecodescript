script "editorSharedBehavior"

local sPropertyName
setProp editorProperty pPropertyName
   put pPropertyName into sPropertyName
end editorProperty

getProp editorProperty
   return sPropertyName
end editorProperty

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
      editorValueChanged sPropertyName, sValue
   end if
end updateProperty
