script "revMenubarUI"
on preOpenStack
   if the platform is "macos" then
      set the decorations of me to empty
   end if
   set the resizable of me to false
   
   revIDESubscribe "ideSelectedObjectChanged"
   revIDESubscribe "ideTutorialProgressChanged"
   generateMenu
   layoutMenu
end preOpenStack

on openStack
end openStack

on ideSelectedObjectChanged
   layoutMenu
end ideSelectedObjectChanged

on ideTutorialProgressChanged
   layoutMenu
   updateMenus
end ideTutorialProgressChanged

on generateMenu
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
   
   set the hilitedIcon of the templatebutton to 0
   set the disabledIcon of the templatebutton to 0
   
   if there is a group "tutorial" of me then
      delete group "tutorial" of me
   end if
   
   create group "tutorial"
   create group "progress" in group "tutorial" of me
   set the margins of it to 0
   set the opaque of the templateGraphic to true
   set the style of the templateGraphic to "rectangle"
   set the lineSize of the templateGraphic to 0
   create graphic "Trough" in group "Progress" of group "tutorial" of me
   create graphic "Bar" in group "Progress" of group "tutorial" of me
   set the backcolor of it to "white"
   
   create field "label" in group "tutorial" of me
   
   set the icongravity of the templatebutton to empty
   set the showname of the templatebutton to false
   create button "quit" in group "tutorial" of me
   set the width of it to 15
   set the height of it to 21
   create invisible image "quit" in group "icons" of me
   set the filename of image "quit" of me to revIDEPaletteResourcePath("images/") & "quit.png"
   set the icon of button "quit" of group "tutorial" of me to the id of image "quit" of group "icons" of me
   
   hide group "tutorial" of me
   
   reset the templategraphic
   reset the templatebutton
   reset the templateimage
   reset the templatefield
   unlock messages
end generateMenu

on layoutMenu
   lock screen
   lock messages
   send "revUpdatePalette" to group "revMenuBar" of stack "revMenuBar"
   local tDividerCount
   put 1 into tDividerCount
   
   local tLeft, tLastDivide
   put 10 into tLeft
   repeat for each item tItem in revMenubarItems()
      if tItem is "Divide" then
         local tName
         put tItem & tDividerCount into tName
         set the rect of image tName of group "menu" of me to tLeft + 4, 3, tLeft + 6, 44
         put the long id of image tName of group "menu" of me into tLastDivide
         add 1 to tDividerCount
         add 10 to tLeft
      else
         local tWidth
         set the textStyle["bold"] of button tItem of group "menu" of me to false
         put max(the formattedWidth of button tItem of group "menu" of me, 60) into tWidth
         set the rect of button tItem of group "menu" of me to tLeft, 4, tLeft + 5 + tWidth, 45
         add tWidth to tLeft
      end if
   end repeat
   
   local tTutorial
   put revIDETutorialInProgress() into tTutorial
   if tTutorial is not empty then
      show group "tutorial" of me
      show tLastDivide
      set the text of field "label" of group "tutorial" of me to "Tutorial -" && tTutorial
      set the width of field "label" of group "tutorial" of me to the formattedwidth of field "label" of group "tutorial" of me
      set the topleft of field "label" of group "tutorial" of me to 10, 10
      
      set the topleft of button "quit" of group "tutorial" of me to 10 + the width of field "label" of group "tutorial" of me, 10
      
      set the backcolor of graphic "Trough" of group "progress" of me to revTutorialMessageAltColor()
      set the rect of graphic "Trough" of group "progress" of me to 0, 0, 100, 5
      set the rect of graphic "Bar" of group "progress" of me to 0, 0, revTutorialDoneRatio() * 100, 5
      set the loc of group "progress" of me to the loc of field "label" of me
      set the top of group "progress" of me to 35
      
      set the topleft of group "tutorial" of me to tLeft, 0
      add the formattedWidth of group "tutorial" of me + 10 to tLeft
   else
      hide tLastDivide
      hide group "tutorial" of me
   end if
   
   updateButtonState
   set the width of me to tLeft
   set the height of me to 47
   if the platform is "macos" then
      local tTopLeft
      put the topleft of stack "revMenuBar" into tTopLeft
      put item 2 of tTopLeft + 3 into item 2 of tTopLeft
      set the topleft of me to tTopLeft
   end if
   unlock messages
   unlock screen
end layoutMenu

on updateButtonState
   repeat for each item tItem in revMenubarItems()
      if tItem is "Divide" then
         next repeat
      end if
      local tOriginButton
      put revMenubarButtonNameToOldButtonName(tItem) into tOriginButton
      if the enabled of button tOriginButton of stack "revMenuBar" then
         enable button tItem of group "menu" of me
         if the hilite of button tOriginButton of stack "revMenuBar" then
            set the hilite of button tItem of group "menu" of me to true
            set the textStyle["bold"] of button tItem of group "menu" of me to true
         else
            set the hilite of button tItem of group "menu" of me to false
            set the textStyle["bold"] of button tItem of group "menu" of me to false
         end if
      else
         disable button tItem of group "menu" of me
      end if
   end repeat
end updateButtonState

function revMenubarItems
   return "Inspector,Code,Message Box,Divide,Group,Edit Group,Select Grouped,Divide,Messages,Errors,Divide,Sample Stacks,Tutorials,Resources,Dictionary,Divide,Test,Divide"
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
   if the target begins with "button" then
      local tOriginButton, tTarget
      put the short name of the target into tTarget
      if tTarget is "quit" then
         answer "Are you sure you want to exit this tutorial?" with "OK" or "Cancel"
         if it is "OK" then
            revIDEStopTutorial
         end if
      else
         put revMenubarButtonNameToOldButtonName(tTarget) into tOriginButton
         send "mouseUp" to button tOriginButton of stack "revMenuBar"
         layoutMenu
      end if
   end if
   unlock screen
end mouseUp

local sMenuHighlight
function absoluteRectOfObject pObject
   local tRect
   put the rect of menu pObject into tRect
   if the platform is "macos" then
      put item 1 of tRect + 140 into item 1 of tRect
      put item 3 of tRect + 140 into item 3 of tRect
   end if
   return tRect
end absoluteRectOfObject

on highlightObject pObject
   if pObject is empty or pObject is an array then
      put pObject into sMenuHighlight
      buildMenus
   else if there is a button pObject of stack "revMenubar" then
      enable button pObject of stack "revMenubar"
   end if
   layoutMenu
end highlightObject

local sMenuState
on storeMenuState
   repeat for each line tControl in the childControlIDs of this card of stack "revMenubar"
      if the enabled of control id tControl of this card of stack "revMenubar" then
         put true into sMenuState[tControl]
      else
         put false into sMenuState[tControl]
      end if
   end repeat
end storeMenuState

on restoreMenuState
   if sMenuState is empty then
      exit restoreMenuState
   end if
   repeat for each key tID in sMenuState
      set the enabled of control id tID of this card of stack "revMenubar" to sMenuState[tID]
   end repeat
   put empty into sMenuState
end restoreMenuState

on disableMenus
   put empty into sMenuHighlight
   repeat for each line tControl in the childControlIDs of this card of stack "revMenubar"
      disable control id tControl of stack "revMenubar"
   end repeat
   highlightObject empty
end disableMenus

on updateMenus
   if revIDETutorialInProgress() is not empty then
      if sMenuState is empty then
         storeMenuState
      end if
      disableMenus
   else
      restoreMenuState
      dispatch "buildMenus" to group "revMenuBar" of stack "revMenubar"
   end if
   layoutMenu
end updateMenus
   
on buildMenus
   buildFileMenu
   buildEditMenu
end buildMenus

command buildFileMenu
   local tFile
   put "(&New Mainstack" & return after tFile
   
   put "(&New Substack" & return after tFile
   /*
   if sStep is not "stack" then
      put "(&New Substack of" && char 1 to 20 of the mainStack of the topStack & "/|New Substack" & return after tFile
   else
      put "(&New Substack" & return after tFile
   end if
   */
   put "(&Open Stack.../O" & return after tFile
   put "(Open Recent File" & return after tFile
   put revIDEGetRecentPathsAsMenu() & return after tFile
   put "(&Close/W" & return after tFile
   put "(Close and Remove From Memor&y" & return after tFile
   put "-" & return after tFile
   
   put "(Import As Control" & return after tFile
   put tab & "Image File.../>" & return after tFile
   put tab & "Audio File..." & return after tFile
   put tab & "Video File..." & return after tFile
   put tab & "Text File..." & return after tFile
   put tab & "Snapshot of Screen" & return after tFile
   put tab & "Snapshot of Selected Object" & return after tFile
   put tab & "-" & return after tFile
   put tab & "All Images in Folder..." & return after tFile
   put tab & "All Audio Files in Folder..." & return after tFile
   
   put "(New Referenced Control" & return after tFile
   put tab & "Image File..." & return after tFile
   put tab & "Quicktime-Supported File..." & return after tFile
   put tab & "-" & return after tFile
   put tab & "All Images in Folder..." & return after tFile
   put "-" & return after tFile
   
   put "(&Save/S" & return after tFile
   put "(Save &As..." & return after tFile
   put "(Move S&ubstack to File..." & return after tFile
   put "(&Revert to Saved..." & return after tFile
   put "-" & return after tFile
   
   put "(Share This Stack..." & return after tFile
   put "-" & return after tFile
   
   put"(Standalone Application Settings..." & return after tFile
   put "(Save as Standalone Application..." & return after tFile
   put "-" & return after tFile
   
   put "(P&age Setup..." & return after tFile
   put "(&Print Card.../P" & return after tFile
   put "(Print Field..." & return after tFile
   put "-" & return after tFile
   
   ## EJB 2014-08-26
   ## [[Bug 12880]]
   if the platform is "Linux" then
      put "&Quit" & return after tFile
   else
      put "E&xit" & return after tFile
   end if
   
   set the text of menu "File" to tFile
   
   if sMenuHighlight["File"] is not empty then
      set the wholematches to false
      get lineoffset(sMenuHighlight["File"], menu "File")
      enable line it of menu "File"
   end if
   enable menu "File"
end buildFileMenu

command buildEditMenu
   local tEdit
   
   local tObjectsLabel
   if word 1 of the selObj is "card" then
      put "Card" into tObjectsLabel
   else if word 1 of the selobj is not "stack" then
      put "Objects" into tObjectsLabel
   else
      put empty into tObjectsLabel
   end if
   
   local tSelectionLabel
   if the selectedImage is not empty then
      put "Image Selection" into tSelectionLabel
   else if false then
      put "Text" into tSelectionLabel
   else if true then
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
   
   put "(&Undo/Z" & return after tEdit
   put "-" & return after tEdit
   put "(Cu&t" && tSelectionLabel & "/X|cut" & return after tEdit
   put "(&Copy" && tSelectionLabel & "/C|copy" & return after tEdit
   put "(&Paste"&& tClipboardLabel & "/V|paste" & return after tEdit
   put "(Paste &Unformatted/Cmd Shift Opt V" & return after tEdit
   put "(Clea&r" && tSelectionLabel & return after tEdit
   put "-" & return after tEdit
   put "(&Duplicate" && tObjectsLabel &"/D" & return after tEdit
   put "(&Replicate..." & return after tEdit
   put "-" & return after tEdit
   put "(Select All/A" & return after tEdit
   put "(Deselect All" & return after tEdit
   put "(In&vert Selection" & return after tEdit
   put "(Select Grouped Controls" & return after tEdit
   put "(Intersected Selections" & return after tEdit
   put "-" & return after tEdit
   put "(Find and Replace.../F" & return after tEdit
   put "-" & return after tEdit
   put "(Pre&ferences" after tEdit
   
   set the text of button "Edit" of stack "revMenuBar" to tEdit
   
   if sMenuHighlight["Edit"] is not empty then
      enable menu "Edit"
      set the wholematches to false
      get lineoffset(sMenuHighlight["Edit"], menu "Edit")
      enable line it of menu "Edit"
   end if
   
end buildEditMenu
