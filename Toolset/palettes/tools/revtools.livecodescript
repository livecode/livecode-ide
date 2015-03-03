script "revtools"
constant BLOCK_SIZE = 20

on preOpenStack
   set the behavior of me to revIDEFrameBehavior()
   
   ### Header
   addFrameItem "add_widget","header", "action", "Find More Widgets", "f055", "f13e","findMoreWidgets", the long id of me
   
   # Preferences
   if revIDEGetPreference("revTools_columns") is not a number then revIDESetPreference "revTools_columns", 2
   addFrameItem "revTools_columns", "header", "preference", "View Columns", "enum","2,3,4", "framePreferenceSelected", the long id of me
   
   # Look at the preference setting and validate the entries against the tool data
   local tAllViewList, tObjectData
   put objectTypes() into tObjectData
   repeat for each line tKey in the keys of tObjectData
      put tObjectData[tKey]["name"] & comma after tAllViewList
   end repeat
   delete the last char of tAllViewList
   
   local tObjectViewsPreferenceSetting, tObjectViewsToShow
   put revIDEGetPreference("revTools_show") into tObjectViewsPreferenceSetting
   repeat for each item tView in tObjectViewsPreferenceSetting
      if tView is among the items of tAllViewList then
         if tObjectViewsToShow is empty then
            put tView into tObjectViewsToShow
         else 
            put comma & return after tObjectViewsToShow
         end if
      end if
   end repeat
   
   # Set the preference in the frame
   if tObjectViewsToShow is empty then revIDESetPreference "revTools_show", tAllViewList
   else if tObjectViewsToShow is not tObjectViewsToShow then revIDESetPreference "revTools_show", tObjectViewsToShow
   addFrameItem "revTools_show", "header", "preference", "Show Sections", "set","widget:Widgets Controls,classic:Classic Controls,graphic:Graphic Objects,graphictools:Graphic Tools,paint:Paint Tools", "framePreferenceSelected", the long id of me
   
   ### Properties
   
   set the resizable of me to false

   
   
   ### Create
   
end preOpenStack

on openStack
  	lock screen
   layoutpalette
   registerForMessages
   set the visible of me to true
   unlock screen
end openStack

on registerForMessages
 	### Messages
   revIDESubscribe "idePreferenceChanged:revTools_columns"
   revIDESubscribe "idePreferenceChanged:revTools_show"
   revIDESubscribe "ideToolChanged"
   revIDESubscribe "ideExtensionsChanged"
end registerForMessages

on ideExtensionsChanged
   lock screen
   generatePalette
   layoutPalette
   unlock screen
end ideExtensionsChanged

on findMoreWidgets
   lock screen
   revIDEFindMoreWidgets
   unlock screen
end findMoreWidgets

on idePreferenceChanged pPreference
   switch pPreference
      case  "revTools_columns"
         # User has changed the number of columns they want to see
         resizeStack
         break
      case "revTools_show"
         # User has changed the sections of controls they want to see in their palette
         lock screen
         generatePalette
         resizeStack
         unlock screen
         break
   end switch
end idePreferenceChanged

on ideToolChanged
   repeat with x = 1 to the number of controls of group "contents"
      if the cToolName of control x of group "contents" is empty then next repeat
      
      if the tool is "graphic tool" then 
         if the cToolName of control x of group "contents" is the tool and the style of the templategraphic is the cStyle of control x of group "contents" then
            set the loc of graphic "tool_hilite" of group "contents" to the loc of control x of group "contents"
            show graphic "tool_hilite" of group "contents" 
            exit ideToolChanged
         end if
      else
         if the cToolName of control x of group "contents" is the tool  then
            set the loc of graphic "tool_hilite" of group "contents" to the loc of control x of group "contents"
            show graphic "tool_hilite" of group "contents" 
            exit ideToolChanged
         end if
      end if
   end repeat
end ideToolChanged

on framePreferenceSelected pPreference, pValue
   switch pPreference
      case "revTools_columns"
         if pValue is not a number then exit framePreferenceSelected
         revIDESetPreference "revTools_columns", pValue
         break
      case "revTools_show"
         local tCurrentPreferenceValue, tPreferencePosition
         put revIDEGetPreference("revTools_show") into tCurrentPreferenceValue
         put itemoffset(pValue, tCurrentPreferenceValue) into tPreferencePosition
         if tPreferencePosition > 0 and item tPreferencePosition of tCurrentPreferenceValue is pValue then
            delete item tPreferencePosition of tCurrentPreferenceValue
         else
            put "," & pValue after tCurrentPreferenceValue
         end if
         revIDESetPreference "revTools_show", tCurrentPreferenceValue
         break
   end switch
end framePreferenceSelected

on resizeStack
   lock screen
   lock messages
   layoutPalette
   unlock messages
   unlock screen
end resizeStack

on generatePalette
   lock screen
   # Clean up existing UI
   repeat while there is a group "contents"
      delete group "contents"
   end repeat
   create group "contents"
   
   # Get the appropriate platform theme folder
   local tThemePath
   put revIDEThemePath() into tThemePath
   
   # Get the data used for generating the palette
   local tViews, sViewsData
   put revIDEGetPreference("revTools_show") into tViews
   
   put revIDERunEditTools() into sViewsData["runedit"]
   repeat for each item tView in tViews
      switch tView
         case "widget"
            put revIDEExtensions("","installed") into sViewsData["widget"]
            break
         case "classic"
            put revIDEClassicControls() into sViewsData["classic"]
            
            break
         case "graphic"
            put revIDEGraphics() into sViewsData["graphic"]
            break 
         case "graphictools"
            put revIDEGraphicTools() into sViewsData["graphictools"]
            break 
         case "paint"
            put revIDEPaintTools() into sViewsData["paint"]
            break
      end switch
   end repeat
   
   
   
   # Generate UI
   lock messages
   
   # Reset the templates we are going to use
   reset the templatebutton
   reset the templategraphic
   reset the templateimage
   
   # Setup the template button
   set the width of the templatebutton to BLOCK_SIZE * 2
   set the height of the templatebutton to BLOCK_SIZE
   
   # Create hilite and hover graphic for tools
   set the opaque of the templategraphic to true
   set the visible of the templategraphic to false
   set the linesize of the templategraphic to 0
   set the width of the templategraphic to BLOCK_SIZE
   set the height of the templategraphic to BLOCK_SIZE
   set the backgroundcolor of the templategraphic to revIDEColor("edition_color")
   
   create graphic "tool_hover" in group "contents"
   set the backgroundcolor of the templategraphic to "175,175,175"
   create graphic "tool_hilite" in group "contents"
   
   set the visible of the templategraphic to true
   set the height of the templategraphic to 1
   set the backgroundcolor of the templategraphic to "200,200,200"
   
   set the itemdel to "."
   create group "images" in group "contents"
   
   
   repeat for each line tView in the keys of sViewsData
      if the number of elements of sViewsData[tView] is 0 then next repeat
      
      # Get a list of the ordered keys
      set the itemdel to ","
      local tOrder
      put empty into tOrder
      repeat for each line tObjectID in the keys of sViewsData[tView]
         put tObjectID & comma & sViewsData[tView][tObjectID]["order"] & return after tOrder
      end repeat
      delete the last char of tOrder
      sort lines tOrder numeric ascending by item 2 of each
      set the itemdel to "."
      
      # Create the group to hold the controls
      create group tView in group "contents" 
      repeat for each line tControlTypeID in tOrder
         if tControlTypeID is a number then
            
            end if
         set the itemdel to ","
         put item 1 of tControlTypeID into tControlTypeID
         set the itemdel to "."
         
         # Setup the default button
         set the showname of the templatebutton to false
         set the name of the templatebutton to the last item of tControlTypeID
         set the style of the templatebutton to "transparent"
         
         set the tooltip of the templatebutton to sViewsData[tView][tControlTypeID]["tooltip"]
         
         set the icongravity of the templatebutton to "top"
         set the threed of the templatebutton to false
         set the borderwidth of the templatebutton to 0
         set the cType of the templatebutton to tView
         set the cStyle of the templatebutton to sViewsData[tView][tControlTypeID]["properties"]["style"]["default"]
         
         if sViewsData[tView][tControlTypeID]["icon"] is not empty then 
            set the name of the templateimage to tControlTypeID & ".icon.png"
            set the visible of the templateimage to false
            set the filename of the templateimage to sViewsData[tView][tControlTypeID]["icon"]
            create image in group "images" of group "contents"
            revIDEResizeImageInBounds the long ID of the last image, BLOCK_SIZE * 2,BLOCK_SIZE
            set the icon of the templatebutton to the ID of the last image
         else if there is a file (tThemePath & slash & tControlTypeID & ".icon.png") then 
            # If we can find an icon file in the theme, create it
            set the name of the templateimage to tControlTypeID & ".icon.png"
            set the visible of the templateimage to false
            set the filename of the templateimage to tThemePath & slash & tControlTypeID & ".icon.png"
            create image in group "images" of group "contents"
            set the icon of the templatebutton to the ID of the last image
         else 
            set the icon of the templatebutton to empty
         end if
         
         # If the object is a tool, set the key custom properties to make it behave like a tool
         if sViewsData[tView][tControlTypeID]["tool"] is not empty or sViewsData[tView][tControlTypeID]["properties"]["tool"]["label"] is not empty then
            local tToolName 
            put sViewsData[tView][tControlTypeID]["tool"] into tToolName
            if sViewsData[tView][tControlTypeID]["properties"]["tool"]["label"] is not empty then 
               put sViewsData[tView][tControlTypeID]["properties"]["tool"]["label"] into tToolName
            end if
            set the cTool of the templatebutton to true
            set the cToolName of the templatebutton to tToolName
         else
            if the tooltip of the templatebutton is empty then
               set the tooltip of the templatebutton to "Click and drag or double click to create this object"
            end if
            set the cTool of the templatebutton to false
         end if
         
         # Create the button
         create button tControlTypeID in group tView of group "contents"
      end repeat
      
      # Create the seperator
      create graphic tView in group "contents"
   end repeat
   
   
   # Reset the templates back post use
   reset the templatebutton
   reset the templategraphic
   reset the templateimage
   
   
   unlock messages
   unlock screen
end generatePalette

on layoutPalette
   lock screen
   
   if there is not a group "contents" of me then generatePalette  
   
   # Get the space that the content should fill
   unlock messages
   local tContentRect, tWidth, tPaletteMargin, tPalettePadding
   put the paletteMargin of me into tPaletteMargin
   put the palettePadding of me into tPalettePadding
   put the contentrect of me into tContentRect
   
   lock messages
   
   # Set the width based on the number of columns in the preference
   local tColumns
   put revIDEGetPreference("revTools_columns") into tColumns
   if tColumns < 2 or tColumns is not a number then put 2 into tColumns
   
   # Set the width of the palette based on number of columns in preference
   local tStackWidth, tStackLeft
   put  (tColumns * BLOCK_SIZE * 2) + (tPaletteMargin * 2) + (tPalettePadding * (tColumns - 1)) into tStackWidth
   set the maxwidth of me to tStackWidth
   set the minwidth of me to tStackWidth
   put the left of me into tStackLeft
   set the width of me to tStackWidth
   put tStackWidth - (tPaletteMargin * 2) into tWidth
   
   local tLeft,tTop, tLastView
   put item 2 of tContentRect + tPaletteMargin into tTop
   
   local tObjectTypeData, tView
   put objectTypes() into tObjectTypeData
   
   repeat with x = 1 to the number of elements of tObjectTypeData
      # Check if the group of obejct type exists
      put tObjectTypeData[x]["name"] into tView
      if there is not a group tView of group "contents" then next repeat
      put tView into tLastView
      
      # Get the column count
      local tColumnCount, tBlockSize
      if  tObjectTypeData[x]["block size"] < 20 then
         put tColumns * 2 into tColumnCount
         put BLOCK_SIZE into tBlockSize
      else
         put tColumns into tColumnCount
         put BLOCK_SIZE * 2 into tBlockSize
      end if
      
      local tPadding
      put (tWidth - (tColumnCount * tBlockSize)) / (tColumnCount *2) into tPadding
      
      put tPaletteMargin  into tLeft
      
      repeat with y = 1 to the number of controls of group tView of group "contents"
         set the width of control y of group tView of group "contents" to tBlockSize
         set the topleft of control y of group tView of group "contents" to tLeft, tTop
         put the right of control y of group tView of group "contents" + (tPadding * 2) into tLeft
         
         if tLeft >= the width of me - tPaletteMargin - 5 then
            put tPaletteMargin  into tLeft
            add BLOCK_SIZE + (tPalettePadding) to tTop
         end if
      end repeat
      
      if y > 0 then
         set the width of graphic tView of group "contents" to tWidth - (tPadding * 2)
         set the left of graphic tView of group "contents" to tPaletteMargin
         set the top of graphic tView of group "contents" to the bottom of control y of group tView of group "contents" + tPalettePadding
         
         put the bottom graphic tView of group "contents" + tPalettePadding into tTop
         put tPaletteMargin into tLeft
      end if
   end repeat
   
   # Hide the last seperator
   if there is a graphic tLastView of group "contents" then hide graphic tLastView of group "contents"
   
   reset the templatebutton
   
   set the rect of me to tStackLeft, the top of me, tStackLeft+tStackWidth, the formattedheight of group "contents" of me + the bottom of graphic "header_background" of group "background" of me + the top of me
   
   ideToolChanged
   --layoutFrame
   unlock messages
   unlock screen
end layoutPalette

function objectTypes
   local tData
   put "runedit" into tData[1]["name"]
   put 20 into tData[1]["block size"]
   
   put "widget" into tData[2]["name"]
   put 20 into tData[2]["block size"]
   
   put "classic" into tData[3]["name"]
   put 20 into tData[3]["block size"]
   
   put "graphic" into tData[4]["name"]
   put 10 into tData[4]["block size"]
   
   put "graphictools" into tData[5]["name"]
   put 10 into tData[5]["block size"]
   
   put "paint" into tData[6]["name"]
   put 10 into tData[6]["block size"]
   
   put "graphictoolcontrollers" into tData[7]["name"]
   put 10 into tData[7]["block size"]
   
   return tData
end objectTypes

on mouseDoubleUp
   if the mode of the topStack is not 1 or the cantModify of the topStack then  exit mouseDoubleUp
   if the cType of the target is empty then exit mouseDoubleUp
   if the cTool of the target is true then exit mouseDoubleUp
   
   lock screen
   local tObject
   revIDECreateObject the short name of the target, the long ID of the topStack, the loc of this cd of the topStack
   put the result into tObject
   choose pointer tool
   select tObject
   unlock screen
end mouseDoubleUp

on mouseDown
   if the cType of the target is empty then exit mouseDown
   if the cTool of the target is false then 
      revIDESetCursor "com.livecode.cursor.grabclose"
   end if
   if the cTool of the target is true then
      if the cStyle of the target is not empty then
         reset the templategraphic
         set the style of the templategraphic to the cStyle of the target
      end if
      revIDESetTool the cToolName of the target
      exit mouseDown
   end if
   
   if the tool is not "browse tool" and the tool is not "pointer tool" then 
      choose "pointer" tool
   end if
   
   lock messages
   
   # Wait until the mouse has moved a decent distance
   local tStartLoc
   put the screenMouseLoc into tStartLoc
   repeat -- check for some movement before drag
      local tNowLoc
      put the screenMouseLoc into tNowLoc
      if abs(item 1 of tNowLoc - item 1 of tStartLoc) < 8 then
         if the mouse is up then exit mouseDown
         next repeat
      else
         exit repeat
      end if
   end repeat
   
   local tTarget, tObjectTypeID, tToolsStackID
   put the long ID of the target into tTarget
   put the short name of the target into tObjectTypeID
   put the long ID of this stack into tToolsStackID
   
   # Generate the drag stack
   reset the templatestack
   set the name of the templateStack to "revDragControl"
   set the visible of the templateStack to false
   set the backGroundColor of the templateStack to the hiliteColor
   set the decorations of the templateStack to "noShadow"
   set the style of the templateStack to "palette"
   set the blendLevel of the templateStack to 25
   set the loc of the templatestack to -500,-500
   create invisible stack
   reset the templatestack
   set the defaultStack to "revDragControl"
   
   # Create a control and Generate a drag image
   revIDECreateObject tObjectTypeID, the long ID of card 1 of this stack, "0,0"
   if the result is false then exit mouseDown
   
   local tControlLongID
   put the result into tControlLongID
   set the topleft of tControlLongID to 0,0
   
   # Create the image for the windowshape
   set the visible of the templateimage to false
   import snapshot from rect (the rect of tControlLongID) of tControlLongID
   reset the templateimage
   
   set the windowshape of this stack to the ID of image 1
   set the rect of this stack to the rect of image 1
   
   close stack "revDragControl"
   show this stack
   go stack "revDragControl"
   
   # Let the user drag around
   local tExit, tCount, tValidDropStacks
   put false into tExit
   
   local tStackList,tStackName,tStackCount
   put revIDEEditableStacks() into tStackList
   put 1 into tStackCount
   repeat for each line tStackName in tStackList
      if tStackName is "ideTools" then next repeat
      if tStackName begins with  "DataViewControl" then next repeat
      put the long ID of stack tStackName into tValidDropStacks[tStackCount]["long id"]
      put the rect of stack tStackName into tValidDropStacks[tStackCount]["rect"]
      put the backgroundcolor of stack tStackName into tValidDropStacks[tStackCount]["backgroundcolor"]
      add 1 to tStackCount
   end repeat
   
   local tHighlightedStack
   repeat while tExit is false
      if tCount > 12 then
         set the loc of this stack to the screenmouseloc
         put 0 into tCount
         
         # Find target to drop onto
         local tTargetStack, tStackKeys, tStackID
         repeat with x = 1 to the number of lines of the keys of tValidDropStacks
            put tValidDropStacks[x]["long id"] into tStackID
            if the screenmouseloc is within the rect of tStackID then
               put tStackID into tTargetStack
               exit repeat
            end if
         end repeat
         
         # BB 18/2/2015 [[ Bug 14627 ]] - Part 1 - Removed the old way of highlighting the target stack
         __hiliteAdd tTargetStack
      end if
      
      if the mouse is up then put true into tExit
      add 1 to tCount
   end repeat
   
   # Change the cursor back
   revIDEResetCursor
   
   local tDropScreenLocation
   put the screenmouseloc into tDropScreenLocation
   
   # BB 18/2/2015 [[ Bug 14627 ]] - Removed the old way of unhighlighting all stacks and replaced with targetting a single stack
   # Clear any hilites
   __hiliteRemove
   
   # Delete the drag stack
   if there is a stack "revDragControl" then 
      delete stack "revDragControl"
   end if
   
   unlock messages
   
   # Check if mouse up occured over a valid drop stack
   local tLeft, tTop, tCreateObjectID
   repeat with x = 1 to the number of lines of the keys of tValidDropStacks
      if tDropScreenLocation is within the rect of tValidDropStacks[x]["long id"] then
         put item 1 of tDropScreenLocation - the left of stack tValidDropStacks[x]["long id"] into tLeft
         put item 2 of tDropScreenLocation - the top of stack tValidDropStacks[x]["long id"] into tTop
         
         set the defaultstack to tValidDropStacks[x]["long id"]
         revIDECreateObject tObjectTypeID, tValidDropStacks[x]["long id"], tLeft & comma & tTop
         put the result into tCreateObjectID
         set the defaultstack to tToolsStackID
         revIDESetTool "pointer"
         select tCreateObjectID
         exit repeat 
      end if
   end repeat
end mouseDown

on mouseEnter
   if the cType of the target is empty then exit mouseEnter
   if the cTool of the target is false then 
      # We are hovering over a draggable item
      revIDESetCursor "com.livecode.cursor.grab"
      set the coloroverlay["opacity"] of the target to "50"
      set the coloroverlay["color"] of the target to "0,0,0"
   else if the cTool of the target is true then
      # We are hovering over a tool
      set the loc of graphic "tool_hover" of group "contents" to the loc of the target
      show graphic "tool_hover" of group "contents" 
   end if
end mouseEnter

on mouseLeave
   try
      hide graphic "tool_hover" of group "contents" 
      set the coloroverlay of the target to empty
   end try
   revIDEResetCursor
end mouseLeave

on dragEnter
   set the dragAction to "copy"
end dragEnter

on dragDrop
   revIDEInstallExtension the dragData["files"]
end dragDrop

local sHighlightedStack
private on __hiliteAdd pStackLongID
   if pStackLongID is sHighlightedStack then exit __hiliteAdd
   
   lock screen
   lock messages
   # Unhighlight previously hilited stack
   __hiliteRemove
   
   # Store the new stack being hilited
   put pStackLongID into sHighlightedStack
   set the backgroundcolor of pStackLongID to revIDEColor("edition_color")
   
   unlock messages
   unlock screen
end __hiliteAdd

private on __hiliteRemove
   if not exists(sHighlightedStack) then exit __hiliteRemove
   
   lock messages
   set the backgroundcolor of sHighlightedStack to empty
   put empty into sHighlightedStack
    unlock messages
end __hiliteRemove
