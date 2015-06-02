script "revMenuBar"
local sMenuTarget
on preOpenStack
   global gREVDontLoadMenus
   if gREVDontLoadMenus then
      put false into gREVDontLoadMenus
      exit preOpenStack
   end if
   
   #set the cRecentPaths of stack "revPreferences" to the cRecentPaths of stack "revPreferences" -- setprop will initialise
   # OK-2007-07-06 : Reworked recent files list code.
   //revMenuBarUpdateRecentPaths
   
   revIDESubscribe "ideSelectedObjectChanged"
   revIDESubscribe "idePreferenceChanged:cToolbarIcons"
   revIDESubscribe "idePreferenceChanged:cToolbarText"
   revIDESubscribe "ideToolChanged"
   
   setMenuProperties
   generateMenu
   updateMenubarPreference
   layoutMenu
   revMenubarBuildMenus
end preOpenStack

on openStack
end openStack

on setMenuProperties
   set the height of me to 47
   set the resizable of me to false
   
   local tTitle
   set the itemDelimiter to "-"
   put "LiveCode" into tTitle
   if revLicenseType() is "community" then
      put space & "Community" after tTitle
   end if
   if item 1 of the version ends with ".0" then
      put space & char 1 to -3 of item 1 of the version after tTitle
   else
      put space & item 1 of the version after tTitle
   end if
   if item 2 of the version is not empty then
      put space & "(" & item 2 of the version && item 3 of the version & ")" after tTitle
   end if
   set the itemDelimiter to comma
   set the title of me to tTitle
   
   if the platform is not "MacOS" then
      --set the showBorder of this cd to false
      --set the borderWidth of this cd to 0
      
      if item 3 of the screenRect is 800 then
         set the topLeft of me to item 1 to 2 of the windowBoundingRect
      else
         --screen rect > 800 by 600
         if the cREVMenuBarTopLeft of stack "revPreferences" is empty
         then set the loc of me to item 1 of the screenLoc, 54
         else set the topLeft of me to the cREVMenuBarTopLeft of stack "revPreferences"    
      end if
   end if
   
   if the platform is "MacOS" then
      set the decorations of me to empty
      set the topLeft of me to item 1 of the windowBoundingRect,20
   else
      set the decorations of me to "default"
   end if
end setMenuProperties

/*
on preOpenStack
   
   local lOrigLoc, lTargetSpecs, lCurrentObject, oldStyle
   global gREVTextMenu, gREVDisabledText
   
   
   if not the selectGroupedControls then 
      set the textFont of button "select grouped controls" to empty
      set the hilite of button "select grouped controls" to false
      set the textStyle of button "select grouped controls" to "plain"
   else 
      set the textFont of button "select grouped controls" to empty
      set the hilite of button "select grouped controls" to true
      set the textStyle of button "select grouped controls" to "bold"
   end if
   
   local tFilePath
   put the fileName of stack "revMenuBar" into tFilePath
   
   -- KM-2006-01-14: Plug ins new code for 2.7
   revUpdatePlugins
   
   --degrees character in rotate submenu
   local tObject
   put the text of button "Object" into tObject
   
   local tDegreeSymbol
   if the platform is "MacOS" then
      put NumToChar(188) into tDegreeSymbol
   else 
      put NumToChar(176) into tDegreeSymbol
   end if
   put tab & "90" & tDegreeSymbol & " Right" & return & tab & "90" & tDegreeSymbol & " Left" & return & tab & "180" & tDegreeSymbol into line -18 to -16 of tObject
   set the text of button "Object" to tObject
   
   local tView
   put the text of button "View" into tView
   delete line -6 to -1 of tView
   
   local tOn, tOff
   switch the platform
      case "MacOS"
         put cr&"!c"&tab into tOn
         put cr&"!u"&tab into tOff
         break
      default
         put cr&tab&"!r" into tOn
         put cr&tab&"!u" into tOff
         break
   end switch
   
   put tOn&"Default Appearance Manager"&tOff&"Mac OS Platinum Emulated"&tOff&"Windows Emulated"&tOff&"Motif Emulated" after tView
   put cr&"-"&cr&"!nShow &Invisible Objects" after tView
   put tView into button "View"
   revSetupText
   revUpdatePalette
   
   --LG-2007-12-18
   --Bug 5668:  Moved here from revInternal_InitialiseMenus of home stack.
   
end preOpenStack
*/
on openStack
end openStack

on ideSelectedObjectChanged
   layoutMenu
end ideSelectedObjectChanged

on idePreferenceChanged pPreference
   switch pPreference
      case  "cToolbarText"
         updateMenubarPreference
         layoutMenu
      case "cToolbarIcons"
         updateMenubarPreference
         layoutMenu
         break
   end switch
end idePreferenceChanged

on generateMenu
   generateMenubarUI
   generateMenuGroup
   generateContextMenu
end generateMenu

on generateMenubarUI
   if there is a group "icons" of me then
      delete group "icons" of me
   end if
   
   if there is a group "menu" of me then
      delete group "menu" of me
   end if
   
   create group "icons"
   create group "menu"
   
   lock messages
   # Setup the default button
   set the showname of the templatebutton to true
   set the style of the templatebutton to "transparent"
   set the threed of the templatebutton to false
   set the borderwidth of the templatebutton to 0
   set the blendlevel of the templatebutton to 0
   set the margins of the templatebutton to "4,0,4,1"
   set the icongravity of the templatebutton to "top"
   
   set the resizequality of the templateimage to "best"
   
   local tDividerCount
   put 1 into tDividerCount
   repeat for each item tItem in revMenubarItems()
      if tItem is "Divide" then
         local tName
         put tItem & tDividerCount into tName
         create image tName in group "menu"
         set the filename of image tName of group "menu" of me to revMenubarButtonNameToIconPath(tItem)
         add 1 to tDividerCount
      else
         create invisible image tItem in group "icons" of me
         set the filename of image tItem of me to revMenubarButtonNameToIconPath(tItem)
         local tFilename
         repeat for each item tStyle in "hilited,disabled" 
            put revMenubarButtonNameToIconPath(tItem, tStyle) into tFilename
            if there is a file tFilename then
               create invisible image (tItem & "-" & tStyle) in group "icons" of me
               set the filename of image (tItem & "-" & tStyle) of me to tFilename
               if tStyle is "hilited" then 
                  set the hilitedIcon of the templatebutton to the id of image (tItem & "-" & tStyle) of group "icons" of me
               else if tStyle is "disabled" then
                  set the disabledIcon of the templatebutton to the id of image (tItem & "-" & tStyle) of group "icons" of me
               end if
            else
               if tStyle is "hilited" then 
                  set the hilitedIcon of the templatebutton to 0
               else if tStyle is "disabled" then
                  set the disabledIcon of the templatebutton to 0
               end if
            end if
         end repeat
         
         create button tItem in group "menu" of me
         set the icon of button tItem of group "menu" of me to the id of image tItem of group "icons" of me
         set the label of button tItem of group "menu" of me to revIDELocalizeMenuItem(tItem)
      end if
   end repeat
   
   reset the templatebutton
   reset the templateimage
   unlock messages
end generateMenubarUI

on generateMenuGroup
   lock messages
   if there is a group "revMenuBar" of me then
      delete group "revMenuBar" of me
   end if
   
   set the style of the templatebutton to "menu"
   set the menumode of the templatebutton to "pulldown"
   set the height of the templatebutton to 22
   local tButtonScript
   put "on menuPick pWhich; revMenubarMenuPick pWhich; end menuPick" into tButtonScript
   set the script of the templatebutton to tButtonScript
   
   local tGroupScript
   put  "on mouseDown; revMenubarBuildMenus; end mouseDown" into tGroupScript
   create invisible group "revMenuBar"
   set the script of it to tGroupScript
   
   set the topleft of group "revMenuBar" of me to 0,0
   set the lockloc of group "revMenuBar" of me to true
   
   local tLeft
   put 1 into tLeft
   repeat for each item tItem in revMenubarMenus()
      create button tItem in group "revMenuBar" of me
      set the width of it to the formattedwidth of it
      set the left of it to tLeft
      set the top of it to 1
      add the formattedwidth of it to tLeft
   end repeat
   
   if the platform is not "macos" then
      show group "revMenuBar" of me
   end if
   
   create graphic "Divider" in group "revMenuBar"
   set the style of it to "line"
   
   reset the templatebutton
   unlock messages
end generateMenuGroup

on generateContextMenu
   if there is a button "context" of me then
      delete button "context" of me
   end if
   
   set the style of the templatebutton to "menu"
   set the menumode of the templatebutton to "popup"
   set the visible of the templatebutton to false
   
   create button "context"
end generateContextMenu

on layoutMenu
   lock screen
   lock messages
   local tDividerCount
   put 1 into tDividerCount
   
   local tLeft, tTop
   put 10 into tLeft
   
   if the platform is "macos" then 
      put 3 into tTop
   else
      put 29 into tTop
   end if
   local tTopLeft
   put the topleft of me into tTopLeft
   repeat for each item tItem in revMenubarItems()
      if tItem is "Divide" then
         local tName
         put tItem & tDividerCount into tName
         set the rect of image tName of group "menu" of me to tLeft + 4, tTop, tLeft + 6, tTop + 41
         add 1 to tDividerCount
         add 10 to tLeft
      else
         local tWidth, tHeight
         set the textStyle["bold"] of button tItem of group "menu" of me to false
         put max(the formattedWidth of button tItem of group "menu" of me, 60) into tWidth
         set the width of button tItem of group "menu" of me to tWidth
         set the topleft of button tItem of group "menu" of me to tLeft,tTop
         add tWidth to tLeft
      end if
   end repeat
   set the width of me to tLeft + 10
   set the height of group "revMenuBar" of me to 26
   set the width of group "revMenuBar" of me to the width of me
   set the topleft of group "revMenuBar" of me to 0,0
   set the points of graphic "Divider" of group "revMenuBar" of me to "0,24" & return & tLeft + 10 & ",24" & return
   set the topleft of me to tTopLeft
   unlock messages
   updateButtonState
   unlock screen
end layoutMenu

on updateMenubarPreference
   local tShowIcons, tShowText
   put revIDEGetPreference("cToolbarIcons") is not false into tShowIcons
   put revIDEGetPreference("cToolbarText") is not false into tShowText
   
   local tTopLeft
   put the topleft of me into tTopLeft
   
   local tButtonRef
   repeat for each line tButton in the childControlNames of group "menu" of me
      if tButton is "Divide" then next repeat
      if there is not a button tButton of group "menu" of me then
         next repeat
      end if
      
      put the long id of button tButton of group "menu" into tButtonRef
      if tShowIcons and tShowText then
         set the height of tButtonRef to 43
      else if tShowIcons then
         set the height of tButtonRef to 26
      else if tShowText then
         set the height of tButtonRef to 14
      end if
      
      if tShowIcons then
         set the showIcon of tButtonRef to true
      else
         set the showIcon of tButtonRef to false
      end if
      if tShowText then
         set the showName of tButtonRef to true
      else
         set the showName of tButtonRef to false
      end if
   end repeat 
   
   if the platform is "macos" then
      show me
      if tShowIcons is false and tShowText is false then
         hide me
      else if tShowIcons is false then
         set the height of me to 19
      else if tShowText is false then
         set the height of me to 32
      else
         set the height of me to 47
      end if
   else
      show group "menu" of me
      if tShowIcons is false and tShowText is false then
         hide group "menu" of me
         set the height of me to 23
      else if tShowIcons is false then
         set the height of me to 44
      else if tShowText is false then
         set the height of me to 59
      else
         set the height of me to 75
      end if
   end if
   
   set the topleft of me to tTopLeft
end updateMenubarPreference

on updateButtonState
   local tState
   put ((the selectedField) is empty) & comma & ((the selObj) is empty) & comma & (the mode of the topStack is 1) into tState
   
   if the editBg of the topStack and word 1 of (the selObj) is not "group" then
      set the hilite of button "edit group" of group "menu" of me to true
      set the textStyle of button "edit group" of group "menu" of me to "bold"
      enable button "edit group" of group "menu" of me 
   else
      set the hilite of button "edit group" of group "menu" of me to false
      set the textStyle of button "edit group" of group "menu" of me to "plain"
      enable button "edit group" of group "menu" of me
   end if
   if (the selObj) is not empty and word 1 of (the selObj) is "group" and the number of lines in (the selObj) is 1 then
      set the hilite of button "Group" of group "menu" of me to true
      set the textStyle of button "Group" of group "menu" of me to "bold"
      set the label of button "Group" of group "menu" of me to "Ungroup"
   else
      set the hilite of button "Group" of group "menu" of me to false
      set the textStyle of button "Group" of group "menu" of me to "plain"
      set the label of button "Group" of group "menu" of me to "Group"
      if not the editBg of the topStack then 
         disable button "edit group" of group "menu" of me 
      end if
   end if
   
   if (the selObj) is empty then
      if the mode of the topStack is 1 then
         enable button "Code" of group "menu" of me 
      else 
         disable button "Code" of group "menu" of me 
      end if
      disable button "Group" of group "menu" of me 
   else
      if word 1 of (the selObj) is not among the items of "card,stack" then
         enable button "Group" of group "menu" of me 
      end if
      enable button "Code" of group "menu" of me 
   end if
   
   enable button "Inspector" of group "menu" of me
   
   if revIDEGetPreference("cDeployPlatforms") is empty then
      disable button "Test" of group "menu" of me
   else
      enable button "Test" of group "menu" of me
   end if
   
   local tSelectedObject
   put the selectedObject into tSelectedObject
   if there is no tSelectedObject then
      if the mode of topStack is not 1 then
         disable button "Inspector"of group "menu" of me
      end if
   end if
end updateButtonState

on revTextbar
   revIDESetPreference "cToolbarText", true
   revIDESetPreference "cToolbarIcons", false
end revTextbar

on revIconsBar
   revIDESetPreference "cToolbarText", false
   revIDESetPreference "cToolbarIcons", true
end revIconsBar

on revFullBar
   revIDESetPreference "cToolbarText", true
   revIDESetPreference "cToolbarIcons", true
end revFullBar

function revMenubarItems
   return "Inspector,Code,Message Box,Divide,Group,Edit Group,Select Grouped,Divide,Messages,Errors,Divide,Sample Stacks,Tutorials,Resources,Dictionary,Divide,Test"
end revMenubarItems

function revMenubarButtonNameToIconPath pName, pStyle
   local tPath, tIcon
   put revIDEPaletteResourcePath("images/") into tPath
   replace " " with "-" in pName
   put tPath & toLower(pName) into tIcon
   if pStyle is not empty then
      put "-" & pStyle after tIcon
   end if
   return tIcon & ".png"
end revMenubarButtonNameToIconPath

function revMenubarButtonNameToOldButtonName pName
   switch pName
      case "Inspector"
         return "Object Properties"
      case "Code"
         return "Edit Script"
      case "Group"
         return "Group Controls"
      case "Select Grouped"
         return "Select Grouped Controls"
      case "Messages"
         return "Suppress Messages"
      case "Errors"
         return "Suppress Errors"
      case "Sample Stacks"
         return "Rev Online"
      case "Resources"
         return "ResourceCenter"
      case "Dictionary"
         return "help1"
      case "Test"
         return "Deploy"
      case "Edit Group"
      case "Tutorials"
      default
         return pName 
   end switch
end revMenubarButtonNameToOldButtonName

function revIDELocalizeMenuItem pItem
   return pItem
end revIDELocalizeMenuItem

on mouseUp
   lock screen
   if the owner of the target is "revMenuBar" then
   else if the target begins with "button" then
      local tOriginButton, tTarget
      put the short name of the target into tTarget
      revMenubarMenuButtonClicked tTarget
      layoutMenu
   end if
   unlock screen
end mouseUp

on mouseDown
   put the owner of the target
   if the owner of the target is "revMenuBar" then
      revMenubarBuildMenus
   end if
   pass mouseDown
end mouseDown

on revMenubarMenuButtonClicked pWhich
   switch pWhich
      case "Inspector"
         revIDEOpenPalette "inspector"
         break
      case "Code"
         # OK-2008-04-09 : New script editor changes. When in edit group mode, the selectObject actually
         # returns incorrect long ids for objects that are inside the group being edited. To fix this problem
         # we convert the long id to a "rugged id".
         if (the selectedObject) is empty then
            edit script of the topStack
         else
            repeat for each line tObject in (the selectedObject)
               local tRuggedObject
               put revRuggedId(tObject) into tRuggedObject
               edit the script of tRuggedObject
            end repeat
         end if
         break
      case "Message Box"
         revIDEShowMessageBox
         break
      case "Group"
         lock screen
         if the number of lines in (the selObj) > 1 or word 1 of (the selObj) is not "group" then
            revMenubarObjectMenuPick "Group selected"
            set the hilite of the target to "true"
            set the textStyle of the target to "bold"
            set the label of the target to "Ungroup"
         else
            revMenubarObjectMenuPick "Ungroup selected"
            set the hilite of the target to "false"
            set the textStyle of the target to "plain"
            set the label of the target to "Group"
         end if
         unlock screen
         break
      case "Edit Group"
         send "mouseDown" to group 1 of stack "revMenuBar"
         set the defaultStack to the topStack
         if word 1 of (the selObj) is "group" then
            if revMenuManagerGroup(the selobj) then
               answer error "Can't edit group that is in use by the Menu Manager.  To edit this group close the Menu Manager."
               exit revMenubarMenuButtonClicked
            end if
            --send "deleteThumbnail" && the long id of the selobj to stack "revProjectBrowser"
            --send "deleteParentThumbnail" && the long id of the selobj to stack "revProjectBrowser"
            start editing the selobj
         else if the editBg then set the editBg to false
         revKillRedundantPalettes
         if the mode of stack "revApplicationOverview" is not 0 \
               and the short name of this cd of stack "revApplicationOverview" is "Cards and Controls" then
            send "revRefreshControls true, false" to stack "revApplicationOverview"
         end if
         break
      case "Select Grouped"
         set the selectGroupedControls to not (the selectGroupedControls)
         if the selectGroupedControls then set the textStyle of the target to "bold"
         else set the textStyle of the target to "plain"
         set the hilite of the target to the selectGroupedControls
         if the selectGroupedControls and word 1 of (the selObj) is "group" then 
            send "revRestoreHilite" to the target in 100 milliseconds
            select empty
         end if
         break
      case "Messages"
         global gREVSuppressMessages
         revMenubarDevelopmentMenuPick "Suppress Messages"
         set the hilite of the target to gREVSuppressMessages
      case "Errors"
         global gREVSuppressErrors
         revMenubarDevelopmentMenuPick "Suppress Errors"
         set the hilite of me to gREVSuppressErrors
      case "Sample Stacks"
         revGoOnline
         break
      case "Tutorials"
         launch url "http://lessons.runrev.com"
         break
      case "Resources"
         revIDEShowResourceCenter
         break
      case "Dictionary"
         revIDEShowDictionary
         break
      case "Test"
         revIDEDeployAction
         break
   end switch
end revMenubarMenuButtonClicked
/*
on revRestoreHilite
  set the textStyle of me to "bold"
  set the hilite of me to true
end revRestoreHilite
*/
function revMenubarMenus
   return "File,Edit,Tools,Object,Text,Development,View,Window,Help"
end revMenubarMenus

command revMenubarBuildMenus
   local tContext
   put buildMenuContext() into tContext
   
   lock menus
   repeat for each item tMenu in revMenubarMenus()
      set the text of menu tMenu to revMenubarBuildMenu(tMenu, tContext)
   end repeat
   unlock menus
end revMenubarBuildMenus

function revMenubarBuildMenu pMenu, pContext
   switch pMenu
      case "File"
         return revMenubarFileMenu(pContext)
      case "Edit"
         return buildEditMenu(pContext)
      case "Tools"
         return buildToolsMenu(pContext)
      case "Object"
         return buildObjectMenu(pContext)
      case "Text"
         return buildTextMenu(pContext)
      case "Development"         
         return buildDevelopmentMenu(pContext)
      case "View"
         return buildViewMenu(pContext)
      case "Window"
         return buildWindowMenu(pContext)
      case "Help"
         return buildHelpMenu(pContext)
      default
         break
   end switch
   
   return empty
end revMenubarBuildMenu

# Returns an array containing the context needed to build the menus. This is stuff like which images / objects / text is selected etc.
function buildMenuContext
   local tContext
   
   if (the selectedText) is empty then
      put false into tContext["textSelected"]   
   else
      put true into tContext["textSelected"]
   end if
   
   local tEnableText
   put false into tEnableText
   
   local tObjectsSelected
   local tTextMenuSelection
   put empty into tTextMenuSelection
   if (the selectedObject) is not empty then
      put true into tEnableText
      put "objects" into tTextMenuSelection
      put true into tObjectsSelected
   else put false into tObjectsSelected
   if the selectedField is not empty then
      local tSelField
      put the long id of the selectedField into tSelField
      
      local tTargetStack
      put revTargetStack(tSelField) into tTargetStack
      if revFilterStacksList(tTargetStack) is tTargetStack then 
         put true into tEnableText
         put "text" into tTextMenuSelection
      else
         local tName
         put the short name of tSelField into tName
         if word 1 of tTargetStack is "revPropertyPalette" then
            switch tName 
               case "label"
               case "htmlText"
               case "text"
                  put true into tEnableText
                  put "text" into tTextMenuSelection
                  break
            end switch
         else if tTargetStack is "revMenuManager"
         then if tName is "Menu Name" or tName is "Item Name" then 
            put true into tEnableText
            put "text" into tTextMenuSelection
         end if
      end if
   end if
   
   --Flip/Rotate/Reshape enabling
   local tSelectedObject
   put the selobj into tSelectedObject
   
   local tEnableFlipandRotate
   put true into tEnableFlipandRotate
   
   local tAllGraphics
   put true into tAllGraphics
   
   local tAllImages
   put true into tAllImages
   repeat for each line l in tSelectedObject
      switch word 1 of l
         case "graphic"
            if the style of l is among the items of "line,curve,polygon"
            then put false into tAllImages
            else put false into tEnableFlipandRotate
            break
         case "image"
            put false into tAllGraphics
            break
         default
            put false into tEnableFlipandRotate
            exit repeat
            break
      end switch
   end repeat
   
   put tEnableFlipandRotate into tContext["enableFlipAndRotate"]
   put tSelectedObject into tContext["selectedObject"]
   put tAllGraphics into tContext["allGraphics"]
   put tAllImages into tContext["allImages"]
   put tEnableText into tContext["enableText"]
   put tTextMenuSelection into tContext["textMenuSelection"]
   put tObjectsSelected into tContext["objectsSelected"]
   
   return tContext
end buildMenuContext

################################################################################

private function revMenubarFileMenu pContext
   local tIsUserTarget
   put the mode of the topStack is 1 into tIsUserTarget
   
   local tCanSaveStack
   put false into tCanSaveStack
   if not revOKTarget(the topStack) or the mode of the topStack is 1 then
      put true into tCanSaveStack
   end if
   
   local tFile
   put "&New Stack" & return after tFile
   put tab & "Default" & return after tFile
   put tab & "iPhone (375x667)" & return after tFile
   put tab & "iPad//Tablet (768x1024)" & return after tFile
   put tab & "-" & return after tFile
   put tab & "Script only" & return after tFile
   
   if tIsUserTarget then
      put "&New Substack of" && char 1 to 20 of the mainStack of the topStack & "/|New Substack" & return after tFile
   else
      put "(&New Substack" & return after tFile
   end if
   put "&Open Stack.../O" & return after tFile
   put "Open Recent File" & return after tFile
   put revIDEGetRecentPathsAsMenu() & return after tFile
   put enableMenuItem("&Close/W", the mode of the topStack <= 3) & return after tFile
   put enableMenuItem("Close and Remove From Memor&y", tCanSaveStack) & return after tFile
   put "-" & return after tFile
   
   put enableMenuItem("Import As Control", tIsUserTarget) & return after tFile
   put tab & "Image File.../>|image" & return after tFile
   put tab & "Audio File.../|audio" & return after tFile
   put tab & "Video File.../|video" & return after tFile
   put tab & "Text File.../|text" & return after tFile
   put tab & "-" & return after tFile
   put tab & "Snapshot of Screen" & return after tFile
   put tab & enableMenuItem("Snapshot of Selected Object",  pContext["objectsSelected"]) & return after tFile
   put tab & "-" & return after tFile
   put tab & "All Images in Folder.../|image folder" & return after tFile
   put tab & "All Audio Files in Folder.../|audio folder" & return after tFile
   put tab & "All Video Files in Folder.../|video folder" & return after tFile
   put tab & "All Text Files in Folder.../|text folder" & return after tFile
   
   put enableMenuItem("New Referenced Control", tIsUserTarget) & return after tFile
   put tab & "Image File.../|image" & return after tFile
   put tab & enableMenuItem("Video File.../|video", the platform is not "Linux") & return after tFile
   put tab & "-" & return after tFile
   put tab & "All Images in Folder.../|image folder" & return after tFile
   put tab & enableMenuItem("All Video Files in Folder.../|video folder", the platform is not "Linux") & return after tFile
   put "-" & return after tFile
   
   put enableMenuItem("&Save/S", tCanSaveStack) & return after tFile
   put enableMenuItem("Save &As...", tCanSaveStack) & return after tFile
   put enableMenuItem("Move S&ubstack to File...", tIsUserTarget and the short name of the topStack is not the mainStack of the topStack) & return after tFile
   put enableMenuItem("&Revert to Saved...", tIsUserTarget and the effective filename of the topStack is not empty) & return after tFile
   put "-" & return after tFile
   
   put enableMenuItem("Standalone Application Settings...", tIsUserTarget) & return after tFile
   put enableMenuItem("Save as Standalone Application...", tIsUserTarget) & return after tFile
   put "-" & return after tFile
   
   put "P&age Setup..." & return after tFile
   put enableMenuItem("&Print Card.../P", tIsUserTarget) & return after tFile
   put enableMenuItem("Print Field...", word 1 of (the selObj) is "field") & return after tFile
   put "-" & return after tFile
   
   ## EJB 2014-08-26
   ## [[Bug 12880]]
   if the platform is "Linux" then
      put "&Quit" & return after tFile
   else
      put "E&xit" & return after tFile
   end if
   return modifyMenu("File", tFile)
end revMenubarFileMenu

################################################################################

private function buildEditMenu pContext
   local tEdit
   --put the text of button "Edit" into tEdit --only set the text once   
   
   local tObjectsLabel
   if pContext["objectsSelected"] then
      if word 1 of the selObj is "card" then
         put "Card" into tObjectsLabel
      else if word 1 of the selobj is not "stack" then
         put "Objects" into tObjectsLabel
      else
         put empty into tObjectsLabel
      end if
   end if
   
   local tSelectionLabel
   if the selectedImage is not empty then
      put "Image Selection" into tSelectionLabel
   else if pContext["textSelected"] then
      put "Text" into tSelectionLabel
   else if pContext["objectsSelected"] then
      put tObjectsLabel into tSelectionLabel
   else
      put empty into tSelectionLabel
   end if
   
   local tClipboardLabel
   switch the clipboard
      case "empty"
         put empty into tClipboardLabel
         break
         -- MW-2012-09-19: [[ Bug 9600 ]] Treat 'files' as 'text' clipboard type.
      case "text"
      case "files"
         if the selectedField is empty then
            put empty into tClipboardLabel
         else
            put "Text" into tClipboardLabel
         end if
         break
      case "objects"
         put "Objects" into tClipboardLabel
         break
      case "image"
         put "Image" into tClipboardLabel
         break
   end switch
   
   put "&Undo/Z" & return after tEdit
   put "-" & return after tEdit
   put enableMenuItem("Cu&t" && tSelectionLabel & "/X|cut", tSelectionLabel is not empty) & return after tEdit
   put enableMenuItem("&Copy" && tSelectionLabel & "/C|copy", tSelectionLabel is not empty) & return after tEdit
   put enableMenuItem("&Paste"&& tClipboardLabel & "/V|paste", tClipboardLabel is not empty) & return after tEdit
   put enableMenuItem("Paste &Unformatted/Cmd Shift Opt V", tClipboardLabel is "Text") & return after tEdit
   put enableMenuItem("Clea&r" && tSelectionLabel, tSelectionLabel is not empty) & return after tEdit
   put "-" & return after tEdit
   put enableMenuItem("&Duplicate" && tObjectsLabel &"/D", tObjectsLabel is not empty) & return after tEdit
   put enableMenuItem("&Replicate...", tObjectsLabel is "Objects") & return after tEdit
   put "-" & return after tEdit
   put "Select All/A" & return after tEdit
   put "Deselect All" & return after tEdit
   put enableMenuItem("In&vert Selection", tObjectsLabel is "Objects") & return after tEdit
   put toggleMenuItem("Select Grouped Controls", the selectGroupedControls) & return after tEdit
   put toggleMenuItem("Intersected Selections", the selectionMode is "intersect") & return after tEdit
   put "-" & return after tEdit
   put "Find and Replace.../F" & return after tEdit
   put "-" & return after tEdit
   put "Pre&ferences" after tEdit
   
   return modifyMenu("Edit", tEdit)
end buildEditMenu

################################################################################

private function buildToolsMenu pContext
   local tTools
   
   put markMenuItem("&Browse Tool/9", the tool is "browse tool") & return after tTools
   put markMenuItem("&Pointer Tool/0", the tool is "pointer tool") & return after tTools
   put "-" & return after tTools
   put toggleMenuItem("&Tools Palette/T", the mode of stack "revTools" is not 0) & return after tTools
   put toggleMenuItem("&Paint and Draw Tools", "paint" is among the items of revIDEGetPreference("revTools_show")) & return after tTools
   put "-" & return after tTools
   put "Application Browser" & return after tTools
   put "Project Browser" & return after tTools
   put "&Message Box/M" & return after tTools
   put "Extension Manager" & return after tTools
   put "-" & return after tTools
   put enableMenuItem("Menu Builder", the mode of the topStack is 1) & return after tTools
   if revIDEPrefGet("Unsupported,EnableDBQueryBuilder") then
      put enableMenuItem("Database Query Builder", the mode of the topStack is 1) & return after tTools
   end if
   
   return modifyMenu("Tools", tTools)
end buildToolsMenu

################################################################################

private function buildTextMenu pContext
   global gREVDisabledText, gREVTextMenu
   
   local tText,tFont,tSize,tAlign,tStyle,tColor
   
   if not pContext["enableText"] then
      put gREVDisabledText into tText
   else   
      put gREVTextMenu into tText   
      if pContext["textMenuSelection"] is "objects" then   
         --selected object   
         put "(!nSubscript" & return & "(!nSuperscript" into line 11 to 12 of tText   
         try
            put the textFont of the selectedObject into tFont   
            put the textSize of the selectedObject into tSize   
            put the textStyle of the selectedObject into tStyle   
            put the textColor of the selectedObject into tColor   
            put the textAlign of the selectedObject into tAlign   
            if the number of lines in (the selObj) > 1 then   
               repeat for each line l in (the selObj)   
                  if the textFont of l is not tFont then put "MULTIPLE" into tFont   
                  if the textSize of l is not tSize then put "MULTIPLE" into tSize   
                  if the textStyle of l is not tStyle then put "MULTIPLE" into tStyle   
                  if the textColor of l is not tColor then put "MULTIPLE" into tColor   
                  if the textAlign of l is not tAlign then put empty into tAlign   
               end repeat   
            end if   
         end try
      else   
         --selected text   
         put item 1 of the textFont of the selectedChunk into tFont   
         put the textSize of the selectedChunk into tSize   
         put the textStyle of the selectedChunk into tStyle
         if tStyle is empty then put "plain" into tStyle
         
         local tShift
         put the textShift of the selectedChunk into tShift   
         put the textColor of the selectedChunk into tColor   
         --text shift   
         if tShift is empty then put 0 into tShift   
         if tShift > 0 then put "!cSubscript" into line 11 of tText   
         else put "!nSubscript" into line 11 of tText   
         if tShift < 0 then put "!cSuperscript" into line 12 of tText   
         else put "!nSuperscript" into line 12 of tText   
      end if   
      --font   
      if tFont is empty then put "Use Owner's Font" into tFont   
      local tLineNo
      put lineOffset(tFont,tText) into tLineNo   
      if tLineNo is not 0 then   
         --if it is 0, auto unhiliting will occur as text is set to default   
         put "c" into char 2 of line tLineNo of tText   
      end if   
      --size   
      local tStartNum
      put lineOffset("Size"&cr,tText) into tStartNum   
      if tSize is empty then put "Use Owner's Size" into tSize   
      
      put lineOffset(tSize,tText,tStartNum)+tStartNum into tLineNo   
      if tLineNo is not 0 and tSize is not "Multiple" then   
         if tSize is not among the items of "Use Owner's Size,8,9,10,12,14,18,24,36,48" then put lineOffset("Other..."&cr,tText) into tLineNo   
         put "c" into char 2 of line tLineNo of tText   
      end if   
      --style   
      replace "threedbox" with "3D Box" in tStyle   
      repeat for each item tItem in tStyle   
         put lineOffset(tItem, tText) into tLineNo   
         if tLineNo is not 0 then put "c" into char 2 of line tLineNo of tText   
      end repeat   
      --color   
      if tColor is "0,0,0" then put "Black" into tColor   
      if tColor is "255,255,255" then put "White" into tColor   
      if tcolor is "255,0,0" then put "Red" into tColor   
      if tColor is "0,255,0" then put "Green" into tColor   
      if tColor is "0,0,255" then put "Blue" into tColor   
      if tColor is "255,255,0" then put "Yellow" into tColor   
      put lineOffset("Color"&cr,tText) into tStartNum   
      if tColor is empty then put "Use Owner's Color" into tColor   
      if tColor is the penColor then put "pen color" into tColor   
      put lineOffset(tColor,tText,tStartNum)+tStartNum into tLineNo   
      if tLineNo is not 0 and tLineNo is not tStartNum then   
         put "c" into char 2 of line tLineNo of tText   
      end if   
      --align   
      if tAlign is not empty then
         local tAlignSkip
         put lineOffset("&Align",tText) into tAlignSkip
         --items including right,left,center could be included in Font menu
         put lineOffset(tAlign,tText,tAlignSkip) + tAlignSkip into tAlignSkip
         put "c" into char 2 of line tAlignSkip of tText
      end if  
   end if
   
   return modifyMenu("Text", tText)
end buildTextMenu

################################################################################

private function buildObjectMenu pContext
   local tObject
   
   local tIsObjectTarget, tIsUserTarget
   put (the selObj) is not empty and word 1 of (the selObj) is not "stack" into tIsObjectTarget
   put char 1 to 3 of the short name of the topStack is not "rev" into tIsUserTarget
   
   ### Initial sections
   put enableMenuItem("&Object Inspector", tIsObjectTarget) & return after tObject
   put enableMenuItem("&Card Inspector", tIsUserTarget) & return after tObject
   put enableMenuItem("&Stack Inspector/K", tIsUserTarget) & return after tObject
   put "-" & return after tObject
   put enableMenuItem("Object Script/E", tIsObjectTarget) & return after tObject
   put enableMenuItem("Card Script", tIsUserTarget) & return after tObject
   put enableMenuItem("Stack Script", tIsUserTarget) & return after tObject
   put "-" & return after tObject
   
   ### Lines 9 to 11: Group, Edit Group, Remove Group
   local tGroupLines
   if the selectedImage is empty and pContext["objectsSelected"] then
      if word 1 of (the selObj) is "group" and the number of lines in (the selObj) is 1 then   
         put "&Ungroup Selected/G" & return & "&Edit Group/R" & return & "Remove Group"into tGroupLines   
      else if word 1 of (the selObj) is not among the items of "card,stack" then
         put "&Group Selected/G" & return & "(&Edit Group/R" & return & "(Remove Group"into tGroupLines
      else
         put "(&Group Selected/G" & return & "(&Edit Group/R" & return & "(Remove Group" into tGroupLines
      end if
   else
      put "(&Group Selected/G" & return & "(&Edit Group/R" & return & "(Remove Group" into tGroupLines   
   end if
   if the editBackground of the topStack and word 1 of (the selObj) is not "group" then
      put "&Stop Editing Group" into line 2 of tGroupLines
   end if
   put tGroupLines & return after tObject
   
   ### Line 12: Place group, with the list of groups
   local tGroupNames
   put buildGroupSubmenu(the short name of the topStack) into tGroupNames
   if the mode of the topStack is not 1 or tGroupNames is empty then 
      put "(Place Group" & return after tObject   
   else
      put "Place Group" & return & tGroupNames & return after tObject 
   end if
   put "-" & return after tObject
   
   ### New Card and Delete Card
   put enableMenuItem("&New Card/N", tIsUserTarget) & return after tObject
   put enableMenuItem("Delete Card", tIsUserTarget) & return after tObject
   put enableMenuItem("New Control", the mode of the topStack is 1) & return after tObject
   put buildNewControlSubmenu() & return after tObject
   put "-" & return after tObject
   
   local tFlipText, tRotateText, tReshapeText
   if not pContext["enableFlipAndRotate"] or pContext["selectedObject"] is empty then
      put "(Flip" into tFlipText
      put "(Rotate" into tRotateText
      put "(Reshape Graphic" into tReshapeText
   else
      if pContext["allImages"] then
         put "Flip Image" into tFlipText
         put "Rotate Image" into tRotateText
         put "(Reshape Graphic" into tReshapeText
      else if pContext["allGraphics"] then
         put "Flip Graphic" into tFlipText
         put "Rotate Graphic" into tRotateText
         if the long id of stack "revReshapeLibrary" is among the lines of the frontScripts then
            put "!cReshape Graphic" into tReshapeText
         else 
            put "Reshape Graphic" into tReshapeText
         end if
      else
         put "Flip Selected" into tFlipText
         put "Rotate Selected" into tRotateText
         put "(Reshape Graphic" into tReshapeText
      end if
   end if
   
   ### Flip, with a submenu. Rotate, with a submenu. And Reshape graphic
   put tFlipText & return after tObject
   put buildFlipSubmenu() & return after tObject
   
   put tRotateText & return after tObject
   put buildRotateSubmenu() & return after tObject
   
   put tReshapeText & return after tObject
   
   put "-" & return after tObject
   
   ### Align selected controls, with a submenu
   put enableMenuItem("Align Selected Controls", the number of lines in (the selObj) >= 2) & return after tObject
   put buildAlignSubmenu() & return after tObject
   
   put "-" & return after tObject
   
   ### Send to back, Move Backward, Move Forward and Bring to Front
   put enableMenuItem("&Send to Back", pContext["objectsSelected"]) & return after tObject
   put enableMenuItem("Move Backward/[", pContext["objectsSelected"]) & return after tObject
   put enableMenuItem("Move For&ward/]", pContext["objectsSelected"]) & return after tObject
   put enableMenuItem("Bring to &Front", pContext["objectsSelected"]) & return after tObject
   
   return modifyMenu("Object", tObject)
end buildObjectMenu

private function buildNewControlSubmenu
   return \	
         tab & "Standard Button" & return & \
         tab & "Rectangle Button" & return & \
         tab & "Shadow Button" & return & \
         tab & "Blank Button" & return & \
         tab & "-" & return & \
         tab & "Check Box" & return & \
         tab & "Radio Button" & return & \
         tab & "-" & return & \
         tab & "Tabbed Button" & return & \
         tab & "-" & return & \
         tab & "Table Field" & return & \
         tab & "Data Grid" & return & \
         tab & "-"  & return & \
         tab & "Field" & return & \
         tab & "Scrolling Field" & return & \
         tab & "List Field" & return & \
         tab & "Scrolling List Field" & return & \
         tab & "Label Field" & return & \
         tab & "-" & return & \
         tab & "Horizontal Scrollbar" & return & \
         tab & "Vertical Scrollbar" & return & \
         tab & "Scale Bar" & return & \
         tab & "Progress Bar" & return & \
         tab & "-" & return & \
         tab & "Pulldown menu" & return & \
         tab & "Popup Menu" & return & \
         tab & "Option Menu" & return & \
         tab & "Combo Box Menu" & return & \
         tab & "-" & return & \
         tab & "Menu Item" & return & \
         tab & "Cascade Menu Item" & return & \
         tab & "Divider Button" & return & \
         tab & "-" & return & \
         tab & "Rectangle Graphic" & return & \
         tab & "Oval Graphic" & return & \
         tab & "Curve Graphic" & return & \
         tab & "Round Rect Graphic" & return & \
         tab & "Polygon Graphic" & return & \
         tab & "Line Graphic" & return & \
         tab & "Regular Polygon Graphic" & return & \
         tab & "-" & return & \
         tab & "Image" & return & \
         tab & "-" & return & \
         tab & "Player"
end buildNewControlSubmenu

private function buildFlipSubmenu
   return \
         tab & "Horizontal" & return & \
         tab & "Vertical" 
end buildFlipSubmenu

private function buildRotateSubmenu
   return \
         tab & "By..." & return & \
         tab & "90° Right" & return & \
         tab & "90° Left" & return & \
         tab & "180°"
end buildRotateSubmenu

# OK-2007-10-04 : Forgot this one- oops
private function buildAlignSubmenu
   return \
         tab & "Left" & return & \
         tab & "Right" & return & \
         tab & "Top" & return & \
         tab & "Bottom" & return & \
         tab & "-" & return & \
         tab & "Make Widths E&qual" & return & \
         tab & "Make &Heights Equal"
end buildAlignSubmenu

# OK-2009-11-20 : Bug 8235 - This is much faster using the engine version
private function buildGroupSubmenu pStack
   local tStack
   put the long id of stack pStack into tStack
   
   local tUnplacedIds
   put the revUnplacedGroupIds of tStack into tUnplacedIds
   
   local tFinalGroups
   repeat for each line tGroup in tUnplacedIds   
      put tab & the short name of control id tGroup of tStack & "/|" & tGroup & return after tFinalGroups
   end repeat   
   delete last char of tFinalGroups
   sort tFinalGroups   
   
   return tFinalGroups
end buildGroupSubmenu

################################################################################

private function buildHelpMenu pContext
   local tHelp
   put "Welcome Screen/|Welcome Screen" & return after tHelp
   put "Start Center/|Start Center" & return after tHelp
   put "Dictionary (API)/|Dictionary" & return after tHelp
   --put "Resource Center/|Resource Center" & return after tHelp
   
   put "-" & return  after tHelp
   
   put "Sample Stacks" & return after tHelp
   put "Sample Scripts" & return after tHelp
   put "-" & return after tHelp
   put "Beginners Guide" & return after tHelp
   put "All Guides" & return after tHelp
   put "Tutorials" & return after tHelp
   put "User Guide" & return after tHelp
   put "-" & return after tHelp
   put "Forums" & return after tHelp
   put "Technical Questions" & return after tHelp
   put "Use List" & return after tHelp
   put "Newsletters" & return after tHelp
   put "-" & return after tHelp
   
   --put "Example Stacks and Resources/|Resources" & return after tHelp 
   --put "-" & return after tHelp
   --put "User Guide/|User Guide" & return after tHelp
   put "Release Notes/|Release Notes" & return after tHelp
   --put "iOS Release Notes/|iOS Release Notes" & return after tHelp
   --put "Android Release Notes/|Android Release Notes" & return after tHelp
   put "License Agreement/|License Agreement" & return after tHelp
   put "-" & return after tHelp
   put "&Buy a License.../|Buy" & return after tHelp
   put "&Support.../|Support" & return after tHelp
   put "-" & return after tHelp
   put enableMenuItem("Re-license LiveCode/|Relicense", line 7 of the revLicenseInfo is not "Global") & return after tHelp
   put "-" & return after tHelp
   put "Check For Updates/|Update" & return after tHelp
   put "-" & return after tHelp
   put "About LiveCode/|About" after tHelp
   
   return modifyMenu("Help", tHelp)
end buildHelpMenu

################################################################################

private function buildViewMenu pContext
   global gREVPalettes, gREVShowStacks
   
   local tView
   put enableMenuItem("Go &First/1", the mode of the topStack is 1) & return after tView
   put enableMenuItem("Go Pre&v/2", the mode of the topStack is 1) & return after tView
   put enableMenuItem("Go Ne&xt/3", the mode of the topStack is 1) & return after tView
   put enableMenuItem("Go &Last/4", the mode of the topStack is 1) & return after tView
   put enableMenuItem("Go Recent/5", the mode of the topStack is 1) & return after tView
   put "-" & return after tView
   put toggleMenuItem("Toolbar Text", the cToolbarText of stack "revPreferences") & return after tView
   put toggleMenuItem("Toolbar Icons", the cToolbarIcons of stack "revPreferences") & return after tView
   put "-" & return after tView
   
   -- Bug 10729
   -- gRevPalletes is not a boolean so changed to check for empty
   put toggleMenuItem("Palettes", gREVPalettes is empty) & return after tView
   put toggleMenuItem("Rulers", the mode of stack "revRulersH" is not 0) & return after tView
   put toggleMenuItem("Grid", the grid) & return after tView
   put toggleMenuItem("Backdrop", the backdrop is not "none") & return after tView
   put toggleMenuItem("LiveCode UI Elements in Lists", gREVShowStacks) & return after tView
   put "-" & return after tView
   put "Look and Feel" & return after tView
   put tab & markMenuItem("Native Theme", the lookAndFeel is "Appearance Manager") & return after tView
   put tab & markMenuItem("Emulated - Mac OS Classic", the lookAndFeel is "Macintosh") & return after tView
   put tab & markMenuItem("Emulated - Windows 95", the lookAndFeel is "Windows 95") & return after tView
   put tab & markMenuItem("Emulated - Motif", the lookAndFeel is "Motif") & return after tView
   put "-" & return after tView
   put toggleMenuItem("Show &Invisible Objects" , the showInvisibles) & return after tView
   
   return modifyMenu("View", tView)
end buildViewMenu

################################################################################

private function buildDevelopmentMenu pContext
   global gREVSuppressErrors, gREVSuppressMessages
   
   revIDEUpdatePlugins
   
   local tDevelopment
   put "Object Library" & return after tDevelopment
   put "Image Library" & return after tDevelopment
   put "Plugins" & return after tDevelopment
   put revIDEPluginNames() & return after tDevelopment
   put tab & "-" & return after tDevelopment
   put tab & "Plugin Settings" & return after tDevelopment
   put "-" & return after tDevelopment
   put buildSimulatorSubmenu() after tDevelopment
   put "-" & return after tDevelopment   
   put toggleMenuItem("Script Debug Mode", revDebuggerEnabled()) & return after tDevelopment
   put"Clear All Breakpoints" & return after tDevelopment
   put "Message Watcher" & return after tDevelopment
   put "-" & return after tDevelopment
   put toggleMenuItem("Suppress Errors", gREVSuppressErrors) & return after tDevelopment
   put toggleMenuItem("Suppress Messages", gREVSuppressMessages) & return after tDevelopment
   put "-" & return after tDevelopment
   put "Suspend Development Tools" & return after tDevelopment
   
   return modifyMenu("Development", tDevelopment)
end buildDevelopmentMenu

private function buildSimulatorSubmenu
   local tSimulators
   put revIDEDeployListTargets() into tSimulators
   
   if tSimulators is not an array then
      return "(Test/|Simulate" & return & "(Test Target" & return & tab & "(No targets configured" & return
   end if
   
   local tCurrentTarget
   put revIDEDeployGetTarget() into tCurrentTarget
   
   local tMenu
   put enableMenuItem("Test/|Simulate", tCurrentTarget is not empty) & return after tMenu
   put "Test Target/|Simulator Version" & return after tMenu
   repeat for each key tPlatform in tSimulators
      local tCanDeploy
      put revIDEDeployIsPossible(tPlatform) into tCanDeploy
      repeat for each line tTarget in tSimulators[tPlatform]
         put tab & enableMenuItem(toggleMenuItem(tTarget, tTarget is tCurrentTarget), tCanDeploy) & return after tMenu
      end repeat
      put tab & "-" & return after tMenu
   end repeat
   delete char -3 to -1 of tMenu
   
   return tMenu
end buildSimulatorSubmenu

################################################################################

private function buildWindowMenu pContext
   local tMendgText
   put revIDEWindowListAsMenu() into tMendgText
   
   local tStackNames
   put revIDEWindowList() into tStackNames
   set the cStacks of button "Window" of me to tStackNames
   
   local tWindow
   if tMendgText is empty then
      put "(No Windows Open" into tWindow
   else
      put tMendgText & return & "-" & return & "Send Window to Back/`" into tWindow
   end if
   
   return modifyMenu("Window", tWindow)
end buildWindowMenu

################################################################################

function revBuildContextSensitiveMenu pExtraText, pTarget
   global gREVLanguageNames
   
   local tTargetStack
   put revIDEStackOfObject(pTarget) into tTargetStack
   
   local tText
   if word 1 of pTarget is not "card" then
      put "Edit Script" & return after tText
      put "Property Inspector" & return after tText
      put "-" & return after tText
      put "Cut" & return after tText
      put "Copy" & return after tText
      put pExtraText after tText
      put "-" & return after tText
      
      local tSendMessageList
      put revListMenuHandlers(pTarget, the cSort of stack "revPreferences", 1) into tSendMessageList
      put enableMenuItem("Send Message", tSendMessageList is not tab) & return after tText
      put tSendMessageList & return after tText
      
      put "Card && Stack" & return after tText
   end if
   
   put tab & "Edit Card Script" & return after tText
   put tab & "Card Property Inspector" & return after tText
   put tab & "New Card" & return after tText
   put tab & "-" & return after tText
   put tab & "Edit Stack Script" & return after tText
   put tab & "Stack Property Inspector" & return after tText
   put tab & "Stack Mode" & return after tText
   if gREVLanguageNames then
      put markMenuItem(tab & tab & "topLevel", the mode of stack tTargetStack < 3) & return after tText
      put markMenuItem(tab & tab & "modeless", the mode of stack tTargetStack is 3) & return after tText
      put markMenuItem(tab & tab & "palette", the mode of stack tTargetStack is 4) & return after tText
      put markMenuItem(tab & tab & "modal", the mode of stack tTargetStack is 5) & return after tText
   else
      put markMenuItem(tab & tab & "TopLevel", the mode of stack tTargetStack < 3) & return after tText
      put markMenuItem(tab & tab & "Modeless", the mode of stack tTargetStack is 3) & return after tText
      put markMenuItem(tab & tab & "Palette", the mode of stack tTargetStack is 4) & return after tText
      put markMenuItem(tab & tab & "Modal", the mode of stack tTargetStack is 5) & return after tText
   end if
   put tab & "Save" & return after tText
   put tab & "-" & return after tText
   put tab & enableMenuItem("Paste Objects", the clipboard is "objects" and the mode of stack tTargetStack is 1) & return after tText
   put tab & "-" & return after tText
   
   local tSendCardMessageList
   put revListMenuHandlers(the long id of this card of stack tTargetStack, the cSort of stack "revPreferences", 2) into tSendCardMessageList
   put tab & enableMenuItem("Send Card Message", tSendCardMessageList is not tab & tab) & return after tText
   put tSendCardMessageList & return after tText
   
   local tSendStackMessageList
   put revListMenuHandlers(the long id of stack tTargetStack, the cSort of stack "revPreferences", 2) into tSendStackMessageList
   put tab & enableMenuItem("Send Stack Message", tSendStackMessageList is not tab & tab) & return after tText
   put tSendStackMessageList & return after tText
   
   return tText
end revBuildContextSensitiveMenu

function revMenubarContextMenu pType, pTarget
   local tText
   switch pType
      case "card"
         put revBuildContextSensitiveMenu("", pTarget) into tText
         replace tab&tab with "#####REVDOUBLETAB#####" in tText
         replace tab with empty in tText
         replace "#####REVDOUBLETAB#####" with tab in tText
         break
      case "group"
         put enableMenuItem("Paste into Group", the clipboard is "objects") & return after tText
         put "-" & return after tText
         put "Edit Group" & return after tText
         put "Ungroup" & return after tText
         put "-" & return after tText
         put toggleMenuItem("Lock Location", the lockLoc of pTarget) & return after tText
         put revBuildContextSensitiveMenu(tText) into tText
         break
      case "image"
         put "-" & return after tText
         put toggleMenuItem("Paint Tools", "Show" is not in the toolTip of btn "paint and draw" of stack "revTools") & return after tText
         put "Launch Editor" & return after tText
         put toggleMenuItem("Magnify", the magnify of pTarget) & return after tText
         put "-" & return after tText
         put toggleMenuItem("Lock Location", the lockLoc of pTarget) & return after tText
         put enableMenuItem("Make Original Size", the formattedWidth of pTarget is not the width of pTarget \
               or the formattedHeight of pTarget is not the height of pTarget) & return after tText
         put revBuildContextSensitiveMenu(tText) into tText
         break
      case "polygon"
         put "-" & return after tText
         put "Reshape Polygon" & return after tText
         put revBuildContextSensitiveMenu(tText) into tText
         break
      case "multiple"
         put "-" & return after tText
         put "Align" & return after tText
         put tab & "Left" & return after tText
         put tab & "Right" & return after tText
         put tab & "Top" & return after tText
         put tab & "Bottom" & return after tText
         put tab & "-" & return after tText
         put tab & "Make Widths Equal" & return after tText
         put tab & "Make Heights Equal" & return after tText
         put "Group" & return after tText
         put revBuildContextSensitiveMenu(tText) into tText
         break
      case "field"
         put enableMenuItem("Paste Text", the clipboard is "text") & return after tText
         put "-" & return after tText
         put toggleMenuItem("Lock Text", the lockText of pTarget) & return after tText
         put toggleMenuItem("Can Receive Keyboard Focus", the traversalOn of pTarget) & return after tText
         put revBuildContextSensitiveMenu(tText) into tText
         break
      case "player"
         put "-" & return after tText
         put enableMenuItem("Play", word 1 of the tool is "browse") & return after tText
         put enableMenuItem("Stop", word 1 of the tool is "browse") & return after tText
         put enableMenuItem("Pause", word 1 of the tool is "browse") & return after tText
         put revBuildContextSensitiveMenu(tText) into tText
         break
      case "menu"
         put enableMenuItem("TopLevel Panel Stack", the menuName of pTarget is not empty) & return after tText
         put revBuildContextSensitiveMenu(tText) into tText
         break
      case "standard"
      default
         put revBuildContextSensitiveMenu() into tText
         break
   end switch
   return modifyMenu(pType, tText)
end revMenubarContextMenu

on revMenubarSetContextMenu pType, pTarget
   set the text of button "context" of me to revMenubarContextMenu(pType, pTarget)
   if pType is "card" then
      set the script of button "context" of me to "on menuPick pWhich; revMenubarContextSubmenuPick pWhich; end menuPick"
   else
      set the script of button "context" of me to "on menuPick pWhich; revMenubarContextMenuPick pWhich; end menuPick"
   end if
end revMenubarSetContextMenu

on revMenubarPopupContextualMenu pTarget
   local tTarget
   if pTarget is not empty then
      put the long id of pTarget into tTarget
   else
      put the long id of the target into tTarget
   end if
   
   local tTargetStack
   put revTargetStack(tTarget) into tTargetStack
   
   put the long id of tTarget into sMenuTarget
   if the number of lines in (the selObj) > 1 and the long id of tTarget is among the lines of (the selObj) then
      revMenubarSetContextMenu "multiple", tTarget
   else
      local tType
      put word 1 of the name of tTarget into tType
      switch tType
         case "button"
            if the menuName of tTarget is not empty then
               revMenubarSetContextMenu "menu", tTarget
            else
               revMenubarSetContextMenu "button", tTarget
            end if
            break
         case "graphic"
            if the style of tTarget is "polygon" then
               revMenubarSetContextMenu "polygon", tTarget
            else
               revMenubarSetContextMenu "standard", tTarget
            end if
            break
         case "card"
         case "group"
         case "image"
         case "field"
         case "player"
            revMenubarSetContextMenu tType, tTarget
            break
         default
            revMenubarSetContextMenu "standard", tTarget
            break
      end switch
   end if
   popup button "context" of me
end revMenubarPopupContextualMenu
################################################################################

private function modifyMenu pMenuName, pMenu
   if the last char of pMenu is not return then
      put return after pMenu
   end if
   
   return pMenu
end modifyMenu

function enableMenuItem pItem, pEnabled
   if pEnabled then
      return pItem
   end if
   return "(" & pItem
end enableMenuItem

function toggleMenuItem pItem, pHilited
   if pHilited then
      return "!c" & pItem
   end if
   return "!n" & pItem
end toggleMenuItem

function markMenuItem pItem, pMarked
   if pMarked then
      return "!r" & pItem
   end if
   return "!u" & pItem
end markMenuItem

################################################################################

command revMenuBarUpdateRecentPaths
  revIDECleanRecentPaths
  
  local tRecentPathsMenu
  put revIDEGetRecentPathsAsMenu() into tRecentPathsMenu
  
  local tFileButtonText
  put the text of button "File" of group "revMenuBar" of me into tFileButtonText
   
  local tStart
  set the wholeMatches to true
  put lineOffset("Open Recent File", tFileButtonText) + 1 into tStart
  set the wholeMatches to false
   
  local tEnd
  put lineOffset("&Close/W", tFileButtonText) - 1 into tEnd
  put tRecentPathsMenu into line tStart to tEnd of tFileButtonText
  set the text of button "File" of group "revMenuBar" of me to tFileButtonText
  
end revMenuBarUpdateRecentPaths

# OK-2007-05-03: Bug 4833.
# Parameters
#   pObject : reference to the object to list handlers for
#   pSort : Whether to sort the list of handlers
#   pIndentationLevel : How many tabs should appear before each line
# Description
#   Returns a formatted list of handler names for the context menu
function revListMenuHandlers pObject, pSort, pIndentationLevel
   local tRawHandlers
   put the revAvailableHandlers of pObject into tRawHandlers
   
   local tIndent
   if pIndentationLevel is an integer then
      repeat pIndentationLevel times
         put tab after tIndent
      end repeat
   end if
   
   local tFormattedHandlers
   repeat for each line tHandler in tRawHandlers
      if char 1 of tHandler is "P" then
         next repeat
      else if char 1 of tHandler is among the items of "S,G,F" then
         next repeat
      else
         # OK-2008-02-26 : Remove start and end line numbers from formattedHandlers, as these were added to the engine recently
         #put tIndent & word 2 to -1 of tHandler & return after tFormattedHandlers
         put tIndent & word 2 of tHandler & return after tFormattedHandlers
      end if
      
   end repeat
   
   # OK-2009-04-02 : Bug 7874 - Include behavior handlers if applicable
   if the behavior of pObject is not empty and there is a (the behavior of pObject) then
      local tBehaviorHandlers
      put the revAvailableHandlers of the behavior of pObject into tBehaviorHandlers
      
      # Only behavior handlers that are non-private, of type "command" and not overridden by the
      # object are included.
      repeat for each line tBehaviorHandler in tBehaviorHandlers
         if char 1 of tBehaviorHandler is "P" then
            next repeat
         else if char 1 of tBehaviorHandler is among the items of "S,G,F" then
            next repeat
         end if
         
         # For each behavior handler, find out if it was overridden by the object before including it
         local tOverridden
         put false into tOverridden
         repeat for each line tFormattedHandler in tFormattedHandlers
            if word 1 of tFormattedHandler is word 2 of tBehaviorHandler then
               put true into tOverridden
               exit repeat
            end if
         end repeat
         
         if not tOverridden then
            put tIndent & word 2 of tBehaviorHandler & return after tFormattedHandlers
         end if
      end repeat
   end if
   delete the last char tFormattedHandlers
   
   if pSort then
      sort lines of tFormattedHandlers
   end if
   
   if tFormattedHandlers is empty then
      put tIndent into tFormattedHandlers
   end if
   
   return tFormattedHandlers  
end revListMenuHandlers

on unIconifyStack
   global gREVBackDropRestore, gREVRestore
   if gREVRestore["windowBoundingRect"] is empty then pass unIconifyStack
   set cursor to watch
   lock messages
   set the iconic of stack "revMenubar" to false
   
   local tOpenStackslist, tNoLines, l
   put the cREVMaxList of stack "revmenuBar" into tOpenStackslist
   put the number of lines in tOpenStacksList into tNoLines
   repeat with i = tNoLines down to 1
      put line i of tOpenStacksList into l
      if l is "revMenuBar" then next repeat
      
      -- Fix for stacks reappearing if they were hidden before a minimize.
      if revMetaDataGet(the name of stack l, "general", "AlreadyHidden") then next repeat
      
      if there is a stack l and not the visible of stack l then
         show stack l
      end if
   end repeat
   if gREVBackDropRestore is not empty then set the backDrop to gREVBackDropRestore
   unlock messages
   set the windowBoundingRect to gREVRestore["windowBoundingRect"]
end unIconifyStack

on iconifyStack
   local tOpenStackslist, tMaxlist
   global gREVBackDropRestore, gREVMenutopLeft, gREVRestore
   put the windowBoundingRect into gREVRestore["windowBoundingRect"]
   set the windowBoundingRect to 0,0,item 3 to 4 of the windowBoundingRect
   lock messages
   set cursor to watch
   set the iconic of stack "revMenubar" to true
   put the openStacks into tOpenStackslist
   repeat for each line l in tOpenStacksList
      if l is "revMenuBar" then next repeat
       
      -- Fix for stacks reappearing if they were hidden before a minimize.
      revMetaDataSet the name of stack l, "general", "AlreadyHidden", not the visible of stack l
      
      --if the visible of stack l then
      put l & cr after tMaxlist
      hide stack l
      --end if
   end repeat
   delete last char of tMaxList
   set the cREVMaxList of stack "revMenuBar" to tMaxList
   if the backDrop is not "none" then put the backDrop into gREVBackDropRestore
   set the backDrop to "none"
   unlock messages
end iconifyStack

################################################################################
#
#                 MENU PICK
#
################################################################################
# We handle all menu picks here 

on revMenubarMenuPick pWhich
   switch the short name of the target
      case "File"
         revMenubarFileMenuPick pWhich
         break
      case "Edit"
         revMenubarEditMenuPick pWhich
         break
      case "Tools"
         revMenubarToolsMenuPick pWhich
         break
      case "Object"
         revMenubarObjectMenuPick pWhich
         break
      case "Text"
         revMenubarTextMenuPick pWhich
         break
      case "Development"
         revMenubarDevelopmentMenuPick pWhich
         break
      case "View"
         revMenubarViewMenuPick pWhich
         break
      case "Window"
         revMenubarWindowMenuPick pWhich
         break
      case "Help"
         revMenubarHelpMenuPick pWhich 
         break
   end switch
end revMenubarMenuPick

on revMenubarContextSubmenuPick pWhich, pOwnerMenu
   local tTargetStack
   put revIDEStackOfObject(sMenuTarget) into tTargetStack
   switch pWhich
      ######## CARD AND STACK #########
      case "Edit Card Script"
         revIDEEditScriptOfObject the long id of this card of tTargetStack
         break
      case "Card Property Inspector"
         revIDEOpenInspectorForObjects the long id of this card of tTargetStack
         break
      case "New Card"
         set the defaultStack to tTargetStack
         create card
         break
      case "Edit Stack Script"
         revIDEEditScriptOfObject tTargetStack
         break
      case "Stack Property Inspector"
         revIDEOpenInspectorForObjects tTargetStack
         break
      case "topLevel"
      case "modeless"
      case "palette"
      case "modal"
         send "revChangeMode pMenuItem, tTargetStack" to me in 200 milliseconds
         break
      case "Save"
         if the effective fileName of stack tTargetStack is not empty
         then revSave tTargetStack
         else revSaveAs tTargetStack
         break
      case "Paste Objects"
         set the defaultStack to tTargetStack
         paste
         break
      default
         --pMenuItem must be a message name
         --either send it to the card or the stack
         if pOwnerMenu is "Send Card Message"
         then send "revSendMessage pMenuItem, the long id of this cd of stack tTargetStack" to me
         else send "revSendMessage pMenuItem, the long id of stack tTargetStack" to me
         break
   end switch
end revMenubarContextSubmenuPick

on revMenubarContextMenuPick pWhich
   switch pWhich
      ######## OBJECTS #########
      case "Edit Script"
         revIDEEditScriptOfObject sMenuTarget
         break
      case "Property Inspector"
         revIDEOpenInspectorForObjects sMenuTarget
         break
      case "Cut"
         cut pTarget
         break
      case "Copy"
         copy pTarget
         break
      case "Lock Location"
      case "lockLocation"
         set the lockLoc of sMenuTarget to not (the lockLoc of sMenuTarget)
         break
         ######## GROUP SPECIFIC #########
      case "Edit Group"
         start editing sMenuTarget
         break
      case "Ungroup"
         select sMenuTarget
         ungroup
         break
      case "Paste into Group"
         lock screen
         start editing sMenuTarget
         send "revStopEditingGroupAfterPasting" to me in 500 milliseconds
         
         break
         ######## IMAGE SPECIFIC #########
      case "Paint Tools"
         send "menuPick Paint and Draw Tools" to btn "Tools" of cd 1 of stack "revMenubar" 
         break
      case "Launch Editor"
         revEditImage sMenuTarget
         break
      case "Magnify"
         set the magnify of sMenuTarget to not (the magnify of sMenuTarget)
         if the magnify of sMenuTarget then
            if the tool is "pointer tool" or the tool is "browse tool" then 
               send "mouseUp" to btn "select" of stack "revTools"
            end if
         end if
         break 
      case "Make Original Size"
         set the width of sMenuTarget to the formattedWidth of sMenuTarget
         set the height of sMenuTarget to the formattedHeight of sMenuTarget
         break
         ######## FIELD SPECIFIC #########
      case "Paste Text"
         lock screen
         local tLockText, tTraversalOn
         put the lockText of sMenuTarget into tLockText
         put the traversalOn of sMenuTarget into tTraversalOn
         set the lockText of sMenuTarget to false
         set the traversalOn of sMenuTarget to true
         if the selection is not empty and the long id of the selectedField is sMenuTarget then
            paste
         else
            select after text of sMenuTarget
            paste
         end if
         set the lockText of sMenuTarget to tLockText
         set the traversalOn of sMenuTarget to tTraversalOn
         unlock screen
         break
      case "Can Receive Keyboard Focus"
      case "traversalOn"
         set the traversalOn of sMenuTarget to not (the traversalOn of sMenuTarget)
         break
         ######## PLAYER SPECIFIC #########
      case "Play"
         do "start" && sMenuTarget
         break
      case "Stop"
         do "stop playing" && sMenuTarget
         break
      case "Pause"
         --paused apparently reporting true when the player's playing
         --so always pause the player
         set the paused of sMenuTarget to true
         --set the paused of gREVMenutarget to not (the paused of gREVMenuTarget)
         break
         ######## MENU SPECIFIC #########
      case "TopLevel Panel Stack"
         toplevel the menuname of sMenuTarget
         break
      default
         set the itemDel to "|"
         switch item 1 of pWhich
            case "Align"
               send "menuPick pWhich" to btn "Object" of stack "revMenuBar"     
               break     
            case "Send Message"
               local tMessage
               put item 2 of pWhich into tMessage
               send "revSendMessage tMessage, sMenuTarget" to me
               break
            default
               --Card and stack
               local tOwnerMenu, tCardMenuItem
               put item 2 of pWhich into tOwnerMenu
               put the last item of pWhich into tCardMenuItem
               set the itemDel to comma
               revMenubarContextSubmenuPick tCardMenuItem, tOwnerMenu
               break
         end switch
   end switch
end revMenubarContextMenuPick

######## FILE MENU ##########
on revMenubarFileMenuPick pWhich
   switch pWhich
      case "New Substack"
         revIDENewSubstack the long id of the topStack
         break
      case "Open Stack..."
         revIDEActionOpenStack
         break
      case "Close"
         revIDECloseStack the long id of the topStack, false
         break
      case "Close and Remove From Memory"
         revIDECloseStack the long id of the topStack, true
         break
      case "Save"
         revIDESaveStack the long id of the topStack
         break
      case "Save As..."
         revIDESaveStackAs the long id of the topStack
         break
      case "Save As Standalone Application..."
         revIDESaveAsStandalone the long id of the topStack
         break
      case "Standalone Application Settings..."
         revIDEOpenPalette "standalone settings"
         break
      case "Move substack to file..."
         revIDEMoveSubstackToFile the long id of the topStack
         break
      case "Revert To Saved..."
         revIDEActionRevertToSavedStack the long id of the topStack
         break
      case "Page Setup..."
         revIDEPrintPageSetup
         break
      case "Print Card..."
         revIDEPrintCard this card
         break
      case "Print Field..."
         revIDEPrintField line 1 of (the selObj)
         break
      case "Quit"
      case "Exit"
         revIDEQuit
         break
      default
         set the itemDel to "|"
         local tType
         switch item 1 of pWhich      
            case "New Stack"
               local tStackType
               put item 2 of pWhich into tStackType
               if tStackType is "Script only" then
                  revIDEActionNewScriptOnlyStack
               else
                  revIDEActionNewMainstack tStackType
               end if
               break
            case "Open Recent File"
               revIDEActionOpenRecent item 2 of pWhich
               break
            case "Import As Control"
               put item 2 of pWhich into tType
               switch tType
                  case "image"
                  case "audio"
                  case "video"
                  case "text"
                     revIDEActionImportAsControl tType
                     break 
                  case "Snapshot of Screen"
                     revIDEImportSnapshotOfScreen
                     break
                  case "Snapshot of Selected Object"
                     revIDEImportSnapshotOfObject the selobj
                     break
                  case "image folder"
                  case "audio folder"
                  case "video folder"
                  case "text folder"
                     revIDEActionImportAsControlFromFolder word 1 of tType
                     break
               end switch
            case "New Referenced Control"
               put item 2 of pWhich into tType
               switch tType
                  case "image"
                  case "video"
                     revIDEActionReferencedControl tType
                     break
                  case "image folder"
                  case "video folder"
                     revIDEActionReferencedControlFromFolder word 1 of tType
                     break
               end switch
         end switch
   end switch
end revMenubarFileMenuPick

on revMenubarEditMenuPick pWhich
   global gREVChunkStore, gREVUndoList
   switch pWhich
      case "Undo"
         if gREVUndoList is not empty then
            if line -1 of gREVUndoList is "width" then
               delete last line of gREVUndoList
               
               local tObject
               repeat for each line tLine in gREVUndoList
                  put item 1 to -2 of tLine into tObject
                  if there is a tObject then
                     set the width of tObject to item -1 of tLine
                  end if
                  send "revCacheGeometry true" to tObject
               end repeat
            else if line -1 of gREVUndoList is "height" then
               delete last line of gREVUndoList
               repeat for each line l in gREVUndoList
                  put item 1 to -2 of l into tObject
                  if there is a tObject then set the height of tObject to item -1 of l
                  send "revCacheGeometry true" to tObject
               end repeat
            else if line -1 of gREVUndoList is "rect" then
               delete last line of gREVUndoList
               repeat for each line l in gREVUndoList
                  put item 1 to -5 of l into tObject
                  if there is a tObject then set the rect of tObject to item -4 to -1 of l
                  send "revCacheGeometry true" to tObject
               end repeat
            end if
            put empty into gREVUndoList
         else
            undo
            repeat for each line l in the selObj
               send "revCacheGeometry true" to l
            end repeat
         end if
         break
      case "Cut Object(s)"
      case "Cut Objects"
      case "Cut Card"
      case "Cut"
      case "Cut Text"
      case "Cut Image Selection"
         if the selectedField is not empty and the lockText of the selectedField then 
            exit to top
         end if
         lock screen
         if the selectedImage is not empty then
            if the selectedText is not empty then select empty
            lock screen
            set the defaultStack to revTargetStack(the long id of the selectedImage)
            cut
            unlock screen
            exit revMenubarEditMenuPick
         end if
         if revCheckGroupDelete() then
            cut
         end if
         revUpdatePalette
         unlock screen
         exit to top
         break
      case "Copy Objects"
      case "Copy Object(s)"
      case "Copy Card"
      case "Copy"
      case "Copy Text"
      case "Copy Image Selection"
         if the selectedImage is not empty then
            if the selectedText is not empty then select empty
            set the defaultStack to revTargetStack(the long id of the selectedImage)
            copy
            exit revMenubarEditMenuPick
         else copy
         
         revUpdatePalette
         exit to top
         break
      case "Paste"
      case "Paste Object(s)"
      case "Paste Objects"
      case "Paste Text"
      case "Paste Image"
      case "Paste Unformatted"
         lock screen
         local tUnformatted
         if pWhich is "Paste Unformatted" then 
            put true into tUnformatted
         end if
         if the clipBoard is "text" and (the selectedChunk) is empty and (gREVChunkStore) is not empty then
            try
               select gREVChunkStore
               if tUnformatted then
                  put the clipBoardData["text"] into the selection
               else
                  paste
               end if
               --if pasting into the script editor, enable the Revert/Apply buttons
               local tFocusedObject
               put (the focusedObject) into tFocusedObject
               
               local tOwnercard
               put word 5 to -1 of tFocusedObject into tOwnerCard
               --check the Script field of the script editor is focused
               if the name of tFocusedObject is "field " & quote & "Script" & quote and the name of tOwnerCard is "card " & quote & "revScript" & quote
               then send "rawKeyUp" to tFocusedObject
               exit revMenubarEditMenuPick
            catch someError
               beep
            end try
            exit revMenubarEditMenuPick
         end if
         lock messages
         set the defaultStack to the topStack
         if the clipBoard is not text and (the mode of the topStack is not 1 or the cantModify of the topStack) then
            beep
            exit revMenubarEditMenuPick
         end if
         if the clipBoard is "image" and the selectedImage is empty then
            lock messages
            lock screen
            create image
            put the clipBoardData["image"] into last image
            unlock messages
            unlock screen
            local tObjects
            put true into tObjects
            choose pointer tool
            select last image
         else
            if tUnformatted then
               put the clipBoardData["text"] into the selection
            else
               -- MW-2012-02-10: [[ Bug ]] Make sure the IDE doesn't interfere with the textChanged
               --   message.
               unlock messages
               paste
               lock messages
            end if
         end if
         if the clipBoard is "objects" or tObjects then
            local tMilliseconds
            put the milliseconds into tMilliseconds
            repeat for each line l in the selObj
               set the cREVGeneral["revUniqueID"] of l to tMilliseconds
               add 1 to tMilliseconds
            end repeat
         end if
         unlock messages
         --if the clipBoard is among the items of "objects,image" or tObjects 
         --then  "selectedObjectChanged" to button "revBackScript" of stack "revLibrary"
         --exit to top
         unlock screen
         break
      case "Clear Objects"
      case "Clear Card"
      case "Clear"
      case "Clear Text"
      case "Clear Image Selection"
         if the selectedImage is not empty then
            set the defaultStack to revTargetStack(the long id of the selectedImage)
            delete
            exit revMenubarEditMenuPick
         end if
         set the defaultStack to the topStack
         if the selectedField is not empty then if the lockText of the selectedField then exit to MetaCard
         if revCheckGroupDelete() then delete
         break
      case "Deselect All"
         select empty
         break
      case "Select All"
         if the mode of the topStack is not 1 and the selectedField is empty then
            beep
            exit revMenubarEditMenuPick
         end if
         if the selectedImage is not empty then
            lock screen
            set the defaultStack to revTargetStack(the long id of the selectedImage)
            local tRect
            put the rect of the selectedImage into tRect
            choose select tool
            drag from item 1 to 2 of tRect to item 3 to 4 of tRect
            unlock screen
            exit revMenubarEditMenuPick
         end if
         if the selectedField is not empty \
               and revTargetStack(the focusedObject) is revTargetStack(the long id of the selectedField) then
            if the lockText of the selectedField then exit to top
            select text of the selectedField
         else
            if the cantModify of the topStack then
               answer "This stack can't be modified"
               exit to top
            end if
            if the tool is not "pointer tool" then 
               beep
               exit revMenubarEditMenuPick
            end if
            lock screen
            lock messages
            set the defaultStack to the topStack
            repeat with i = 1 to the number of layers
               if the visible of control i or the showInvisibles then
                  if not the cantSelect of control i then
                     if the selectGroupedControls and (word 1 of the name of control i is "group" and the selectGroupedControls of control i is true) then
                        if word 1 of the name of control i is not "group" then
                           set the selected of control i to true
                        end if
                     else
                        set the selected of control i to true
                        add the number of layers in control i to i
                     end if
                  else
                     add the number of layers in control i to i
                  end if
               end if
            end repeat
            unlock screen
            unlock messages
            send "selectedObjectChanged" to stack "revBackScriptLibrary"
         end if
         
         // EJB Added to update new Project Browser
         //send "refreshBrowser" to stack "revProjectBrowser"
         
         break
      case "Invert Selection"
         if the mode of the topStack is not 1 and the selectedField is empty then
            beep
            exit revMenubarEditMenuPick
         end if
         lock screen
         lock messages
         set the defaultStack to the topStack
         repeat with i = 1 to the number of controls
            if (the visible of control i or the showInvisibles) and (not the selectGroupedControls or (the selectGroupedControls and word 1 of the name of control i is not "group")) then
               set the selected of control i to not the selected of control i
            end if
            if not the selectGroupedControls then add the number of layers in control i to i
         end repeat
         unlock screen
         unlock messages
         send "selectedObjectChanged" to stack "revBackScriptLibrary"
         
         // EJB Added to update new Project Browser
         send "refreshBrowser" to stack "revProjectBrowser"
         break
      case "Duplicate"
      case "Duplicate Objects"
         # MW-2010-10-15: [[ Bug 9070 ]] Add 'Duplicate Objects' to the switch statement to handle
         #    case where item name has been customized.
         set the defaultStack to revTargetStack(line 1 of (the selobj))
         if the selObj is not empty then
            lock screen
            
            ## EJB 14-07-20414
            ## [[ Bug 11240 ]] lock screen removed so duplicated controls reveive messages
            --lock messages
            
            # OK-2007-07-31 : Bug 4917. Instead of assuming that the duplicated controls will have the highest layer
            # numbers, we make certain that we select the correct objects by saving a list of each newly created control
            local tCreatedObjects
            
            put the milliseconds into i
            repeat for each line tObject in the selObj
               clone tObject
               put the long id of it & return after tCreatedObjects
               
               if the right of last control > the right of this cd or the bottom of last control > the bottom of this cd then 
                  set the topLeft of the last control to 10, 10
               end if
               if word 1 of the name of tObject is not "group" then
                  set the cREVGeneral["revUniqueID"] of last control to i
                  add 1 to i
               else
                  set the cREVGeneral["revUniqueID"] of last control to i
                  add 1 to i
                  
                  repeat with tGroupedControl = 1 to the number of controls of the last group
                     set the cREVGeneral["revUniqueID"] of control tGroupedControl of the last group to i
                     add 1 to i
                  end repeat
               end if
            end repeat
            select empty
            
            repeat for each line tCreatedObject in tCreatedObjects
               set the selected of tCreatedObject to true
            end repeat
            
            --unlock messages
            unlock screen
            send "selectedObjectChanged" to stack "revBackScriptLibrary"
            revUpdateAOControls (line 1 of the selObj)
            
            // EJB Added to update new Project Browser
            if there is a stack "revProjectBrowser" then
               send "refreshBrowser" to stack "revProjectBrowser"
            end if
         end if
         break
      case "Duplicate Card"
         set the defaultStack to revTargetStack(line 1 of (the selobj))
         clone the selobj
         break
      case "Replicate..."
         modal "revReplicate"
         break
      case "Select Grouped Controls"
         set the selectGroupedControls to not (the selectGroupedControls)
         if the selectGroupedControls and word 1 of (the selObj) is "group" then select empty
         break
      case "Intersected Selections"
         if the selectionMode is "intersect" then
            set the selectionMode to "surround"
         else
            set the selectionMode to "intersect"
         end if
         break
      case "Preferences"
         modeless "revPreferencesGUI"
         break
      case "Find and Replace..."
         modeless "revSearch"
         break
   end switch
end revMenubarEditMenuPick

on revMenubarToolsMenuPick pWhich
   switch pWhich
      case "Database Query Builder"
         # OK-2008-03-06 : Bug 6031. The query builder cannot be used in edit group mode
         # so we turn this off if the user launches the stack.
         if the editBackground of the topStack then
            set the editBackground of the topStack to false
         end if
         
         modeless "revdbquerysetup"
         break
      case "Tools Palette"
         if the mode of stack "revTools" is 0 then palette "revTools"
         else close stack "revTools"
         break
      case "Browse Tool"
         choose browse tool
         break
      case "Pointer Tool"
         choose pointer tool
         break
      case "paint and draw tools"
         local tToolsOnShow
         put revIDEGetPreference("revTools_show") into tToolsOnShow
         if "paint" is among the items of tToolsOnShow then
            delete item itemoffset("paint", tToolsOnShow) of tToolsOnShow
         else
            if tToolsOnShow is empty then
               put "paint" into tToolsOnShow
            else
               put comma & "paint" after tToolsOnShow
            end if
         end if
         revIDESetPreference "revTools_show", tToolsOnShow
         
         break
      case "Menu Builder"
         modeless "revMenuManager"
         break
      case "Message Box"
         # OK-2008-06-24: Bug 6575
         revIDEShowMessageBox
         break
      case "Animation Builder"
         palette "revAnimation"
         break
      case "Application Browser"
         --modeless "revApplicationOverview"
         # TH-2008-02-07 :: Now opens using new mode that allows minimising
         set the _ideoverride of stack "revApplicationOverview" to true
         toplevel "revApplicationOverview"
         break
      case "Project Browser"
         --         set the cIDEProjectBrowserOpen of stack "revPreferences" to true
         --         revInternal__SavePreferences
         --         modeless "revProjectBrowser"
         revIDEOpenPalette "project browser"
         break
      case "Extension Manager"
         revIDEOpenPalette "extension manager"
         break
      case "Report Builder"
         modeless "revReportSetup"
         break
   end switch
end revMenubarToolsMenuPick

on revMenubarObjectMenuPick pWhich
   global gREVStacksList, gREVStackStatus, gREVObjectsList
   
   if pWhich is empty then exit revMenubarObjectMenuPick
   switch pWhich
      case "Reshape Graphic"
         if "revReshapeLibrary" is not among the lines of revInternal__ListLoadedLibraries() then
            choose pointer tool
            revInternal__LoadLibrary "revReshapeLibrary"
            put empty into gREVObjectsList
            revSetMarkers
         else
            revSetMarkers true
            revInternal__UnloadLibrary "revReshapeLibrary"
         end if
         Break
      case "New card"
         local tFilterStack
         put the short name of the topStack into tFilterStack
         if revFilterStacksList(tFilterStack) is empty then 
            send "menuPick" && "New Mainstack" to btn "File" of stack "revMenuBar"
            exit revMenubarObjectMenuPick
         end if
         set the defaultStack to the topStack
         create card
         put "edited" into gREVStackStatus[the short name of this stack]
         break
      case "Delete Card"
         set the defaultStack to the topStack
         answer error "Are you sure you want to delete this card?" with "Yes" or "No"
         if it is not "yes" then exit revMenubarObjectMenuPick
         delete this card
         put "edited" into gREVStackStatus[the short name of this stack]
         break
      case "Object Inspector"
         --send "revBuildPropertyPalette" to stack "revTemplatePalette"
         revIDEOpenPalette "inspector"
         break
      case "Card Inspector"
         select this cd of the topStack
         --send "revBuildPropertyPalette" to stack "revTemplatePalette"
         revIDEOpenPalette "inspector"
         break
      case "Stack Inspector"
         select empty
         --send "revBuildPropertyPalette" to stack "revTemplatePalette"
         revIDEOpenPalette "inspector"
         break 
      case "Object Script"
         # OK-2008-04-09 : New script editor changes. When in edit group mode, the selectedObject returns
         # incorrect long ids. We use the "rugged id" to get around this problem.
         local tRuggedObject
         repeat for each line tObject in (the selectedObject)
            put revRuggedId(tObject) into tRuggedObject
            edit the script of tRuggedObject
         end repeat
         break
      case "Card Script"
         edit script of this cd of the topStack
         break
      case "Stack Script"
         edit script of the topStack
         break
      case "Remove Group"
         set the defaultStack to the topStack
         
         if the editBg of this stack then
            answer error "This group is nested and cannot be removed separately from its owner group."
            pass revMenubarObjectMenuPick
         end if
         
         repeat for each line l in (the selobj)
            if word 5 of l is among the items of "background,group" then
               answer error "This group is nested and cannot be removed separately from its owner group."
               pass revMenubarObjectMenuPick
            end if
         end repeat
         
         repeat for each line l in (the selObj)
            if word 1 of l is "group" then
               revDeleteLinkedObject l
               remove l from this cd
            end if
         end repeat
         revUpdateAOControls the long id of this cd
         break
      case "Send to Back"
         lock screen
         revSendToBack the selObj
         revUpdateSizeAndPosition
         unlock screen
         break
      case "Move Backward"
         lock screen
         revMoveBackward the selObj
         revUpdateSizeAndPosition
         unlock screen
         break
      case "Move forward"
         lock screen
         revMoveForward the selObj
         revUpdateSizeAndPosition
         unlock screen
         break
      case "Bring to Front"
         lock screen
         revBringToFront the selObj
         revUpdateSizeAndPosition
         unlock screen
         break
      case "Group Selected"
         if (the selObj) is not empty then
            if word 1 of (the selObj) is not "group" or the number of lines in (the selObj) > 1 then revCheckGroup
            else revCheckUnGroup
            
            local tTarget
            put line 1 of (the selobj) into tTarget
            
            local tStack
            put revTargetStack(tTarget) into tStack
            revUpdateAOControls the long id of this cd of stack tStack
            
         end if
         break
      case "Edit Group"
         if the selobj is empty or word 1 of (the selObj) is not "group" then exit revMenubarObjectMenuPick
         if revMenuManagerGroup(the selobj) then
            set the defaultStack to revTargetStack(line 1 of (the selobj))
            answer error "Can't edit group that is in use by the Menu Manager.  To edit this group close the Menu Manager."
            exit revMenubarObjectMenuPick
         end if
         
         start editing the selObj
         revKillRedundantPalettes
         if the mode of stack "revApplicationOverview" is not 0 \
               and the short name of this cd of stack "revApplicationOverview" is "Cards and Controls" then
            send "revRefreshControls true" to stack "revApplicationOverview"
         end if
         --send "refreshBrowser" to stack "revProjectBrowser"
         break
      case "Stop Editing Group"
         set the defaultStack to the topStack
         set the editBG to false
         revKillRedundantPalettes
         if the mode of stack "revApplicationOverview" is not 0 \
               and the short name of this cd of stack "revApplicationOverview" is "Cards and Controls" then
            send "revRefreshControls true, false" to stack "revApplicationOverview"
         end if
         ## EJB Bug 11043
         ## Ungrouping was nor causing the PB to update
         ## As only selectedObjectChanged message is sent which does not cause a redraw
         --send "refreshBrowser" to stack "revProjectBrowser"
         break
      case "Ungroup selected"
         if (the selObj) is not empty then
            if word 1 of (the selObj) is not "group" then revCheckGroup
            else revCheckUnGroup
            
            put line 1 of (the selobj) into tTarget
            put revTargetStack(tTarget) into tStack
            revUpdateAOControls the long id of this cd of stack tStack
            --send "refreshBrowser" to stack "revProjectBrowser"
         end if
         break
      case "show Invisibles"
         set the showInvisibles to not (the showInvisibles)
         break
      case "Reshape Graphic"
         if "revReshapeLibrary" is not among the lines of revInternal__ListLoadedLibraries() then
            revInternal__LoadLibrary "revReshapeLibrary"
            put empty into gREVObjectsList
            revSetMarkers
         else
            revSetMarkers true
            revInternal__UnloadLibrary "revReshapeLibrary"
         end if
         break
      default
         set the itemDel to "|"
         
         local tItem
         put item 2 of pWhich into tItem
         if item 1 of pWhich is "Place Group" then
            # OK-2009-10-02 : Code was breaking with groups named "Background", and seemed to be overcomplicated.
            set the defaultStack to the topStack
            if tItem is not empty then
               place background id tItem onto this card
               if the tool is "pointer tool" then
                  do ("select background id" & quote & tItem & quote)
               end if
               revUpdateAOControls the long id of this card
            end if
            
         end if
         if word 1 of item 1 of pWhich is "Flip" then
            local tSelectedObject
            put the selectedObject into tSelectedObject
            set the defaultStack to revTargetStack(line 1 of tSelectedObject)
            lock screen
            if item 2 of pWhich is "Horizontal" then
               set the itemDel to comma
               repeat for each line l in tSelectedObject
                  if word 1 of l is "image" then
                     flip image id (the id of l) horizontal
                  else
                     ## 2014-08-20 EJB [[Bug 13191]]
                     --flip graphic horizontally
                     local tLeft, tRight, tPoints, tNewPoints
                     put the left of l into tLeft
                     put the right of l into tRight
                     put the points of l into tPoints
                     put empty into tNewPoints
                     repeat for each line m in tPoints
                        
                        -- added BN in case a line is empty
                        if m = "" then
                           put cr after tNewPoints
                           next repeat
                        end if
                        -- end addition BN for empty line
                        
                        put tLeft+tRight-(item 1 of m),item 2 of m & cr after tNewPoints
                     end repeat
                     set the points of l to tNewPoints
                  end if
               end repeat
            else
               ## 2014-08-20 EJB [[Bug 13191]]
               --flip vertical
               set the itemDel to comma
               repeat for each line l in tSelectedObject
                  if word 1 of l is "image" then
                     flip image id (the id of l) vertical
                  else
                     --flip graphic vertically
                     local tTop, tBottom
                     put the top of l into tTop
                     put the bottom of l into tBottom
                     put the points of l into tPoints
                     put empty into tNewPoints
                     repeat for each line m in tPoints
                        
                        -- added BN in case a line is empty
                        if m = "" then 
                           put cr after tNewPoints
                           next repeat
                        end if
                        -- end addition BN for empty line
                        
                        put item 1 of m,tTop+tBottom-(item 2 of m) & cr after tNewPoints
                     end repeat
                     set the points of l to tNewPoints
                  end if
               end repeat
            end if
            unlock screen
            exit revMenubarObjectMenuPick
         end if
         if word 1 of item 1 of pWhich is "Rotate" then
            put the selectedObject into tSelectedObject
            set the defaultStack to revTargetStack(line 1 of tSelectedObject)
            --note that rotate works counter clockwise
            
            local tPreviousImageQualitySetting
            switch
               case item 2 of pWhich is "By..."
                  modal "revRotate"
                  if the cRotateGraphic of stack "revRotate" is empty then exit revMenubarObjectMenuPick
                  
                  local tRotateGraphic
                  put the cRotateGraphic of stack "revRotate" into tRotateGraphic
                  
                  local tRotateImage
                  put the cRotateImage of stack "revRotate" into tRotateImage
                  lock screen
                  
                  
                  repeat for each line l in tSelectedObject
                     if word 1 of l is "image" then
                        put the resizeQuality of image id (the id of l) into tPreviousImageQualitySetting
                        set the resizeQuality of image id (the id of l) to "best"
                        rotate image id (the id of l) by tRotateImage
                        set the resizeQuality of image id (the id of l) to tPreviousImageQualitySetting
                     else
                        --rotate graphic
                        revRotatePoly l,tRotateGraphic
                     end if
                  end repeat
                  choose pointer tool
                  unlock screen
                  break
               case word 2 of item 2 of pWhich is "Right"
                  lock screen
                  repeat for each line l in tSelectedObject
                     if word 1 of l is "image" then
                        put the resizeQuality of image id (the id of l) into tPreviousImageQualitySetting
                        set the resizeQuality of image id (the id of l) to "best"
                        rotate image id (the id of l) by 270
                        set the resizeQuality of image id (the id of l) to tPreviousImageQualitySetting
                     else
                        --rotate graphic 90 degrees
                        revRotatePoly l,90
                     end if
                  end repeat
                  choose pointer tool
                  unlock screen
                  break
               case word 2 of item 2 of pWhich is "Left"
                  lock screen
                  repeat for each line l in tSelectedObject
                     if word 1 of l is "image" then
                        put the resizeQuality of image id (the id of l) into tPreviousImageQualitySetting
                        set the resizeQuality of image id (the id of l) to "best"
                        rotate image id (the id of l) by 90
                        set the resizeQuality of image id (the id of l) to tPreviousImageQualitySetting
                     else
                        --rotate graphic 270 degrees
                        revRotatePoly l,270
                     end if
                  end repeat
                  choose pointer tool
                  unlock screen
                  break
               case char 1 to 3 of item 2 of pWhich is "180"
               case char 1 to 3 of item 2 of pWhich is "270"
                  local tBy
                  put char 1 to 3 of item 2 of pWhich into tBy
                  lock screen
                  repeat for each line l in tSelectedObject
                     if word 1 of l is "image" then
                        put the resizeQuality of image id (the id of l) into tPreviousImageQualitySetting
                        set the resizeQuality of image id (the id of l) to "best"
                        rotate image id (the id of l) by tBy
                        set the resizeQuality of image id (the id of l) to tPreviousImageQualitySetting
                     else
                        --rotate graphic tBy degrees
                        revRotatePoly l,tBy 
                     end if
                  end repeat
                  choose pointer tool
                  unlock screen
                  break
            end switch
            exit revMenubarObjectMenuPick
         end if
         
         set the defaultStack to the topStack
         reset the templateButton
         set the loc of the templateButton to the loc of this cd
         revNewObjectName "button"
         reset the templateField
         set the loc of the templateField to the loc of this cd
         revNewObjectName "field"
         reset the templateGraphic
         set the loc of the templateGraphic to the loc of this cd
         set the opaque of the templateGraphic to true
         revNewObjectName "graphic"
         reset the templateScrollBar
         set the loc of the templateScrollbar to the loc of this cd
         revNewObjectName "scrollBar"
         reset the templateImage
         set the loc of the templateImage to the loc of this cd
         revNewObjectName "image"
         set the loc of the templatePlayer to the loc of this cd
         revNewObjectName "player"
         
         choose pointer tool
         lock messages
         switch tItem
            case "Standard Button"
               set the width of the templateButton to the cButtonWidth of stack "revPreferences"
               set the height of the templateButton to the cButtonHeight of stack "revPreferences"
               create button
               exit switch
            case "Round Rect Button"
               set the style of the templateButton to "roundRect"
               set the width of the templateButton to the cButtonWidth of stack "revPreferences"
               set the height of the templateButton to the cButtonHeight of stack "revPreferences"
               create button
               exit switch
            case "Rectangle Button"
               set the style of the templateButton to "rectangle"
               set the width of the templateButton to the cButtonWidth of stack "revPreferences"
               set the height of the templateButton to the cButtonHeight of stack "revPreferences"
               create button
               exit switch
            case "Shadow Button"
               set the style of the templateButton to "shadow"
               set the width of the templateButton to the cButtonWidth of stack "revPreferences"
               set the height of the templateButton to the cButtonHeight of stack "revPreferences"
               create button
               exit switch
            case "Radio Button"
               set the style of the templateButton to "radiobutton"
               set the hiliteBorder of the templateButton to false
               set the width of the templateButton to the cButtonWidth of stack "revPreferences"
               set the height of the templateButton to the cButtonHeight of stack "revPreferences"
               create button
               exit switch
            case "Blank Button"
               set the showName of the templateButton to false
               set the traversalOn of the templateButton to false
               set the hiliteBorder of the templateButton to false
               set the sharedHilite of the templateButton to false
               set the hiliteFill of the templateButton to false
               set the showBorder of the templateButton to false
               set the threeD of the templateButton to false
               set the width of the templateButton to the cButtonWidth of stack "revPreferences"
               set the height of the templateButton to the cButtonHeight of stack "revPreferences"
               create button
               break
            case "table field"
               set the style of the templateField to "scrolling"
               set the hGrid of the templateField to true
               set the vGrid of the templateField to true
               set the tabStops of the templateField to 75
               set the lockText of the templateField to true
               set the name of the templateField to "Table Field"
               set the width of the templateField to the cFieldWidth of stack "revPreferences"
               set the height of the templateField to the cFieldHeight of stack "revPreferences"
               create fld
               set the cREVGeneral["table"] of last fld to true
               set the cREVTable["celledit"] of last fld to true
               exit switch
            case "Divider Button"
               set the height of the templateButton to 2
               set the width of the templateButton to the cButtonWidth of stack "revPreferences"
               create button
               break
            case "Check Box"
               set the style of the templateButton to "checkbox"
               set the hiliteBorder of the templateButton to false
               set the width of the templateButton to the cButtonWidth of stack "revPreferences"
               set the height of the templateButton to the cButtonHeight of stack "revPreferences"
               create button
               exit switch
            case "Tabbed Button"
               set the style of the templateButton to "menu"
               set the menuMode of the templateButton to "tabbed"
               set the text of the templateButton to "Tab 1" & cr & "Tab 2" & cr & "Tab 3"
               set the showName of the templateButton to false
               if the platform is "MacOS" and char 1 of the systemVersion is "1" then
                  set the textFont of the templateButton to "Lucida Grande"
                  set the textSize of the templateButton to 13
               end if
               set the width of the templateButton to the cTabButtonWidth of stack "revPreferences"
               set the height of the templateButton to the cTabButtonHeight of stack "revPreferences"
               create button
               exit switch
            case "Field"
               set the width of the templateField to the cLabelFieldWidth of stack "revPreferences"
               set the height of the templateField to the cLabelFieldHeight of stack "revPreferences"
               create field
               break
            case "Scrolling Field"
               set the width of the templateField to the cFieldWidth of stack "revPreferences"
               set the height of the templateField to the cFieldHeight of stack "revPreferences"
               set the style of the templateField to "scrolling"
               create field
               break
            case "List Field"
               set the width of the templateField to the cFieldWidth of stack "revPreferences"
               set the height of the templateField to the cFieldHeight of stack "revPreferences"
               set the listBehavior of the templateField to true
               set the sharedText of the templateField to true
               set the dontWrap of the templateField to true
               set the lockText of the templateField to true
               set the text of the templateField to "Choice 1" & cr & "Choice 2" & cr & "Choice 3"
               create field
               break
            case "Scrolling list field"
               set the width of the templateField to the cFieldWidth of stack "revPreferences"
               set the height of the templateField to the cFieldHeight of stack "revPreferences"
               set the style of the templateField to "scrolling"
               set the listBehavior of the templateField to true
               set the sharedText of the templateField to true
               set the dontWrap of the templateField to true
               set the lockText of the templateField to true
               set the text of the templateField to "Choice 1" & cr & "Choice 2" & cr & "Choice 3"
               create field
               break
            case "Label Field"
               set the width of the templateField to the cLabelFieldWidth of stack "revPreferences"
               set the height of the templateField to the cLabelFieldHeight of stack "revPreferences"
               set the lockText of the templateField to false
               set the sharedText of the templateField to true
               set the dontWrap of the templateField to true
               set the showBorder of the templateField to false
               set the opaque of the templateField to false
               set the traversalOn of the templateField to false
               set the autoHilite of the templateField to false
               set the text of the templateField to "Label text"
               create field
               break
            case "Vertical Scrollbar"
               set the height of the templateScrollBar to the cScrollBarWidth of stack "revPreferences"
               if the platform is "MacOS" then
                  set the width of the templateScrollbar to the cMacOSScrollbarHeight of stack "revPreferences"
               else
                  set the width of the templateScrollbar to the cScrollBarHeight of stack "revPreferences"
               end if
               create scrollbar
               break
            case "Horizontal Scrollbar"
               set the width of the templateScrollBar to the cScrollBarWidth of stack "revPreferences"
               if the platform is "MacOS" then
                  set the height of the templateScrollbar to the cMacOSScrollbarHeight of stack "revPreferences"
               else
                  set the height of the templateScrollbar to the cScrollBarHeight of stack "revPreferences"
               end if
               create scrollbar
               break
            case "Scale Bar"
               set the style of the templateScrollBar to "scale"
               set the width of the templateScrollbar to the cScrollbarwidth of stack "revPreferences"
               if the platform is "MacOS" then
                  set the height of the templateScrollbar to the cMacOSScrollbarHeight of stack "revPreferences"
               else
                  set the height of the templateScrollbar to the cScrollBarHeight of stack "revPreferences"
               end if
               create scrollbar
               break
            case "Progress Bar"
               set the style of the templateScrollBar to "progress"
               set the width of the templateScrollbar to the cScrollbarwidth of stack "revPreferences"
               if the platform is "MacOS" then
                  set the height of the templateScrollbar to the cMacOSProgressScrollbarHeight of stack "revPreferences"
               else
                  set the height of the templateScrollbar to the cScrollBarHeight of stack "revPreferences"
               end if
               create scrollbar
               break
            case "Pulldown Menu"
               set the width of the templateButton to the cMenuWidth of stack "revPreferences"
               set the height of the templateButton to the cMenuHeight of stack "revPreferences"
               set the style of the templateButton to "menu"
               set the menuMode of the templateButton to "pulldown"
               set the showBorder of the templateButton to false
               set the autoHilite of the templateButton to false
               set the traversalOn of the templateButton to false
               set the armBorder of the templateButton to false
               set the textAlign of the templateButton to "left"
               set the text of the templateButton to "Choice 1" & cr & "Choice 2" & cr & "Choice 3"
               create button
               exit switch
            case "Popup menu"
               set the width of the templateButton to the cMenuWidth of stack "revPreferences"
               set the height of the templateButton to the cMenuHeight of stack "revPreferences"
               set the style of the templateButton to "menu"
               set the menuMode of the templateButton to "popUp"
               set the text of the templateButton to "Choice 1" & cr & "Choice 2" & cr & "Choice 3"
               create button
               exit switch
            case "Option menu"
               set the width of the templateButton to the cMenuWidth of stack "revPreferences"
               set the height of the templateButton to the cMenuHeight of stack "revPreferences"
               set the style of the templateButton to "menu"
               set the menuMode of the templateButton to "option"
               set the autoHilite of the templateButton to false
               set the armBorder of the templateButton to false
               set the traversalOn of the templateButton to false
               set the text of the templateButton to "Choice 1" & cr & "Choice 2" & cr & "Choice 3"
               create button
               exit switch
            case "Combo box menu"
               set the width of the templateButton to the cMenuWidth of stack "revPreferences"
               set the height of the templateButton to the cMenuHeight of stack "revPreferences"
               set the style of the templateButton to "menu"
               set the menuMode of the templateButton to "combobox"
               set the autoHilite of the templateButton to false
               set the armBorder of the templateButton to false
               set the traversalOn of the templateButton to true
               set the text of the templateButton to "Choice 1" & cr & "Choice 2" & cr & "Choice 3"
               create button
               exit switch
            case "menu item"
               set the style of the templateButton to "standard"
               set the width of the templateButton to the cMenuWidth of stack "revPreferences"
               set the height of the templateButton to the cMenuHeight of stack "revPreferences"
               set the showBorder of the templateButton to false
               set the autoHilite of the templateButton to false
               set the autoArm of the templateButton to true
               set the textAlign of the templateButton to "left"
               create button
               break
            case "Cascade Menu Item"
               set the style of the templateButton to "menu"
               set the menuMode of the templateButton to "cascade"
               set the width of the templateButton to the cMenuWidth of stack "revPreferences"
               set the height of the templateButton to the cMenuHeight of stack "revPreferences"
               set the showBorder of the templateButton to false
               set the autoHilite of the templateButton to false
               set the autoArm of the templateButton to true
               set the textAlign of the templateButton to "left"
               create button
               break
            case "Rectangle Graphic"
               set the width of the templateGraphic to the cREVGraphicWidth of stack "revPreferences"
               set the height of the templateGraphic to the cREVGraphicHeight of stack "revPreferences"
               set the style of the templateGraphic to "rectangle"
               create graphic
               exit switch
            case "Oval Graphic"
               set the width of the templateGraphic to the cREVGraphicWidth of stack "revPreferences"
               set the height of the templateGraphic to the cREVGraphicHeight of stack "revPreferences"
               set the style of the templateGraphic to "oval"
               create graphic
               exit switch
            case "Curve Graphic"
               set the width of the templateGraphic to the cREVGraphicWidth of stack "revPreferences"
               set the height of the templateGraphic to the cREVGraphicHeight of stack "revPreferences"
               set the style of the templateGraphic to "curve"
               set the points of the templateGraphic to "43,105" & cr & "43,104" & cr & "46,102" & cr & "56,96" & cr & "70,90" & cr & "78,86" & cr & "81,85" & cr & "82,85" & cr & "85,85" & cr & "94,90" & cr & "101,99" & cr & "108,109" & cr & "111,117" & cr & "112,120" & cr & "117,121" & cr & "138,118" & cr & "157,113" & cr & "162,111" & cr & "165,108" & cr & "166,108" & cr & "167,109" & cr & "171,115" & cr & "175,124" & cr & "179,132" & cr & "180,134" & cr & "181,134" & cr & "183,134" & cr & "190,134" & cr & "198,130" & cr & "205,129" & cr & "206,128" & cr & "207,128" & cr & "207,129" & cr & "212,137" & cr & "215,142" & cr & "216,145" & cr & "217,146" & cr & "217,147" & cr & "218,148" & cr & "219,149" & cr & "220,150" & cr & "221,150"
               set the loc of the templateGraphic to the loc of this cd
               create graphic
               exit switch
            case "Round Rect Graphic"
               set the width of the templateGraphic to the cREVGraphicWidth of stack "revPreferences"
               set the height of the templateGraphic to the cREVGraphicHeight of stack "revPreferences"
               set the style of the templateGraphic to "roundRect"
               create graphic
               exit switch
            case "Polygon Graphic"
               set the width of the templateGraphic to the cREVGraphicWidth of stack "revPreferences"
               set the height of the templateGraphic to the cREVGraphicHeight of stack "revPreferences"
               set the style of the templateGraphic to "polygon"
               set the points of the templateGraphic to 0,0,100,100,100,50,50,100
               set the loc of the templateGraphic to the loc of this cd
               create graphic
               exit switch
            case "Regular Polygon Graphic"
               set the width of the templateGraphic to the cREVGraphicWidth of stack "revPreferences"
               set the height of the templateGraphic to the cREVGraphicHeight of stack "revPreferences"
               set the style of the templateGraphic to "regular"
               set the polySides of the templateGraphic to 4
               create graphic
               exit switch
            case "Line Graphic"
               set the width of the templateGraphic to the cREVGraphicWidth of stack "revPreferences"
               set the height of the templateGraphic to the cREVGraphicHeight of stack "revPreferences"
               set the style of the templateGraphic to "line"
               set the points of the templateGraphic to 0,0,120,120
               set the loc of the templateGraphic to the loc of this cd
               create graphic
               exit switch
            case "Image"
               set the width of the templateImage to the cREVImageWidth of stack "revPreferences"
               set the height of the templateImage to the cREVImageHeight of stack "revPreferences"
               create image
               break
            case "Player"
               set the showController of the templatePlayer to true
               set the width of the templatePlayer to the cREVPlayerWidth of stack "revPreferences"
               set the height of the templatePlayer to the cREVPlayerHeight of stack "revPreferences"
               create player
               break
            case "Data Grid"
               # OK-2010-02-22: Bug 7992 - This should probably be refactored to the revIDE backscript 
               # to prevent needing to use call.
               local tGridLocation
               put the location of this card into tGridLocation
               
               local tGridStack
               put the short name of this stack into tGridStack
               
               local tObjectType
               put "data grid" into tObjectType
               
               local tGrid
               call "revCreateObject tObjectType, tGridStack, tGridLocation" to card 1 of stack "revTools"
               put the result into tGrid
               select tGrid
               
               break
            default
               revSaveLayout
               revAlignObjects tItem
               exit revMenubarObjectMenuPick
               break
         end switch
         
         if tItem is not "Data Grid" then
            select last control
         end if
         
         reset the templateButton
         reset the templateField
         reset the templateGraphic
         reset the templateScrollBar
         reset the templateImage
         reset the templatePlayer
         unlock messages
         put "edited" into gREVStackStatus[the short name of the topStack]
         send "selectedObjectChanged" to btn "revBackScript" of stack "revLibrary"
         break
         break
   end switch
end revMenubarObjectMenuPick

on revMenubarTextMenuPick pWhich
   local tSelectedObject,tTargetObject, tTargetStack, tFieldVScrollPosition, tFieldHScrollPosition, tPickedItem, tPickedParams, tSelectedChunk
   
   if the selectedChunk is empty and the selectedObject is empty then exit to top
   
   if the selectedfield is not empty then 
      put word -2 to -1 of the long ID of the selectedfield into tTargetStack
      put the long ID of the selectedfield into tTargetObject
      put the long ID of the selectedfield into tSelectedObject
      put the vScroll of the selectedfield into tFieldVScrollPosition
      put the hScroll of the selectedfield into tFieldHScrollPosition
      if the selectedChunk is not empty then 
         put the selectedChunk into tSelectedChunk
         put word 1 to 4 of tSelectedChunk & " " before tSelectedObject
      end if
   else 
      put the long ID of the selectedObject into tSelectedObject
      put the long ID of the selectedObject into tTargetObject
      put word -2 to -1 of the long ID of the selectedObject into tTargetStack
   end if
   
   // We need to ignore actions that are performed on LiveCode palettes unless specifically allowed
   if revOKTarget(tTargetStack) then 
      // Add IDE Exception here that are allowed to have their text manipulated
      if the short name of tTargetObject is not among the words of "htmltext" then
         exit to top
      end if
   end if
   
   // tPickedItem could have parameters
   set the itemdel to "|"
   if the number of items of pWhich > 1 then
      put toLower(item 2 to -1 of pWhich) into tPickedParams
      put toLower(item 1 of pWhich) into tPickedItem
   end if
   set the itemdel to comma
   
   // Some of the text labels in the text menu don't relate directly to style properties
   // So processing them here to turn them into actual property name
   if tPickedItem is "3d box" then put "threeDbox" into tPickedItem
   
   switch tPickedItem
      case "plain"
         //put return & "Action: set the textStyle of" && tSelectedObject & " to empty" after msg
         set the textStyle of tSelectedObject to empty
         break
      case "bold"
      case "italic"
      case "underline"
      case "strikeout"
      case "box"
      case "link"
      case "condensed"
      case "expanded"
      case "threeDbox"
         //put return & "Action: set the textStyle['"&tPickedItem&"'] of" && tSelectedObject & " to true" after msg
         if the textStyle[tPickedItem] of tSelectedObject is true then
            set the textStyle[tPickedItem] of tSelectedObject to false
         else
            set the textStyle[tPickedItem] of tSelectedObject to true
         end if
         break
         
      case "subscript"
      case "superscript"
         local tTextShiftAmount
         
         if tPickedItem is "superscript" then put -4 into tTextShiftAmount
         else put 4 into tTextShiftAmount
         if the textShift of tSelectedObject is a number then put 0 into tTextShiftAmount
         
         set the textShift of tSelectedObject to tTextShiftAmount
         break
      case "font"
         if tPickedParams is "Use Owner's Font" then set the textFont of tSelectedObject to empty
         else set the textFont of tSelectedObject to tPickedParams
         break
      case "size"
         if tPickedParams is "Use Owner's Size" then 
            set the textSize of tSelectedObject to empty
         else if tPickedParams is a number then
            set textSize of tSelectedObject to tPickedParams
         else if tPickedParams is "Other..." then
            ask "Choose the text size"
            if it is empty then 
               exit revMenubarTextMenuPick
            else
               set textSize of tSelectedObject to it
            end if
         end if
         break
      case "color"
         if tPickedParams is "Use Owner's Color" then set the textColor of tSelectedObject to empty
         else if tPickedParams is "Pen Color" then set textColor of tSelectedObject to the penColor
         else set textColor of tSelectedObject to tPickedParams
         break
      case "align"
         // If there is a selection we want to sent the alignment of the paragraph(s) in question 
         if the selectedChunk is not empty then
            local tStartChar, tEndChar, tStartPara, tEndPara, tParaFirstChar, tParaLastChar
            put word 2 of the selectedChunk into tStartChar
            put word 4 of the selectedChunk into tEndChar
            put return & "Start / End: " & tStartChar && tEndChar after msg
            
            put tStartChar && tEndChar
            put the lineIndex of char tStartChar of tTargetObject into tStartPara
            put the lineIndex of char tEndChar of tTargetObject into tEndPara
            put return & "Paras: " & tStartPara & " to " & tEndPara after msg
            
            repeat with x = tStartPara to tEndPara
               put the charindex of line x of tTargetObject into tParaFirstChar
               put the charindex of line x of tTargetObject + the length of line x of tTargetObject - 1 into tParaLastChar
               set the textAlign of char tParaFirstChar to tParaLastChar of tTargetObject to tPickedParams
               put return & "Para "&x&": char " & tParaFirstChar & " to " & tParaLastChar after msg
            end repeat
            
            
         else
            set textAlign of tTargetObject to tPickedParams
         end if
         break
   end switch
   
   if the selectedfield is not empty then 
      set the vScroll of the selectedfield to tFieldVScrollPosition
      set the hScroll of the selectedfield to tFieldHScrollPosition
   end if
end revMenubarTextMenuPick

local lRestore
on revMenubarDevelopmentMenuPick pWhich
   global gREVSuppressErrors, gREVSuppressMessages, gREVRestore, gREVOldScriptDebugMode
   
   local tMainWhich
   set the itemDelimiter to "|"
   put item 1 of pWhich into tMainWhich
   set the itemDelimiter to comma
   
   switch tMainWhich
      case "Message Watcher"
         palette "revMessageWatcher"
         break
      case "Clear all Breakpoints"
         answer warning "Really clear all breakpoints from all open stacks?  This operation cannot be undone." with "Don't Clear" or "Clear"
         if it is "Clear" then 
            --            set the defaultStack to the topStack
            --            revClearAllBreakPoints
            # OK-2008-06-18
            revDebuggerClearAllBreakpoints
         end if
         break
      case "Script Debug Mode"
         if revDebuggerEnabled() then
            revDebuggerDisable
         else
            revDebuggerEnable
         end if
         
         # OK-2010-01-18: Update any open script editors so that the breakpoints are shown correctly,
         # they should all be grey when script debug mode is off, otherwise their color depends on their
         # exact circumstances.
         local tPrefsChanged
         put false into tPrefsChanged
         send "revSEUpdateEditors tPrefsChanged" to revScriptEditorMain()
         break
      case "Suspend Development Tools"
         revIDESuspendDevelopmentTools
         break
      case "Suppress Messages"
         if not gREVSuppressMessages then
            revInternal__LoadLibrary "revNoMessagesLibrary"
            put true into gREVSuppressMessages
            set the lockCursor to false
            repeat for each line l in the pendingMessages
               if char 1 to 3 of item 2 of l is not "rev" then cancel (item 1 of l)
            end repeat
            repeat for each line l in the frontScripts
               if char 1 to 3 of the short name of l is not "rev" then
                  put l & cr after lRestore["front"]
                  remove script of l from front
               end if
            end repeat
            repeat for each line l in the backScripts
               if char 1 to 3 of the short name of l is not "rev" then
                  put l & cr after lRestore["back"]
                  remove script of l from back
               end if
            end repeat
            repeat for each line l in the stacksInUse
               if char 1 to 3 of l is not "rev" then
                  put l & cr after lRestore["inUse"]
                  stop using stack l
               end if
            end repeat
         else if "revNoMessagesLibrary" is among the lines of revInternal__ListLoadedLibraries() then
            revInternal__UnloadLibrary "revNoMessagesLibrary"
            put false into gREVSuppressMessages
            set the hilite of btn "suppress messages" to false
            set the textStyle of btn "suppress messages" to "plain"
            repeat for each line l in lRestore["front"]
               insert script of l into front
            end repeat
            repeat for each line l in lRestore["back"]
               insert script of l into back
            end repeat
            repeat for each line l in lRestore["inUse"]
               start using stack l
            end repeat
            delete variable lRestore
         end if
         exit switch
      case "Suppress Errors"
         if not gREVSuppressErrors or gREVSuppressErrors is empty then
            put true into gREVSuppressErrors
            set the hilite of btn "Suppress Errors" to true
            set the textStyle of btn "Suppress Errors" to "bold"
         else
            put false into gREVSuppressErrors
            set the hilite of btn "Suppress Errors" to false
            set the textStyle of btn "Suppress Errors" to "plain"
         end if
         exit switch
      case "Simulate"
         revIDEDeployAction
         break
      case "Simulator Version"
         set the itemDel to "|"
         revIDEDeploySetTarget item 2 of pWhich
         break
      case "Plugins"
         set the itemDel to "|"
         switch item 2 of pWhich
            case "Plugin Settings"
               set the defaultStack to the topStack
               modeless "revPlugInEditor"
               break
            default
               set the wholeMatches to true
               
               local tLine
               put lineOffset(tab & item 2 of pWhich, the text of menu "Development")-3 into tLine
               set the wholeMatches to false
               
               local tStackPath
               put (line tLine of the cMenuList of btn "list" of stack "revplugineditor") into tStackPath
               
               local tMode
               if the cREVLoadInfo["mode"] of stack tStackPath is not empty then 
                  put the cREVLoadInfo["mode"] of stack tStackPath into tMode
               else 
                  put "palette" into tMode
               end if
               
               if tMode is "invisible" then
                  go invisible stack tStackPath
               else 
                  do "go stack" && quote &  tStackPath & quote && "as" && tMode
               end if
               break
         end switch
         break
      case "Image Library"
         go cd 2 of stack "revImageLibrary" as modeless
         lock messages
         set the menuHistory of btn "tabs" of stack "RevImageLibrary" to 2
         break
      case "Object Library"
         go cd 1 of stack "revImageLibrary" as modeless
         lock messages
         set the menuHistory of btn "tabs" of stack "RevImageLibrary" to 1
         break
      case "Rev Online"
         revGoOnline
         break
   end switch
end revMenubarDevelopmentMenuPick

on revMenubarViewMenuPick pWhich
   global gREVSuppressErrors, gREVSuppressMessages, gREVPalettes, gREVShowStacks
   switch pWhich
      case "LiveCode UI Elements In Lists"
         lock screen
         set the hilite of button "show revolution stacks" of card "general" of stack "revPreferencesGUI" to not gREVShowStacks
         
         local tOpenStacks
         put the openStacks into tOpenStacks
         
         local tFrontStack
         put empty into tFrontStack
         repeat for each line tStack in tOpenStacks
            if tStack is not "revMenubar" and the mode of stack tStack is among the items of "1,2,3" then
               put tStack into tFrontStack
               exit repeat
            end if
         end repeat
         if tFrontStack is not empty then
            set the wholeMatches to true
            local tBringToFront
            if lineOffset(tFrontStack, tOpenStacks) < lineOffset("revApplicationOverview", tOpenStacks) then
               put true into tBringToFront
            end if
         end if
         send "revToggleShowStacks" to button "show revolution stacks" of card "general" of stack "revPreferencesGUI"
         
         // EJB
         --ideShowUIElements
         unlock screen
         
         if tBringToFront then
            lock messages
            switch the mode of stack tFrontStack
               case 1
               case 2
                  toplevel tFrontStack
                  break
               case 3
                  modeless tFrontStack
                  break
            end switch
            unlock messages 
         end if
         break
      case "Show Invisible Objects"
         set the showInvisibles to not (the showInvisibles)
         break
      case "Rulers"
         if the mode of stack "revRulersH" is not 0 then
            revInternal__UnloadLibrary "revRulersScript"
            lock messages
            close stack "revRulersH"
            close stack "revRulersV"
            unlock messages
         else
            lock messages
            revCalculateRulers
            if the mode of the topStack is 1 then
               palette "revRulersH"
               palette "revRulersV"
            end if
            unlock messages
         end if
         break
      case "Go First"
         bufferedMoveCard "first"
         break
      case "Go Prev"
         bufferedMoveCard "prev"
         break
      case "Go Next"
         bufferedMoveCard "next"
         break
      case "Go Last"
         bufferedMoveCard "last"
         break
      case "Go Recent"
         bufferedMoveCard "recent"
         break
      case "Toolbar Text"
         local tAlterBounding
         if abs(item 2 of the windowBoundingRect - the bottom of stack "revMenuBar") < 10 then 
            put true into tAlterBounding
         end if
         if the cToolbarText of stack "revPreferences" then
            if the cToolbarIcons of stack "revPreferences" then 
               revIconsBar
            else
               revNoBar
            end if
         else
            if the cToolbarIcons of stack "revPreferences" then
               revFullBar
            else 
               revTextBar
            end if
         end if
         if tAlterBounding then
            set the windowBoundingRect to item 1 of the windowBoundingRect,the bottom of stack "revMenuBar"+25,item 3 to 4 of the windowBoundingRect
         end if
         break
      case "Toolbar Icons"
         if abs(item 2 of the windowBoundingRect - the bottom of stack "revMenuBar") < 10 then 
            put true into tAlterBounding
         end if
         if the cToolbarIcons of stack "revPreferences" then
            --remove icons
            if the cToolbarText of stack "revPreferences" then 
               revTextBar
            else
               revNoBar
            end if
         else
            --include icons
            if the cToolbartext of stack "revPreferences" then
               revFullBar
            else 
               revIconsBar
            end if 
         end if
         if tAlterBounding then
            set the windowBoundingRect to item 1 of the windowBoundingRect,the bottom of stack "revMenuBar"+25,item 3 to 4 of the windowBoundingRect
         end if
         break
      case "Palettes"
         revIDETogglePaletteView
         break
      case "Backdrop"
         if the backDrop is "none" then
            if the cBackDropColor of stack "revPreferences" is empty then 
               set the cBackDropColor of stack "revPreferences" to "black"
            end if
            set the backDrop to the cBackDropColor of stack "revPreferences"
            set the cBackDrop of stack "revPreferences" to the backDrop
         else
            set the backDrop to "none"
            set the cBackDrop of stack "revPreferences" to "none"
         end if
         exit switch
      case "Grid"
         if the grid is false then
            set the grid to true
            set the cGrid of stack "revPreferences" to true
         else
            set the grid to false
            set the cGrid of stack "revPreferences" to false
         end if
         exit switch
      default
         set the itemDel to "|"
         if item 1 of pWhich is "Go to Report Page" then
            send "revUpdateFields" to stack "revReportSetup"
            switch item 2 of pWhich
               case "First"
                  send "revMoveFirstCard" to stack "revReportSetup"
                  break
               case "Prev"
                  send "revMovePreviousCard" to stack "revReportSetup"
                  break
               case "Next"
                  send "revMoveNextCard" to stack "revReportSetup"
                  break
               case "Last"
                  send "revMoveLastCard" to stack "revReportSetup"
                  break
               case "Number..."
                  ask question "Go to report page number:" titled "Report Page Number"
                  if it is not empty then
                     send "revMenuNavigation it" to stack "revReportSetup"
                  end if
                  break
            end switch
            
         else
            --Look and Feel
            switch
               case "Native" is in pWhich 
                  set the lookAndFeel to "Appearance Manager"
                  break
               case "Mac OS" is in pWhich
                  set the lookAndFeel to "Macintosh"
                  break
               case "Windows" is in pWhich
                  set the lookAndFeel to "Windows 95"
                  break
               case "Motif" is in pWhich 
                  set the lookAndFeel to "Motif"
                  break
            end switch
            exit to top
         end if
         break
   end switch
end revMenubarViewMenuPick

on revMenubarWIndowMenuPick pWhich
   set the wholeMatches to true
   local tLineNumber
   put the menuHistory of me into tLineNumber
   
   if tLineNumber > the number of lines of the cStacks of me then
      # This means they clicked on something after the list of stacks, i.e the "send window to back" item
      sendWindowToBack
   else
      # This means they clicked on a stack name, we get its name from cStacks
      local tStackName
      put line tLineNumber of the cStacks of me into tStackName
      
      go tStackName
      show tStackName
   end if
end revMenubarWIndowMenuPick

on revMenubarHelpMenuPick pWhich
   set the itemDel to "|"
   switch item 1 of pWhich
      case "Dictionary"
         revIDEShowDictionary
         break
      case "Resource Center"
         revIDEShowResourceCenter
         break
      case "Start Center"
         revIDEOpenPalette "Start Center"
         break
      case "Welcome Screen"
         revIDEOpenPalette "Welcome"
         break
      case "Search"
         revIDEShowSearchEngine
         break
      case "Buy"
         launch url "http://www.runrev.com/links/livecode/tools-buy"
         break
      case "About"
      case "About LiveCode"
         modeless "revAbout"
         break
      case "Support"
         launch url "http://www.runrev.com/links/livecode/tools-help"
         break
      case "Relicense"
         answer question "Are you sure you want to re-license? Clicking " & quote & "Ok" & quote & " will restart LiveCode and you will be asked re-activate." with "Cancel" or "OK"
         if it is "OK" then
            revReLicense
         end if
         break
      case "User Guide"
         revDocumentationLaunchUserGuide
         break
      case "License Agreement"
         launch document (revEnvironmentToolsPath() & slash & "License Agreement.txt")
         break
      case "Release Notes"
         launch document (revEnvironmentToolsPath() & slash & "Release Notes.pdf")
         break
      case "iOS Release Notes"
         launch document (revEnvironmentToolsPath() & slash & "iOS Release Notes.pdf")
         break
      case "Android Release Notes"
         launch document (revEnvironmentToolsPath() & slash & "Android Release Notes.pdf")
         break
      case "Resources"
         launch document revEnvironmentToolsPath() & slash & "Resources"
         break
      case "Template Projects"
         
         break
      case "Sample Stacks"
         launch url "http://livecode.com/links/livecode/revonline"
         break
      case "Sample Scripts"
         launch url "http://lessons.runrev.com/m/2592"
         break
      case "Beginners Guide"
         launch url "http://livecode.com/links/livecode/beginners-course"
         break
      case "Tutorials"
         launch url "http://livecode.com/links/livecode/tutorials"
         break
      case "All Guides"
         launch url "http://livecode.com/links/livecode/guides"
         break
      case "API"
         launch url "http://livecode.com/links/livecode/api"
         break
      case "Forums"
         launch url "http://livecode.com/links/livecode/forum"
         break
      case "Technical Questions"
         launch url "http://livecode.com/links/stackoverflow"
         break
      case "Use List"
         launch url "http://livecode.com/links/lists"
         break
      case "Newsletters"
         launch url "http://livecode.com/links/livecode/newsletters"
         break
      case "Update"
         revIDECheckForUpdates
         break
   end switch
end revMenubarHelpMenuPick

/*
         on revStopEditingGroupAfterPasting
            choose pointer tool
            set the defaultStack to the topStack
            paste
            set the editBg to false
end revStopEditingGroupAfterPasting

on revDoCardStackMenu pMenuItem, pOwnerMenu
   global gREVMenuTarget
   
   local tTargetStack
   put revTargetStack(gREVMenuTarget) into tTargetStack
   switch pMenuItem
      case "Edit Card Script"
         revMenubarEditScript the long id of this card of stack tTargetStack
         break
      case "Card Property Inspector"
         select this cd of stack tTargetStack
         --send "revBuildPropertyPalette" to stack "revTemplatePalette"
         revIDEOpenPalette "inspector"
         break
      case "New Card"
         set the defaultStack to tTargetStack
         create card
         break
      case "Edit Stack Script"
         revMenubarEditScript the long id of stack tTargetStack
         break
      case "Stack Property Inspector"
         select stack tTargetStack
         revIDEOpenPalette "inspector"
         --send "revBuildPropertyPalette" to stack "revTemplatePalette"
         break
      case "topLevel"
      case "modeless"
      case "palette"
      case "modal"
         send "revChangeMode pMenuItem, tTargetStack" to me in 200 milliseconds
         break
      case "Save"
         if the effective fileName of stack tTargetStack is not empty
         then revSave tTargetStack
         else revSaveAs tTargetStack
         break
      case "Paste Objects"
         set the defaultStack to tTargetStack
         paste
         break
      default
         --pMenuItem must be a message name
         --either send it to the card or the stack
         if pOwnerMenu is "Send Card Message"
         then revSendMessage pMenuItem, the long id of this cd of stack tTargetStack
         else revSendMessage pMenuItem, the long id of stack tTargetStack
         break
   end switch
end revDoCardStackMenu
*/
