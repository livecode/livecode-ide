script "revMenuBar"
local sMenuTarget
on preOpenStack
   global gREVDontLoadMenus
   if gREVDontLoadMenus then
      put false into gREVDontLoadMenus
      exit preOpenStack
   end if
   
   subscribeMessages
   
   setDefaultText
   setMenuProperties
   generateMenu
   revMenubarBuildMenus
   updateMenubarPreference
   layoutMenu
   revIDEPositionPalette the short name of me
   # Since the menubar is topleveled on Linux and Windows, set the cantModify to true
   # to prevent users being able to alter the menubar stack.
   set the cantModify of me to true
end preOpenStack

on closeStackRequest
   revIDEQuit
end closeStackRequest

on subscribeMessages
   revIDESubscribe "ideSelectedObjectChanged"
   revIDESubscribe "idePreferenceChanged:cToolbarIcons"
   revIDESubscribe "idePreferenceChanged:cToolbarText"
   revIDESubscribe "ideToolChanged"
   
   revIDESubscribe "ideToggleChanged:suppressMessages"
   revIDESubscribe "ideToggleChanged:suppressErrors"
   revIDESubscribe "ideToggleChanged:selectGrouped"
   
   revIDESubscribe "idePluginsChanged"
   revIDESubscribe "ideWindowsChanged"
   
   revIDESubscribe "ideTutorialProgressChanged"
   revIDESubscribe "ideActiveStacksChanged"
end subscribeMessages

local sTextMenuDisabledText, sTextMenuText, sPluginMenuText
on setDefaultText
   setupTextMenu
end setDefaultText

private on setupDevelopmentMenu
   local tPlugins
   put the keys of revIDEPlugins() into tPlugins
   sort tPlugins
   local tPluginMenuText
   repeat for each line tPlugin in tPlugins
      if tPluginMenuText is empty then
         put tab & tPlugin into tPluginMenuText
      else
         put return & tab & tPlugin after tPluginMenuText
      end if
   end repeat
   put tPluginMenuText into sPluginMenuText
end setupDevelopmentMenu

private on setupTextMenu
   local tText
   put toggleMenuItem("Plain/;", false) & return after tText
   put toggleMenuItem("&Bold/B", false) & return after tText
   put toggleMenuItem("&Italic/I", false) & return after tText
   put toggleMenuItem("&Underline/U", false) & return after tText
   put toggleMenuItem("Strikeout", false) & return after tText
   put toggleMenuItem("Box", false) & return after tText
   put toggleMenuItem("3D Box", false) & return after tText
   put "-" & return after tText
   put toggleMenuItem("Link", false) & return after tText
   put "-" & return after tText
   put toggleMenuItem("Subscript", false) & return after tText
   put toggleMenuItem("Superscript", false) & return after tText
   put "-" & return after tText
   put "Font" & return after tText
   
   local tFontNames
   put the fontNames into tFontNames
   replace "/" with "\" in tFontNames
   sort lines of tFontNames
   
   /* Fake fonts begin with "(", but the menu code interprets a "(" at 
   the beginning of the item to mean the item is disabled. 
   So, to show a "(" instead of disabling, we need to double it */
   repeat with tLine = 1 to the number of lines of tFontNames
      if line tLine of tFontNames begins with "(" then
         put "(" before line tLine of tFontNames
      end if
   end repeat
   
   put "Use Owner's Font" & return & "-" & return before tFontNames
   
   local fontnum
   put 1 into fontnum
   repeat for each line tFontName in tFontNames
      if tFontName is "-" then 
         put tab & tFontName & return after tText
      else
         put "!u" & tab & tFontName & return after tText
      end if
   end repeat
   put "Size" & return after tText
   
   local tFontSizes
   put format("Use Owner's Size\n-\n8\n9\n10\n12\n14\n18\n24\n36\n48\n-\nOther...") into tFontSizes
   repeat for each line l in tFontSizes
      if l is "-" then put tab & l & cr after tText
      else put "!u" & tab & l & cr after tText
   end repeat
   put "Color" & cr after tText
   
   local tColors
   put format("Use Owner's Color\n-\nBlack\nWhite\nRed\nGreen\nBlue\nYellow\n-\nPen Color") into tColors
   repeat for each line tColor in tColors
      if tColor is "-" then
         put tab & tColor & return after tText
      else 
         put "!u" & tab & tColor & return after tText
      end if
   end repeat
   put  "-" & return & "&Align" & return & "!u"  & tab & "Left" & return & "!u" & tab & "Center" & return & "!u" & tab & "Right" after tText
   
   # Cache the text menu text in non-disabled state
   put tText into sTextMenuText
   repeat for each line tLine in tText
      if the platform is "MacOS" and tab is in tLine then
         replace tab with empty in tLine
         local tDisabledText
         put tab & "(" & tLine & return after tDisabledText
      else
         put "(" & tLine & return after tDisabledText
      end if
   end repeat
   delete last char of tDisabledText
   # Cache the disabled text menu text
   put tDisabledText into sTextMenuDisabledText
end setupTextMenu

# OK-2010-02-19: Bug 8157 - Escape special characters from stack names in menus, more may 
# need to be added here.
private function revMenubarEscapeStackNameForMenu pName
   replace "!" with "\!" in pName
   replace "&" with "\&" in pName
   if the platform is "MacOS" then 
      replace "/" with "\/" in pName
      replace "(" with "\(" in pName
   else
      replace "/" with "//" in pName
   end if
   return pName
end revMenubarEscapeStackNameForMenu

local sWindowMenuWindows
private on setupWindowMenu
   #   Set sWindowMenuText to a list of open Windows in suitable format for putting into a menu button.
   #   This will be any script editors or the dictionary or resource center if they are open, and any user stacks.
   local tWindows
   put revIDEWindowList() into tWindows
   
   if tWindows is empty then      
      put empty into sWindowMenuWindows
      exit setupWindowMenu
   end if
   
   // PM-2016-05-14: [[ Bug 17638 ]] Show stacks by name, unless they are instances of the script editor,
   // the Dictionary or the Resource Center. In this case show the stack title, as in LC 6.7.x
   local tMenu, tMenuLine, tStackName
   repeat for each line tStack in tWindows
      if there is not a stack tStack then next repeat
      put the short name of tStack into tStackName
      if revIDEStackIsIDEWindow(tStackName) then
         put the title of tStack into tStackName
      end if
      
      put "!n" & revMenubarEscapeStackNameForMenu(tStackName) & "/|" & tStack into tMenuLine
      if tMenu is empty then
         put tMenuLine into tMenu
      else
         put return & tMenuLine after tMenu
      end if
   end repeat
   
   # Put a checkmark against the 'topmost' stack
   put "!c" into char 1 to 2 of line 1 of tMenu
   
   put tMenu into sWindowMenuWindows
end setupWindowMenu

/*
Generates the menu for the recent files
*/
constant kClearRecentFiles = "ClearTheRecentFileList"
function revMenuBarRecentFiles
   # Get the recent file data
   local tRecentFiles
   put revIDERecentStacks() into tRecentFiles
   
   # Generate the menu
   local tMenu
   repeat with x = 1 to the number of elements of tRecentFiles
      if tMenu is empty then
         put tab & revMenubarEscapeStackNameForMenu(tRecentFiles[x]["label"]) & "/|" & tRecentFiles[x]["filename"] into tMenu
      else
         put return & tab & revMenubarEscapeStackNameForMenu(tRecentFiles[x]["label"]) & "/|" & tRecentFiles[x]["filename"] after tMenu
      end if
   end repeat

   if tMenu is not empty then
      put return & tab & "-" after tMenu
      put return & tab & "Clear Recent Files" & "/|" & kClearRecentFiles after tMenu
   end if

   return tMenu
end revMenuBarRecentFiles

on moveStack
   if the platform is "MacOS" then
      local tScreenRect
      put revIDEStackScreenRect(the short name of this stack, true) into tScreenRect
      set the topLeft of this stack to item 1 to 2 of tScreenRect
   end if
   revIDESetPaletteRectPreference the short name of me
   ideSetWindowBoundingRect
   
   pass moveStack
end moveStack

on setMenuProperties
   set the height of me to 47
   set the resizable of me to false
   
   local tTitle
   set the itemDelimiter to "-"
   put "LiveCode" && revEnvironmentEditionProperty("name") into tTitle
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
   
   local tScreenRect
   put revIDEStackScreenRect(the short name of this stack, true) into tScreenRect
   
   if the platform is not "MacOS" then
      if item 3 of the screenRect is 800 then
         set the topLeft of me to item 1 to 2 of tScreenRect
      else 
         --screen rect > 800 by 600
         if revIDEGetPreference("cREVMenuBarTopLeft") is empty
         then set the loc of me to item 1 of revIDEStackScreenLoc(the short name of this stack), 54
         else set the topLeft of me to revIDEGetPreference("cREVMenuBarTopLeft")
      end if
   end if
   
   if the platform is "MacOS" then
      set the decorations of me to empty
      set the topLeft of me to item 1 to 2 of tScreenRect
   else
      set the decorations of me to "default"
   end if
end setMenuProperties

on ideSelectedObjectChanged
   updateButtonState
end ideSelectedObjectChanged

on ideActiveStacksChanged
   updateButtonState
end ideActiveStacksChanged

on ideTutorialProgressChanged
   highlightObject empty
   layoutMenu
   revMenubarBuildMenus
end ideTutorialProgressChanged

on idePreferenceChanged pPreference
   switch pPreference
      case "cToolbarText"
      case "cToolbarIcons"
         lock screen
         show me
         updateMenubarPreference
         layoutMenu
         ideSetWindowBoundingRect
         unlock screen
         break
   end switch
end idePreferenceChanged

on ideToggleChanged pToggle
   switch pToggle
      case "suppressMessages"
      case "suppressErrors"
      case "selectGrouped"
         updateButtonState
         break
      default
         break
   end switch
   
end ideToggleChanged

on idePluginsChanged
   setupDevelopmentMenu
end idePluginsChanged

on generateMenu
   generateMenubarUI
   generateMenuGroup
   generateContextMenu
end generateMenu

constant kTutorialActionSize = 10
on generateMenubarUI
   if there is a group "icons" of me then
      delete group "icons" of me
   end if
   
   if there is a group "toolbar" of me then
      delete group "toolbar" of me
   end if
   
   reset the templatebutton
   
   create group "icons"
   create group "toolbar"
   
   lock messages
   # Setup the default button
   set the showname of the templatebutton to true
   set the style of the templatebutton to "transparent"
   set the threed of the templatebutton to false
   set the borderwidth of the templatebutton to 0
   set the blendlevel of the templatebutton to 0
   set the margins of the templatebutton to "4,0,4,1"
   set the traversalOn of the templatebutton to false
   set the autoHilite of the templatebutton to false
   
   # Setup the default image
   set the resizequality of the templateimage to "best"
   
   # Setup the default field
   set the traversalon of the templatefield to false
   set the threed of the templatefield to false
   set the showborder of the templatefield to false
   set the showfocusborder of the templatefield to false
   set the opaque of the templatefield to false
   set the height of the templatefield to 21
   set the locktext of the templatefield to true
   
   local tDividerCount
   put 1 into tDividerCount
   repeat for each item tItem in revMenubarItems()
      if tItem is "Divide" then
         local tName
         put tItem & tDividerCount into tName
         create image tName in group "toolbar"of me
         set the id of it to revIDENewIconID()
         set the filename of image tName of group "toolbar" of me to revMenubarButtonNameToIconPath(tItem)
         add 1 to tDividerCount
      else
         create invisible image tItem in group "icons" of me
         set the id of it to revIDENewIconID()
         set the filename of image tItem of me to revMenubarButtonNameToIconPath(tItem)
         local tFilename
         repeat for each item tStyle in "hilited,disabled,depressed,hilited-depressed" 
            put revMenubarButtonNameToIconPath(tItem, tStyle) into tFilename
            if there is a file tFilename then
               create invisible image (tItem & "-" & tStyle) in group "icons" of me
               set the id of it to revIDENewIconID()
               set the filename of image (tItem & "-" & tStyle) of me to tFilename
               if tStyle is "hilited" then 
                  set the cHighlightedIcon of the templatebutton to the id of image (tItem & "-" & tStyle) of group "icons" of me
               else if tStyle is "depressed" then
                  set the cDepressedIcon of the templatebutton to the id of image (tItem & "-" & tStyle) of group "icons" of me
               else if tStyle is "hilited-depressed" then
                  set the cHighlightedDepressedIcon of the templatebutton to the id of image (tItem & "-" & tStyle) of group "icons" of me
               else if tStyle is "disabled" then
                  set the disabledIcon of the templatebutton to the id of image (tItem & "-" & tStyle) of group "icons" of me
               end if
            else
               if tStyle is "hilited" then 
                  set the cHighlightedIcon of the templatebutton to the cIcon of the templatebutton
               else if tStyle is "disabled" then
                  set the disabledIcon of the templatebutton to the cIcon of the templatebutton
               else if tStyle is "depressed" then
                  set the cDepressedIcon of the templatebutton to the cIcon of the templatebutton
               else if tStyle is "hilited-depressed" then
                  set the cHighlightedDepressedIcon of the templatebutton to the cDepressedIcon of the templatebutton
               end if
            end if
         end repeat
         
         create button tItem in group "toolbar" of me
         set the cIcon of it to the id of image tItem of group "icons" of me
         set the icon of it to the cIcon of it
         set the label of it to revIDELocalizeMenuItem(tItem)
      end if
   end repeat
   
   set the hilitedIcon of the templatebutton to 0
   set the disabledIcon of the templatebutton to 0
   
   generateTutorialGroup
   generateUpgradeGroup
   
   reset the templategraphic
   reset the templatebutton
   reset the templateimage
   reset the templatefield
   
   unlock messages
end generateMenubarUI

private command generateTutorialGroup
   if there is a group "tutorial" of me then
      delete group "tutorial" of me
   end if
   
   create group "tutorial"
   set the margins of it to 0
   create group "progress" in group "tutorial" of me
   set the margins of it to 0
   set the opaque of the templateGraphic to true
   set the style of the templateGraphic to "rectangle"
   set the lineSize of the templateGraphic to 0
   create graphic "Trough" in group "Progress" of group "tutorial" of me
   create graphic "Bar" in group "Progress" of group "tutorial" of me
   set the backcolor of it to "white"
   
   create field "label" in group "tutorial" of me
   set the margins of it to 4
   set the textSize of it to 10
   set the traversalOn of it to false
   
   create group "actions" in group "tutorial" of me
   set the margins of it to 0
   create widget "stop" as "com.livecode.widget.svgpath" in group "actions" of group "tutorial" of me
   set the width of it to kTutorialActionSize
   set the height of it to kTutorialActionSize
   set the iconPresetName of it to "stop"
   set the traversalOn of it to false
   
   create widget "skip" as "com.livecode.widget.svgpath" in group "actions" of group "tutorial" of me
   set the width of it to kTutorialActionSize
   set the height of it to kTutorialActionSize
   set the iconPresetName of it to "forward"
   set the traversalOn of it to false
   
   hide group "tutorial" of me
end generateTutorialGroup

private command generateUpgradeGroup
   if there is a group "upgrade" of me then
      delete group "upgrade" of me
   end if
   
   create group "upgrade"
   set the margins of it to 0
   
   create graphic "bg" in group "upgrade" of me
   set the opaque of it to true
   set the style of it to "roundRect"
   set the lineSize of it to 0
   
   local tUpgradeEdition
   put revEnvironmentEditionProperty("upgrade_edition") into tUpgradeEdition
   set the backcolor of it to revEnvironmentEditionProperty("color", tUpgradeEdition)
   set the roundRadius of it to 8
   
   create field "label" in group "upgrade" of me
   set the margins of it to 4
   set the traversalOn of it to false
   set the text of it to "Upgrade Options"
   set the textStyle["bold"] of it to true
   set the textColor of it to "white"
   
   hide group "upgrade" of me
end generateUpgradeGroup

on generateMenuGroup
   lock messages
   if there is a group "revMenuBar" of me then
      delete group "revMenuBar" of me
   end if
   
   set the traversalOn of the templatebutton to false
   set the style of the templatebutton to "menu"
   set the menumode of the templatebutton to "pulldown"
   set the height of the templatebutton to 22
   # Pulldown menus with showBorder true don't receive keyboard shortcut menu picks
   set the showborder of the templatebutton to false
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
      # Enable Alt + letter to open menu on Linux and Windows
      if tItem is "Text" then
         set the mnemonic of it to 3
      else
         set the mnemonic of it to 1
      end if
   end repeat
   
   if the platform is not "macos" then
      show group "revMenuBar" of me
   end if
   set the menubar of me to "revMenuBar"
   
   reset the templatebutton
   set the style of the templatebutton to "rectangle"
   set the height of the templatebutton to 2
   set the threed of the templatebutton to true
   set the showborder of the templatebutton to true
   set the borderwidth of the templatebutton to 2
   set the showname of the templatebutton to false
   
   if the platform is "Linux" then 
      create button "Divider" in group "revMenuBar"
   else
      create invisible button "Divider" in group "revMenuBar"
   end if
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

constant kPadding = 10
constant kDividerWidth = 2
constant kDividerHeight = 41
constant kMenuBarHeight = 26
constant kMenuBarTop = 3
constant kUpgradeButtonMarginVertical = 8
constant kUpgradeButtonMarginHorizontal = 15
on layoutMenu
   lock screen
   lock messages
   
   local tDividerCount
   put 1 into tDividerCount
   
   local tLeft, tTop
   put kPadding into tLeft
   
   if the platform is "macos" then 
      put kMenuBarTop into tTop
   else
      put kMenuBarTop + kMenuBarHeight into tTop
   end if
   local tTopLeft
   put the topleft of me into tTopLeft
   
   local tLastDivide
   repeat for each item tItem in revMenubarItems()
      if tItem is "Divide" then
         local tName
         put tItem & tDividerCount into tName
         set the rect of image tName of group "toolbar" of me to 0, 0, kDividerWidth, kDividerHeight
         set the topleft of image tName of group "toolbar" of me to tLeft + kPadding / 2 - kDividerWidth / 2, tTop
         add 1 to tDividerCount
         add kPadding to tLeft
         put the long id of image tName into tLastDivide
      else
         local tWidth, tHeight
         set the textStyle["bold"] of button tItem of group "toolbar" of me to false
         put revMenubarButtonFormattedWidth(tItem) into tWidth
         set the width of button tItem of group "toolbar" of me to tWidth
         set the topleft of button tItem of group "toolbar" of me to tLeft,tTop
         add tWidth to tLeft
      end if
   end repeat
   
   local tTutorial, tLabelWidth
   put revIDETutorialInProgress() into tTutorial
   if tTutorial is not empty then
      hide group "upgrade" of me
      
      add kPadding/2 to tLeft
      show group "tutorial" of me
      show tLastDivide
      set the text of field "label" of group "tutorial" of me to tTutorial["lesson"] 
      set the width of field "label" of group "tutorial" of me to 1000
      set the height of field "label" of group "tutorial" of me to the formattedHeight of field "label" of group "tutorial" of me
      
      put the formattedwidth of field "label" of group "tutorial" of me into tLabelWidth
      set the width of field "label" of group "tutorial" of me to tLabelWidth
      set the topleft of field "label" of group "tutorial" of me to 0, 0
      
      set the backcolor of graphic "Trough" of group "progress" of me to "white"
      set the backcolor of graphic "Bar" of group "progress" of me to "black"
      set the rect of graphic "Trough" of group "progress" of me to 0, 0, tLabelWidth, kPadding / 2
      set the rect of graphic "Bar" of group "progress" of me to 0, 0, revIDETutorialDonePercentage() * tLabelWidth / 100, kPadding / 2
      set the rect of group "progress" of me to the formattedRect of group "progress" of me
      set the loc of group "progress" of me to the loc of field "label" of me
      set the top of group "progress" of me to the bottom of field "label" of group "tutorial" of me + kPadding / 5
      
      set the topleft of widget "skip" of group "actions" of group "tutorial" of me to 0,0
      set the topleft of widget "stop" of group "actions" of group "tutorial" of me to kTutorialActionSize + kPadding / 2, 0
      set the rect of group "actions" of group "tutorial" of me to the formattedRect of group "actions" of group "tutorial" of me
      set the loc of group "actions" of group "tutorial" of me to the loc of field "label" of me
      set the top of group "actions" of group "tutorial" of me to the bottom of group "progress" of me + kPadding / 2
      
      set the rect of group "tutorial" of me to the formattedRect of group "tutorial" of me
      set the loc of group "tutorial" of me to the loc of group "toolbar" of me
      set the left of group "tutorial" of me to tLeft
      
      add the width of group "tutorial" of me + kPadding to tLeft
   else if ideShouldShowUpgradeOptions() then
      hide group "tutorial" of me
      
      add kPadding/2 to tLeft
      show group "upgrade" of me
      show tLastDivide
      
      put the height of me into tHeight
      
      local tMenuBarHeight = 0
      if the platform is not "MacOS" then
         subtract kMenuBarHeight from tHeight
         put kMenuBarHeight into tMenuBarHeight
      end if
      
      set the topLeft of group "upgrade" of me to \
            tLeft, \
            tMenuBarHeight + (tHeight - the height of group "upgrade" of me) / 2
      
      add the width of group "upgrade" of me + kPadding to tLeft
   else
      hide tLastDivide
      hide group "tutorial" of me
      hide group "upgrade" of me
   end if	
   
   set the width of me to tLeft
   set the height of group "revMenuBar" of me to kMenuBarHeight
   set the width of group "revMenuBar" of me to the width of me
   set the topleft of group "revMenuBar" of me to 0,0
   set the rect of button "Divider" of group "revMenuBar" of me to 0, kMenuBarHeight - kDividerWidth, tLeft + kPadding, kMenuBarHeight
   set the topleft of me to tTopLeft
   unlock messages
   
   updateButtonState
   unlock screen
end layoutMenu	

function revMenubarItems
   return "Inspector,Code,Message Box,Divide,Group,Edit Group,Select Grouped,Divide,Messages,Errors,Divide,Sample Stacks,Tutorials,Resources,Dictionary,Divide,Test,Divide"
end revMenubarItems

on updateMenubarPreference
   lock screen
   lock messages
   local tShowIcons, tShowText
   put revIDEGetPreference("cToolbarIcons") is not false into tShowIcons
   put revIDEGetPreference("cToolbarText") is not false into tShowText
   
   local tTopLeft
   put the topleft of me into tTopLeft
   
   local tButtonRef
   repeat for each line tButton in the childControlNames of group "toolbar" of me
      if tButton is "Divide" then next repeat
      if there is not a button tButton of group "toolbar" of me then
         next repeat
      end if
      
      put the long id of button tButton of group "toolbar" into tButtonRef
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
      if tShowIcons is false and tShowText is false then
         set the height of me to 0
         hide me
      else if tShowIcons is false then
         set the height of me to 19
      else if tShowText is false then
         set the height of me to 32
      else
         set the height of me to 47
      end if
   else
      show group "toolbar" of me
      if tShowIcons is false and tShowText is false then
         hide group "toolbar" of me
         set the height of me to 23
      else if tShowIcons is false then
         set the height of me to 44
      else if tShowText is false then
         set the height of me to 59
      else
         set the height of me to 75
      end if
   end if
   
   set the width of field "label" of group "upgrade" of me to 1000
   set the height of field "label" of group "upgrade" of me to the formattedHeight of field "label" of group "upgrade" of me
   local tLabelWidth
   put the formattedwidth of field "label" of group "upgrade" of me into tLabelWidth
   set the width of field "label" of group "upgrade" of me to tLabelWidth
   set the loc of field "label" of group "upgrade" of me to 0,0
   
   if tShowIcons is false then
      set the visible of graphic "bg" of group "upgrade" of me to false
      set the textColor of field "label" of group "upgrade" of me to "black"
   else
      set the visible of graphic "bg" of group "upgrade" of me to true
      set the textColor of field "label" of group "upgrade" of me to "white"
      
      local tHeight
      put the height of me - kPadding into tHeight
      
      if the platform is not "MacOS" then
         subtract kMenuBarHeight from tHeight
      end if
      
      local tRect
      put the rect of field "label" of group "upgrade" of me into tRect
      put item 1 of tRect - kUpgradeButtonMarginHorizontal, \
            -tHeight div 2, \
            item 3 of tRect + kUpgradeButtonMarginHorizontal, \
            tHeight div 2 into tRect
      
      set the rect of graphic "bg" of group "upgrade" of me to tRect
   end if
   set the rect of group "upgrade" of me to the formattedRect of group "upgrade" of me
   
   set the topleft of me to tTopLeft
   unlock messages
   unlock screen
end updateMenubarPreference

on setButtonHilite pLongId, pValue
   if pValue then
      set the hilite of pLongID to true
      set the textStyle of pLongID to "bold"
   else
      set the hilite of pLongID to false
      set the textStyle of pLongID to "plain"
   end if
end setButtonHilite

private on disableToolbar
   local tControlName
   repeat for each line tControl in the childControlIDs of group "toolbar" of me
      disable control id tControl of stack "revMenubar"
   end repeat
end disableToolbar

private on enableToolbar
   local tControlName
   repeat for each line tControl in the childControlIDs of group "toolbar" of me
      enable control id tControl of stack "revMenubar"
   end repeat
end enableToolbar

on updateButtonHilite pTargetName, pValue
   lock screen
   lock messages
   
   local tTargetLongID
   put the long id of button pTargetName of group "toolbar" of me into tTargetLongID
   
   local tShowIcon
   put the showIcon of tTargetLongID into tShowIcon
   
   setButtonHilite tTargetLongID, pValue
   set the label of tTargetLongID to revMenubarButtonText(pTargetName, pValue)
   if pValue then
      set the icon of tTargetLongID to the cHighlightedIcon of tTargetLongID
   else
      set the icon of tTargetLongID to the cIcon of tTargetLongID
   end if
   
   set the showIcon of tTargetLongID to tShowIcon

   unlock messages
   unlock screen
end updateButtonHilite

private command setToolbarButtonState pName, pValue
   set the enabled of button pName of group "toolbar" of me to pValue
end setToolbarButtonState

local sToolbarHighlight
on updateButtonState
   lock screen
   lock messages
   
   enableToolbar
   
   local tSelObj
   put revIDESelectedObjects() into tSelObj
   
   local tControlSelected
   put tSelObj is not empty and word 1 of tSelObj \ 
         is not among the items of "card,stack" into tControlSelected
   
   local tUserStack
   put not revIDEStackIsIDEStack(the topstack) into tUserStack
   
   local tGroupHilite
   put word 1 of tSelObj is "group" and the number of lines in tSelobj is 1 into tGroupHilite
   updateButtonHilite "Group", tGroupHilite
   
   -- Group button should be disabled if no controls are selected
   setToolbarButtonState "Group", tControlSelected
   
   local tEditGroupHilite
   put the editBg of the topStack and word 1 of tSelObj is not "group" into tEditGroupHilite
   updateButtonHilite "Edit Group", tEditGroupHilite
   
   -- If a group is selected, the Edit Group button should be enabled
   -- It should also be enabled (with label 'Stop Editing') if we're currently editing a group
   setToolbarButtonState "Edit Group", \
         tGroupHilite or the editBg of the topstack
   
   # Click buttons don't stay hilited
   updateButtonHilite "Message Box", false
   updateButtonHilite "Inspector", false
   updateButtonHilite "Code", false
   updateButtonHilite "Test", false
   updateButtonHilite "Sample Stacks", false
   updateButtonHilite "Tutorials", false
   updateButtonHilite "Resources", false
   updateButtonHilite "Dictionary", false
   
   # Toggle buttons hilited according to state of property
   global gRevSuppressErrors, gRevSuppressMessages
   updateButtonHilite "Errors", gRevSuppressErrors
   updateButtonHilite "Messages", gRevSuppressMessages
   updateButtonHilite "Select Grouped", the selectGroupedControls
   
   # Deal with enabled/disabled of code and inspector
   global gRevDevelopment
   local tCanInspect
   put tControlSelected or tUserStack or gRevDevelopment into tCanInspect
   
   setToolbarButtonState "Code", tCanInspect
   setToolbarButtonState "Inspector", tCanInspect
   
   # Deal with enabled/disabled of test
   setToolbarButtonState "Test", \
         revIDEGetPreference("cDeployPlatforms") is not empty 
   
   if revIDETutorialInProgress() is not empty then
      disableToolbar
      if sToolbarHighlight is not empty then
         enable button sToolbarHighlight of group "toolbar" of me
      end if
   end if
   
   unlock messages
   unlock screen
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

function revMenubarButtonText pName, pHilited
   if pHIlited is false then
      return pName
   end if
   
   switch pName
      case "Group"
         return "Ungroup"
      case "Edit Group"
         return "Stop Editing"
      default
         return pName
   end switch
end revMenubarButtonText

function __buttonMaxFormattedWidth pName
   lock screen
   lock messages
   local tWidth, tOldLabel, tNewLabel
   put the label of button pName of group "toolbar" of me into tOldLabel
   repeat for each item tHilite in "true,false"
      set the label of button pName of group "toolbar" of me to revMenubarButtonText(pName, tHIlite)
      put max(tWidth, the formattedwidth of button pName of group "toolbar" of me) into tWidth
   end repeat
   set the label of button pName of group "toolbar" of me to tOldLabel
   unlock messages
   unlock screen
   return tWidth
end __buttonMaxFormattedWidth

constant kMinimumMenuButtonWidth = 64
function revMenubarButtonFormattedWidth pName
   return max(__buttonMaxFormattedWidth(pName), kMinimumMenuButtonWidth)
end revMenubarButtonFormattedWidth

function revIDELocalizeMenuItem pItem
   return pItem
end revIDELocalizeMenuItem

private on setButtonDepressed pTarget
   lock screen
   lock messages
   
   local tHilite, tShowIcon
   put the hilite of pTarget into tHilite
   put the showIcon of pTarget into tShowIcon
   if tHilite then
      set the icon of pTarget to the cHighlightedDepressedIcon of pTarget
   else
      set the icon of pTarget to the cDepressedIcon of pTarget
   end if
   setButtonHilite pTarget, not the hilite of pTarget
   set the showIcon of pTarget to tShowIcon

   unlock messages
   unlock screen
end setButtonDepressed

private on setButtonReleased pTarget
   updateButtonState
end setButtonReleased

on mouseDown
   if the short name of the owner of the target is "revMenuBar" then
      revMenubarBuildMenus
   else if the short name of the owner of the target is "toolbar" and the target begins with "button" then
      setButtonDepressed the long id of the target
   end if
end mouseDown

on mouseRelease
   if the short name of the owner of the target is "toolbar" and the target begins with "button" then
      setButtonReleased the long id of the target
   end if
end mouseRelease

on mouseUp
   lock screen
   if the target begins with "widget" then
      local tOriginButton, tTarget
      put the short name of the target into tTarget
      if tTarget is "stop" then
         answer "Are you sure you want to exit this tutorial?" with "OK" or "Cancel"
         if it is "OK" then
            revIDEStopTutorial
         end if
      else if tTarget is "skip" then
         revIDETutorialSkipToNextSkipPoint
      end if
   else if the short name of the owner of the target is "upgrade" then
      local tStartCenterClassic
      put revIDEGetPreference("StartCenterClassic") into tStartCenterClassic
      revIDESetPreference "StartCenterClassic", true
      ideShowUpgradeOptions
      revIDESetPreference "StartCenterClassic", tStartCenterClassic
   else if the short name of the owner of the target is "toolbar" and the target begins with "button" then
      revMenubarMenuButtonClicked the short name of the target
      setButtonReleased the long id of the target
   end if
   unlock screen
end mouseUp

/*
There is no way to get the real screen rects of the mac menu buttons,
so this function has the current values hard-coded. The easiest way 
to find these values is to use 'the left of stack "Message Box" whilst aligning
visually.

At some point we will need to sort out the conflict between this function
and potential user locale settings.
*/
private function rectOfMacMenuItem pItem
   local tLeft, tRight
   switch pItem
      case "File"
         put 140 into tLeft
         put 162 into tRight
         break
      case "Edit"
         put 182 into tLeft
         put 202 into tRight
         break
      case "Tools"
         put 222 into tLeft
         put 260 into tRight
         break
      case "Object"
         put 280 into tLeft
         put 322 into tRight
         break
      case "Text"
         put 342 into tLeft
         put 370 into tRight
         break
      case "Development"
         put 390 into tLeft
         put 478 into tRight
         break
      case "View"
         put 498 into tLeft
         put 528 into tRight
         break
      case "Window"
         put 548 into tLeft
         put 600 into tRight
         break
      case "Help"
         put 620 into tLeft
         put 650 into tRight
         break
   end switch
   return tLeft, 0, tRight, 15
end rectOfMacMenuItem

function absoluteRectOfObject pObject
   local tRect
   if there is a button pObject of group "revMenuBar" of me then
      if the platform is "macos" then
         return rectOfMacMenuItem(pObject)
      end if
      put the rect of button pObject into tRect
   else 
      if there is a button pObject of group "toolbar" of me then
         put the rect of button pObject of group "toolbar" of me into tRect
      else if pObject is "tutorial" then
         put the rect of group "tutorial" of me into tRect
      end if
   end if
   put revIDERelativeRectToAbsolute(tRect, me) into tRect
   return tRect
end absoluteRectOfObject

local sMenuHighlight
on highlightObject pObject
   if pObject is empty or pObject is an array then
      put pObject into sMenuHighlight
      revMenubarBuildMenus
   else if there is a button pObject of me then
      put pObject into sToolbarHighlight
   else if pObject is "tutorial" then
      // HIghlight tutorial progress group
   end if
   updateButtonState
end highlightObject

on revMenubarMenuButtonClicked pWhich
   switch pWhich
      case "Inspector"
         if (the selectedObject) is empty then
            revIDEActionInspectStack
         else
            revIDEActionInspectObjects
         end if
         break
      case "Code"
         if (the selectedObject) is empty then
            revIDEActionEditScriptOfStack
         else
            revIDEActionEditScriptOfObjects
         end if
         break
      case "Message Box"
         revIDETogglePalette "message box"
         break
      case "Group"
         if the number of lines in (the selObj) > 1 or word 1 of (the selObj) is not "group" then
            revIDEActionGroupObjects
         else
            revIDEActionUngroup
         end if
         break
      case "Edit Group"
         revIDEActionEditGroup
         break
      case "Select Grouped"
         revIDEToggle "Select Grouped Controls"
         break
      case "Messages"
         revIDEToggle "Suppress Messages"
         break
      case "Errors"
         revIDEToggle "Suppress Errors"
         break
      case "Sample Stacks"
      case "Tutorials"
         revIDELaunchResource pWhich
         break
      case "Resources"
         revIDEOpenPalette "Resource Center"
         break
      case "Dictionary"
         revIDEDocumentationLoad "API", "LiveCode Script"
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

on highlightMenuItem pMenu, pSubMenus
   local tMenuText
   put the text of button pMenu of group "revMenuBar" of me into tMenuText
   replace "&" with empty in tMenuText
   local tTabNesting, tSubMenuNum, tLineNum
   put 1 into tSubMenuNum
   repeat for each line tLine in tMenuText
      add 1 to tLineNum
      if tLine contains pSubMenus[tSubMenuNum] and \
            (tTabNesting is empty or tLine contains tTabNesting) then
         enable line tLineNum of button pMenu of group "revMenuBar" of me
         put tab after tTabNesting
         add 1 to tSubMenuNum
      else
         disable line tLineNum of button pMenu of group "revMenuBar" of me
      end if
   end repeat
   put the text of button pMenu of group "revMenuBar" of me into tMenuText
end highlightMenuItem

command revMenubarBuildMenus
   local tContext
   put buildMenuContext() into tContext
   
   lock screen
   lock messages
   lock menus
   repeat for each item tMenu in revMenubarMenus()
      set the text of button tMenu of group "revMenuBar" of me to revMenubarBuildMenu(tMenu, tContext)
      enable button tMenu of group "revMenuBar"
   end repeat
   
   if revIDETutorialInProgress() is not empty then
      repeat for each item tMenu in revMenubarMenus()
         # Don't disable the help menu during tutorials
         if tMenu is "Help" then
            next repeat
         end if
         disable button tMenu of group "revMenuBar" of me
      end repeat
      
      repeat for each key tMenu in sMenuHighlight
         enable button tMenu of group "revMenuBar" of me
         highlightMenuItem tMenu, sMenuHighlight[tMenu]
      end repeat
   end if
   unlock menus
   unlock messages
   unlock screen
end revMenubarBuildMenus

function revMenubarBuildMenu pMenu, pContext
   switch pMenu
      case "File"
         return revMenubarFileMenu(pContext)
      case "Edit"
         return revMenubarEditMenu(pContext)
      case "Tools"
         return revMenubarToolsMenu(pContext)
      case "Object"
         return revMenubarObjectMenu(pContext)
      case "Text"
         return revMenubarTextMenu(pContext)
      case "Development"         
         return revMenubarDevelopmentMenu(pContext)
      case "View"
         return revMenubarViewMenu(pContext)
      case "Window"
         return revMenubarWindowMenu(pContext)
      case "Help"
         return revMenubarHelpMenu(pContext)
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
   local tIsUserTarget, tIsScriptOnly
   put the mode of the topStack is 1 into tIsUserTarget
   put the scriptOnly of the topStack into tIsScriptOnly
   
   local tCanSaveStack
   put false into tCanSaveStack
   if not revIDEStackIsIDEStack(the topStack) or the mode of the topStack is 1 then
      put true into tCanSaveStack
   end if
   
   local tFile
   put "&New Stack" & return after tFile
   put tab & "Default Size" & return after tFile
   put tab & "-" & return after tFile
   put tab & "iPhone 4 (320x480)" & return after tFile
   put tab & "iPhone 5 (320x568)" & return after tFile
   put tab & "iPhone 6 (375x667)" & return after tFile
   put tab & "iPhone 6 Plus (414x736)" & return after tFile
   put tab & "iPad//Tablet Portrait (768x1024)" & return after tFile
   put tab & "iPad//Tablet Landscape (1024x768)" & return after tFile
   put tab & "-" & return after tFile
   put tab & "Script only Stack" & return after tFile
   
   if tIsUserTarget and not tIsScriptOnly then
      put "&New Substack of" && char 1 to 20 of the mainStack of the topStack & "/|New Substack" & return after tFile
   else
      put "(&New Substack" & return after tFile
   end if
   
   put "&Open Stack.../O" & return after tFile
   
   if revMenuBarRecentFiles() is not empty then
      put "Open Recent File" & return after tFile
      put revMenuBarRecentFiles() & return after tFile
   else
      put "(Open Recent File" & return after tFile
   end if
   
   put enableMenuItem("&Close/W", the mode of the topStack <= 3 and the short name of the topstack is not "revMenubar") & return after tFile
   put enableMenuItem("Close and Remove From Memor&y", tCanSaveStack) & return after tFile
   put "-" & return after tFile
   
   put enableMenuItem("Import As Control", tIsUserTarget) & return after tFile
   put tab & "Image File.../>|image" & return after tFile
   put tab & "Audio File.../|audio" & return after tFile
   put tab & "Video File.../|video" & return after tFile
   put tab & "Text File.../|text" & return after tFile
   put tab & "-" & return after tFile
   put tab & "Graph from CSV File.../|graph" & return after tFile
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
   
   put enableMenuItem("&Share this stack...", tCanSaveStack) & return after tFile
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

private function revMenubarEditMenu pContext
   local tEdit
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
end revMenubarEditMenu

################################################################################

private function revMenubarToolsMenu pContext
   local tTools
   
   put markMenuItem("&Browse Tool/9", the tool is "browse tool") & return after tTools
   put markMenuItem("&Pointer Tool/0", the tool is "pointer tool") & return after tTools
   put "-" & return after tTools
   put toggleMenuItem("&Tools Palette/T", revIDEPaletteIsVisible("tools")) & return after tTools
   put toggleMenuItem("&Paint and Draw Tools", "paint" is among the items of revIDEGetPreference("revTools_show")) & return after tTools
   put "-" & return after tTools
   
   put toggleMenuItem("Project Browser", revIDEPaletteIsVisible("project browser")) & return after tTools
   put toggleMenuItem("&Message Box/M", revIDEPaletteIsVisible("message box")) & return after tTools
   put toggleMenuItem("Extension Manager", revIDEPaletteIsVisible("extension manager")) & return after tTools
   put toggleMenuItem("Extension Builder", revIDEPaletteIsVisible("extension builder")) & return after tTools
   put "-" & return after tTools
   put toggleMenuItem(enableMenuItem("Menu Builder", the mode of the topStack is 1), revIDEPaletteIsVisible("menu builder")) & return after tTools
   
   return modifyMenu("Tools", tTools)
end revMenubarToolsMenu

################################################################################

private function revMenubarTextMenu pContext
   local tText,tFont,tSize,tAlign,tStyle,tColor
   
   if not pContext["enableText"] then
      put sTextMenuDisabledText into tText
   else   
      put sTextMenuText into tText   
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
end revMenubarTextMenu

################################################################################

private function revMenubarObjectMenu pContext
   local tObject
   
   local tIsObjectTarget, tIsUserTarget
   put (the selObj) is not empty and word 1 of (the selObj) is not "stack" into tIsObjectTarget
   put not revIDEStackIsIDEStack(the topstack) into tIsUserTarget
   
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
   put revMenubarNewControlSubmenu() & return after tObject
   put "-" & return after tObject
   put enableMenuItem("New Widget", the mode of the topStack is 1) & return after tObject
   put revMenubarNewWidgetSubmenu() & return after tObject
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
         if "revReshapeLibrary" is in revInternal__ListLoadedLibraries() then
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
   
   local tCanRelayer = true
   local tCanMoveBack = true
   local tCanMoveForward = true
   if pContext["objectsSelected"] then
      local tSelectedObjects
      put the selectedObjects into tSelectedObjects
      
      local tOwner
      put the long owner of (line 1 of tSelectedObjects) into tOwner
      
      local tNumSelected
      put the number of lines of (tSelectedObjects) into tNumSelected
      if tNumSelected is the number of controls of tOwner then
         put false into tCanRelayer
      end if
      
      if tCanRelayer then
         local tID
         repeat for each line tID in tSelectedObjects
            if the long owner of tID is not tOwner then
               put false into tCanRelayer
               exit repeat
            end if
            if the layer of tID is the layer of tOwner + 1 then
               put false into tCanMoveBack
            end if
            if the layer of tID is the layer of tOwner + the number of controls of tOwner then
               put false into tCanMoveForward
            end if
         end repeat
      end if
   end if
   
   ### Send to back, Move Backward, Move Forward and Bring to Front
   put enableMenuItem("&Send to Back", pContext["objectsSelected"] and tCanRelayer and tCanMoveBack) & return after tObject
   put enableMenuItem("Move Backward/[", pContext["objectsSelected"] and tCanRelayer and tCanMoveBack) & return after tObject
   put enableMenuItem("Move For&ward/]", pContext["objectsSelected"] and tCanRelayer and tCanMoveForward) & return after tObject
   put enableMenuItem("Bring to &Front", pContext["objectsSelected"] and tCanRelayer and tCanMoveForward) & return after tObject
   
   return modifyMenu("Object", tObject)
end revMenubarObjectMenu

private function revMenubarNewControlSubmenu
   local tControlsA, tControlList
   put revIDEAvailableControls() into tControlsA
   
   put the keys of tControlsA into tControlList
   
   # Sort alphabetically
   sort tControlList
   # Then group by type
   sort lines of tControlList by tControlsA[each]["type"]
   
   local tControlMenu, tItem, tLastType, tType
   put tControlsA[line 1 of tControlList]["type"] into tLastType
   repeat for each line tLine in tControlList
      put tControlsA[tLine]["type"] into tType
      if tType is not tLastType then
         put return & tab & "-" after tControlMenu
         put tType into tLastType
      end if
      
      put tab & tLine & "/|" & tControlsA[tLine]["kind"] into tItem
      if tControlMenu is empty then
         put tItem into tControlMenu
      else
         put return & tItem after tControlMenu
      end if
   end repeat
   return tControlMenu
end revMenubarNewControlSubmenu

private function revMenubarNewWidgetSubmenu
   local tWidgetsA, tWidgetList
   put revIDEAvailableWidgets() into tWidgetsA
   
   put the keys of tWidgetsA into tWidgetList
   
   # Sort alphabetically
   sort tWidgetList
   
   local tWidgetMenu, tItem
   repeat for each line tLine in tWidgetList
      put tab & tLine & "/|" & tWidgetsA[tLine]["kind"] into tItem
      if tWidgetMenu is empty then
         put tItem into tWidgetMenu
      else
         put return & tItem after tWidgetMenu
      end if
   end repeat
   return tWidgetMenu
end revMenubarNewWidgetSubmenu

private function buildFlipSubmenu
   return \
         tab & "Horizontal" & return & \
         tab & "Vertical" 
end buildFlipSubmenu

private function buildRotateSubmenu
   return \
         tab & "By.../|By" & return & \
         tab & "90° Right/|270" & return & \
         tab & "90° Left/|90" & return & \
         tab & "180°/|180"
end buildRotateSubmenu

private function buildDistributeSubmenu
   return \
   tab & tab & "First to last selected" & return & \
   tab & tab & "Edge to edge" & return & \
   tab & tab & "Across card"
end buildDistributeSubmenu

private function buildAlignSubmenu
   local tAlign
   put tab & "Left" & return after tAlign
   put tab & "Right" & return after tAlign
   put tab & "Top" & return after tAlign
   put tab & "Bottom" & return after tAlign
   put tab & "-" & return after tAlign
   put tab & "Make Widths E&qual/|Width" & return after tAlign
   put tab & "Make &Heights Equal/|Height" & return after tAlign
   put tab & "-" & return after tAlign
   put tab & "Distribute Objects Horizontally..." & return after tAlign
   put buildDistributeSubmenu() & return after tAlign
   put tab & "Distribute Objects Vertically..." & return after tAlign
   put buildDistributeSubmenu() after tAlign
   return tAlign
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

private function revMenubarHelpMenu pContext
   local tHelp
   # AL-2015-07-10: Temporarily remove welcome screen option from help menu
   //put "Welcome Screen/|Welcome" & return after tHelp
   put "Start Center/|Start Center" & return after tHelp
   put "User Guide" & return after tHelp
   put "Dictionary (API)/|Dictionary" & return after tHelp
   
   put "-" & return  after tHelp
   
   put "Sample Stacks" & return after tHelp
   put "Sample Scripts" & return after tHelp
   put "-" & return after tHelp
   put "Beginners Guide" & return after tHelp
   put "All Guides" & return after tHelp
   put "Tutorials" & return after tHelp
   put "-" & return after tHelp
   put "Forums" & return after tHelp
   put "Technical Questions" & return after tHelp
   put "Discussion List" & return after tHelp
   put "Newsletters" & return after tHelp
   put "-" & return after tHelp
   put "Release Notes/|Release Notes" & return after tHelp
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
end revMenubarHelpMenu

################################################################################

private function revMenubarViewMenu pContext
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
   put toggleMenuItem("Palettes", gREVPalettes is empty) & return after tView
   put "-" & return after tView
   put toggleMenuItem("Rulers", the mode of stack "revRulersH" is not 0) & return after tView
   put toggleMenuItem("Grid", the grid) & return after tView
   put toggleMenuItem("Backdrop", the backdrop is not "none") & return after tView
   put toggleMenuItem("Show IDE Stacks In Lists", gREVShowStacks) & return after tView
   put "-" & return after tView
   put toggleMenuItem("Show &Invisible Objects" , the showInvisibles) & return after tView
   
   return modifyMenu("View", tView)
end revMenubarViewMenu

################################################################################

private function revMenubarDevelopmentMenu pContext
   global gREVSuppressErrors, gREVSuppressMessages
   
   local tIsUserTarget
   put not revIDEStackIsIDEStack(the topstack) into tIsUserTarget
   
   local tDevelopment
   put "Object Library" & return after tDevelopment
   put "Image Library" & return after tDevelopment
   put "Plugins" & return after tDevelopment
   if sPluginMenuText is not empty then
      put sPluginMenuText & return after tDevelopment
   end if
   put tab & "-" & return after tDevelopment
   put tab & "Plugin Settings" & return after tDevelopment
   put "-" & return after tDevelopment
   put revMenubarSimulatorSubmenu() after tDevelopment
   put "-" & return after tDevelopment   
   
   if revEnvironmentEditionProperty("script_profiler") then
      local tProfiler
      put the long id of stack "com.livecode.library.scriptprofiler" into tProfiler
      if tProfiler is among the lines of the backScripts then
         put enableMenuItem("Start Profiling Scripts", tIsUserTarget) & return after tDevelopment
      else
         put enableMenuItem("Stop Profiling Scripts...", tIsUserTarget) & return after tDevelopment
      end if
      put "-" & return after tDevelopment
   end if
   
   put toggleMenuItem("Script Debug Mode", revDebuggerEnabled()) & return after tDevelopment
   put"Clear All Breakpoints" & return after tDevelopment
   put "Message Watcher" & return after tDevelopment
   put "-" & return after tDevelopment
   put toggleMenuItem("Suppress Errors", gREVSuppressErrors) & return after tDevelopment
   put toggleMenuItem("Suppress Messages", gREVSuppressMessages) & return after tDevelopment
   put "-" & return after tDevelopment
   put "Suspend Development Tools" & return after tDevelopment
   
   return modifyMenu("Development", tDevelopment)
end revMenubarDevelopmentMenu

private function revMenubarSimulatorSubmenu
   local tSimulators
   put revIDETestTargets() into tSimulators
   
   if tSimulators is not an array then
      return "(Test/|Simulate" & return & "(Test Target" & return & tab & "(No targets configured" & return
   end if
   
   local tCurrentTarget
   put revIDETestTarget() into tCurrentTarget
   
   local tMenu
   put enableMenuItem("Test/|Simulate", tCurrentTarget is not empty) & return after tMenu
   put "Test Target/|Simulator Version" & return after tMenu
   repeat for each key tPlatform in tSimulators
      local tCanDeploy
      put revIDETestCanDeployToTarget(tPlatform) into tCanDeploy
      repeat for each line tTarget in tSimulators[tPlatform]
         put tab & enableMenuItem(toggleMenuItem(tTarget, tTarget is tCurrentTarget), tCanDeploy) & return after tMenu
      end repeat
      put tab & "-" & return after tMenu
   end repeat
   delete char -3 to -1 of tMenu
   
   return tMenu
end revMenubarSimulatorSubmenu

################################################################################

private function revMenubarWindowMenu pContext
   revIDEUpdateWindowList
   
   setupWindowMenu
   
   local tWindow
   if sWindowMenuWindows is empty then
      put "(No Windows Open" into tWindow
   else
      put sWindowMenuWindows & return & "-" & return & "Send Window to Back/`" into tWindow
   end if
   
   return modifyMenu("Window", tWindow)
end revMenubarWindowMenu

################################################################################

function revMenubarAdditionalContextMenu pIndent
   local tIndent
   repeat pIndent
      put tab after tIndent
   end repeat
   
   local tText
   put return & tIndent & "-" after tText
   put return & tIndent & "Show In Project Browser" after tText
   put return & tIndent & "Show Documentation" after tText
   return tText
end revMenubarAdditionalContextMenu

function revMenubarSendContextMenu pObject, pIndent
   local tIndent
   repeat pIndent
      put tab after tIndent
   end repeat
   
   local tHandlerList, tText
   put revListMenuHandlers(pObject, the cSort of stack "revPreferences", pIndent + 1) into tHandlerList
   put tIndent & enableMenuItem("Send Message", tHandlerList is not tIndent & tab) after tText
   if tHandlerList is not tIndent & tab then
      put return & tHandlerList after tText
   end if
   return tText
end revMenubarSendContextMenu

function revMenubarStackContextMenu pStack, pIndent
   global gRevLanguageNames
   
   local tIndent
   repeat pIndent
      put tab after tIndent
   end repeat
   
   local tText
   put tIndent & "Edit Script" & return after tText
   put tIndent & enableMenuItem("Edit Behavior Script", \
         exists(the behavior of stack pStack)) & return after tText
   put tIndent & "Property Inspector" & return after tText
   put tIndent & "-" & return after tText
   put tIndent & "Stack Mode" & return after tText
   if gREVLanguageNames then
      put tIndent & tab & markMenuItem("topLevel", the mode of stack pStack < 3) & return after tText
      put tIndent & tab & markMenuItem("modeless", the mode of stack pStack is 3) & return after tText
      put tIndent & tab & markMenuItem("palette", the mode of stack pStack is 4) & return after tText
      put tIndent & tab & markMenuItem("modal", the mode of stack pStack is 5) & return after tText
   else
      put tIndent & tab & markMenuItem("TopLevel", the mode of stack pStack < 3) & return after tText
      put tIndent & tab & markMenuItem("Modeless", the mode of stack pStack is 3) & return after tText
      put tIndent & tab & markMenuItem("Palette", the mode of stack pStack is 4) & return after tText
      put tIndent & tab & markMenuItem("Modal", the mode of stack pStack is 5) & return after tText
   end if
   put tIndent & "-" & return after tText
   put tIndent & enableMenuItem("Paste Objects", the clipboard is "objects" and the mode of stack pStack is 1) & return after tText
   put tIndent & "-" & return after tText
   put tIndent & "New Card" & return after tText
   put tIndent & "Delete Card" & return after tText
   put tIndent & "-" & return after tText
   put tIndent & "New Substack" & return after tText
   put tIndent & enableMenuItem("Delete Substack", the mainstack of pStack is not the short name of pStack) & return after tText
   put tIndent & "-" & return after tText
   put tIndent & "Save" & return after tText
   put tIndent & "Close and Remove From Memory" & return after tText
   put tIndent & "-" & return after tText
   put tIndent & "Standalone Application Settings..." & return after tText
   put tIndent & "Save As Standalone Application..." & return after tText
   put tIndent & "-" & return after tText
   
   if there is a stack "com.livecode.library.scriptprofiler" then
      local tProfiler
      put the long id of stack "com.livecode.library.scriptprofiler" into tProfiler
      if tProfiler is among the lines of the backScripts then
         put tIndent & "Start Profiling Scripts" & return after tText
      else
         put tIndent & "Stop Profiling Scripts..." & return after tText
      end if
      put tIndent & "-" & return after tText
   end if
   
   put revMenubarSendContextMenu(pStack, pIndent) after tText
   put revMenubarAdditionalContextMenu(pIndent) after tText
   
   return tText
end revMenubarStackContextMenu

function revMenuBarCardContextMenu pCard, pIndent
   local tIndent
   repeat pIndent
      put tab after tIndent
   end repeat
   
   local tTargetStack
   put revIDEStackOfObject(pCard) into tTargetStack
   
   local tText
   put revMenuBarStandardContextMenu(pCard, pIndent) & return into tText
   put tIndent & "-" & return after tText
   put tIndent & enableMenuItem("Paste Objects", the clipboard is "objects" and the mode of stack tTargetStack is 1) & return after tText
   put tIndent & "-" & return after tText
   put tIndent & "New Card" & return after tText
   put tIndent & "Delete Card" & return after tText
   put tIndent & "-" & return after tText
   put revMenubarSendContextMenu(pCard, pIndent) after tText
   put revMenubarAdditionalContextMenu(pIndent) after tText
   return tText
end revMenuBarCardContextMenu

function revMenuBarObjectContextMenu pExtraText, pObject, pIndent, pSelectable
   local tIndent
   repeat pIndent
      put tab after tIndent
   end repeat
   
   local tText
   put revMenuBarStandardContextMenu(pObject, pIndent, pSelectable) & return into tText
   repeat for each line tLine in pExtraText
      put tIndent & tLine & return after tText
   end repeat
   put tIndent & "-" & return after tText
   put revMenubarSendContextMenu(pObject, pIndent) after tText
   put revMenubarAdditionalContextMenu(pIndent) after tText
   return tText
end revMenuBarObjectContextMenu

function revMenuBarStandardContextMenu pObject, pIndent, pSelectable
   local tIndent
   repeat pIndent
      put tab after tIndent
   end repeat
   
   local tText
   put tIndent & "Edit Script" & return after tText
   put tIndent & enableMenuItem("Edit Behavior Script", \
         exists(the behavior of pObject)) & return after tText
   put tIndent & "Property Inspector" & return after tText
   put tIndent & "-" & return after tText
   put tIndent & enableMenuItem("Cut", pSelectable) & return after tText
   put tIndent & enableMenuItem("Copy", pSelectable) after tText
   return tText
end revMenuBarStandardContextMenu

function revBuildContextSensitiveMenu pExtraText, pTarget, pType, pSelectable
   local tText
   if word 1 of pTarget is "stack" then
      put revMenuBarStackContextMenu(pTarget, 0) into tText
      return tText
   end if
   
   local tTargetStack
   put revIDEStackOfObject(pTarget) into tTargetStack
   
   if word 1 of pTarget is "card" then
      put revMenuBarCardContextMenu(pTarget,0) into tText
      put return & "-" after tText
      put return & "Stack" after tText
      put return & revMenuBarStackContextMenu(tTargetStack, 1) after tText
      return tText
   end if
   
   put revMenuBarObjectContextMenu(pExtraText, pTarget,0, pSelectable) into tText
   put return & "-" after tText
   put return & enableMenuItem("Clear", pSelectable) after tText
   put return & "-" after tText
   put return & "Card" after tText
   put return & revMenuBarCardContextMenu(the long id of this card of tTargetStack, 1) after tText
   put return & "-" after tText
   put return & "Stack" after tText
   put return & revMenuBarStackContextMenu(tTargetStack, 1) after tText
   return tText
end revBuildContextSensitiveMenu

function revMenubarContextMenu pType, pTarget
   local tSelectable
   put revIDEObjectsAreSelectable(sMenuTarget) into tSelectable
   
   local tText
   switch pType
      case "group"
         put enableMenuItem("Paste into Group", tSelectable and the clipboard is "objects") & return after tText
         put "-" & return after tText
         put enableMenuItem("Edit Group", tSelectable) & return after tText
         put enableMenuItem("Ungroup", tSelectable) & return after tText
         put "-" & return after tText
         put toggleMenuItem("Lock Location", the lockLoc of pTarget) & return after tText
         break
      case "image"
         put "-" & return after tText
         put "Launch Editor" & return after tText
         put toggleMenuItem("Magnify", the magnify of pTarget) & return after tText
         put "-" & return after tText
         put toggleMenuItem("Lock Location", the lockLoc of pTarget) & return after tText
         put enableMenuItem("Make Original Size", the formattedWidth of pTarget is not the width of pTarget \
               or the formattedHeight of pTarget is not the height of pTarget) & return after tText
         break
      case "polygon"
         put "-" & return after tText
         put toggleMenuItem( "Reshape Polygon", the editMode of pTarget is "polygon") & return after tText
         break
      case "multiple"
         put "-" & return after tText
         put "Align" & return after tText
         put tab & "Left" & return after tText
         put tab & "Right" & return after tText
         put tab & "Top" & return after tText
         put tab & "Bottom" & return after tText
         put tab & "-" & return after tText
         put tab & "Make Widths Equal/|Width" & return after tText
         put tab & "Make Heights Equal/|Height" & return after tText
         put enableMenuItem("Group", tSelectable) & return after tText
         break
      case "field"
         put enableMenuItem("Paste Text", tSelectable and the clipboard is "text") & return after tText
         put "-" & return after tText
         put toggleMenuItem("Lock Text", the lockText of pTarget) & return after tText
         put toggleMenuItem("Can Receive Keyboard Focus", the traversalOn of pTarget) & return after tText
         break
      case "player"
         put "-" & return after tText
         put enableMenuItem("Play", word 1 of the tool is "browse") & return after tText
         put enableMenuItem("Stop", word 1 of the tool is "browse") & return after tText
         if the paused of pTarget then
            put enableMenuItem("Unpause", word 1 of the tool is "browse") & return after tText
         else
            put enableMenuItem("Pause", word 1 of the tool is "browse") & return after tText
         end if
         break
      case "menu"
         put enableMenuItem("TopLevel Panel Stack", the menuName of pTarget is not empty) & return after tText
         break
   end switch
   
   put revBuildContextSensitiveMenu(tText, pTarget, , tSelectable) into tText
   
   return modifyMenu(pType, tText)
end revMenubarContextMenu

on revMenubarSetContextMenu pType, pTarget
   set the text of button "context" of me to revMenubarContextMenu(pType, pTarget)
   set the script of button "context" of me to "on menuPick pWhich; revMenubarContextMenuPick pWhich; end menuPick"
end revMenubarSetContextMenu

on revMenubarPopupContextualMenu pTargets
   local tTarget
   if pTargets is not empty then
      put the long id of (line 1 of pTargets) into tTarget
   else
      put the long id of the target into tTarget
   end if
   
   local tTargetStack
   put revTargetStack(tTarget) into tTargetStack
   
   put empty into sMenuTarget
   repeat for each line tLine in pTargets
      if sMenuTarget is empty then
         put tLine into sMenuTarget
      else
         put return & tLine after sMenuTarget
      end if
   end repeat
   
   if the number of lines in sMenuTarget > 1 then
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
         case "widget"
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
   global gREVBackDropRestore, gREVRestore
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

on revMenubarContextMenuPick pWhich
   revMenubarContextMenuPickTarget pWhich, sMenuTarget
end revMenubarContextMenuPick

on revMenubarContextMenuPickTarget pWhich, pTarget
   local tTargetStack
   put revIDEStackOfObject(line 1 of pTarget) into tTargetStack
   
   set the itemdelimiter to "|"
   switch item 1 of pWhich
      ######## OBJECTS #########
      case "Edit Script"
         revIDEEditScriptOfObjects pTarget
         break
      case "Edit Behavior Script"
         revIDEEditScriptOfObjects the behavior of pTarget
         break
      case "Property Inspector"
         revIDEOpenInspectorForObjects pTarget
         break
      case "Cut"
         revIDECutObjects pTarget
         break
      case "Copy"
         revIDECopyObjects pTarget
         break
      case "Lock Location"
         revIDEToggleLockLocationOfObjects pTarget
         break
      case "Show Documentation"
         revIDEGoToObjectAPI pTarget
         break
      case "Show In Project Browser"
         revIDEShowInProjectBrowser pTarget
         break
         ######## GRAPHIC SPECIFIC #########
      case "Reshape Polygon"
         if the editMode of pTarget is "polygon" then
            set the editMode of pTarget to "none"
         else
            set the editMode of pTarget to "polygon"
         end if
         break
         ######## GROUP SPECIFIC #########
      case "Edit Group"
         revIDEEditGroup pTarget
         break
      case "Ungroup"
         revIDEUngroup pTarget
         break
      case "Paste into Group"
         revIDEPasteIntoGroup pTarget
         break
      case "Clear"
         revIDEActionClearObjects pTarget
         break
         ######## IMAGE SPECIFIC #########
      case "Paint Tools"
         revIDETogglePaintAndDrawTools
         break
      case "Launch Editor"
         revIDEEditImage pTarget
         break
      case "Magnify"
         revIDEToggleMagnifyOfImage pTarget
         break 
      case "Make Original Size"
         revIDEMakeImageOriginalSize pTarget
         break
         ######## FIELD SPECIFIC #########
      case "Paste Text"
         revIDEActionPasteTextIntoField pTarget
         break
      case "Lock Text"
         revIDEToggleLockTextOfField pTarget
         break
      case "Can Receive Keyboard Focus"
         revIDEToggleTraversalOnOfField pTarget
         break
         ######## PLAYER SPECIFIC #########
      case "Play"
         revIDEStartPlayingPlayer pTarget
         break
      case "Stop"
         revIDEStopPlayingPlayer pTarget
         break
      case "Pause"
         revIDETogglePauseOfPlayer
         break
         
         ######## MENU SPECIFIC #########
      case "TopLevel Panel Stack"
         toplevel the menuname of pTarget
         break
         ######## STACK SCPECIFIC ########
      case "New Card"
         revIDEActionNewCard
         break
      case "Delete Card"
         if word 1 of pTarget is "stack" then
            revIDEActionDeleteCard
         else
            revIDEDeleteCard pTarget
         end if
         break
      case "Save"
         revIDESaveStack tTargetStack
         break
      case "Paste Objects"
         revIDEPasteOntoStack tTargetStack
         break
      case "Stack Mode"
         revIDESetModeOfStack tTargetStack, item 2 of pWhich
         break
      case "New Substack"
         revIDENewSubstackOfStack the short name of tTargetStack
         break
      case "Close And Remove From Memory"
         revIDECloseStack tTargetStack, true
         break
      case "Delete Substack"
         revIDEDeleteSubstack tTargetStack
         break
      case "Standalone Application Settings..."
         revIDEStandaloneSettingsForStack tTargetStack
         break
      case "Save As Standalone Application..."
         revIDESaveAsStandalone tTargetStack
         break
      case "Start Profiling Scripts" 
         scriptprofilerStartProfiler the short name of tTargetStack
         break
      case "Stop Profiling Scripts..." 
         scriptprofilerStopProfiler
         break
         ######## MULTI OBJECT SPECIFIC #########
      case "Align"
         revIDEAlignControls pTarget, item 2 of pWhich 
         break     
      case "Send Message"
         revIDESendMessageToObject item 2 of pWhich, pTarget
         break
      case "Group"
         revIDEGroupObjects pTarget
         if the result is empty and exists(it) then
            select it
         else
            beep
         end if
         break
         ######### SUBMENUS ########
      case "Card"
         revMenubarContextMenuPickTarget item 2 to 3 of pWhich, the long id of this card of tTargetStack
         break
      case "Stack"
         revMenubarContextMenuPickTarget item 2 to 3 of pWhich, tTargetStack
         break
      default
         break
   end switch
end revMenubarContextMenuPickTarget

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
         revIDEActionSaveStackAs the long id of the topStack
         break
      case "Save As Standalone Application..."
         revIDESaveAsStandalone the long id of the topStack
         break
      case "Share this stack..."
         revIDEShareStack the long id of the topStack
         break
      case "Standalone Application Settings..."
         revIDEStandaloneSettingsForStack the long id of the topStack
         break
      case "Move substack to file..."
         revIDEMoveSubstackToFile the long id of the topStack
         break
      case "Revert To Saved..."
         revIDERevertToSavedStack the long id of the topStack
         break
      case "Page Setup..."
         revIDEPrintPageSetup
         break
      case "Print Card..."
         revIDEPrintCurrentCard
         break
      case "Print Field..."
         revIDEPrintField the long ID of the selectedobject
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
               if tStackType is "Script Only Stack" then
                  revIDEActionNewScriptOnlyStack
               else
                  revIDEActionNewMainstack tStackType
               end if
               break
            case "Open Recent File"
               local tRecentStack
               put item 2 of pWhich into tRecentStack
               if tRecentStack is kClearRecentFiles then
                  revIDESetPreference "cRecentStackPaths", empty
                  ideMessageSend "ideRecentFilesChanged"
               else
                  revIDEOpenStack tRecentStack
               end if
               break
            case "Import As Control"
               put item 2 of pWhich into tType
               switch tType
                  case "image"
                  case "audio"
                  case "video"
                  case "text"
                  case "graph"
                     revIDEActionImportControl tType
                     break 
                  case "Snapshot of Screen"
                     revIDEImportSnapshot "screen"
                     break
                  case "Snapshot of Selected Object"
                     revIDEImportSnapshot "object", the selobj
                     break
                  case "image folder"
                  case "audio folder"
                  case "video folder"
                  case "text folder"
                     revIDEActionImportControlFromFolder word 1 of tType
                     break
               end switch
               break
            case "New Referenced Control"
               put item 2 of pWhich into tType
               switch tType
                  case "image"
                  case "video"
                     revIDEActionImportControl tType, true
                     break
                  case "image folder"
                  case "video folder"
                     revIDEActionImportControlFromFolder word 1 of tType, true
                     break
               end switch
         end switch
   end switch
end revMenubarFileMenuPick

on revMenubarEditMenuPick pWhich
   switch pWhich
      case "Undo"
         revIDEUndo
         break
      case "Cut Object(s)"
      case "Cut Objects"
      case "Cut Card"
      case "Cut"
      case "Cut Text"
      case "Cut Image Selection"
         revIDECut
         break
      case "Copy Objects"
      case "Copy Object(s)"
      case "Copy Card"
      case "Copy"
      case "Copy Text"
      case "Copy Image Selection"
         revIDECopy
         break
      case "Paste"
      case "Paste Object(s)"
      case "Paste Objects"
      case "Paste Text"
      case "Paste Image"
         revIDEPaste
         break
      case "Paste Unformatted"
         revIDEActionPasteUnformatted
         break
      case "Clear Objects"
      case "Clear Card"
      case "Clear"
      case "Clear Text"
      case "Clear Image Selection"
         revIDEActionClear
         break
      case "Deselect All"
         revIDEDeselectAll
         break
      case "Select All"
         revIDESelectAll
         break
      case "Invert Selection"
         revIDEInvertObjectSelection
         break
      case "Duplicate"
      case "Duplicate Objects"
         revIDEActionDuplicate
         break
      case "Duplicate Card"
         revIDEDuplicateCard
         break
      case "Select Grouped Controls"
      case "Intersected Selections"
         revIDEToggle pWhich
         break
      case "Preferences"
         revIDEOpenPalette "preferences"
         break
      case "Find and Replace..."
         revIDEOpenPalette "search"
         break
   end switch
end revMenubarEditMenuPick

on revMenubarToolsMenuPick pWhich
   switch pWhich
      case "Tools Palette"
         revIDETogglePalette "tools"
         break
      case "Browse Tool"
         revIDEChooseBrowseTool
         break
      case "Pointer Tool"
         revIDEChoosePointerTool
         break
      case "paint and draw tools"
         revIDETogglePaintAndDrawTools
         break
      case "Menu Builder"
      case "Message Box"
      case "Project Browser"
      case "Extension Manager"
      case "Extension Builder"
         revIDETogglePalette pWhich
         break
   end switch
end revMenubarToolsMenuPick

on revMenubarObjectMenuPick pWhich
   set the itemdelimiter to "|"
   switch item 1 of pWhich
      case "Reshape Graphic"
         revIDEToggleReshapeGraphic
         break
      case "New card"
         revIDEActionNewCard
         break
      case "Delete Card"
         revIDEActionDeleteCard
         break
      case "Object Inspector"
         revIDEActionInspectObjects
         break
      case "Card Inspector"
         revIDEActionInspectCard
         break
      case "Stack Inspector"
         revIDEActionInspectStack
         break 
      case "Object Script"
         revIDEActionEditScriptOfObjects
         break
      case "Card Script"
         revIDEActionEditScriptOfCard
         break
      case "Stack Script"
         revIDEEditScriptOfObjects the long ID of the topstack
         break
      case "New Control"
      case "New Widget"
         revIDEActionCreateObject item 2 of pWhich
         break
      case "Place Group"
         revIDEPlaceGroupOnCard item 2 of pWhich
         break
      case "Remove Group"
         revIDEActionRemoveGroupFromCard
         break
      case "Send to Back"
         revIDEActionSendToBack
         break
      case "Move Backward"
         revIDEActionMoveBackward
         break
      case "Move forward"
         revIDEActionMoveForward
         break
      case "Bring to Front"
         revIDEActionBringToFront
         break
      case "Group Selected"
         revIDEActionGroupObjects
         break
      case "Edit Group"
         revIDEActionEditGroup
         break
      case "Stop Editing Group"
         revIDEStopEditingGroup
         break
      case "Ungroup selected"
         revIDEActionUngroup
         break
      case "Flip Image"
         revIDEActionFlipImage item 2 of pWhich
         break
      case "Flip Graphic"
         revIDEActionFlipGraphic item 2 of pWhich
         break
      case "Rotate Image"
         if item 2 of pWhich is "By" then
            revIDEActionRotateImageBy
         else
            revIDEActionRotateImage item 2 of pWhich
         end if
         break
      case "Rotate Graphic"
         if item 2 of pWhich is "By" then
            revIDEActionRotateGraphicBy
         else
            revIDEActionRotateGraphic item 2 of pWhich
         end if
         break
      case "Align Selected Controls"
         if item 2 of pWhich begins with "Distribute Objects" then
            revIDEActionDistributeControls item 2 of pWhich is "Distribute Objects Horizontally...", item 3 of pWhich
         else
            revIDEActionAlign item 2 of pWhich
         end if
         break
   end switch
end revMenubarObjectMenuPick

on revMenubarTextMenuPick pWhich
   local tPickedItem, tPickedParams
   
   // tPickedItem could have parameters
   set the itemdel to "|"
   if the number of items of pWhich > 1 then
      put toLower(item 2 to -1 of pWhich) into tPickedParams
      put toLower(item 1 of pWhich) into tPickedItem
   else 
      put pWhich into tPickedItem
   end if

   switch tPickedItem
      case "plain"
         revIDEStyleTextPlain
         break
      case "bold"
         revIDEStyleTextBold
         break
      case "italic"
         revIDEStyleTextItalic
         break
      case "underline"
         revIDEStyleTextUnderline
         break
      case "strikeout"
         revIDEStyleTextStrikeout
         break
      case "box"
         revIDEStyleTextBox
         break
      case "link"
         revIDEStyleTextLink
         break
      case "3d box"
         revIDEStyleText3DBox
         break
      case "subscript"
         revIDEStyleTextSubscript
         break
      case "superscript"
         revIDEStyleTextSuperscript
         break
      case "font"
         revIDESetTextFont tPickedParams
         break
      case "size"
         revIDESetTextSize tPickedParams
         break
      case "color"
         revIDESetTextColor tPickedParams
         break
      case "align"
         revIDESetTextAlign tPickedParams
         break
   end switch
end revMenubarTextMenuPick

local lRestore
on revMenubarDevelopmentMenuPick pWhich
   local tWhich
   set the itemDelimiter to "|"
   put item 1 of pWhich into tWhich
   
   switch tWhich
      case "Message Watcher"
         revIDEOpenPalette "message watcher"
         break
      case "Clear all Breakpoints"
         revIDEActionClearAllBreakpoints
         break
      case "Script Debug Mode"
      case "Suppress Messages"
      case "Suppress Errors"
         revIDEToggle tWhich
         break
      case "Suspend Development Tools"
         revIDESuspendDevelopmentTools
         break
      case "Simulate"
         revIDEActionTest
         break
      case "Simulator Version"
         revIDESetTestTarget item 2 of pWhich
         break
      case "Object Library"
         go cd 1 of stack "revImageLibrary" as modeless
         lock messages
         set the menuHistory of btn "tabs" of stack "RevImageLibrary" to 1
         unlock messages
         break
      case "Image Library"
         go cd 2 of stack "revImageLibrary" as modeless
         lock messages
         set the menuHistory of btn "tabs" of stack "RevImageLibrary" to 2
         unlock messages
         break
      case "Plugins"
         local tPicked
         set the itemDel to "|"
         put item 2 of pWhich into tPicked
         switch tPicked
            case "Plugin Settings"
               revIDEOpenPalette "plugin preferences"
               break
               # A plugin has been selected
            default
               revIDEOpenPlugin tPicked
               break
         end switch
         break
      case "Start Profiling Scripts" 
         scriptprofilerStartProfiler the short name of the topStack
         break
      case "Stop Profiling Scripts..." 
         scriptprofilerStopProfiler
         break
   end switch
end revMenubarDevelopmentMenuPick

on revMenubarViewMenuPick pWhich
   switch pWhich
      case "Show IDE Stacks In Lists"
      case "Show Invisible Objects"
      case "Rulers"
      case "Backdrop"
      case "Grid"
         revIDEToggle pWhich
         break
      case "Go First"
         revIDEGoCard "first"
         break
      case "Go Prev"
         revIDEGoCard "prev"
         break
      case "Go Next"
         revIDEGoCard "next"
         break
      case "Go Last"
         revIDEGoCard "last"
         break
      case "Go Recent"
         revIDEGoCard "recent"
         break
      case "Toolbar Text"
      case "Toolbar Icons"
         revIDEToggleToolbar pWhich
         break
      case "Palettes"
         revIDETogglePaletteView
         break
   end switch
end revMenubarViewMenuPick

on revMenubarWindowMenuPick pWhich
   if pWhich is "Send Window To Back" then
      revIDESendCurrentWindowToBack
   else
      revIDESendWindowToFront pWhich
   end if
end revMenubarWindowMenuPick

on revMenubarHelpMenuPick pWhich
   set the itemDel to "|"
   local tPick
   put item 1 of pWhich into tPick
   switch tPick
      case "Dictionary"
         revIDEDocumentationLoad "API", "LiveCode Script"
         break
      case "Start Center"
      case "Welcome"
      case "About"
         revIDEOpenPalette tPick
         break
      case "Buy"
      case "Support"
      case "User Guide"
      case "License Agreement"
      case "Release Notes"
      case "Sample Stacks"
      case "Sample Scripts"
      case "Beginners Guide"
      case "Tutorials"
      case "Forums"
      case "Technical Questions"
      case "Discussion List"
      case "Newsletters"
         revIDELaunchResource tPick
         break
      case "All Guides"
         revIDEOpenPalette "guide"
         break
      case "Relicense"
         revIDEActionRelicense
         break
      case "Update"
         revIDECheckForUpdates
         break
   end switch
end revMenubarHelpMenuPick
