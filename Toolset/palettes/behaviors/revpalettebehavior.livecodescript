script "revPaletteBehavior"
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
   layoutFrame
end showFrameItem

on hideFrameItem pName
   local tIndex
   put __frameItemNameToIndex(pName) into tIndex
   if tIndex is not a number then exit hideFrameItem
   
   put true into sData[tIndex]["hidden"] 
   layoutFrame
end hideFrameItem

on hiliteFrameItem pName
   lock screen
   lock messages
   local tIndex
   __unhiliteFrameNavigation
   put __frameItemNameToIndex(pName) into tIndex
   if tIndex is not a number then exit hiliteFrameItem
   
   put true into sData[tIndex]["selected"] 
   __frameRehighlight
   unlock messages
   unlock screen
end hiliteFrameItem

on unhiliteFrameItem pName
   local tIndex
   put __frameItemNameToIndex(pName) into tIndex
   if tIndex is not a number then exit unhiliteFrameItem
   
   put false into sData[tIndex]["selected"] 
   __frameRehighlight
end unhiliteFrameItem

on disableFrameItem pName
   if __frameItemNameToIndex(pName) is not a number then exit disableFrameItem
   if there is not a field pName of group "background" of me then exit disableFrameItem
   
   lock screen
   lock messages
   disable field pName of group "background" of me
   set the textcolor of field pName of group "background" of me to TAB_DISABLED_COLOR
    unlock messages
   unlock screen
end disableFrameItem

on enableFrameItem pName
   if __frameItemNameToIndex(pName) is not a number then exit enableFrameItem
   if there is not a field pName of group "background" of me then exit enableFrameItem
   
   lock screen
   lock messages
   enable field pName of group "background" of me
   set the textcolor of field pName of group "background" of me to TAB_TEXT_COLOR
   unlock messages
   unlock screen
end enableFrameItem

on clearFrameData
   put empty into sData
end clearFrameData

on clearFrameNavigationData
   repeat for each key tKey in sData
      if sData[tKey]["type"] is "navigation" then
         delete variable sData[tKey]
      end if
   end repeat
end clearFrameNavigationData

on generateFrame
   lock screen
   lock messages
   
   repeat with x = 1 to the number of cards of me
      repeat while there is a group "background" of card x of me then
         delete group "background" of card x of me
      end repeat
   end repeat
   
   reset the templategroup
   set the defaultstack to the long ID of me
   set the backgroundbehavior of the templategroup to true
   set the sharedbehavior of the templategroup to true
   create group "background"
   reset the templategroup
   
   set the textsize of group "background" of me to __textsize()
   set the textfont of group "background" of me to "fontawesome"
   
   # Create the header and footer backgrounds
   set the linesize of the templategraphic to 0
   set the backgroundcolor of the templategraphic to TAB_DISABLED_COLOR
   set the opaque of the templategraphic to true
   
   # Setup the template field
   set the sharedtext of the templatefield to true
   set the opaque of the templatefield to false
   set the height of the templatefield to BAR_HEIGHT
   set the style of the templatefield to "transparent"
   set the autohilite of the templatefield to false
   set the fixedlineheight of the templatefield to false
   set the cFrameButton of the templatefield to 1
   set the textColor of the templatefield to TAB_TEXT_COLOR
   set the textAlign of the templatefield to "center"
   set the traversalon of the templatefield to false
   set the showfocusborder of the templatefield to false
   set the locktext of the templatefield to true
   set the margins of the templatefield to 1,7,1,0
   set the borderwidth of the templatefield to 1
   set the threed of the templatefield to false
   set the bordercolor of the templatefield to TAB_DISABLED_COLOR
   set the dontwrap of the templatefield to true
   
   # Generate all the button fields 
   
   local tPreferences, tNavigation, tHeaderAction
   put false into tPreferences
   put false into tNavigation
   put false into tHeaderAction
   
   repeat for each element tNavItem in sData
      if tNavItem["type"] is "preference" and there is not a graphic "header_background" of group "background" of me then create graphic "header_background" in group "background" of me
      if tNavItem["location"] is "header" and there is not a graphic "header_background" of group "background" of me then create graphic "header_background" in group "background" of me
      if tNavItem["location"] is "footer" and there is not a graphic "footer_background" of group "background" of me then create graphic "footer_background" in group "background" of me
      if tNavItem["type"] is "navigation" then put true into tNavigation
      if tNavItem["type"] is "action" and tNavItem["location"] is "header" then put true into tHeaderAction
      
      if tNavItem["type"] is "preference" then
         put true into tPreferences
         next repeat
      end if
      
      
      set the name of the templatefield to tNavItem["name"]
      set the tooltip of the templatefield to tNavItem["label"]
      set the cType of the templatefield to tNavItem["type"]
      
      if tNavItem["type"] is "toggle" and tNavItem["selected"] is "true" then
         if the number of characters of tNavItem["icon_selected"] is 4 then
            set the text of the templatefield to numtocodepoint("0x" & tNavItem["icon_selected"])
         end if
      else if tNavItem["type"] is "list" then
         set the text of the templatefield to item 1 of line 1 of tNavItem["label"]
      else if tNavItem["type"] is "navigation" then
         if sNavStyle is "names" then
            set the text of the templatefield to tNavItem["label"]
         else
            set the text of the templatefield to numtocodepoint("0x" & tNavItem["icon"])
         end if
      else
         if the number of characters of tNavItem["icon"] is 4 then
            set the text of the templatefield to numtocodepoint("0x" & tNavItem["icon"])
         end if
      end if
      
      create field in group "background" of me
   end repeat
   
   if tNavigation is true then 
      create graphic "tab_line_cover" in group "background" of me
      set the backgroundcolor of graphic "tab_line_cover" of group "background" of me to the backgroundcolor of this card
      set the height of graphic "tab_line_cover" of group "background" of me to 1
   end if
   
   # Create a seperator if there is a preference and some header actions
   if tHeaderAction is true and tPreferences is true then
      create graphic "pref_line" in group "background" of me
   end if
   
   # Generate a preferences button and a bar 
   if tPreferences is true then
      set the text of the templatefield to numtocodepoint("0xf013")
      set the name of the templatefield to "preferences"
      set the tooltip of the templatefield to "Preferences"
      create field in group "background" of me
   end if
   
   reset the templategraphic
   reset the templatefield
   
   layoutFrame
   
   unlock messages
   unlock screen
end generateFrame

function barHeight pSize
   switch pSize
      case "large"
         return 30
         break
      case "medium"
         return 25
         break
      default
         return 21
   end switch
end barHeight

function barRight pSize
   local tNumNavItems, tWidth, tTotalWidth
   put the number of elements of sData into tNumNavItems
   
   if sNavStyle is "icons" then
      put ITEM_SPACING  into tWidth
      return tNumNavItems*tWidth + (tNumNavItems/4)*(item 1 of HEADER_NAVIGATION_MARGINS) + (tNumNavItems/4)*(item 3 of HEADER_NAVIGATION_MARGINS)
      
   else
      local tKeys
      put the keys of sData into tKeys
      sort lines of tKeys ascending numeric
      
      put 0 into tTotalWidth
      repeat for each line tKey in tKeys
         if there is not a field sData[tKey]["name"] of group "background" of me then next repeat
         
         if sData[tKey]["hidden"] is true then
            hide field sData[tKey]["name"] of group "background" of me
            next repeat
         end if
         
         add the width of field sData[tKey]["name"] of group "background" of me to tTotalWidth
      end repeat
      return tTotalWidth
   end if
end barRight

on layoutFrame
   lock screen
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
      
      # No background found so generate one
      if there is not a group "background" of me then
         generateFrame 
      end if
   end if
   
   lock messages
   
   # Setup the size everything should be
   local tIconTextSize, tTextSize
   switch revIDEGetPreference("revPaletteFrameSize")
      case "large"
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
      default
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
   end switch
   
   if there is a graphic "header_background" of group "background" of me then 
      set the rect of graphic "header_background" of group "background" of me to 0,BAR_HEIGHT-1,the width of me,BAR_HEIGHT
   end if
   if there is a graphic "footer_background" of group "background" of me then 
      set the rect of graphic "footer_background" of group "background" of me to 0,the height of me - BAR_HEIGHT,the width of me,the height of me - BAR_HEIGHT + 1
   end if
   
   # Setup the key markers for positions
   local tNavTop, tNavLeft
   put 0 into tNavTop
   put BAR_MARGIN / 2 into tNavLeft
   
   local tHeaderActionsTop, tHeaderActionsRight
   put item 2 of HEADER_ACTION_MARGINS into tHeaderActionsTop
   put the width of me - BAR_MARGIN into tHeaderActionsRight
   if there is a field "preferences" of group "background" of me then
      set the textsize of field "preferences" of group "background" of me to tIconTextSize
      set the height of field "preferences" of group "background" of me to BAR_HEIGHT
      set the width of field "preferences" of group "background" of me to the formattedwidth of field "preferences" of group "background" of me
      set the topright of field "preferences" of group "background" of me to tHeaderActionsRight, tHeaderActionsTop
      subtract the width of field "preferences" of group "background" of me + ITEM_SPACING from tHeaderActionsRight
      
      if there is a graphic "pref_line" of group "background" then
         set the width of graphic "pref_line" of group "background" of me to 1
         set the height of graphic "pref_line" of group "background" of me to BAR_HEIGHT * 0.5
         set the top of graphic "pref_line" of group "background" of me to BAR_HEIGHT * 0.25
         set the right of graphic "pref_line" of group "background" of me to tHeaderActionsRight
         subtract ITEM_SPACING from tHeaderActionsRight
      end if
   end if
   
   local tFooterActionsTop, tFooterActionsLeft
   put the height of me - BAR_HEIGHT into tFooterActionsTop
   put BAR_MARGIN into tFooterActionsLeft
   
   # Order the keys of sData so that we lay everything out in the right order
   local tKeys
   put the keys of sData into tKeys
   sort lines of tKeys ascending numeric
   
   repeat for each line tKey in tKeys
      if there is not a field sData[tKey]["name"] of group "background" of me then next repeat
      
      if sData[tKey]["hidden"] is true then
         hide field sData[tKey]["name"] of group "background" of me
         next repeat
      end if
      
      set the textsize of field sData[tKey]["name"] of group "background" of me to tIconTextSize
      set the height of field sData[tKey]["name"] of group "background" of me to BAR_HEIGHT
      set the width of field sData[tKey]["name"] of group "background" of me to the formattedwidth of field sData[tKey]["name"] of group "background" of me
      show field sData[tKey]["name"] of group "background" of me
      
      switch sData[tKey]["type"]
         case "navigation"
            set the margins of field sData[tKey]["name"] of group "background" of me to HEADER_NAVIGATION_MARGINS
            if sNavStyle is "names" then
               set the textsize of field sData[tKey]["name"] of group "background" of me to tTextSize
               set the width of field sData[tKey]["name"] of group "background" of me to the formattedwidth of field sData[tKey]["name"] of group "background" of me
            end if
            
            set the top of field sData[tKey]["name"] of group "background" of me to tNavTop
            set the left of field sData[tKey]["name"] of group "background" of me to tNavLeft
            
            add the formattedwidth of field sData[tKey]["name"] of group "background" of me to tNavLeft
            break
         case "action"
         case "toggle"
            if sData[tKey]["location"] is "header" then
               set the top of field sData[tKey]["name"] of group "background" of me to tHeaderActionsTop
               set the right of field sData[tKey]["name"] of group "background" of me to tHeaderActionsRight
               subtract the width of field sData[tKey]["name"] of group "background" of me + ITEM_SPACING from tHeaderActionsRight
               break
            else
               set the margins of field sData[tKey]["name"] of group "background" of me to FOOTER_ACTION_MARGINS
               set the textsize of field sData[tKey]["name"] of group "background" of me to tIconTextSize * 0.85
               set the width of field sData[tKey]["name"] of group "background" of me to the formattedwidth of field sData[tKey]["name"] of group "background" of me
               set the top of field sData[tKey]["name"] of group "background" of me to tFooterActionsTop
               set the left of field sData[tKey]["name"] of group "background" of me to tFooterActionsLeft
               add the width of field sData[tKey]["name"] of group "background" of me + ITEM_SPACING to tFooterActionsLeft
               break
            end if
            break
         case "list"
            set the margins of field sData[tKey]["name"] of group "background" of me to HEADER_NAVIGATION_MARGINS
            set the textsize of field sData[tKey]["name"] of group "background" of me to tTextSize
            set the top of field sData[tKey]["name"] of group "background" of me to tHeaderActionsTop
            set the right of field sData[tKey]["name"] of group "background" of me to tHeaderActionsRight
            subtract the width of field sData[tKey]["name"] of group "background" of me + ITEM_SPACING from tHeaderActionsRight
            break
      end switch
   end repeat
   
   __hiliteFrameItem
   unlock messages
   unlock screen
end layoutFrame

on revIDEFrameSizeChanged pName, pValue
   revIDESetPreference "revPaletteFrameSize", pValue
end revIDEFrameSizeChanged

after resizeStack
   layoutFrame
end resizeStack

before openCard
   layoutFrame
end openCard

before mouseEnter
   if the cFrameButton of the target is not 1 then exit mouseEnter
   if the disabled of the target is true then exit mouseEnter
   if the showborder of the target is true then exit mouseEnter
   
   set the textColor of the target to TAB_HOVER_TEXT_COLOR
end mouseEnter

before mouseLeave
   if the cFrameButton of the target is not 1 then exit mouseLeave
   if the disabled of the target is true then exit mouseLeave
   if the showborder of the target is true then exit mouseLeave
   
   set the textColor of the target to TAB_TEXT_COLOR
end mouseLeave

after preOpenStack
   put revIDEColor("edition_color") into TAB_SELECTED_TEXT_COLOR
   put revIDEColor("edition_color") into TAB_HOVER_TEXT_COLOR
   addFrameItem "revPaletteFrameSize", "header", "preference", "Header // Footer Size", "enum","small,medium,large", "revIDEFrameSizeChanged", the long id of me
   revIDESubscribe "idePreferenceChanged:revPaletteFrameSize"
   generateFrame
   layoutFrame
end preOpenStack

before idePreferenceChanged
   layoutFrame
end idePreferenceChanged

after idePreferenceChanged
   dispatch "resizeStack" to this card
end idePreferenceChanged

before mouseUp
   if the cFrameButton of the target is not 1 then exit mouseUp
   if the disabled of the target is true then exit mouseUp
   if the short name of the target is "preferences" then
      __preferencePopup
      exit mouseUp
   end if
   if the cType of the target is "list" then
      __listPopup the short name of the target
      exit mouseUp
   end if
   
   lock screen
   # Get index
   local tIndex
   put __frameItemNameToIndex(the short name of the target) into tIndex
   
   # Get callback info
   local tMessage, tTarget, tParameter
   put sData[tIndex]["message"] into tMessage
   put sData[tIndex]["target"] into tTarget
   put sData[tIndex]["parameter"] into tParameter   
   
   # Set highlight
   switch sData[tIndex]["type"] 
      case "navigation" 
         __unhiliteFrameNavigation
         put true into sData[tIndex]["selected"]
         dispatch tMessage to tTarget with tParameter
         break
      case "toggle"
         if sData[tIndex]["selected"] is true then
            put false into sData[tIndex]["selected"]
            dispatch tMessage to tTarget with false
         else
            put true into sData[tIndex]["selected"]
            dispatch tMessage to tTarget with true
         end if
         break
      default
         dispatch tMessage to tTarget with tParameter
         break
   end switch
   
   __frameRehighlight
   unlock screen
end mouseUp

before menupick pItem
   switch the short name of the target
      case "preferences_popup"
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
         
         dispatch tMessage to tTarget with tName,tValue
         break
      case "list_popup"
         
         break
   end switch
end menupick

getProp contentRect
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
   repeat for each line tIndex in the keys of sData
      if sData[tIndex]["name"] is pName then return tIndex
   end repeat
end __frameItemNameToIndex

private on __frameRehighlight
   repeat for each line tIndex in the keys of sData
      if sData[tIndex]["selected"] is true then
        __hiliteFrameItem tIndex
     else
        __unhiliteFrameItem tIndex
      end if
   end repeat
end __frameRehighlight

local sHilitedInded
private on __hiliteFrameItem pIndex
   if pIndex is empty then put sHilitedInded into pIndex
   else put pIndex into sHilitedInded
   
   if sHilitedInded is not a number then return empty
   
   lock screen
   lock messages
   local tName
   put sData[pIndex]["name"] into tName
   if there is not a field tName of group "background" of me then exit __hiliteFrameItem
   
   if sData[pIndex]["type"] is "navigation" then
      if TAB_SELECTED_COLOR is not empty then
         set the opaque of field tName of group "background" of me to true
         set the backgroundcolor of field tName of group "background" of me to TAB_SELECTED_COLOR
         set the backgroundcolor of graphic "tab_line_cover" of group "background" of me to TAB_SELECTED_COLOR
      end if
      set the textcolor of field tName of group "background" of me to TAB_SELECTED_TEXT_COLOR
      set the showborder of field tName of group "background" of me to true
      set the height of field tName of group "background" of me to BAR_HEIGHT * 0.9
      set the bottom of field tName of group "background" of me to the bottom of graphic "header_background" of group "background" of me
      
      set the width of graphic "tab_line_cover" of group "background" of me to the width of field tName of group "background" of me - 2
      set the left of graphic "tab_line_cover" of group "background" of me to the left of field tName of group "background" of me + 1
      set the bottom of graphic "tab_line_cover" of group "background" of me to the bottom of graphic "header_background" of group "background" of me
   else if sData[pIndex]["type"] is "toggle" then 
      set the text of field sData[pIndex]["name"] to numtocodepoint("0x" & sData[pIndex]["icon_selected"])
   end if
   unlock messages
   unlock screen
end __hiliteFrameItem

private on __unhiliteFrameItem pIndex
   lock screen
   lock messages
   local tName
   put sData[pIndex]["name"] into tName
   if there is not a field tName of group "background" of me then exit __unhiliteFrameItem
   
   if sData[pIndex]["type"] is "navigation" then
      set the opaque of field tName of group "background" of me to false
      set the textColor of field tName of group "background" of me to TAB_TEXT_COLOR
      set the showborder of field tName of group "background" of me to false
      set the height of field tName of group "background" of me to BAR_HEIGHT
      set the top of field tName of group "background" of me to 0
   else if sData[pIndex]["type"] is "toggle" then 
      set the text of field sData[pIndex]["name"] to numtocodepoint("0x" & sData[pIndex]["icon"])
   end if
   unlock messages
   unlock screen
end __unhiliteFrameItem

private on __unhiliteFrameNavigation
   repeat for each line tIndex in the keys of sData
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

private on __preferencePopup
   lock screen
   lock messages
   # Create the menu button
   if there is not a button "preferences_popup" of group "background" of me then 
      create button "preferences_popup" in group "background" of me
      set the style of button "preferences_popup" of group "background" of me to "menu"
      set the menumode of button "preferences_popup" of group "background" of me to "popup"
      set the visible of button "preferences_popup" of group "background" of me to false
   end if
   
   # Generate the menu items
   local tMenuText, tData, tIndex
   put sData into tData
   --put the number of elements of tData + 1 into tIndex
   
   --put "revPaletteFrameSize" into tData[tIndex]["name"]
   --put "Header // Footer Size" into tData[tIndex]["label"]
   --put "preference" into tData[tIndex]["type"]
   --put "enum" into tData[tIndex]["value_type"]
   --put "small,medium,large" into tData[tIndex]["value"]
   
   repeat for each element tNavItem in tData
      if tNavItem["type"] is "preference" then
         local tMenuItemText
         
         local tPreferenceValue
         put revIDEGetPreference(tNavItem["name"]) into tPreferenceValue
         
         switch tNavItem["value_type"]
            case "enum"
               if tPreferenceValue is empty then put item 1 of tNavItem["value"] into tPreferenceValue
               put tNavItem["label"] & "/|" & tNavItem["name"] into tMenuItemText
               repeat for each item tItem in tNavItem["value"]
                  if tItem is tPreferenceValue then
                     put return & tab & "!c" & tItem after tMenuItemText
                  else
                     put return & tab & tItem after tMenuItemText
                  end if
               end repeat
               break
            case "set"
               put tNavItem["label"] & "/|" & tNavItem["name"] into tMenuItemText
               repeat for each item tItem in tNavItem["value"]
                  # Parse out the value and label from the item
                  set the itemdel to ":"
                  local tValue, tLabel
                  if the number of items of tItem > 1 then
                     put item 1 of tItem into tValue
                     put item 2 of tItem into tLabel
                  else
                     put tItem into tLabel
                     put tItem into tValue
                  end if
                  
                  # Check whether the set item is in the preference value
                  set the itemdel to comma
                  if tValue is among the items of tPreferenceValue then
                     put return & tab & "!c" & tValue after tMenuItemText
                  else
                     put return & tab & tValue after tMenuItemText
                  end if
               end repeat
               break
            case "boolean"
               if tPreferenceValue is true then
                  put "!c" & tNavItem["label"] & "/|" & tNavItem["name"] into tMenuItemText
               else
                  put tNavItem["label"] & "/|" & tNavItem["name"] into tMenuItemText
               end if
               break
            case default
               put tNavItem["label"] & "/|" & tNavItem["name"]  into tMenuItemText
               break
         end switch
         
         if tMenuText is empty then 
            put tMenuItemText into tMenuText
         else
            put return & tMenuItemText after tMenuText
         end if
      end if
   end repeat
   set the text of button "preferences_popup" of group "background" of me to tMenuText
   
   unlock messages
   unlock screen
   popup button "preferences_popup" of group "background" of me at the loc of field "preferences" of group "background" of me
end __preferencePopup

function __textsize
   return round(BAR_HEIGHT * 0.6)
end __textsize
