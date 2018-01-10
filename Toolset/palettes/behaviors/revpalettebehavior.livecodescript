script "revPaletteBehavior"
on setAsBehavior pTarget
   set the behavior of pTarget to the long id of this me
end setAsBehavior

local FOOTER_ACTION_MARGINS,HEADER_NAVIGATION_MARGINS,HEADER_ACTION_MARGINS

local BAR_HEIGHT = 21
CONSTANT BAR_MARGIN  = 5
local ITEM_SPACING = 10

CONSTANT TAB_TEXT_COLOR = "150,150,150"
local TAB_SELECTED_COLOR
local TAB_SELECTED_TEXT_COLOR
CONSTANT TAB_HOVER_COLOR = "200,200,200"
local TAB_HOVER_TEXT_COLOR
CONSTANT TAB_DISABLED_COLOR = "200,200,200"

local sNavStyle
local sData

local sHideFrame
setProp frameHidden pValue
   put pValue into sHideFrame
   if pValue is false then
      generateFrame
   end if
end frameHidden

local sShowPreferenceAction
setProp showPreferenceAction pValue
   if pValue is not sShowPreferenceAction then
      put pValue into sShowPreferenceAction
      resizeStack
   end if
end showPreferenceAction

on addFrameItem pName, pLocation, pItemType, pLabel, pIcon, pIconSelected, pCallbackMessage, pCallbackTarget, pParameter
   if __itemExists(pName) then return empty
   
   local tNewIndex
   put the number of elements of sData + 1 into tNewIndex
   
   switch pItemType
      case "preference"
         put pName into sData[tNewIndex]["name"]
         put pItemType into sData[tNewIndex]["type"]
         put pLabel into sData[tNewIndex]["label"]
         put pIcon into sData[tNewIndex]["value_type"]
         put pIconSelected into sData[tNewIndex]["value"]
         put pCallbackTarget into sData[tNewIndex]["target"]
         put pCallbackMessage into sData[tNewIndex]["message"]
         put pParameter into sData[tNewIndex]["parameter"]
         put true into sData[tNewIndex]["enabled"]
         put false into sData[tNewIndex]["selected"]
         break
      default
         put pName into sData[tNewIndex]["name"]
         put pLocation into sData[tNewIndex]["location"]
         put pItemType into sData[tNewIndex]["type"]
         put pLabel into sData[tNewIndex]["label"]
         put pIcon into sData[tNewIndex]["icon"]
         put pIconSelected into sData[tNewIndex]["icon_selected"]
         put pCallbackTarget into sData[tNewIndex]["target"]
         put pCallbackMessage into sData[tNewIndex]["message"]
         put pParameter into sData[tNewIndex]["parameter"]
         put true into sData[tNewIndex]["enabled"]
         put false into sData[tNewIndex]["selected"]
         break
   end switch
end addFrameItem

on showFrameItem pName
   local tIndex
   put __frameItemNameToIndex(pName) into tIndex
   if tIndex is not a number then exit showFrameItem
   
   put false into sData[tIndex]["hidden"] 
   generateFrame
end showFrameItem

on hideFrameItem pName
   local tIndex
   put __frameItemNameToIndex(pName) into tIndex
   if tIndex is not a number then exit hideFrameItem
   
   put true into sData[tIndex]["hidden"] 
   generateFrame
end hideFrameItem

on disableFrameItem pName
   setEnabledOfFrameItem pName, false
end disableFrameItem

on enableFrameItem pName
   setEnabledOfFrameItem pName, true
end enableFrameItem

command setEnabledOfFrameItem pName, pValue
   local tIndex
   put __frameItemNameToIndex(pName) into tIndex
   if tIndex is not a number then exit setEnabledOfFrameItem
   
   lock screen
   lock messages
   put pValue into sData[tIndex]["enabled"] 
   generateFrame
   unlock messages
   unlock screen
end setEnabledOfFrameItem

on toggleFrameItem pName, pValue
   local tIndex
   put __frameItemNameToIndex(pName) into tIndex
   if tIndex is not a number then exit toggleFrameItem
  
   put pValue into sData[tIndex]["selected"]
   generateFrame
end toggleFrameItem

on hiliteFrameItem pName
   lock screen
   lock messages
   local tIndex
   __unhiliteFrameNavigation
   put __frameItemNameToIndex(pName) into tIndex
   if tIndex is not a number then exit hiliteFrameItem
   
   put true into sData[tIndex]["selected"] 
   set the selectedNavItem of widget "header_background" of group "background" of me to pName
   
   unlock messages
   unlock screen
end hiliteFrameItem

on clearFrameData
   put empty into sData
end clearFrameData

on clearFrameNavigationData
   local tNewDataA, tCount, tElement
   repeat with x = 1 to the number of elements in sData
      put sData[x] into tElement
      if tElement["type"] is "navigation" then
         next repeat
      end if
      add 1 to tCount
      put tElement into tNewDataA[tCount]
   end repeat
   put tNewDataA into sData
end clearFrameNavigationData

private on appendMenuItem pNavItem, @xMenuArray
   local tMenuItemA
   
   local tPreferenceValue
   put revIDEGetPreference(pNavItem["name"]) into tPreferenceValue
   
   put pNavItem["label"] into tMenuItemA["label"]
   put pNavItem["name"] into tMenuItemA["name"]
   
   switch pNavItem["value_type"]
      case "enum"
      case "set"
         local tValue, tLabel, tItemCount
         repeat for each item tItem in pNavItem["value"]
            add 1 to tItemCount
            # Parse out the value and label from the item
            set the itemdel to ":"
            if the number of items of tItem > 1 then
               put item 1 of tItem into tValue
               put item 2 of tItem into tLabel
            else
               put tItem into tLabel
               put tItem into tValue
            end if
            set the itemdel to comma
            
            # Enums can't be empty so use the first value by default
            if tPreferenceValue is empty and pNavItem["value_type"] is "enum" then 
               put tValue into tPreferenceValue
            end if
            
            put tLabel into tMenuItemA["menu"][tItemCount]["label"]
            put tValue into tMenuItemA["menu"][tItemCount]["name"]
            
            local tChecked
            if pNavItem["value_type"] is "enum" then
               put tValue is tPreferenceValue into tChecked
            else
               if the number of lines in tPreferenceValue > 1 then
                  put tValue is among the lines of tPreferenceValue into tChecked
               else
                  put tValue is among the items of tPreferenceValue into tChecked
               end if
            end if
            
            if tChecked then
               put true into tMenuItemA["menu"][tItemCount]["checked"]
            else
               put false into tMenuItemA["menu"][tItemCount]["checked"]
            end if
         end repeat
         break
      case "boolean"
         if tPreferenceValue is true then
            put true into tMenuItemA["checked"]
         else
            put false into tMenuItemA["checked"]
         end if
         break
      default
         break
   end switch
   
   local tCount
   put the number of elements in xMenuArray into tCount
   add 1 to tCount
   put tMenuItemA into xMenuArray[tCount]
end appendMenuItem

private function preferenceAction pMenuArray
   local tDataA
   put empty into tDataA
   put "preferences" into tDataA["name"]
   put "Preferences" into tDataA["label"]
   put "cog" into tDataA["icon"]
   put pMenuArray into tDataA["menu"]
   put true into tDataA["enabled"]
   return tDataA
end preferenceAction

function canonicalStackName
   local tName
   put the short name of me into tName
   
   # Workaround for inspector copies
   if word 1 of tName is "revPropertyInspector" then
      put "revInspector" into tName
   end if
   
   replace " " with "_" in tName
   
   return tName
end canonicalStackName

on generateFrame
   if sHideFrame is true then
      exit generateFrame
   end if
   
   if sShowPreferenceAction is not false then
      # Add the preference of header size
      addFrameItem "revPaletteFrameSize", "header", "preference", "Header // Footer Size", "enum","small,medium,large,largest", "revIDEFrameSizeChanged", the long id of me
      # Add the preference to use icons / names
      addFrameItem canonicalStackName() & "_displayStyle", "header", "preference", "Tab Display Style", "enum","icons:Icons,names:Labels", "displayPreferenceChanged", the long id of me
      # Ensure the display style matches the saved preference
      if sNavStyle is empty then
         put revIDEGetPreference(canonicalStackName() & "_displayStyle") into sNavStyle
      end if
   end if
   
   lock screen
   lock messages
   
   reset the templategroup
   set the defaultstack to the long ID of me
   set the backgroundbehavior of the templategroup to true
   set the sharedbehavior of the templategroup to true
   if there is not a group "background" of me then
      create group "background"
   end if
   reset the templategroup
   
   # Generate all the button fields 
   
   local tPreferences, tNavigation, tHeaderAction
   local tHeaderActionDataA, tHeaderActionCount
   local tHeaderNavDataA, tHeaderNavCount
   local tFooterActionDataA, tFooterActionCount, tHeaderPreferenceCount
   put false into tPreferences
   put false into tNavigation
   put false into tHeaderAction
   
   local tPreferenceMenuA, tDataA, tSelected
   # Gather the data to set on the widget(s)
   repeat with x = 1 to the number of elements in sData
      local tNavItem
      put sData[x] into tNavItem
      if tNavItem["hidden"] is true then
         next repeat
      end if
      
      put empty into tDataA
      put tNavItem["name"] into tDataA["name"]
      put tNavItem["label"] into tDataA["label"]
      put tNavItem["icon"] into tDataA["icon"]
      
      --put tNavItem["icon_selected"] into tDataA["icon_selected"]
      
      switch tNavItem["type"]
         case "preference"
            # Add preference data to the preference menu
            add 1 to tHeaderPreferenceCount
            appendMenuItem tNavItem, tPreferenceMenuA
            break
         case "navigation"
            add 1 to tHeaderNavCount
            put tDataA into tHeaderNavDataA[tHeaderNavCount]
            if tNavItem["selected"] then
               put tNavItem["name"] into tSelected
            end if
            break
         case "toggle"
         case "action"
            put tNavItem["enabled"] into tDataA["enabled"]
            if tNavItem["selected"] then
               put tNavItem["icon_selected"] into tDataA["icon"]
            end if
            if tNavItem["location"] is "header" then
               add 1 to tHeaderActionCount
               put tDataA into tHeaderActionDataA[tHeaderActionCount]
            else if tNavItem["location"] is "footer" then
               add 1 to tFooterActionCount
               put tDataA into tFooterActionDataA[tFooterActionCount]
            end if
            break
      end switch
   end repeat
   
   # If we have any preferences, add that to the beginning of the header actions
   if tPreferenceMenuA is not empty then
      put preferenceAction(tPreferenceMenuA) into tHeaderActionDataA[0]
   end if
   
   if tHeaderNavCount is not 0 or tHeaderActionCount is not 0 or tHeaderPreferenceCount is not 0 then
      if there is not a widget "header_background" of group "background" of me then 
         create widget "header_background" as "com.livecode.widget.paletteActions" in group "background" of me
      end if
      set the isHeader of widget "header_background" of group "background" of me to true
      set the navData of widget "header_background" of group "background" of me to tHeaderNavDataA
      set the actionData of widget "header_background" of group "background" of me to tHeaderActionDataA
      if sNavStyle is "names" then
         set the showNavIcons of widget "header_background" of group "background" of me to false
      else
         set the showNavIcons of widget "header_background" of group "background" of me to true
      end if
      set the hiliteColor of widget "header_background" of group "background" of me to revIDEColor("edition_color")
      set the borderColor of widget "header_background" of group "background" of me to "178,178,178"
   else
      if there is a widget "header_background" of group "background" of me then 
         delete widget "header_background" of group "background" of me 
      end if
   end if
   
   if tFooterActionCount is not 0 then
      if there is not a widget "footer_background" of group "background" of me then 
         create widget "footer_background" as "com.livecode.widget.paletteActions" in group "background" of me
      end if
      set the isHeader of widget "footer_background" of group "background" of me to false
      set the actionData of widget "footer_background" of group "background" of me to tFooterActionDataA
      set the navData of widget "footer_background" of group "background" of me to empty
      set the hiliteColor of widget "footer_background" of group "background" of me to revIDEColor("edition_color")
      set the borderColor of widget "footer_background" of group "background" of me to "178,178,178"
   else
      if there is a widget "footer_background" of group "background" of me then 
         delete widget "footer_background" of group "background" of me 
      end if
   end if
   
   layoutFrame true
   
   unlock messages
   unlock screen
end generateFrame

function barHeight pSize
   if sHideFrame is true then
      return 0
   end if
   
   switch pSize
      case "small"
         return 21
      case "medium"
         return 25
      case "largest"
         return 35
      case "large"
      default
         return 30
   end switch
end barHeight

function barRight pSize
   if there is a widget "header_background" of group "background" of me then
      return the navBarRight of widget "header_background" of group "background" of me
   end if
   
   return 0
end barRight

on layoutFrame pForceRecalculate
   lock screen
   lock messages
   if there is not a group "background" of me then
      # Place the background from another card
      local tCardNumber
      put the number of this card into tCardNumber
      repeat with x = 1 to the number of cards of me
         if there is a group "background" of card x of me and x is not tCardNumber then
            place group "background" of card x of me onto this card
            exit repeat
         end if
      end repeat 
   end if
   
   if pForceRecalculate then
      # Setup the size everything should be
      local tIconTextSize, tTextSize, tHeaderHeight
      put  revIDEGetPreference("revPaletteFrameSize") into tHeaderHeight
      
      switch tHeaderHeight
         case "small"
            put barHeight("small") into BAR_HEIGHT
            put 7 into ITEM_SPACING
            put 1,10,1,0 into FOOTER_ACTION_MARGINS
            put 3,3,3,0 into HEADER_ACTION_MARGINS
            put round(BAR_HEIGHT * 0.6) into tIconTextSize
            if sNavStyle is "names" then
               put 10,11,8,0 into HEADER_NAVIGATION_MARGINS
            else
               put 7,9,5,0 into HEADER_NAVIGATION_MARGINS
            end if
            put 10 into tTextSize
            break
         case "medium"
            put barHeight("medium")  into BAR_HEIGHT
            put 8 into ITEM_SPACING
            put 1,10,1,0 into FOOTER_ACTION_MARGINS
            put 3,3,3,0 into HEADER_ACTION_MARGINS
            put round(BAR_HEIGHT * 0.6) into tIconTextSize
            if sNavStyle is "names" then
               put 10,11,8,0 into HEADER_NAVIGATION_MARGINS
            else
               put 8,9,6,0 into HEADER_NAVIGATION_MARGINS
            end if
            put 12 into tTextSize
            break
         case "largest"
            put barHeight("largest") into BAR_HEIGHT
            put 12 into ITEM_SPACING
            put 1,10,1,0 into FOOTER_ACTION_MARGINS
            put 1,5,1,0 into HEADER_ACTION_MARGINS
            put round(BAR_HEIGHT * 0.6) into tIconTextSize
            if sNavStyle is "names" then
               put 10,11,8,0 into HEADER_NAVIGATION_MARGINS
            else
               put 12,13,12,0 into HEADER_NAVIGATION_MARGINS
            end if
            put 16 into tTextSize
            break
         case "large"
         default
            put barHeight("large") into BAR_HEIGHT
            put 10 into ITEM_SPACING
            put 1,10,1,0 into FOOTER_ACTION_MARGINS
            put 1,5,1,0 into HEADER_ACTION_MARGINS
            put round(BAR_HEIGHT * 0.6) into tIconTextSize
            if sNavStyle is "names" then
               put 10,11,8,0 into HEADER_NAVIGATION_MARGINS
            else
               put 10,11,8,0 into HEADER_NAVIGATION_MARGINS
            end if
            put 14 into tTextSize
            break
      end switch
      
      local tHeaderWidth, tFooterWidth
      if there is a widget "header_background" of group "background" of me then
         set the height of widget "header_background" of group "background" of me to BAR_HEIGHT
         put the minWidth of widget "header_background" of group "background" of me into tHeaderWidth
      end if
      if there is a widget "footer_background" of group "background" of me then 
         set the height of widget "footer_background" of group "background" of me to BAR_HEIGHT
         put the minWidth of widget "footer_background" of group "background" of me into tFooterWidth 
      end if
      
      local tMinWidth
      put max(tFooterWidth, tHeaderWidth) into tMinWidth
      
      set the minwidth of me to tMinWidth
      if tMinWidth > the width of me then
         local tStackLeft
         put the left of me into tStackLeft
         set the width of me to tMinWidth
         set the left of me to tStackLeft
      end if
   end if
   
   if there is a widget "header_background" of group "background" of me then 
      set the width of widget "header_background" of group "background" of me to the width of me
      set the topleft of widget "header_background" of group "background" of me to 0,0
   end if
   if there is a widget "footer_background" of group "background" of me then
      set the width of widget "footer_background" of group "background" of me to the width of me
      set the bottomleft of widget "footer_background" of group "background" of me to 0,the height of me
   end if
   unlock messages
   if pForceRecalculate then
      dispatch "resizeStack" to this card of me with \
            the width of this card of me, the height of this card of me
   end if
   
   unlock screen
end layoutFrame

# Sent when the tab navigation is clicked
on navChanged
   layoutFrame true
end navChanged

# Sent when the preference changes
on displayPreferenceChanged pPreference, pValue
   local tName
   put canonicalStackName() into tName
   switch pPreference
      case tName & "_displayStyle"
         set the navigationDisplayStyle of me to pValue
         revIDESetPreference tName & "_displayStyle", pValue
         break
      default
         break
   end switch
end displayPreferenceChanged

on revIDEFrameSizeChanged pName, pValue
   revIDESetPreference "revPaletteFrameSize", pValue
end revIDEFrameSizeChanged

after resizeStack
   if sHideFrame is not true then
      layoutFrame
   end if
end resizeStack

on ideDesktopChanged
   revIDEEnsureOnScreen the short name of this stack
end ideDesktopChanged

after openCard
   generateFrame
end openCard

before preOpenStack
   if the visible of me is true then
      hide me
   end if
end preOpenStack

after preOpenStack
   revIDESubscribe "ideDesktopChanged"
   if sHideFrame is not true then
      put revIDEColor("edition_color") into TAB_SELECTED_TEXT_COLOR
      put revIDEColor("edition_color") into TAB_HOVER_TEXT_COLOR
      revIDESubscribe "idePreferenceChanged:revPaletteFrameSize"
      generateFrame
      
      # set the default position of the stack. revIDEPaletteRect will return either a rect or a topLeft position for the stack
      revIDEPositionPalette the short name of me
   end if
end preOpenStack

after openStack
   if the visible of me is false then
      show me
   end if
end openStack

# MDW-2015-12-21 [[ unsubscribe_on_closestack]] plays well with others
on closeStack
	revIDEUnsubscribeAll
	pass closeStack
end closeStack

after closeStack
   revIDESetPaletteRectPreference the short name of me
end closeStack

# Description
#    Sent when the script editor is moved. Saves the new size in the preferences.
after moveStack
   revIDESetPaletteRectPreference the short name of me
end moveStack

private on __doCallback pDataIndex
   local tData
   put sData[pDataIndex] into tData
   
   # Get callback info
   local tMessage, tTarget, tParameter
   put tData["message"] into tMessage
   put tData["target"] into tTarget
   put tData["parameter"] into tParameter   
   
   # Set highlight
   switch tData["type"] 
      case "navigation" 
         __unhiliteFrameNavigation
         dispatch tMessage to tTarget with tParameter
         put true into sData[pDataIndex]["selected"]
         break
      case "toggle"
         local tNewValue
         put not tData["selected"] into tNewValue
         dispatch tMessage to tTarget with tNewValue
         put tNewValue into sData[pDataIndex]["selected"]
         generateFrame
         break
      default
         dispatch tMessage to tTarget with tParameter
         break
   end switch
end __doCallback

before actionSelected pActionName
   lock screen
   # Get index
   local tIndex
   put __frameItemNameToIndex(pActionName) into tIndex
   __doCallback tIndex
   unlock screen
end actionSelected

before navSelected pNavName
   lock screen
   # Get index
   local tIndex
   put __frameItemNameToIndex(pNavName) into tIndex
   __doCallback tIndex
   unlock screen
end navSelected

before menupick pItem
   # Find out the name of the preference
   set the itemdel to "|"
   local tIndex, tName
   put item 1 of pItem into tName
   put __frameItemNameToIndex(tName) into tIndex
   
   # Get the callback from the data array
   local tMessage, tTarget
   put sData[tIndex]["message"] into tMessage
   put sData[tIndex]["target"] into tTarget
   
   if not exists(tTarget) then exit menupick
   
   local tValue
   if the number of items of pItem is 1 then
      put not revIDEGetPreference(tName) into tValue
   else
      put item 2 of pItem into tValue
   end if
   lock screen
   dispatch tMessage to tTarget with tName,tValue
   generateFrame
   unlock screen
end menupick

getProp contentRect
   if sHideFrame is true then
      return 0,5,the height of me, the width of me
   end if
   
   lock messages
   local tTop,tBottom,tBarSize
   
   put barHeight(revIDEGetPreference("revPaletteFrameSize")) into tBarSize
   
   put the height of me into tBottom
   repeat for each element tElement in sData
      if tElement["location"] is "footer" then
         put the height of me - tBarSize into tBottom
         exit repeat
      end if
   end repeat
   unlock messages
   
   return 0,tBarSize,the width of me,tBottom
end contentRect

getProp paletteMargin
  return 6
end paletteMargin

getProp palettePadding
  return 3
end palettePadding

getProp headerHeight
   return barHeight(revIDEGetPreference("revPaletteFrameSize"))
end headerHeight

getProp footerHeight
   local tBarSize, tHeight
   put barHeight(revIDEGetPreference("revPaletteFrameSize")) into tBarSize
   
   put 0 into tHeight
   repeat for each element tElement in sData
      if tElement["location"] is "footer" then
         put tBarSize into tHeight
         exit repeat
      end if
   end repeat
   
   return tHeight
end footerHeight

setProp hilitedTabColor pColor
  put pColor into TAB_SELECTED_COLOR
end hilitedTabColor

setProp navigationDisplayStyle pStyle
   switch pStyle
      case "names" 
         put "names" into sNavStyle
         break
      default
         put "icons" into sNavStyle 
   end switch
end navigationDisplayStyle

private function __frameItemNameToIndex pName
   repeat for each key tIndex in sData
      if sData[tIndex]["name"] is pName then return tIndex
   end repeat
end __frameItemNameToIndex

local sHilitedIndex
private on __hiliteFrameItem pIndex
   if pIndex is empty then put sHilitedIndex into pIndex
   else put pIndex into sHilitedIndex
   
   if sHilitedIndex is not a number then return empty
   
   lock screen
   lock messages
   local tName
   put sData[pIndex]["name"] into tName
   
   if sData[pIndex]["type"] is "navigation" then
      set the selectedNavItem of widget "header_background" of group "background" of me to tName
   else if sData[pIndex]["type"] is "toggle" then 
      set the text of field sData[pIndex]["name"] to numtocodepoint("0x" & sData[pIndex]["icon_selected"])
   end if
   unlock messages
   unlock screen
end __hiliteFrameItem

private on __unhiliteFrameNavigation
   repeat for each key tIndex in sData
      if sData[tIndex]["type"] is "navigation" then put false into sData[tIndex]["selected"]
   end repeat
end __unhiliteFrameNavigation

private function __itemExists pName
   repeat for each element tNavItem in sData
      if tNavItem["name"] is pName then return true
   end repeat
   return false
end __itemExists

private on __listPopup pName
   lock screen
   lock messages
   
   # Create the menu button
   if there is not a button "list_popup" of group "background" of me then 
      create button "list_popup" in group "background" of me
      set the style of button "list_popup" of group "background" of me to "menu"
      set the menumode of button "list_popup" of group "background" of me to "popup"
      set the visible of button "list_popup" of group "background" of me to false
      set the cTargetName of button "list_popup" of group "background" of me to pName
   end if
   
   local tIndex, tData
   put __frameItemNameToIndex(pName) into tIndex
   put sData[tIndex]["label"] into tData
   set the text of button "list_popup" of group "background" of me to tData
   
   unlock messages
   unlock screen
   popup button "list_popup" of group "background" of me at the loc of the target
end __listPopup

function __textsize
   return round(BAR_HEIGHT * 0.6)
end __textsize

on actionSelected
   pass actionSelected
end actionSelected

on navSelected
   pass navSelected
end navSelected
