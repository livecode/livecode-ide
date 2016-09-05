script "revExtensionBuilderBehavior"
local sLoadedPackage -- will be empty unless there is a multi-extension package open
local sLoadedExtension

local sPackages, sPackageExtensions

on preOpenStack
   dispatch "setAsBehavior" to revIDEFrameBehavior() with the long id of this me
   
   ### Header
   --addFrameItem "add","header", "action", "Create a new extension", "plus sign", "plus sign","headerActionNewExtension", the long id of me
   addFrameItem "open","header", "action", "Open an existing extension", "folder open", "folder open","headerActionOpenExtension", the long id of me
   
   put "No API entries found" into field "message_api" of me
   put "No user guide found" into field "message_guide" of me
   
   put revIDEGetPreference("extensionBuilderPlugin_lastSelected") into sLoadedExtension
   put revIDEGetPreference("extensionBuilderPlugin_lastSelectedPackage") into sLoadedPackage
   
   populateExtensionList
   
   clearExtension
   
   if sLoadedPackage is empty then
      openExtension sLoadedExtension
   else
      openExtension sLoadedPackage
   end if
   
   __LayoutStack
end preOpenStack

on closeStackRequest
   if there is folder sLoadedPackage then
      revIDESetPreference "extensionBuilderPlugin_lastSelectedPackage", sLoadedPackage
   end if
   if there is folder sLoadedExtension then
      revIDESetPreference "extensionBuilderPlugin_lastSelected", sLoadedExtension
   end if
   
   clearExtension
   
   pass closeStackRequest
end closeStackRequest


##########################
###         CALLBACKS         ###
on ideExtensionLog pMessage
   lock screen
   lock messages
   if field "console" of group "test" of me is empty then
      put the time & ":" && pMessage into field "console" of group "test"  of me
   else
      put return & the time & ":" && pMessage after field "console" of group "test"  of me
   end if
   
   // BN-2016-08-11: [[Bug 18169]] Scrollbar not visible when console_content > field_height
   consoleScrollbarUpdate
   
   set the vscroll of field "console" of group "test" of me to \
         the formattedheight field "console" of group "test" of me-the height of field "console" of group "test"  of me
   unlock messages
   unlock screen
end ideExtensionLog

private on consoleScrollbarUpdate
   if the formattedheight of field "console" of group "test" of me > the height of field "console" of group "test" of me then
      set the vscrollbar of field "console" of group "test" of me to true
   else
      set the vscrollbar of field "console" of group "test" of me to false
   end if
end consoleScrollbarUpdate

on headerActionNewExtension
end headerActionNewExtension

on headerActionOpenExtension
   answer folder "Please select a package folder"
   
   if the result is "cancel" then exit headerActionOpenExtension
   if there is not a folder it then exit headerActionOpenExtension
   
   openExtension it
   
   populateExtensionList
end headerActionOpenExtension

on selectionChanged pIndex
   switch the short name of the target
      case "packages"
         __OpenExtension sPackages[pIndex]["folder"]
         break
      case "extensions"
         __OpenExtension sPackageExtensions[pIndex]["folder"]
         break
   end switch
end selectionChanged

on hiliteChanged
   switch the short name of the target
      case "mode"
         lock screen
         set the visible of group "test" to the hilitedItemNames of the target is "test"
         set the visible of group "extension" to the hilitedItemNames of the target is "extension"
         switch the hilitedItemNames of the target
            case "test"
               revIDEDeveloperExtensionTest sLoadedExtension
               break
         end switch
         unlock screen
         break
   end switch
end hiliteChanged

on mouseUp pButtonNumber
   if pButtonNumber is not 1 then
      pass mouseUp
   end if
   switch the short name of the target
      case "Package"
         if sLoadedPackage is empty then
            revIDEDeveloperExtensionBuildPackage sLoadedExtension
         else
            revIDEDeveloperExtensionBuildPackage sLoadedPackage
         end if
         break
      case "Edit Script"
         revIDEDeveloperExtensionEditScript  sLoadedPackage
         break
      case "Uninstall"
         if sLoadedPackage is empty then
            revIDEDeveloperExtensionUninstall sLoadedExtension
         else
            revIDEDeveloperExtensionUninstall sLoadedPackage
         end if
         break
      case "Install"
         if sLoadedPackage is empty then
            revIDEDeveloperExtensionInstall sLoadedExtension
         else
            revIDEDeveloperExtensionInstall sLoadedPackage
         end if
         break
   end switch
   pass mouseUp
end mouseUp

on openExtension pPath
   dispatch "__OpenExtension" to stack "revExtensionBuilder" with pPath
end openExtension

command __OpenExtension pPath
   if there is not a folder pPath then 
      set the title of this stack to "Extension Builder"
      clearExtension
      exit __OpenExtension
   end if
   
   revIDEDeveloperExtensionClearTestStack
   
   lock screen
   set the hilitedItemNames of widget "mode" of me to "extension"
   set the visible of group "test" to false
   set the visible of group "extension" to true
   
   revIDEDeveloperExtensionOpen pPath
   
   local tExtensionData
   put the result into tExtensionData
   
   # Store the loaded extension path 
   put pPath into sLoadedExtension
   
   if tExtensionData["type"] is "package" then
      put pPath into sLoadedPackage
      
      local tPackageData
      put revIDEDeveloperExtensions(pPath) into tPackageData
      
      local tSelected = 0
      __ParsePackageData tPackageData, sPackageExtensions, tSelected
      
      if tSelected is 0 then
         put sPackageExtensions[1]["folder"] into sLoadedExtension
         put 1 into tSelected
      end if
      
      show group "extensions" of me
      send "renderView" to group "extensions" of me
      set the dvHilitedRow[true] of group "extensions" of me to tSelected
      
      displayExtensionData sPackageExtensions[tSelected]
      send "__LayoutStack" to me
      
      unlock screen
      exit __OpenExtension
   else
      set the itemDelimiter to slash
      if sLoadedPackage is not item 1 to -2 of sLoadedExtension then
         put empty into sLoadedPackage
         hide group "extensions" of me
      end if
   end if
   
   lock messages
   
   # Clear the console window
   put empty into field "console" of group "test" of me
   
   # Display the data for the given extenion
   displayExtensionData tExtensionData
   
   # Enable the actions
   enable button "install" of group "extension" of me
   enable button "uninstall" of group "extension" of me
   enable button "package" of group "extension" of me
   enable button "edit script" of group "extension" of me
   
   # Unsubscribe any previous property changed messages
   revIDEUnsubscribeAll
   revIDESubscribe "ideExtensionLog"
   unlock messages
   unlock screen
end __OpenExtension

on updateExtension
   local tExtensionData
   revIDEDeveloperExtensionOpen sLoadedExtension
   put the result into tExtensionData
   displayExtensionData tExtensionData
end updateExtension

##########################
### Standard libraries ###

private function __DisplayName pDataA
   local tDisplayName
   if pDataA["title"] is not empty then
      put pDataA["title"] into tDisplayName
   else if pDataA["name"] is not empty then
      put pDataA["name"] into tDisplayName
   else
      put pDataA["file"] into tDisplayName 
   end if
   
   if pDataA["version"] is not empty then
      put " " & pDataA["version"] after tDisplayName
   end if
   
   replace "/" with "\/" in tDisplayName
   return tDisplayName
end __DisplayName

private command __ParsePackageData pPackageData, @xPackageData, @xSelected
   local tFolder
   repeat for each key tFolder in pPackageData
      put tFolder into pPackageData[tFolder]["folder"]
      put __DisplayName(pPackageData[tFolder]) into pPackageData[tFolder]["displayname"]
   end repeat
   
   local tFolders
   put the keys of pPackageData into tFolders
   sort tFolders by pPackageData[each]["displayname"]
   
   put empty into xPackageData
   local tCount = 1
   repeat for each line tFolder in tFolders
      put pPackageData[tFolder] into xPackageData[tCount]
      if tFolder is sLoadedExtension then 
         put tCount into xSelected
      end if
      add 1 to tCount
   end repeat
end __ParsePackageData

on populateExtensionList
   lock screen
   local tPackageData
   put revIDEDeveloperExtensions() into tPackageData
   
   local tSelected = 0
   __ParsePackageData tPackageData, sPackages, tSelected
   
   send "renderView" to group "packages" of me
   if tSelected is not 0 then
      set the dvHilitedRow[true] of group "packages" of me to tSelected
   end if
   unlock screen
end populateExtensionList

function NumberOfRows
   switch the short name of the target
      case "packages"
         return the number of elements in sPackages
      case "extensions"
         return the number of elements in sPackageExtensions
   end switch
end NumberOfRows

command DataForRow pRow, @pDataA, @pTemplateStyle
   switch the short name of the target
      case "packages"
         put sPackages[pRow] into pDataA
         break
      case "extensions"
         put sPackageExtensions[pRow] into pDataA
         break
   end switch
   put "extension" into pTemplateStyle
end DataForRow

private on displayExtensionData pData
   set the title of this stack to "Extension Builder - " & __DisplayName(pData)
      
   local tPath
   put pData["svgicon"] into tPath
   
   if tPath is empty then
      if there is a file pData["retina_icon"] then 
         put URL ("binfile:" & pData["retina_icon"]) into image "icon_retina" of group "extension" of me
      else
         put revIDEDefaultExtensionIconPath(pData["type"]) into tPath
         if tPath is empty then
            put URL ("binfile:" & revIDEDefaultExtensionIcon(pData["type"], true)) into image "icon_retina" of group "extension" of me
         end if
      end if
      if there is a file pData["icon"] then 
         put empty into tPath
         put URL ("binfile:" & pData["icon"]) into image "icon" of group "extension" of me
      else if tPath is empty then 
         put URL ("binfile:" & revIDEDefaultExtensionIcon(pData["type"], false)) into image "icon" of group "extension" of me
      end if
   end if
   
   if tPath is not empty then
      set the iconPath of widget "svgicon" of group "extension" of me to tPath
   end if
   
   set the invisible of widget "svgicon" of group "extension" of me to tPath is empty
   set the visible of image "icon" of group "extension" of me to tPath is empty
   set the visible of image "icon_retina" of group "extension" of me to tPath is empty
   
   
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
   put empty into field "console" of group "test" of me
   
   send "__LayoutStack" to me
end displayExtensionData

on clearExtension
   lock screen
   lock messages
   disable button "install" of group "extension" of me
   disable button "uninstall" of group "extension" of me
   disable button "package" of group "extension" of me
   disable button "edit script" of group "extension" of me
   
   set the text of image "icon_retina" of group "extension" of me to empty
   set the text of image "icon" of group "extension" of me to empty
   put empty into field "resources" of group "extension" of me
   put empty into field "message_api" of group "extension" of me
   put empty into field "message_guide" of group "extension" of me
   put empty into field "console" of group "test" of me
   put empty into field "defaultscript" of group "extension" of me
   unlock messages
   unlock screen
end clearExtension

command __LayoutStack
   local tRect, tMargin, tPadding
   put the contentrect of me into tRect
   put the paletteMargin of me * 2 into tMargin
   put the palettePadding of me * 2 into tPadding
   
   lock screen
   local tListWidth
   put (item 3 of tRect - item 1 of tRect) div 4 into tListWidth
   # Packages
   set the rect of group "packages" to item 1 of tRect, item 2 of tRect, item 1 of tRect + tListWidth, the height of me
   put the right of group "packages" into item 1 of tRect
   
   # Extension List
   if the visible of group "extensions" of me then
      set the rect of group "extensions" to item 1 of tRect, item 2 of tRect, item 1 of tRect + tListWidth, the height of me
      put the right of group "extensions" into item 1 of tRect
   end if
   
   lock messages
   
   set the loc of widget "mode" of me to item 1 of tRect+ (item 3 of tRect - item 1 of tRect) div 2, item 2 of the loc of widget "mode" of me
   put the bottom of widget "mode" of me into item 2 of tRect
   
   local tLeft, tTop, tRight, tBottom
   put item 4 of tRect - tMargin into tBottom
   put item 3 of tRect - tMargin into tRight
   put item 1 of tRect + tMargin into tLeft
   put item 2 of tRect + tPadding into tTop
   
   # Console
   set the topleft of field "label_console" of me to tLeft, tTop
   put the bottom of field "label_console" of me + tPadding into tTop
   set the rect of field "console" of me to tLeft, tTop, tRight, tBottom
   consoleScrollbarUpdate
   
   # Buttons
   set the bottomright of button "Edit Script" of group "extension" of me to tRight, tBottom
   subtract the width of button "Edit Script" of group "extension" of me + tPadding from tRight
   set the bottomright of button "Install" of group "extension" of me to tRight, tBottom
   subtract the width of button "Install" of group "extension" of me + tPadding from tRight
   set the bottomright of button "Uninstall" of group "extension" of me to tRight, tBottom
   subtract the width of button "Uninstall" of group "extension" of me + tPadding from tRight
   set the bottomright of button "Package" of group "extension" of me to tRight, tBottom
   put the top of button "Package" of group "extension" of me - tPadding into tBottom
   put item 3 of tRect - tMargin into tRight
   
   # Extensions
   local tLabelWidth
   put 100 into tLabelWidth
   put item 1 of tRect + tMargin into tLeft
   put item 2 of tRect + tMargin into tTop
   
   # Icons
   put item 1 of tRect + tMargin into tLeft
   set the width of field "label_icons" of me to tLabelWidth
   set the topleft of field "label_icons" of me to tLeft,tTop
   put the right of field "label_icons" of me + tPadding into tLeft
   set the topleft of image "icon_retina" of group "extension" of me to tLeft,tTop
   set the topleft of widget "svgicon" of group "extension" of me to tLeft,tTop
   put the right of image "icon_retina" of group "extension" of me + tPadding into tLeft
   set the topleft of image "icon" of group "extension" of me to tLeft,tTop
   
   # Guide
   put item 1 of tRect + tMargin into tLeft
   set the rect of field "label_guide" of group "extension" of me to \
         tLeft,tBottom - the formattedheight of field "label_guide" of me, tLeft+tLabelWidth, tBottom
   put the right of field "label_guide" of group "extension" of me + tPadding into tLeft
   set the rect of field "message_guide" of group "extension" of me to \
         tLeft, tBottom - the formattedheight of field "message_guide" of me, tRight, tBottom
   put the top of field "message_guide" of group "extension" of me - tPadding into tBottom
   
   # API
   put item 1 of tRect + tMargin into tLeft
   set the rect of field "label_api" of group "extension" of me to \
         tLeft,tBottom - the formattedheight of field "label_api" of group "extension" of me, tLeft+tLabelWidth, tBottom
   put the right of field "label_api" of group "extension" of me + tPadding into tLeft
   set the rect of field "message_api" of group "extension" of me to \
         tLeft, tBottom - the formattedheight of field "message_api"  of group "extension"of me, tRight, tBottom
   put the top of field "message_api" of group "extension" of me - tPadding into tBottom
   
   set the bottomRight of button "defaultscript_edit" of group "extension" of me to \
         tRight, tBottom
   put the top of button "defaultscript_edit" of group "extension" of me - tPadding into tBottom
   
   # Resources
   put item 1 of tRect + tMargin into tLeft
   put item 3 of tRect - tMargin into tRight
   put the bottom of image "icon_retina" of group "extension" of me + tPadding into tTop
   set the width of field "label_resources" of me to tLabelWidth
   set the topleft of field "label_resources" of me to tLeft, tTop
   put the right of field "label_icons" of me + tPadding into tLeft
   set the rect of field "resources" of me to \
         tLeft, tTop, tRight, tTop+(tBottom - tTop - tPadding) div 2
   
   # Default script
   put item 1 of tRect + tMargin into tLeft
   put item 3 of tRect - tMargin into tRight
   put the bottom of field "resources" of me + tPadding into tTop
   set the width of field "label_defaultscript" of me to tLabelWidth
   set the topleft of field "label_defaultscript" of me to tLeft, tTop
   put the right of field "label_defaultscript" of me + tPadding into tLeft
   set the rect of field "defaultscript" of me to \
         tLeft, tTop, tRight, tBottom
   
   unlock screen
   unlock messages
end __LayoutStack

on resizeStack
   __LayoutStack
   
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
