script "revMenubarUI"
on preOpenStack
   set the decorations of me to empty
   set the resizable of me to false
   set the height of me to 47
   
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
   set the textalign of the templatefield to right
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
      set the topleft of field "label" of group "tutorial" of me to 10, 10
      
      set the backcolor of graphic "Trough" of group "progress" of me to revTutorialMessageAltColor()
      set the rect of graphic "Trough" of group "progress" of me to 0, 0, 100, 5
      set the rect of graphic "Bar" of group "progress" of me to 0, 0, revTutorialDoneRatio() * 100, 5
      set the loc of group "progress" of me to the loc of field "label" of me
      set the top of group "progress" of me to 35
      
      set the topleft of group "tutorial" of me to tLeft, 0
      add the formattedWidth of group "tutorial" of me to tLeft
   else
      hide tLastDivide
      hide group "tutorial" of me
   end if
   
   set the width of me to tLeft
   set the topleft of me to the topleft of stack "revMenuBar"
   updateButtonState
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
      put revMenubarButtonNameToOldButtonName(tTarget) into tOriginButton
      send "mouseUp" to button tOriginButton of stack "revMenuBar"
      layoutMenu
   end if
   unlock screen
end mouseUp

on mouseDown
end mouseDown
