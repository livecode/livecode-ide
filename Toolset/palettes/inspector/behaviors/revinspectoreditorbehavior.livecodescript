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
local sValue
setProp editorValue[pKey] pValue
   set the casesensitive to true
   if sValue is empty or pValue is not sValue or sEditorEffective then
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

on updateProperty pForce
   if pForce or (sAllowUpdate is true and not sPropertyInfo["read_only"]) then
      set the itemdelimiter to ";"
      -- Single editors can control multiple properties delimited by ;
      if the number of items in sPropertyInfo["property_name"] > 1 then
         repeat for each item tProp in sPropertyInfo["property_name"]
            dispatch "editorValueChanged" with tProp, sValue[tProp], false
         end repeat
      else
         dispatch "editorValueChanged" with sPropertyInfo["property_name"], sValue, false
      end if
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
   
end editorPopup

after editorPopup pClickLoc
   local tStackName
   put popupStackName() into tStackName
   if tStackName is in the openstacks then
      exit editorPopup
   end if
   create invisible stack tStackName
   dispatch "setAsBehavior" to stack \
         revIDEPaletteResourcePath("behaviors/revinspectorpopupstackbehavior.livecodescript", \
         the long id of stack "revInspector") with the long id of stack tStackName
   set the frameHidden of stack tStackName to true
   dispatch "inspectorGenerateGroups" to stack tStackName with sPropertyInfo["popup"]
   dispatch "inspectorLayoutGroups" to stack tStackName with sPropertyInfo["popup"]
   dispatch "inspectorFillGroups" to stack tStackName with sPopupData
   set the editorTarget of stack tStackName to the long id of me
   // In LC 9.0 DP-7 you can resize the inspector window, by putting all the contents in a group "inspector" and adding a vScrollbar to the group
   // but 'modeless stack X' breaks the vScrollbar of groups, so ensure the popup stack has the correct height before going 'modeless'
   set the height of stack tStackName to \
         the formattedHeight of group "inspector" of stack tStackName
   set the title of stack tStackName to the rowLabel of the owner of me
   modeless stack tStackName
end editorPopup

private function popupStackName
   return "revPropertyPopup" && sPropertyInfo["property_name"]
end popupStackName

setProp editorPopupData pData
   if pData is not sPopupData then
      local tStackName
      put popupStackName() into tStackName
      put pData into sPopupData
      if there is a stack tStackName then
         dispatch "inspectorFillGroups" to stack tStackName with sPopupData
      end if
   end if
end editorPopupData

getProp editorPopupData
   return sPopupData
end editorPopupData

command editorDeletePopup
   local tStackName
   put popupStackName() into tStackName
   if there is a stack tStackName then
      delete stack tStackName
   end if
end editorDeletePopup

after popupDismissed
   editorDeletePopup
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

local sConflicts
setProp editorConflicts pValue
   put pValue into sConflicts
end editorConflicts
   
getprop editorConflicts
   return sConflicts
end editorConflicts

on editorFinalize
   if there is a stack popupStackName()  then
      dispatch "popupDismissed" to me
   end if
end editorFinalize

local sExpandVertical
setProp editorExpandVertical pValue
   put pValue into sExpandVertical
end editorExpandVertical

getProp editorExpandVertical
   return sExpandVertical
end editorExpandVertical

on rawKeyDown pKeyNum
   -- allow scroll wheel, pgup, & pgdn to scroll the text field
   -- bubble up to the parent if at either limit
   if the target contains "field" then
      local tScrollPosition, tScrollAmount, tScrollMax
      put the vScroll of the target into tScrollPosition
      put 0 into tScrollAmount
      switch pKeyNum
         case "65365"
            put 45 into tScrollAmount
            -- fall through
         case "65309"
            if tScrollPosition is 0 then pass rawKeyDown
            add 5 to tScrollAmount
            put max(0, tScrollPosition - tScrollAmount) into tScrollPosition
            break
         case "65366"
            put 45 into tScrollAmount
            -- fall through
         case "65308"
            add 5 to tScrollAmount
            put the formattedHeight of the target - \
                  the height of the target into tScrollMax
            if tScrollPosition is tScrollMax then pass rawKeyDown
            put min(tScrollMax, tScrollPosition + tScrollAmount) \
                  into tScrollPosition
            break
         default
            pass rawKeyDown
      end switch
      set the vScroll of the target to tScrollPosition
   else
      pass rawKeyDown
   end if
end rawKeyDown

after openField
   select the text of the target
end openField
