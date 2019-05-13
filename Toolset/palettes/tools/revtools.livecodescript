script "revTools"
constant BLOCK_SIZE = 20

constant kToolsColumnCountDefault = 3
on preOpenStack
   dispatch "setAsBehavior" to revIDEFrameBehavior() with the long id of me
   
   set the title of me to "Tools"
   
   # Preferences
   if revIDEGetPreference("revTools_columns") is not a number then revIDESetPreference "revTools_columns", kToolsColumnCountDefault
   addFrameItem "revTools_columns", "header", "preference", "View Columns", "enum","2,3,4", "framePreferenceSelected", the long id of me
   addFrameItem "add_widget","header", "action", "Find More Widgets", "plus", "plus","findMoreWidgets", the long id of me
   
   # Look at the preference setting and validate the entries against the tool data
   local tAllViewList, tObjectData
   put objectTypes() into tObjectData
   repeat for each key tKey in tObjectData
      put tObjectData[tKey]["name"] & comma after tAllViewList
   end repeat
   delete the last char of tAllViewList
   
   local tObjectViewsPreferenceSetting, tObjectViewsToShow
   put revIDEGetPreference("revTools_show") into tObjectViewsPreferenceSetting
   
   # AL-2015-03-13: [[ Bug 14934 ]] Ensure empty preference results in all tools showing in the palette
   if tObjectViewsPreferenceSetting is empty then
      put tAllViewList into tObjectViewsToShow
   else
      repeat for each item tView in tObjectViewsPreferenceSetting
         if tView is among the items of tAllViewList then
            if tObjectViewsToShow is empty then
               put tView into tObjectViewsToShow
            else 
               put comma & tView after tObjectViewsToShow
            end if
         end if
      end repeat
   end if
   
   # Set the preference in the frame
   if tObjectViewsToShow is not tObjectViewsPreferenceSetting then 
      revIDESetPreference "revTools_show", tObjectViewsToShow
   end if
   addFrameItem "revTools_show", "header", "preference", "Show Sections", "set","widget:Widgets Controls,classic:Classic Controls,graphic:Graphic Objects,graphictools:Graphic Tools,paint:Paint Tools", "framePreferenceSelected", the long id of me
   
   ### Properties
   set the resizable of me to false
   
   # Ensure paint defaults are set
   reset paint
   set the filled to true
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
   revIDESubscribe "idePreferenceOfSetChanged"
   revIDESubscribe "ideToolChanged"
   revIDESubscribe "ideExtensionsChanged"
end registerForMessages

on findMoreWidgets
    lock screen
    revIDEFindMoreWidgets
    unlock screen
 end findMoreWidgets
 
on ideExtensionsChanged
   lock screen
   generatePalette
   layoutPalette
   unlock screen
end ideExtensionsChanged

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

on idePreferenceOfSetChanged pSet, pPreference
   switch pPreference
      case "uservisible"
         -- Regenerate tools palette after visible of widget changed
         generatePalette
         resizeStack
         break
   end switch
end idePreferenceOfSetChanged

constant kPolygonMenu = "Rectangle Tool\nRounded Rectangle Tool\nOval Tool\nRegular Polygon Tool\nPolygon Tool"
on ideToolChanged
   local tTool
   put the tool into tTool
   set the itemdelimiter to "\n"
   if tTool is among the items of kPolygonMenu then
      put "paint polygon shape tool" into tTool
   end if
   
   local tControlID
   repeat with x = 1 to the number of controls of group "contents"
      put the long id of control x of group "contents" into tControlID
      if the cToolName of tControlID is tTool then
         if tTool is "graphic tool" and the style of the templategraphic is not the cStyle of tControlID then
            next repeat
         end if
         set the loc of graphic "tool_hilite" of group "contents" to the loc of tControlID
         show graphic "tool_hilite" of group "contents" 
         exit ideToolChanged
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
         local tCurrentPreferenceValue, tPreferencePosition, tItemOffset
         put revIDEGetPreference("revTools_show") into tCurrentPreferenceValue
         put itemOffset(pValue, tCurrentPreferenceValue) into tItemOffset
         if tItemOffset is not 0 then
            delete item tItemOffset of tCurrentPreferenceValue
         else
            if tCurrentPreferenceValue is empty then
               put pValue into tCurrentPreferenceValue
            else
               put comma & pValue after tCurrentPreferenceValue
            end if
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

constant kNoSeparatorSections = "runedit,graphictoolscontrols,paintcontrols"
on generatePalette
   lock screen
   # Clean up existing UI
   repeat while there is a group "contents"
      delete group "contents"
   end repeat
   reset the templateGroup
   create group "contents"
   
   # Clear the error group
   if there is a group "errors" then delete group "errors"
   
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
            put revIDEWidgets() into sViewsData["widget"]
            break
         case "classic"
            put revIDEClassicControls() into sViewsData["classic"]
            break
         case "graphic"
            put revIDEGraphics() into sViewsData["graphic"]
            break 
         case "graphictools"
            put revIDEGraphicTools() into sViewsData["graphictools"]
            put revIDEGraphicToolControllers() into sViewsData["graphictoolscontrols"]
            break 
         case "paint"
            put revIDEPaintTools() into sViewsData["paint"]
            put revIDEPaintToolControllers() into sViewsData["paintcontrols"]
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
   set the showname of the templatebutton to false
   set the style of the templatebutton to "transparent"
   
   set the threed of the templatebutton to false
   set the borderwidth of the templatebutton to 0
   set the blendlevel of the templatebutton to 0
   
   # Set up the template graphic
   set the opaque of the templategraphic to true
   set the visible of the templategraphic to false
   set the linesize of the templategraphic to 0
   set the width of the templategraphic to BLOCK_SIZE
   set the height of the templategraphic to BLOCK_SIZE
   set the backgroundcolor of the templategraphic to revIDEColor("edition_color")
   
   # Create hilite and hover graphic for tools
   create graphic "tool_hover" in group "contents"
   set the backgroundcolor of the templategraphic to "175,175,175"
   create graphic "tool_hilite" in group "contents"
   
   set the visible of the templategraphic to true
   set the height of the templategraphic to 1
   set the backgroundcolor of the templategraphic to "200,200,200"
   
   set the itemdel to "."
   create group "images" in group "contents"
   
   repeat for each key tView in sViewsData
      if the number of elements of sViewsData[tView] is 0 then next repeat
      
      local tOrder
      put the keys of sViewsData[tView] into tOrder
      if tView is "widget" then
         # AL-2015-05-26: [[ Bug 14561 ]] Order extensions alphabetically
         sort tOrder by sViewsData[tView][each]["title"]
      else
         # Get a list of the ordered keys
         sort lines tOrder numeric ascending by sViewsData[tView][each]["order"]
      end if
      
      # Create the group to hold the controls
      create group tView in group "contents" 
      
      set the itemdel to ","
      if tView is not among the items of kNoSeparatorSections then
         create graphic tView in group "contents"
      end if
      
      repeat for each line tControlTypeID in tOrder
         # AL-2015-09-07: Don't show objects in tools palette if specified
         if sViewsData[tView][tControlTypeID]["userVisible"] is false then
            next repeat
         end if
         
         set the itemdel to ","
         put item 1 of tControlTypeID into tControlTypeID
         set the itemdel to "."
         
         # Setup the default button
         set the name of the templatebutton to the last item of tControlTypeID
         set the cType of the templatebutton to tView
         set the cStyle of the templatebutton to sViewsData[tView][tControlTypeID]["properties"]["style"]["default"]
         set the cName of the templatebutton to sViewsData[tView][tControlTypeID]["properties"]["name"]["default"]
         set the cStatus of the templatebutton to sViewsData[tView][tControlTypeID]["status"]
         
         if sViewsData[tView][tControlTypeID]["status"] is "error" then
            # Create a group to store the error icons
            if there is not a group "errors" of group "contents" then create group "errors" in group "contents"
            
            set the filename of the templateimage to revIDESpecialFolderPath("Toolset") & "/resources/supporting_files/images/warning.png"
            set the name of the templateimage to tControlTypeID
            set the visible of the templateimage to true
            create image in group "errors" of group "contents"
            set the id of it to revIDENewIconID()
         end if
         
         local tImageID, tFilename
         if sViewsData[tView][tControlTypeID]["icon"] is not empty then 
            put sViewsData[tView][tControlTypeID]["icon"] into tFilename
         else if there is a file (tThemePath & slash & tControlTypeID & ".icon.png") then 
            put tThemePath & slash & tControlTypeID & ".icon.png" into tFilename
         else
            put revIDEDefaultExtensionIcon("widget") into tFilename
         end if
         set the name of the templateimage to tControlTypeID & ".icon.png"
         set the visible of the templateimage to false
         set the filename of the templateimage to tFilename
         create image in group "images" of group "contents"
         set the id of it to revIDENewIconID()
         put the long id of image (tControlTypeID & ".icon.png") of group "images" of group "contents" into tImageID
         revIDEResizeImageInBounds tImageID, BLOCK_SIZE * 2,BLOCK_SIZE
         set the icon of the templatebutton to the ID of tImageID
         
         # If the object is a tool, set the key custom properties to make it behave like a tool
         local tToolType
         put sViewsData[tView][tControlTypeID]["type"] into tToolType
         switch tToolType
            case "tool"
            case "option"
            case "paint tool"
               set the cTool of the templatebutton to tToolType
               set the cToolName of the templatebutton to sViewsData[tView][tControlTypeID]["tool"]
               break
            case "graphic tool"
               set the cTool of the templatebutton to tToolType
               set the cToolName of the templatebutton to "graphic tool"
               break
            default
               set the cTool of the templatebutton to empty
               break
         end switch
         
         local tTooltip
         put sViewsData[tView][tControlTypeID]["tooltip"] into tTooltip
         
         if tTooltip is empty then
            put sViewsData[tView][tControlTypeID]["title"] into tTooltip
         end if
         
         if tTooltip is empty then
            put item -1 of tControlTypeID into tTooltip
         end if
         
         set the tooltip of the templatebutton to tTooltip
         
         # Create the button
         if sViewsData[tView][tControlTypeID]["status"] is "error" then
            set the tooltip of the templatebutton to "There was an error while loading widget:" & return & tControlTypeID
            --set the blendlevel of the templatebutton to 50
         end if
         
         if sViewsData[tView][tControlTypeID]["svgicon"] is empty then
            create button tControlTypeID in group tView of group "contents"
            set the cType of button tControlTypeID to tView
         else
            create widget tControlTypeID as "com.livecode.widget.svgpath" in group tView of group "contents"
            set the width of widget tControlTypeID to BLOCK_SIZE * 2
            set the height of widget tControlTypeID to BLOCK_SIZE
            set the foregroundColor of widget tControlTypeID to 100,100,100
            set the iconpath of widget tControlTypeID to sViewsData[tView][tControlTypeID]["svgicon"]
            set the cType of widget tControlTypeID to tView
            set the cStyle of widget tControlTypeID to sViewsData[tView][tControlTypeID]["properties"]["style"]["default"]
            set the cName of widget tControlTypeID to sViewsData[tView][tControlTypeID]["properties"]["name"]["default"]
            set the cStatus of widget tControlTypeID to sViewsData[tView][tControlTypeID]["status"]
            set the cTool of widget tControlTypeID to empty
            set the tooltip of widget tControlTypeID to tTooltip
         end if
      end repeat
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
   local tContentRect, tWidth, tPaletteMargin, tPalettePadding, tHeaderHeight
   put the paletteMargin of me into tPaletteMargin
   put the palettePadding of me into tPalettePadding
   put the contentrect of me into tContentRect
   # AL-2015-03-20: [[ Bug 14911 ]] Get the headerHeight with messages unlocked
   put the headerHeight of me into tHeaderHeight
   
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
      
      # Check if the group of object type exists
      put tObjectTypeData[x]["name"] into tView
      if there is not a group tView of group "contents" then next repeat
      put tView into tLastView
      
      set the itemdel to ","
      if tView is not among the items of kNoSeparatorSections then        
         set the top of graphic tView of group "contents" to tTop
         set the width of graphic tView of group "contents" to tWidth - (tPadding * 2)
         set the left of graphic tView of group "contents" to tLeft
         add tPaletteMargin to tTop
      end if
      
      repeat with y = 1 to the number of controls of group tView of group "contents"
         # Get the short name of the object
         local tObjectID, tObjectName
         put the long id of control y of group tView of group "contents" into tObjectID
         put the short name of tObjectID into tObjectName
         
         set the width of tObjectID to tBlockSize
         set the topleft of tObjectID to tLeft, tTop
         put the right of tObjectID + (tPadding * 2) into tLeft
         
         # Check if there is an error icon
         if there is an image tObjectName of group "errors" of group "contents" then
            set the topright of image tObjectName of group "errors" of group "contents" to the topright of tObjectID
         end if
         
         if tLeft >= the width of me - tPaletteMargin - 5 then
            put tPaletteMargin  into tLeft
            add BLOCK_SIZE + (tPalettePadding) to tTop
         end if
      end repeat
      put the bottom of tObjectID + tPaletteMargin into tTop
   end repeat
   
   reset the templatebutton
   
   set the rect of me to tStackLeft, the top of me, tStackLeft+tStackWidth, tTop + the top of me
   
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
   
   put "graphictoolscontrols" into tData[6]["name"]
   put 10 into tData[6]["block size"]
   
   put "paint" into tData[7]["name"]
   put 10 into tData[7]["block size"]
   
   put "paintcontrols" into tData[8]["name"]
   put 10 into tData[8]["block size"]
   
   return tData
end objectTypes

on mouseDoubleUp
   if the mode of the topStack is not 1 or the cantModify of the topStack then  exit mouseDoubleUp
   if the cType of the target is empty then exit mouseDoubleUp
   if the cTool of the target is not empty then exit mouseDoubleUp
   
   lock screen
   local tObject
   revIDECreateObject the short name of the target, the long ID of the topStack, the loc of this cd of the topStack
   put the result into tObject
   choose pointer tool
   select tObject
   unlock screen
end mouseDoubleUp

on mouseDown pButton
   if the cType of the target is empty then exit mouseDown
   if the target is disabled then exit mouseDown
   if the cStatus of the target is "error" then
      answer "Widget could not be created because there was an error while loading it. To resolve, please go to the extension manager." 
      exit mouseDown
   end if
   switch the cTool of the target
      case "tool"
         revIDESetTool the cToolName of the target
         break
      case "graphic tool"
         revToolsConfigureTemplateGraphic the cStyle of the target, the cName of the target
         revIDESetTool the cToolName of the target
         break
      case "paint tool"
         local tTool
         put the cToolName of the target into tTool
         revToolsConfigurePaint
         revIDESetTool tTool
         
         -- Set the tool cursor
         -- The tool does not actually work without doing this
         switch tTool
            case "spray tool"
               set the spray to the spray
               break
            case "eraser tool"
               set the eraser to the eraser
               break
            case "brush tool"
               set the brush to the brush
               break
            default
               break
         end switch
         break
      case "option"
         revToolsOptionClicked pButton, the long id of the target
         break
      default
         revIDESetCursor "com.livecode.cursor.grabclose"
         break
   end switch
   if the cTool of the target is not empty then 
      exit mouseDown
   end if
   
   reset the templategraphic
   
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
   unlock messages
   
   local tTarget, tObjectTypeID, tToolsStackID
   put the long ID of the target into tTarget
   put the short name of the target into tObjectTypeID
   put the long ID of this stack into tToolsStackID
   
   # Generate the drag stack
   lock screen
   lock messages
   
   reset the templatestack
   set the name of the templateStack to "revDragControl"
   set the visible of the templateStack to false
   set the backGroundColor of the templateStack to the hiliteColor
   set the decorations of the templateStack to "noShadow"
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
   
   set the width of this stack to the width of tControlLongID
   set the height of this stack to the height of tControlLongID
   set the topleft of tControlLongID to 0,0
   
   # AL-2015-09-25: [[ Bug 16025 ]] Use the actual created dg rather than snapshot
   if tObjectTypeID is not "com.livecode.interface.classic.datagrid" then
      # Create the image for the windowshape
      set the visible of the templateimage to false
      import snapshot from rect (the rect of tControlLongID) of tControlLongID
      reset the templateimage
      
      set the windowshape of this stack to the ID of image 1
      set the rect of this stack to the rect of image 1
   end if
   unlock messages
   unlock screen
   
   # AL-2015-03-26: [[ Bug 14892 ]] Simply set the visible of the revDragControl stack to true
   set the loc of this stack to the screenmouseloc
   show this stack
   
   # Let the user drag around
   local tValidDropStacks
   local tStackList,tStackName,tStackCount
   put revIDEEditableStacks() into tStackList
   put 1 into tStackCount
   repeat for each line tStackName in tStackList
      if tStackName begins with "revDataViewControl" then next repeat
      if tStackName is "revDragControl" then next repeat
      put the long ID of stack tStackName into tValidDropStacks[tStackCount]["long id"]
      put the rect of stack tStackName into tValidDropStacks[tStackCount]["rect"]
      add 1 to tStackCount
   end repeat
   
   local tTargetStack, tTargetStackIndex, tScreenmouseloc
   repeat while the mouse is down
      // Tickle the event queue to ensure screenmouseloc is always updated
      wait for 0
      put the screenmouseloc into tScreenmouseloc
      set the loc of this stack to tScreenmouseloc
      
      if tTargetStack is empty then
         # Find target to drop onto
         local tStackKeys, tStackID
         repeat with x = 1 to the number of elements in tValidDropStacks
            put tValidDropStacks[x]["long id"] into tStackID
            if tScreenmouseloc is within tValidDropStacks[x]["rect"] then
               put tStackID into tTargetStack
               put x into tTargetStackIndex
               # BB 18/2/2015 [[ Bug 14627 ]] - Part 1 - Removed the old way of highlighting the target stack
               __hiliteAdd tTargetStack
               exit repeat
            end if
         end repeat
      else
         if tScreenmouseloc is not within tValidDropStacks[x]["rect"] then
            put empty into tTargetStack
            put empty into tTargetStackIndex
            __hiliteRemove
         end if
      end if
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
   
   # Check if mouse up occurred over a valid drop stack
   local tLeft, tTop, tCreateObjectID
   repeat with x = 1 to the number of elements in tValidDropStacks
      if tDropScreenLocation is within tValidDropStacks[x]["rect"] then
         put item 1 of tDropScreenLocation - item 1 of tValidDropStacks[x]["rect"] into tLeft
         put item 2 of tDropScreenLocation - item 2 of tValidDropStacks[x]["rect"] into tTop
         
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
   if the cDisabled of the target is true then exit mouseEnter
   if word 1 of the target is "widget" then
      revIDESetCursor "com.livecode.cursor.grab"
      set the foregroundColor of the target to revIDEColor("edition_color")
   else if the cTool of the target is empty and the cStatus of the target is not "error" then 
      # We are hovering over a draggable item
      revIDESetCursor "com.livecode.cursor.grab"
      set the coloroverlay["opacity"] of the target to "50"
      set the coloroverlay["color"] of the target to "0,0,0"
   else if the cStatus of the target is "error" then
      # Not working on windows.. get the egg timer so disabling for now
      --revIDESetCursor "help"
   else if the cTool of the target is not empty then
      # We are hovering over a tool
      set the loc of graphic "tool_hover" of group "contents" to the loc of the target
      show graphic "tool_hover" of group "contents" 
   end if
end mouseEnter

on mouseLeave
   if the cDisabled of the target is true then exit mouseLeave
   try
      if word 1 of the target is "widget" then
         set the foregroundColor of the target to "100,100,100"
      else
         hide graphic "tool_hover" of group "contents" 
         if the cTool of the target is empty then
            set the coloroverlay of the target to empty
         end if
      end if
   end try
   revIDEResetCursor
end mouseLeave

on dragEnter
   set the dragAction to "copy"
end dragEnter

on dragDrop
   revIDEInstallExtension the dragData["files"]
end dragDrop

local sHighlightedCard, sOldBGColor, sOldBGPattern
private on __hiliteAdd pStackLongID
   lock screen
   lock messages
   # Store the new card being hilited
   local tCardID
   put the long id of this card of pStackLongID into tCardID
   
   if tCardID is sHighlightedCard then 
      exit __hiliteAdd
   end if
   
   # Remove previous hilite
   if sHighlightedCard is not empty then
      __hiliteRemove
   end if
   
   put tCardID into sHighlightedCard
   put the backcolor of tCardID into sOldBGColor
   put the backPattern of tCardID into sOldBGPattern
   set the backgroundcolor of tCardID to revIDEColor("edition_color")
   
   unlock messages
   unlock screen
end __hiliteAdd

private on __hiliteRemove
   if not exists(sHighlightedCard) then 
      exit __hiliteRemove
   end if
   
   lock messages
   if sOldBGPattern is not empty then
      set the backpattern of sHighlightedCard to sOldBGPattern
   else
      set the backcolor of sHighlightedCard to sOldBGColor
   end if
   put empty into sHighlightedCard
   put empty into sOldBGColor
   put empty into sOldBGPattern
   unlock messages
end __hiliteRemove

on isolateTool pWhich
   lock screen
   disableTools
   toolEnable pWhich
   unlock screen
end isolateTool

on enableTools
   lock screen
   repeat for each item tItem in "widget,classic,graphic,graphictools,paint"
      groupDisable tItem, false
   end repeat
   toolEnable "com.livecode.tool.Browse" 
   toolEnable "com.livecode.tool.Pointer"
   unlock screen
end enableTools

on disableTools
   lock screen
   repeat for each item tItem in "widget,classic,graphic,graphictools,paint"
      groupDisable tItem, true
   end repeat
   toolDisable "com.livecode.tool.Browse" 
   toolDisable "com.livecode.tool.Pointer"
   unlock screen
end disableTools

on groupDisable pWhich, pDisable
   lock screen
   local tTools
   switch pWhich
      case "widget"
         put revIDEWidgets() into tTools
         break
      case "classic"
         put revIDEClassicControls() into tTools
         break
      case "graphic"
         put revIDEGraphics() into tTools
         break 
      case "graphictools"
         put revIDEGraphicTools() into tTools
         break 
      case "paint"
         put revIDEPaintTools() into tTools
         break
   end switch
   
   repeat for each key tKey in tTools
      if pDisable then
         toolDisable tKey
      else
         toolEnable tKey
      end if
   end repeat
   unlock screen
end groupDisable

on toolDisable pWhich
   local tIsButton
   if there is a button pWhich of me  then
      put true into tIsButton
   else if there is a widget pWhich of me then
      put false into tIsButton
   else
      exit toolDisable
   end if
   
   if tIsButton then
      set the coloroverlay["opacity"] of button pWhich of me to "90"
      set the coloroverlay["color"] of  button pWhich of me to "255,255,255"
      set the cDisabled of button pWhich of me to true
      disable button pWhich of me
   else
      set the cDisabled of widget pWhich of me to true
      set the foregroundColor of widget pWhich of me to 200,200,200
   end if
end toolDisable

on toolEnable pWhich
   local tIsButton
   if there is a button pWhich of me  then
      put true into tIsButton
   else if there is a widget pWhich of me then
      put false into tIsButton
   else
      throw "Invalid tool type" && pWhich
   end if
   if tIsButton then
      set the coloroverlay of button pWhich of me to empty
      set the cDisabled of button pWhich of me to false
      enable button pWhich of me
   else
      set the cDisabled of widget pWhich of me to false
      set the foregroundColor of widget pWhich of me to 100,100,100
   end if
end toolEnable

function absoluteRectOfObject pObject
   local tRect, tTool
   put toolObjectName(pObject) into tTool
   
   if there is a button tTool of me then
      put the rect of button tTool into tRect
   else if there is a widget tTool of me then
      put the rect of widget tTool into tRect
   end if
   return revIDERelativeRectToAbsolute(tRect, me)
end absoluteRectOfObject

on highlightObject pObject
   local tTool
   put toolObjectName(pObject) into tTool
   isolateTool tTool
end highlightObject

function toolObjectName pTool
   local tTool
   switch pTool
      case "Run Mode"
         put "com.livecode.tool.Browse" into tTool
         break
      case "Edit Mode"
         put "com.livecode.tool.Pointer" into tTool
         break
      case "Create Data Grid"
         put "com.livecode.interface.classic.DataGrid" into tTool
         break
      case "Create Label Field"
         put "com.livecode.interface.classic.LabelField" into tTool
         break
      case "Create Button"
         put "com.livecode.interface.classic.Button" into tTool
         break
      case "Create Text Area"
         put "com.livecode.interface.classic.TextArea" into tTool
         break
      case "Create Field"
         put "com.livecode.interface.classic.Field" into tTool
         break
      case "Create Combo Box"
         put "com.livecode.interface.classic.ComboBox" into tTool
         break
      case "Create Option Menu"
         put "com.livecode.interface.classic.OptionMenu" into tTool
         break
      case "Create Popup Menu"
         put "com.livecode.interface.classic.PopupMenu" into tTool
         break
      case "Create Radio Button"
         put "com.livecode.interface.classic.RadioButton" into tTool
         break
      case "Create Image"
         put "com.livecode.interface.classic.Image" into tTool
         break
      case "Create Rectangle Button"
         put "com.livecode.interface.classic.RectangleButton" into tTool
         break
      case "Create Slider"
         put "com.livecode.interface.classic.Slider" into tTool
         break
      case "Create Default Button"
         put "com.livecode.interface.classic.DefaultButton" into tTool
         break
      case "Create Scrollbar"
         put "com.livecode.interface.classic.Scrollbar" into tTool
         break
      case "Create Little Arrows"
         put "com.livecode.interface.classic.LittleArrows" into tTool
         break
      case "Create Tab Panel"
         put "com.livecode.interface.classic.TabPanel" into tTool
         break
      case "Create Checkbox"
         put "com.livecode.interface.classic.Checkbox" into tTool
         break
      case "Create Pulldown Menu"
         put "com.livecode.interface.classic.PulldownMenu" into tTool
         break
      case "Create Player"
         put "com.livecode.interface.classic.Player" into tTool
         break
      case "Create Table Field"
         put "com.livecode.interface.classic.TableField" into tTool
         break
      case "Create List Field"
         put "com.livecode.interface.classic.ListField" into tTool
         break
      case "Create Progress Bar"
         put "com.livecode.interface.classic.ProgressBar" into tTool
         break
      case "Create Regular Graphic"
         put "com.livecode.interface.classic.RegularGraphic" into tTool
         break
      case "Create Oval Graphic"
         put "com.livecode.interface.classic.OvalGraphic" into tTool
         break
      case "Create Round Rect Graphic"
         put "com.livecode.interface.classic.RoundRectGraphic" into tTool
         break
      case "Create Rectangle Graphic"
         put "com.livecode.interface.classic.RectangleGraphic" into tTool
         break
      case "Create Line Graphic"
         put "com.livecode.interface.classic.LineGraphic" into tTool
         break
      default
         # Try and resolve as a reference to a widget creation tool
         if word 1 of pTool is "Create" then
            return word 2 of pTool
         end if
   end switch
   return tTool
end toolObjectName

local sToolColors, sLineSizes, sBrushes, sPolygon, sPolygonSides
on revToolsOptionClicked pButton, pTarget
   local tToolName, tSection
   put the cToolName of the target into tToolName
   put segment 1 of tToolName into tSection
   switch tToolName
      case "paint fill color tool"
      case "paint line color tool"
      case "graphic fill color tool"
      case "graphic line color tool"
         # Popup the system color dialog
         answer color with sToolColors[tToolName]
         if the result is not "Cancel" then
            put it into sToolColors[tToolName]
            
            # We use a color overlay with the multiply blend mode
            # to just change the white part of the icon to the target color
            set the colorOverlay["color"] of pTarget to sToolColors[tToolName]
            set the colorOverlay["blendMode"] of pTarget to "multiply"
         end if
         break
      case "paint line size tool"
      case "graphic line size tool"
         revToolsPopupLineSizeMenu tToolName
         break
      case "paint polygon shape tool"
         revToolsPopupPolygonMenu tToolName
         revIDESetTool sPolygon[tToolName]
         revToolsConfigurePolygon "paint polygon sides tool"
         break
      case "paint polygon sides tool"
         revToolsPopupPolygonSidesMenu tToolName
         revToolsConfigurePolygon tToolName
         break
      case "paint brush pattern tool"
         local tBrush, tTool
         put the tool into tTool
         switch tTool
            case "eraser tool"
               put the eraser into tBrush
               break
            case "spray tool"
               put the spray into tBrush
               break
            case "brush tool"
            default
               put the brush into tBrush
         end switch
         # revBrushpopup presents the brush image options
         set the cBrushShape of stack "revBrushpopup" to tBrush
         modal stack "revBrushpopup"
         put the cBrushShape of stack "revBrushpopup" into sBrushes[tTool]
         break
   end switch
   
   if tSection is "graphic" then
      revToolsConfigureTemplateGraphicProperties
   else if tSection is "paint" then
      revToolsConfigurePaint
   end if
end revToolsOptionClicked

local sPicksA
on menuPick pWhich
   
   # Generic menuPick processing
   put pWhich into sPicksA[the cName of the target]
   
   local tText
   put the text of the target into tText
   
   # Fetch and clear the current selection
   local tCurrent
   put line lineOffset("!c",tText) of tText into tCurrent
   replace "!c" with empty in tCurrent
   
   switch the short name of the target
      case "lineSizeMenu"
         # Process line size menu pick
         if tCurrent is not a number then 
            put empty into tCurrent
         end if
         if pWhich is "Other..." then
            ask "Please enter a line size:" with tCurrent titled "Line Size" as sheet
            if it is not empty then
               put it into pWhich
            else
               put tCurrent into pWhich
            end if
         end if
         
         if pWhich is "None" then
            put 0 into pWhich
         end if
         if pWhich is a number then
            put pWhich into sLineSizes[the cName of the target]
         end if
         break
      case "polygonSidesMenu"
         # Process polygon sides menu pick
         if tCurrent is not a number then 
            put empty into tCurrent
         end if
         if pWhich is "Other..." then
            ask "Please enter a number of sides:" with tCurrent titled "Polygon Sides" as sheet
            if it is not empty then
               put it into pWhich
            else
               put tCurrent into pWhich
            end if
         end if
         if pWhich is a number and pWhich > 2 then
            put pWhich into sPolygonSides[the cName of the target]
         end if
         break
      case "polygonMenu"
         put pWhich into sPolygon[the cName of the target]
         break
   end switch
end menuPick

private command setChecked pTarget, pChecked
   local tText
   put the text of pTarget into tText
   
   replace "!c" with empty in tText
   put "!c" before line lineOffset(pChecked,tText) of tText
   set the text of pTarget to tText
end setChecked

constant kLineSizeMenu = "None\n1\n2\n3\n4\n6\n8\n10\n-\nOther..."
constant kPolygonSidesMenu = "3\n4\n5\n6\n7\n8\n9\n10\n-\nOther..."
on revToolsPopupLineSizeMenu pTarget
   revToolsPopupMenu "lineSizeMenu", pTarget, kLineSizeMenu, 1
end revToolsPopupLineSizeMenu

on revToolsPopupPolygonMenu pTarget
   revToolsPopupMenu "polygonMenu", pTarget, kPolygonMenu, "Rectangle Tool"
end revToolsPopupPolygonMenu

on revToolsPopupPolygonSidesMenu pTarget
   revToolsPopupMenu "polygonSidesMenu", pTarget, kPolygonSidesMenu, 4
end revToolsPopupPolygonSidesMenu

# Generic popup menu creation
on revToolsPopupMenu pButtonName, pTool, pMenuText, pDefault
   local tLongID
   if there is not a button pButtonName of me then
      set the style of the templatebutton to "menu"
      set the menumode of the templatebutton to "popup"
      set the visible of the templatebutton to false
      local tText
      put pMenuText into tText
      replace "\n" with return in tText
      create button pButtonName
      set the rect of it to -10,-10,-5,-5
      set the text of button pButtonName to tText
      reset the templatebutton
   end if
   
   put the long id of button pButtonName of me into tLongID
   set the cName of tLongID to pTool
   
   local tChecked
   # If there exists a previous pick for the menu, set the check mark
   # Otherwise check the default value
   if sPicksA[pTool] is not empty then
      put sPicksA[pTool] into tChecked
   else
      put pDefault into tChecked
   end if
   setChecked tLongID, tChecked
   
   popup tLongID
end revToolsPopupMenu

on revToolsConfigureTemplateGraphic pStyle, pName
   # Make sure the template graphic has the properties selected in the tools palette
   reset the templategraphic
   if pStyle is not empty then
      set the style of the templategraphic to pStyle
   end if
   if pName is not empty then
      set the name of the templategraphic to pName
   end if
   revToolsConfigureTemplateGraphicProperties
end revToolsConfigureTemplateGraphic

on revToolsConfigureTemplateGraphicProperties
   set the foreColor of the templategraphic to \ 
         sToolColors["graphic line color tool"]
   if sToolColors["graphic fill color tool"] is not empty then
      set the opaque of the templategraphic to true
      set the backColor of the templategraphic to \ 
            sToolColors["graphic fill color tool"]
   end if
   if sLineSizes["graphic line size tool"] is not empty then
      set the lineSize of the templategraphic to \ 
            sLineSizes["graphic line size tool"]
   end if
end revToolsConfigureTemplateGraphicProperties

on revToolsConfigurePaint
   # Make sure the paint properties are those selected in the tools palette
   set the penColor to sToolColors["paint line color tool"]
   set the brushColor to sToolColors["paint fill color tool"]
   
   if sLineSizes["paint line size tool"] is not empty then
      set the penWidth to sLineSizes["paint line size tool"]
   end if
   
   local tTool
   put the tool into tTool
   if sBrushes[tTool] is not empty then
      switch tTool
         case "eraser tool"
            set the eraser to sBrushes[tTool]
            break
         case "spray tool"
            set the spray to sBrushes[tTool]
            break
         case "brush tool"
            set the brush to sBrushes[tTool]
            break
      end switch
   end if
end revToolsConfigurePaint

on revToolsConfigurePolygon pTool
   if the tool is "regular polygon tool" and sPolygonSides[pTool] is not empty then
      set the polysides to sPolygonSides[pTool]
   end if
   revToolsConfigurePaint
end revToolsConfigurePolygon

on moveStack
   ideSetWindowBoundingRect
   pass moveStack
end moveStack
