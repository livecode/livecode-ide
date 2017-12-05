script "revExtensionBuilderBehavior"
local sLoadedExtension

on preOpenStack
   dispatch "setAsBehavior" to revIDEFrameBehavior() with the long id of this me
   
   ### Header
   --addFrameItem "add","header", "action", "Create a new extension", "plus sign", "plus sign","headerActionNewExtension", the long id of me
   addFrameItem "open","header", "action", "Open an existing extension", "folder open", "folder open","headerActionOpenExtension", the long id of me
   
   put "No API entries found" into field "message_api" of me
   put "No user guide found" into field "message_guide" of me
   
   put revIDEGetPreference("extensionBuilderPlugin_lastSelected") into sLoadedExtension
   
   populateExtensionList
   
   clearExtension
   
   send "resizeStack" to me
   
   openExtension sLoadedExtension
   
   revIDESubscribe "ideExtensionLog"
end preOpenStack

on closeStackRequest
   if there is folder sLoadedExtension then
      revIDESetPreference "extensionBuilderPlugin_lastSelected", sLoadedExtension
   end if
   
   clearExtension
   
   pass closeStackRequest
end closeStackRequest

on closeStack
   revIDEUnsubscribeAll
end closeStack

##########################
###         CALLBACKS         ###
on ideExtensionLog pMessage
   lock screen
   lock messages
   if field "console" of me is empty then
      put the time & ":" && pMessage into field "console" of me
   else
      put return & the time & ":" && pMessage after  field "console" of me
   end if
   
   // BN-2016-08-11: [[Bug 18169]] Scrollbar not visible when console_content > field_height
   consoleScrollbarUpdate
   
   set the vscroll of field "console" of me to the formattedheight field "console" of me
   unlock messages
   unlock screen
end ideExtensionLog

private on consoleScrollbarUpdate
   if the formattedheight of field "console" of me > the height of field "console" of me then
      set the vscrollbar of field "console" to true
   else
      set the vscrollbar of field "console" to false
   end if
end consoleScrollbarUpdate

on headerActionNewExtension
end headerActionNewExtension

on headerActionOpenExtension
   answer file "Please select a valid extension file" with type "LiveCode Builder|lcb"
   
   if the result is "cancel" then exit headerActionOpenExtension
   if there is not a file it then exit headerActionOpenExtension
   
   # User has chose a valid file so load it. The load command returns the data array 
   # for the given extenion
   set the itemdelimiter to slash
   openExtension item 1 to -2 of it
end headerActionOpenExtension

on openExtension pPath
   if there is not a folder pPath then exit openExtension
   
   clearExtension
   
   lock screen
   revIDEDeveloperExtensionOpen pPath
   
   lock messages
   local tExtensionData
   put the result into tExtensionData
   
   # Store the loaded extension path 
   put pPath into sLoadedExtension
   
   # Update the extension list box selected
   populateExtensionList
   
   # Clear the console window
   put empty into field "console" of me
   
   # Display the data for the given extenion
   displayExtensionData tExtensionData
   
   # Enable the actions
   enable button "test" of me
   enable button "install" of me
   enable button "uninstall" of me
   enable button "package" of me
   enable button "edit script" of me
   
   unlock messages
   unlock screen
end openExtension

on updateExtension
   local tExtensionData
   revIDEDeveloperExtensionOpen sLoadedExtension
   put the result into tExtensionData
   displayExtensionData tExtensionData
end updateExtension

##########################
### Standard libraries ###

function loadedExtensionGet
   return sLoadedExtension
end loadedExtensionGet

function getDisplayName pData
   if pData["display name"] is not empty then
      return pData["display name"]
   end if
   
   if pData["title"] is not empty then
      return pData["title"] 
   end if
   
   return pData["name"]
end getDisplayName

on populateExtensionList
   # Get a list of all the available extenions
   local tExtensionData
   put revIDEDeveloperExtensions() into tExtensionData
   
   # Prepare a label for the chooser. In the loop, if we find the loaded
   # extension we'll overwrite with the name of the loaded extension
   local tSelectedLabel
   put "Please Select..." into tSelectedLabel
   
   # Loop through the array data and build a list of:
   # path | label
   local tExtensions, tDisplayName, tNameList
   repeat for each key tFolder in tExtensionData
      
      # Build the display name. Use path if no name is available
      put getDisplayName(tExtensionData[tFolder]) into tDisplayName
      if tDisplayName is empty then
         put tFolder into tDisplayName 
      end if
      get the number of elements in tNameList[tDisplayName]
      put tFolder into tNameList[tDisplayName][it + 1]
   end repeat
   
   local tKeys
   put the keys of tNameList into tKeys
   sort tKeys
   repeat for each line tDisplayName in tKeys
      local tNumDuplicated, tToDisplay
      put the number of elements in tNameList[tDisplayName] into tNumDuplicated
      repeat with x = 1 to tNumDuplicated
         put tNameList[tDisplayName][x] into tFolder
         if tNumDuplicated > 1 then
            -- disambiguate dupes with path
            put tDisplayName && "(" & tFolder & ")" into tToDisplay
         else
            put tDisplayName into tToDisplay
         end if
         replace "/" with "\/" in tToDisplay
         
         # Construct the list path / label
         if tExtensions is empty then
            put tToDisplay & "/|" & tFolder into tExtensions
         else
            put return & tToDisplay & "/|" &  tFolder after tExtensions
         end if
         
         # Check if this is the loaded extension
         if tFolder is sLoadedExtension then
            put tToDisplay into tSelectedLabel
         end if
      end repeat
   end repeat
   
   # Set the list on the extension chooser button
   set the text of button "extensions2" of me to tExtensions
   
   # If the loaded extension is in the last, set the label of
   set the label of button "extensions2" of me to tSelectedLabel
end populateExtensionList

private on displayExtensionData pData
   # Exntensions label
   local tLabel
   put getDisplayName(pData) into tLabel
   if tLabel is empty then
      put sLoadedExtension & slash & pData["file"] into tLabel
   end if
   set the label of button "extensions2" of me to tLabel
   
   # Load icons
   # AL-2015-05-22: [[ Bug 14729 ]] Display default widget and library icons if none are provided
   if there is a file pData["icon"] then 
      put URL ("binfile:" & pData["icon"]) into image "icon" of me
   else
      put  URL ("binfile:" & revIDEDefaultExtensionIcon(pData["type"], false)) into image "icon" of me
   end if
   
   if there is a file pData["retina_icon"] then 
      put URL ("binfile:" & pData["retina_icon"]) into image "icon_retina" of me
   else
      put URL ("binfile:" & revIDEDefaultExtensionIcon(pData["type"], true)) into image "icon_retina" of me
   end if
   
   local tHaveSvgIcon
   put (pData["svgicon"] is not empty) into tHaveSvgIcon
   set the visible of widget "svgicon" of me to tHaveSvgIcon
   set the visible of widget "svgicon_retina" of me to tHaveSvgIcon
   set the visible of field "label_svgicon_absent" of me to not tHaveSvgIcon
   if tHaveSvgIcon then
      set the iconPath of widget "svgicon" of me to pData["svgicon"]
      set the iconPath of widget "svgicon_retina" of me to pData["svgicon"]
   end if
   
   # Load resources
   # AL-2015-03-18: [[ Bug 14998 ]] Resources not displaying in plugin
   if pData["resources"] is not empty then put pData["resources"] into field "resources" of me
   else put "No resources found in extension" into field "resources" of me
   
   # API 
   if pData["api"] is not empty then put "Yes" into field "message_api" of me
   else put "No API data found" into field "message_api" of me
   
   # Userguide 
   if pData["user_guide"] is not empty then put "Yes" into field "message_guide" of me
   else put "No user guide found" into field "message_guide" of me
   
   # Default script
   if pData["defaultscript"] is not empty then put pData["defaultscript"] into field "defaultscript" of me
   else put "No default script found" into field "defaultscript" of me
   
   # Clear the console
   put empty into field "console" of me
end displayExtensionData

on clearExtension
   lock screen
   lock messages
   disable button "test" of me
   disable button "install" of me
   disable button "uninstall" of me
   disable button "package" of me
   disable button "edit script" of me
   
   set the text of image "icon_retina" of me to empty
   set the text of image "icon" of me to empty
   set the iconPath of widget "svgicon_retina" of me to empty
   set the visible of widget "svgicon_retina" of me to false
   set the iconPath of widget "svgicon" of me to empty
   set the visible of widget "svgicon" of me to false
   set the visible of field "label_svgicon_absent" of me to true
   
   put empty into field "resources" of me
   put empty into field "message_api" of me
   put empty into field "message_guide" of me
   put empty into field "console" of me
   put empty into field "defaultscript" of me
   unlock messages
   unlock screen
end clearExtension

on resizeStack
   local tRect, tMargin, tPadding
   put the contentrect of me into tRect
   put the paletteMargin of me * 2 into tMargin
   put the palettePadding of me * 2 into tPadding
   
   lock messages
   lock screen
   
   
   local tLeft, tTop, tRight, tBottom
   put item 4 of tRect - tMargin into tBottom
   put item 3 of tRect - tMargin into tRight
   
   # Buttons
   set the bottomright of button "Test" of me to tRight, tBottom
   subtract the width of button "Test" of me + tPadding from tRight
   set the bottomright of button "Edit Script" of me to tRight, tBottom
   subtract the width of button "Edit Script" of me + tPadding from tRight
   set the bottomright of button "Install" of me to tRight, tBottom
   subtract the width of button "Install" of me + tPadding from tRight
   set the bottomright of button "Uninstall" of me to tRight, tBottom
   subtract the width of button "Uninstall" of me + tPadding from tRight
   set the bottomright of button "Package" of me to tRight, tBottom
   
   # Extensions
   local tLabelWidth
   put the width of me * 0.25 into tLabelWidth
   put item 1 of tRect + tMargin into tLeft
   put item 2 of tRect + tMargin into tTop
   set the width of field "label_extensions" of me to tLabelWidth
   set the topleft of field "label_extensions" of me to tLeft,tTop
   put the right of field "label_extensions" of me + tPadding into tLeft
   set the rect of button "extensions" of me to tLeft, tTop, item 3 of tRect-tMargin, tTop + 22
   set the rect of button "extensions2" of me to tLeft, tTop, item 3 of tRect-tMargin, tTop + 22
   put the bottom of button "extensions" of me+tPadding into tTop
   
   # Icons
   put item 1 of tRect + tMargin into tLeft
   set the width of field "label_icons" of me to tLabelWidth
   set the topleft of field "label_icons" of me to tLeft,tTop
   put the right of field "label_icons" of me + tPadding into tLeft
   set the topleft of image "icon_retina" of me to tLeft,tTop
   put the right of image "icon_retina" of me + tPadding into tLeft
   set the topleft of image "icon" of me to tLeft,tTop
   
   # Resources
   put item 1 of tRect + tMargin into tLeft
   put item 3 of tRect - tMargin into tRight
   put the bottom of image "icon_retina" of me + tPadding into tTop
   set the width of field "label_resources" of me to tLabelWidth
   set the topleft of field "label_resources" of me to tLeft,tTop
   put the right of field "label_icons" of me + tPadding into tLeft
   set the rect of field "resources" of me to tLeft,tTop,tRight, tTop+(the height of this card * 0.1)
   
   # Default script
   put item 1 of tRect + tMargin into tLeft
   put item 3 of tRect - tMargin into tRight
   put the bottom of field "resources" of me + tPadding into tTop
   set the width of field "label_defaultscript" of me to tLabelWidth
   set the topleft of field "label_defaultscript" of me to tLeft,tTop
   put the right of field "label_defaultscript" of me + tPadding into tLeft
   set the rect of field "defaultscript" of me to tLeft,tTop,tRight, tTop+(the height of this card * 0.15)
   set the topright of button "defaultscript_edit" of me to tRight, the bottom of field "defaultscript" of me + tPadding
   
   # API
   put item 1 of tRect + tMargin into tLeft
   put the bottom of button "defaultscript_edit" of me + tPadding into tTop
   set the width of field "label_api" of me to tLabelWidth
   set the topleft of field "label_api" of me to tLeft,tTop
   put the right of field "label_api" of me + tPadding into tLeft
   set the rect of field "message_api" of me to tLeft, tTop, tRight, tTop+the formattedheight of field "message_api" of me  -  the margins of field "message_api" of me
   
   # Guide
   put item 1 of tRect + tMargin into tLeft
   put the bottom of field "message_api" of me + tPadding into tTop
   set the width of field "label_guide" of me to tLabelWidth
   set the topleft of field "label_guide" of me to tLeft,tTop
   put the right of field "label_guide" of me + tPadding into tLeft
   set the rect of field "message_guide" of me to tLeft, tTop, tRight, tTop+the formattedheight of field "message_guide" of me -  the margins of field "message_guide" of me
   
   # Console
   put item 1 of tRect + tMargin into tLeft
   put the bottom of field "message_guide" of me + 2 * tPadding into tTop
   put item 3 of tRect - tMargin into tRight
   set the topleft of field "label_console" of me to tLeft, tTop
   
   put the bottom of field "label_console" of me + tPadding into tTop
   put the top of button "test" of me -tPadding into tBottom
   set the rect of field "console" of me to tLeft, tTop, tRight, tBottom
   consoleScrollbarUpdate
   
   unlock screen
   unlock messages
   
   pass resizeStack
end resizeStack

on editDefaultScript
   local tTargetStack
   revIDEDeveloperExtensionEditDefaultScript sLoadedExtension
   put the result into tTargetStack
   
   revIDESubscribe "idePropertyChanged", tTargetStack
end editDefaultScript

on idePropertyChanged
   local tNewScript
   put revIDEDeveloperExtensionFetchDefaultScript(sLoadedExtension) into tNewScript
   if tNewScript is not field "defaultscript" of me then
      put tNewScript into field "defaultscript" of me
   end if
end idePropertyChanged

