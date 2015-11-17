script "revInspectorEditorBehavior"
local sPropertyInfo
setProp editorPropertyInfo pPropertyInfo
   put pPropertyInfo into sPropertyInfo
   if pPropertyInfo["read_only"] is true then
      set the editorEnabled of me to false
   end if
end editorPropertyInfo

function editorPropertyGet pProperty
   if pProperty is empty then exit editorPropertyGet
   return sPropertyInfo[pProperty]
end editorPropertyGet

getProp editorProperty[pProperty]
   if pProperty is empty then exit editorProperty
   return sPropertyInfo[pProperty]
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

local sEnabled
setProp editorEnabled pEnabled
   if pEnabled is true then
      put true into sEnabled
   else
      put false into sEnabled
   end if
end editorEnabled

getProp editorEnabled 
   if sEnabled is false then
      return false
   else
      return true
   end if
end editorEnabled

local sAllowUpdate
local sLastValue
local sValue
setProp editorValue[pKey] pValue
   set the casesensitive to true
   if sLastValue is empty or pValue is not sLastValue or sEditorEffective then 
      put sValue into sLastValue
      if pKey is not empty then
         put pValue into sValue[pKey]
      else
         put pValue into sValue
      end if
      put true into sAllowUpdate
   end if
end editorValue

getProp editorValue[pKey]
   if pKey is not empty then
      return sValue[pKey]
   else
      return sValue
   end if
end editorValue

on updateProperty
  if sAllowUpdate is true then
     dispatch "editorValueChanged" with sPropertyInfo["property_name"], sValue, false, sPropertyInfo["setter"]
     put false into sAllowUpdate
   end if
end updateProperty

before mouseUp pButtonNumber
      if pButtonNumber is 3 and sPropertyInfo["default"] is not "no_default" then
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
   local tDefault
   put the editorDefault of me into tDefault
   if tDefault is not "no_default" then
      if tDefault is "empty" then
         set the editorValue of me to empty
      else
         set the editorValue of me to tDefault
      end if
      updateProperty
   end if
   unlock screen
end menuPick

local sHeight
setprop editorHeight pHeight
   if pHeight is not a number then
      put 0 into pHeight
   end if
   put pHeight into sHeight
end editorHeight

getprop editorHeight
   if sHeight is empty then 
      return 0
   end if	
   return sHeight
end editorHeight

getProp editorWidth
   return the formattedWidth of me
end editorWidth

local sPopupData
on editorPopup pClickLoc
   create invisible stack sPropertyInfo["property_name"]
   dispatch "setAsBehavior" to stack revIDEPaletteResourcePath("behaviors/revinspectorpopupstackbehavior.livecodescript", the long id of stack "revInspector") with the long id of stack sPropertyInfo["property_name"]
   set the frameHidden of stack sPropertyInfo["property_name"] to true
   dispatch "inspectorGenerateGroups" to stack sPropertyInfo["property_name"] with sPropertyInfo["popup"]
   dispatch "inspectorLayoutGroups" to stack sPropertyInfo["property_name"] with sPropertyInfo["popup"]
   dispatch "inspectorFillGroups" to stack sPropertyInfo["property_name"]  with sPopupData
   set the editorTarget of stack sPropertyInfo["property_name"] to the long id of me
   modal stack sPropertyInfo["property_name"]
end editorPopup

setProp editorPopupData pData
   if pData is not sPopupData then
      put pData into sPopupData
      if there is a stack sPropertyInfo["property_name"] then
         dispatch "inspectorFillGroups" to stack sPropertyInfo["property_name"]  with sPopupData
      end if
   end if
end editorPopupData

getProp editorPopupData
   return sPopupData
end editorPopupData

on popupDismissed
   delete stack sPropertyInfo["property_name"]
end popupDismissed

getProp storedValue
   dispatch function "editorStoredValue" with sPropertyInfo["property_name"]
   return the result
end storedValue

on storeProperty
   dispatch "editorStoreValue" with sPropertyInfo["property_name"], sValue
end storeProperty

getProp editorLabel
   global gRevLanguageNames
   if gRevLanguageNames then
      return sPropertyInfo["property_name"]
   else
      return sPropertyInfo["label"]
   end if
end editorLabel

local sConflicted
setProp editorConflicted pValue
   put pValue into sConflicted
end editorConflicted
   
getprop editorConflicted
   return sConflicted
end editorConflicted
