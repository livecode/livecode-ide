script "RevDataGridLibraryBehaviorsDataGridButtonBehavior"
local sDataArray         -- Multi-dimensional array
local sIndexSequencing -- sDataArray indexes in order they should appear

local sInit -- Has control been opened once before?
local sControlIsOpen

constant kDefaultDimmedHiliteColor = "212,212,212"
constant kRowColor = "255,255,255"
constant kHeaderBkgrndStartColor = "219,219,219"
constant kHeaderBkgrndEndColor = "188,188,188"
constant kHeaderBkgrndHiliteStartColor = "194,207,221"
constant kHeaderBkgrndHiliteEndColor = "125,147,148"
constant kHeaderDividerColor = "168,168,168"
constant kHeaderDividerThreeDColor = "227,227,227"
constant kAlternateRowColor = "230,237,247"
constant kDefaultTableColWidth = 100
constant kDefaultRowHeight = 21
constant kDefaultRowColor = "255,255,255"
constant kDefaultCornerColor = "232,232,232"
constant kAlternatingRowModValue = 0 -- 0 to have first color be first, 1 to have first color be alternating color
constant kSortTypes = "text,international,numeric,datetime,system datetime"

constant kSBWidthWin = 17
constant kSBWidthMac = 15
constant kSBWidthLinux = 16

constant kErrInvalidArray = 422
constant kErrInvalidBoolean = 452
constant kErrInvalidNumber = 453
constant kErrPropDoesntExist = 456
constant kErrInvalidInteger = 354
constant kErrInvalidPoint = 355
constant kErrInvalidRect = 356
constant kErrInvalidColor = 343
constant kErrReadOnlyProp = 449
constant kErrInvalidProperty = 348
constant kErrCantFindObject = 619
constant kErrRenameErrorInDestination = 487

constant kFieldEditorName = "DataGridFieldEditor"
local sFieldEditor

local sControlOfIndexA  -- Links an index to a particular control. Used when dgProps["cache controls"] = true and drawing is not done in real time.
local sControlHeights  -- if uFixedLineHeight is true then the height of a single contorl. Otherwise an array keyed by INDEX of sDataArray.
local sFormattedHeight
local sFormattedWidth
local sControlsRequiredToFillSpace
local sHilitedIndexes   -- comma delimited list
local sFirstIndexClickedWithShiftKeyDown -- When shift clicking we need to store first index clicked on for reference
local sPendingMsgsA
local sRunningActionsA

local sIsAnimating = false
local sDeselectOnMouseUp
local sSystemA -- stores system specific settings
local sFocusLeftMe

local sDefaultDropIndicatorRect

local sDropStructure

local sLockDrawing -- todo: add set/get. When locked we don't redraw when data is created, deleted, reordered or updated.

## for tables
local sTableObjectsA

local sScrollerId
local sPollID

--------------------------------------------------------------------------------
-- DataGrid 2 Variables

local sEditMode

---

local sReorderInProgress
local sReorderControl
local sReorderStartIndex
local sReorderStartLine
local sReorderLastHoverLine
local sReorderMouseMoveInProgress
local sReorderMoveMsgId

constant sReorderMovePollRate = 30

constant kReorderDragControlBlendLevel = 30
constant kReorderDragControlGlowColor = "0,0,0"
constant kReorderDragControlGlowSize = 10
constant kReorderDragControlGlowSpread = 10

---

local sReorderScrollPollMsgID

constant kReorderScrollPollRate = 30
constant kReorderScrollPollMargin = 30
constant kReorderScollPollIncrement = 10

---

local sAnimationsA
local sAnimationsLastID
local sAnimationsPulseMsgID

constant kAnimationsPulseRate = 30
---

local sAnimationProps

constant kEditModeEnterExitDuration = 250
constant kEditModeEnterExitActionSelectControlControlEasing = "in out"
constant kEditModeEnterExitReorderControlEasing = "linear"

constant kEditModeActionControlAnimationDuration = 250
constant kEditModeActionControlAnimationEasing = "in out"

constant kReorderAnimationDuration = 250
constant kReorderAnimationEasing = "in out"

constant kReorderHomingDuration = 250
constant kReorderHomingEasing = "in out"

constant kDeleteIndexAnimationDuration = 250
constant kDeleteIndexAnimationEasing = "in out"

constant kSwipeCompleteDuration = 300
constant kSwipeCompleteEasing = "out back"

constant kSwipeReturnDuration = 500
constant kSwipeReturnEasing = "out bounce"

---

local sCustomisableControlsInitialised
local sCustomisableControlsA
local sCustomisableControlsSingletonsA
local sCustomisableControlsSingletonCopyMapA

constant kCustomisableControlNames = "edit mode action control,edit mode action select control,edit mode reorder control,left swipe control,right swipe control"
constant kCustomisableControlSingletons = "edit mode action control,left swipe control,right swipe control"

constant kEditModeReorderControlMargins = 8
constant kEditModeReorderControlWidth = 20
constant kEditModeReorderControlIcon = "reorder"
constant kEditModeReorderControlColor = "199,199,199"

constant kEditModeActionSelectControlMargins = 8
constant kEditModeActionSelectControlWidth = 15
constant kEditModeActionSelectControlIcon = "minus sign"
constant kEditModeActionSelectControlIconColor = "255,59,48"

constant kEditModeActionControlText = "Delete"
constant kEditModeActionControlTextColor = "255,255,255"
constant kEditModeActionControlBGColor = "255,59,48"
constant kEditModeActionControlWidth = 100

constant kSwipeControlWidth = 125
constant kSwipeControlBGColor = "255,59,48"
constant kSwipeControlIcon = "trash"
constant kSwipeControlIconWidth = 20
constant kSwipeControlIconColor = "255,255,255"

---

constant kEditModeEditModeReorderStarted = "EditModeReorderStarted"
constant kEditModeEditModeReorderCompleted = "EditModeReorderCompleted"
constant kMessageEditModeActionSelectControlClicked = "EditModeActionSelectControlClicked"
constant kMessageEditModeActionControlClicked = "EditModeActionControlClicked"
constant kMessageEditModeActionControlHidden = "EditModeActionControlHidden"
constant kMessageRowSwipedRight = "RowSwipedRight"
constant kMessageRowSwipedLeft = "RowSwipedLeft"
constant kMessageRowLeftSwipeControlClicked = "RowLeftSwipeControlClicked"
constant kMessageRowRightSwipeControlClicked = "RowRightSwipeControlClicked"
constant kMessageRowLeftSwipeControlHidden = "RowLeftSwipeControlHidden"
constant kMessageRowRightSwipeControlHidden = "RowRightSwipeControlHidden"

--------------------------------------------------------------------------------

--> Messages (engine)

before preopenControl
   if the target is not me then pass preopencontrol
   local isOpen
   put sControlIsOpen into isOpen
   
   try
      _Initialize
      put true into sControlIsOpen
      
      if not isOpen then
         _DrawAlternatingRows
      end if
   catch e
      put e
   end try
   
   pass preopenControl
end preopenControl


before closeControl
   if the target is not me then pass closeControl
   
   DeleteFieldEditor
   put false into sControlIsOpen
   put true into sFocusLeftMe
   
   if the environment is "mobile" then
      mobileControlDelete sScrollerId
      put empty into sScrollerId
   end if
   
   cancel sPollID
   pass closeControl
end closeControl


before newGroup
   if the target is not me then pass newGroup
   _Initialize
   pass newGroup
end newGroup

on __PollVisibility
   cancel sPollID
   if __HasMobileScroller() then
      send "__PollVisibility" to me in 300 milliseconds
      put the result into sPollID
      
      mobileControlSet sScrollerId, "visible", the effective visible of me
   end if
end __PollVisibility
 
private command _Initialize
   if not sInit then
      set the wholeMatches to true
      local theMasterRect
      put the rect of me into theMasterRect         
      
      ## Configure the DG subgroups to enable use of acceleratedRendering
      ## effectively in form mode.

      ## The top-level group must be container (this means that no adornment
      ## props must be set on the top-level group).
      set the layerMode of me to "container"

      ## The dgBackground group holds the backdrop behind the row-templates.
      ## This can be changed to static when the engine is changed so that
      ## a control is only redrawn when focused *if* it will change appearance.
      set the layerMode of control "dgBackground" of me to "dynamic"

      ## The dgListMask group holds the scrolling elements; in form view mode
      ## only the dgList subgroup is relevant. As it holds other subgroups which
      ## will hold dynamic layers it must be container.
      set the layerMode of group "dgListMask" of me to "container"

      ## The dgList group holds the replicated row template groups. As it holds
      ## dynamic layer groups it must be container.
      set the layerMode of group "dgList" of me to "container"

      ## The dgHorizontalComponents group holds the horizontal scrollbar and
      ## corner wedge. Making it dynamic means that it doesn't cause re-rendering
      ## of static layers above when it changes.
      set the layerMode of group "dgHorizontalComponents" of me to "dynamic"

      ## The dgScrollbar group holds the vertical scrollbar. Making it dynamic
      ## means that it doesn't cause re-rendering of static layers above when it
      ## changes.
      set the layerMode of scrollbar "dgScrollbar" of me to "dynamic"

      ## The following groups all relate to table mode. These are all set to
      ## static for now.
      set the layerMode of group "dgAlternatingRowsMask" of me to "static"
      set the layerMode of group "dgHighlights" of me to "static"
      set the layerMode of group "dgHeaderComponents" of me to "static"
      set the layerMode of group "dgDividers" of me to "static"

      switch the platform 
         case "Win32"
            if "registryRead" is among the items of the securityPermissions then
               put queryRegistry("HKEY_CURRENT_USER\Control Panel\Colors\HilightText") into sSystemA["hilited text color"]
               if sSystemA["hilited text color"] is not empty then
                  replace space with comma in sSystemA["hilited text color"]
               end if
               local theValue
               put queryRegistry("HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics\ScrollWidth") into theValue
               if theValue is an integer then
                  put abs(theValue/15) into sSystemA["scrollbarWidth"]
               end if
            end if
            
            break
      end switch
      
      ## Set behaviors as needed
      ## These behaviors weren't set in original template
      set the behavior of group "dgHeaderMask" of me to the long ID of button "Header Mask" of group "Behaviors" of stack _ResourceStack()
      set the behavior of group "dgList" of me to the long ID of button "dgList Message Catcher" of group "Behaviors" of stack _ResourceStack()
      
      ## Developer could have set data before control opened
      if the keys of sDataArray is empty then
         _DeleteControls
         _RestorePersistentData
      end if
      
      if the environment is not "mobile" then
         set the traversalOn of scrollbar "dgScrollbar" of me to false ## take out of tabbing
         set the traversalOn of scrollbar "dgHScrollbar" of me to false ## take out of tabbing
         set the visible of scrollbar "dgScrollbar" of me to the dgProps["show vscrollbar"] of me is not false
         
         if _ControlType() is "table" then
            set the visible of group "dgHorizontalComponents" of me to the dgProps["show hscrollbar"] of me is not false
         end if
         
         set the borderWidth of scrollbar "dgScrollbar" of me to 0 ## For Windows 2000
         set the borderWidth of scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me to 0 ## For Windows 2000
         
         _SetScrollbarWidth
      else
         _CreateMobileScroller
      end if
      
      ## Set props which didn't come with original Data Grid
      if the dgProps["header divider color"] of me is not a color then
         set the dgProps["header divider color"] of me to kHeaderDividerColor
      end if
      if the dgProps["header divider threeD color"] of me is not a color then
         set the dgProps["header divider threeD color"] of me to kHeaderDividerThreeDColor
      end if
      
      if _ControlType() is "table" then
         _table.CreateColumns
      end if
      
      _ResetTemplateFieldEditor
      
      ## Make sure rect is as it started
      lock messages
      set the rect of me to theMasterRect
      unlock messages
      
      -- Set up DataGrid 2
      DG2_ClearVars
      DG2_AnimationsInitProps
      DG2_EnsureRowChainedBehavior

      put true into sInit
   else if the environment is "mobile" then
      _CreateMobileScroller
   end if
   
   ResizeToFit
end _Initialize


private command _CreateMobileScroller
   set the visible of scrollbar "dgScrollbar" of me to false
   set the visible of scrollbar "dgHScrollbar" of me to false
   if the dgProps["show vscrollbar"] of me is not false or \
         (_ControlType() is "table" and \
         the dgProps["show hscrollbar"] of me is not false) then
      if sScrollerId is empty or sScrollerId is not among the lines of mobileControls() then
         put the long id of me into sScrollerId
         mobileControlCreate "scroller", sScrollerId
      end if
      mobileControlSet sScrollerId, "canBounce", "true"
      mobileControlSet sScrollerId, "pagingEnabled", "false"
      mobileControlSet sScrollerId, "canScrollToTop", "true"
      mobileControlSet sScrollerId, "delayTouches", "false"
      mobileControlSet sScrollerId, "canCancelTouches", "true"
      __PollVisibility
   end if
end _CreateMobileScroller


command _SetScrollbarWidth pWidth
   lock screen
   if pWidth is not an integer then
      if the dgProps["scrollbar width"] of me is an integer then
         put the dgProps["scrollbar width"] of me into pWidth
      else
         if sSystemA["scrollbarWidth"] is an integer then
            put sSystemA["scrollbarWidth"] into pWidth
         else
            if the platform is "MacOS" then
               put kSBWidthMac into pWidth
            else if the platform is "win32" then
               put kSBWidthWin into pWidth
            else
               put kSBWidthLinux into pWidth
            end if
         end if
      end if
   end if
   
   local theRectV, theRectH
   put the rect of scrollbar "dgScrollbar" of me into theRectV
   put the rect of scrollbar "dgHScrollbar" of me into theRectH
   put item 3 of theRectV - pWidth into item 1 of theRectV
   put item 4 of theRectH - pWidth into item 2 of theRectH
   
   set the rect of scrollbar "dgScrollbar" of me to theRectV
   set the rect of scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me to theRectH
   unlock screen
end _SetScrollbarWidth


before deleteGroup
    if the target is not me then pass deleteGroup
end deleteGroup
 
 
before resizeControl
    if the target is not me then return empty
    ResizeToFit
    pass resizeControl
end resizeControl


before focusIn
    ## update the hilite when focus enters control
    if sFocusLeftMe is not false then
        _UpdateHiliteColor
    end if
    
    put false into sFocusLeftMe
    pass focusIn
end focusIn


before openField
    if sFocusLeftMe is not false then
        _UpdateHiliteColor
    end if
    pass openField
end openField


before focusOut
    ## As of Rev 3.5 we don't know whether or not focus is leaving the data grid in focusOut
    ## We send a message in time and check the focusedobject in order to work around this.
    ## This is not ideal and leads to other issues as focus shifts around some UIs but it is all we have.
    send "_CheckForFocusLeavingMe" to me in 0 milliseconds
    pass focusOut
end focusOut

before closeField
    send "_CheckForFocusLeavingMe" to me in 0 seconds
    pass closeField
end closeField

before exitField
    send "_CheckForFocusLeavingMe" to me in 0 seconds
    pass exitField
end exitField


command _CheckForFocusLeavingMe
    if not sControlIsOpen then return empty
    
    if the long ID of me is not in the long ID of the focusedObject then
        ## focus left me
        put true into sFocusLeftMe
        _UpdateHiliteColor
    end if
end _CheckForFocusLeavingMe


## Store data that will be sent when user reorders row
setprop dgDragReorderData pValue
    put pValue into sDropStructure["drag drop data"]
end dgDragReorderData


getprop dgDragReorderData
    return sDropStructure["drag drop data"]
end dgDragReorderData


setprop dgDragImageIndex pIndex
   if _ControlType() is "form" then
      local theControl
      put the dgDataControlOfIndex[pIndex] of me into theControl
      if theControl is not empty then
         _CreateDragImageFromControl theControl
      end if
   else
      _CreateDragImageFromIndex pIndex
   end if
end dgDragImageIndex


setprop dgDragImageLine pLine
   if _ControlType() is "form" then
      local theControl
      put the dgDataControlOfLine[pLine] of me into theControl
      if theControl is not empty then
         _CreateDragImageFromControl theControl
      end if
   else
      _CreateDragImageFromIndex the dgIndexOfLine[pLine] of me
   end if
end dgDragImageLine


private command _CreateDragImageFromControl pControl
   if there is not a image "dgDragImage" of me then
      lock screen
      local msgsAreLocked
      put the lockMessages into msgsAreLocked
      lock messages
      reset the templateImage
      create image "dgDragImage" in me
      set the lockMessages to msgsAreLocked
      set the visible of it to false
      unlock screen
   end if
   export snapshot from pControl to image "dgDragImage" of me as PNG
   
   local theImageOffset
   set the dragImage to the ID of image "dgDragImage" of me
   put the clickH - the left of pControl & comma & \
         the clickV - the top of pControl into theImageOffset
   set the dragImageOffset to theImageOffset
end _CreateDragImageFromControl


private command _CreateDragImageFromIndex pIndex
   local theControls, theRect, theVisibleRect, msgsAreLocked
   put sTableObjectsA["columns"][ line 1 of the keys of sTableObjectsA["columns"] ]["row controls"] into theControls
   repeat for each line theControl in theControls  
      if the dgIndex of theControl is pIndex then
         put the rect of theControl into theRect
         put _VisibleDataRect() into theVisibleRect
         put item 1 of theVisibleRect into item 1 of theRect
         put item 3 of theVisibleRect into item 3 of theRect
         
         if there is not a image "dgDragImage" of me then
            lock screen
            put the lockMessages into msgsAreLocked
            lock messages
            reset the templateImage
            create image "dgDragImage" in me
            set the lockMessages to msgsAreLocked
            set the visible of it to false
            unlock screen
         end if
         
         export snapshot from rect theRect of this card to image "dgDragImage" of me as PNG
         
         set the dragImage to the ID of image "dgDragImage" of me
         
         local theImageOffset
         put the clickH - item 1 of theRect & comma & \
               the clickV - item 2 of theRect into theImageOffset
         set the dragImageOffset to theImageOffset
         
         exit repeat
      end if
   end repeat
end _CreateDragImageFromIndex


## Set to true to turn on drag indicator and announce
## if a successful drop occurs
setprop dgTrackDragReorder [pOriginatingIndex] pValue
    if there is not a group "dgDropIndicator" of me then throw "Group Drag Indicator does not exist in list group:" && the long ID of me
    
    if pValue is not sDropStructure["tracking"] then
        if pValue then
            put pOriginatingIndex into sDropStructure["originating index"]
            
            set the topLeft of group "dgDropIndicator" of me to the topLeft of group "dgList" of me
            dispatch "resizeControl" to group "dgDropIndicator" of me
            put the rect of group "dgDropIndicator" of me into sDefaultDropIndicatorRect
            insert script of button "dgTrackDragDrop" of me into front
            set the dgTargetControl of group "dgDropIndicator" of me to the long ID of me
            ## initialize index mouse is over
            dgDragMove the mouseH, the mouseV
        else
            remove script of button "dgTrackDragDrop" of me from front
            set the visible of group "dgDropIndicator" of me to false
            put empty into sDropStructure
            
            if there is a image "dgDragImage" of me then
                delete image "dgDragImage" of me
            end if
        end if
        
        put pValue is true into sDropStructure["tracking"]
    end if
end dgTrackDragReorder


on dgDragEnd
    set the dgTrackDragReorder of me to false
end dgDragEnd


on dgDragDrop
   ## Cache before we clean up
   local processTheDrop
   put the visible of group "dgDropIndicator" of me into processTheDrop
   
   local theDropStructure
   put sDropStructure into theDropStructure
   
   ## If some other control displays a dialog during dragDrop, dragMove will still be sent
   ## if the mouse moves within the dialog. We don't want to process those any longer at this point.
   set the dgTrackDragReorder of me to false 
   
   if processTheDrop then
      local theStartLine, theDroppedAfterLine, theDroppedOnLine
      put the dgLineOfIndex[ theDropStructure["originating index"] ] of me into theStartLine
      put max(0, the dgLineOfIndex[ theDropStructure["dropped after index"] ] of me) into theDroppedAfterLine
      put theDroppedAfterLine into theDroppedOnLine
      
      if theDroppedAfterLine < theStartLine then add 1 to theDroppedOnLine
      
      dispatch "DragReorderDrop" with theDropStructure["originating index"], \
            theStartLine, theDroppedOnLine
   end if
end dgDragDrop


## Sent from TrackDragDrop
on dgDragMove pMouseH,pMouseV
   ## Throttle calls to this
   if sRunningActionsA["drag move"] then return empty
   
   ## Make sure data grid control will accept drop
   if the dragSource contains the long ID of me and (the mouseControl is not empty and the long id of the mouseControl contains the long ID of me) then
      set the dragAction to "move"
   end if
   
   put true into sRunningActionsA["drag move"]
   try
      _PositionDropIndicator pMouseH,pMouseV
      
      ## We can't send messages so hang out until mouseloc changes
      repeat until (the mouseLoc is not pMouseH,pMouseV) or (mouse(1) is "up" and mouse(3) is "up")
         ## Throttle calls to redrawing
         if not sRunningActionsA["v scroll"] then
            _ListGroupDragReorderAutoScroll pMouseH,pMouseV
            _PositionDropIndicator pMouseH, pMouseV
         end if
      end repeat
   catch e
   end try
   put false into sRunningActionsA["drag move"]
end dgDragMove


private function _VisibleDataRect
   local theRect
   put the rect of group "dgListMask" of me into theRect
   if _ControlType() is "table" then
      if the visible of scrollbar "dgScrollbar" of me then 
         put the left of scrollbar "dgScrollbar" of me into item 3 of theRect
      else
         put the right of group "dgHeaderComponents" of me into item 3 of theRect
      end if
   end if
   
   return theRect
end _VisibleDataRect


private command _PositionDropIndicator pMouseH, pMouseV
   -----
   local i,theX,theY
   local index, theIndex
   local showDropIndicator, theDropIndicatorOffset
   local theControl, theControlIndex
   local theControlsToCheck
   local theCorralRect
   local theEndControl
   local theHeight
   local theSequence
   local theStartControl
   local theTargetControl
   -----
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   set the wholeMatches to true
   put false into showDropIndicator
   
   if pMouseH,pMouseV is within _VisibleDataRect() then --the rect of group "dgListMask" of me then
      put true into showDropIndicator
      
      if the mouseControl is not empty then
         if not (the long ID of the mouseControl contains the long ID of me) then
            put false into showDropIndicator ## control over the list but not part of the list
         else
            put the dgDataControl of the mouseControl into theTargetControl
            
            ## Check for drags in empty columns of tables.
            if theTargetControl is empty then
               if the target is not the name of scrollbar "dgScrollbar" of me then        
                  ## Perhaps no column in clicked area or no mouse receiving controls in column
                  repeat for each line thePotentialControl in _ListOfVisibleControls()
                     local theRect
                     put the rect of thePotentialControl into theRect
                     if pMouseV >= item 2 of theRect and pMouseV <= item 4 of theRect then
                        put the dgIndex of thePotentialControl into theIndex
                        put thePotentialControl into theTargetControl
                        exit repeat
                     end if
                  end repeat
               end if
               
               ## Still no control
               ## Assume we are below the last control
               if theTargetControl is empty then
                  put the last line of _ListOfVisibleControls() into theTargetControl ## explicitly draw on only visible controls
               end if
            end if
            
            if theTargetControl is not empty then
               
               -- put true into showDropIndicator
               
               ## Determine offset of control in list
               put _LineNoOfControlInListControls(theTargetControl, the dgColumn of theTargetControl) into theControlIndex
               -- put "ControlIndex:" && theControlIndex
               
               ## Look for next/prev control that is not filtered out
               ## Direction we look depends on position of mouse
               ## relative to Y of control
               put item 2 of the loc of theTargetControl into theY
               
               ## Look for start/end controls in our drop                
               if the dgAcceptsDrop of theTargetControl is false then
                  ## Look for next control that accepts a drop
                  put line theControlIndex to -1 of sTableObjectsA["visible row controls"] into theControlsToCheck
                  repeat for each line theControl in theControlsToCheck
                     if the dgAcceptsDrop of theControl is false then next repeat
                     else
                        put theControl into theEndControl
                        exit repeat
                     end if
                  end repeat
                  
                  ## Look for preceding control that accepts a drop
                  repeat with i = theControlIndex down to 1
                     put line i of sTableObjectsA["visible row controls"] into theControl
                     if the dgAcceptsDrop of theControl is false then next repeat
                     else
                        put theControl into theStartControl
                        exit repeat
                     end if
                  end repeat
               else
                  put theTargetControl into theStartControl
                  put theTargetControl into theEndControl
               end if
               
               ## What is height of drop area as defined by start/end controls?                
               if theStartControl is empty and theEndControl is empty then
                  ## No drop. Hide the drop indicator
                  put false into showDropIndicator
               else
                  if theStartControl is empty then put theEndControl into theStartControl
                  else if theEndControl is empty then put theStartControl into theEndControl
                  
                  put the bottom of theEndControl - the top of theStartControl into theHeight
                  if pMouseV < (the top of theStartControl + round(theHeight / 2)) then
                     ## if start/end control are same OR the mouse is above theStartControl then use
                     ## the top of control as reference
                     if theStartControl is theEndControl or pMouseV < the top of theStartControl then
                        put the top of theStartControl into theY
                        put the dgIndex of theStartControl into theIndex
                        put itemOffset(theIndex, sIndexSequencing) into theSequence
                        put max(item (theSequence - 1) of sIndexSequencing, 0) into sDropStructure["dropped after index"]
                     else
                        put the bottom of theStartControl into theY
                        put the dgIndex of theStartControl into sDropStructure["dropped after index"]
                     end if
                  else
                     ## If start/end control are same OR the mouse below theEndControl then use
                     ## bottom of control as reference
                     if theEndControl is theStartControl or pMouseV > the bottom of theEndControl then
                        put the bottom of theEndControl into theY
                        put the dgIndex of theEndControl into sDropStructure["dropped after index"]
                     else                                
                        put the top of theEndControl into theY
                        put the dgIndex of theEndControl into theIndex
                        put itemOffset(theIndex, sIndexSequencing) into theSequence
                        put max(item (theSequence - 1) of sIndexSequencing, 0) into sDropStructure["dropped after index"]
                     end if
                  end if
                  
                  ## Position drop indicator
                  put _VisibleDataRect() into theCorralRect
                  put (item 4 of sDefaultDropIndicatorRect - item 2 of sDefaultDropIndicatorRect) / 2 div 1 into theDropIndicatorOffset ## div 1 = floor
                  
                  lock screen
                  lock messages
                  put item 1 of sDefaultDropIndicatorRect into theX
                  put min(item 4 of theCorralRect, max(item 2 of theCorralRect - theDropIndicatorOffset, theY)) into theY ## don't let outside of the List group
                  put theY - theDropIndicatorOffset into theY 
                  set the topLeft of group "dgDropIndicator" of me to theX, theY
                  set the visible of group "dgDropIndicator" of me to true
                  unlock messages
                  dispatch "PositionDropIndicator" to group "dgDropIndicator" of me
                  unlock screen
               end if
            end if
         end if ## mousecontrol is part of list group control
      else
         ## mousecontrol is empty
      end if 
      
   end if ## within rect of list
   
   set the lockMessages to msgsAreLocked
   
   if not showDropIndicator then
      set the visible of group "dgDropIndicator" of me to false
   end if
end _PositionDropIndicator


private function _LineNoOfControlInListControls pControl, pColumn
    -----
    local theLineNo = 0
    local theListControl
    local i
    -----
    if _ControlType() is "form" then
        repeat for each line theListControl in sTableObjectsA["visible row controls"]       
            add 1 to i
            ## We use this technique so that the developer can have uListConrol return a child of the actual list control
            ## Useful when a record can have more than one possible view.
            if pControl ends with theListControl then
                put i into theLineNo
                exit repeat
            end if
        end repeat
     else
        local theShortID
        put the short ID of pControl into theShortID 
        repeat for each line theListControl in sTableObjectsA["columns"][ pColumn ]["row controls"]  
            add 1 to i
            ## We use this technique so that the developer can have uListConrol return a child of the actual list control
            ## Useful when a record can have more than one possible view.
            if word 3 of theListControl is theShortID then
                put i into theLineNo
                exit repeat
            end if
        end repeat
    end if
    
    return theLineNo
end _LineNoOfControlInListControls


private command _ListGroupDragReorderAutoScroll pMouseH, pMouseV
   local theMaskRect
   
   put the rect of group "dgListMask" of me into theMaskRect
   
   ## Check that mouse is within vertical space of group
   if pMouseH > item 1 of theMaskRect and pMouseH < item 3 of theMaskRect then
      local theAvailHeight, theScroll, theHotZone, theDiff
      
      put item 4 of theMaskRect - item 2 of theMaskRect into theAvailHeight
      put round(theAvailHeight * .1) into theScroll
      
      ## Decide the zone where auto scrolling will occur
      if the dgProps["fixed row height"] of me then
         put round(sControlHeights  / 2) into theHotZone
      else
         put 20 into theHotZone ## 20 is arbitrary number
      end if
      
      ## First check above
      put item 2 of theMaskRect - pMouseV into theDiff
      if theDiff > 0 and theDiff <= theHotZone then
         put theDiff * -1 into theDiff
         --            put (theHotZone - theDiff) * -1 into theDiff ## This speeds up scrolling too much
      else
         put pMouseV - item 4 of theMaskRect into theDiff
         --         put item 4 of theMaskRect - pMouseV into theDiff
         if theDiff > 0 and theDiff <= theHotZone then
            --            put (theHotZone - theDiff) into theDiff
         else
            put 0 into theDiff
         end if
      end if
      
      if abs(theDiff) > 0 and abs(theDiff) <= theHotZone then
         local theCurrentScroll
         
         ## Mouse is in a hot zone; auto scroll.
         put round((theDiff * 5) / 100 * theScroll) into theScroll
         put the dgVScroll of me into theCurrentScroll
         put theCurrentScroll + theScroll into theScroll
         _SetVScroll theScroll
      end if
   end if
end _ListGroupDragReorderAutoScroll


on scrollbarDrag pScrollValue
    if the long ID of the target is the long ID of scrollbar "dgScrollbar" of me then
        dgScrollbarDragV pScrollValue
    else if the long ID of the target is the long ID of scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me then
        dgScrollbarDragH pScrollValue
    else
        pass "scrollbarDrag"
    end if
end scrollbarDrag

 
command dgScrollbarDragV pScrollValue
    _ScrollListV pScrollValue
end dgScrollbarDragV


command dgScrollbarDragH pScrollValue
    _ScrollListH pScrollValue
end dgScrollbarDragH


before arrowKey pDirection
    dgArrowKey pDirection
    pass arrowkey
    -- if the result then pass arrowkey
end arrowKey
 
 
command dgArrowKey pDirection
   ## Look for cases where we pass arrowkey
   if the selectedField is not empty and not the lockText of the selectedField then return true
   if the dgProps["auto hilite"] of me is false then return true
   
   ## Don't let queue of key repeats build up or list might keep scrolling after user releases arrow key 
   ## Mac needs 'autokey'. Windows needs 'keyDown'.
   get flushEvents("autokey")
   get flushEvents("keyDown")
   
   local theSelectionChanged
   put false into theSelectionChanged
   
   lock screen
   
   if sHilitedIndexes is not empty then
      set the wholeMatches to true
      local thePreviouslyHilitedIndexes
      put sHilitedIndexes into thePreviouslyHilitedIndexes
      
      switch pDirection
         case "up"
            local theItemNo
            put itemOffset(item 1 of sHilitedIndexes, sIndexSequencing) into theItemNo
            
            if _IsThisModifierSetActive("shift") and the dgProps["multiple lines"] of me then
               if theItemNo > 1 then
                  local theNewIndex
                  put max(1, item (theItemNo - 1) of sIndexSequencing) into theNewIndex
                  put itemOffset(theNewIndex, thePreviouslyHilitedIndexes) into theItemNo
                  if theItemNo is 0 then
                     put comma & theNewIndex after thePreviouslyHilitedIndexes
                     set the dgHilitedIndexes of me to thePreviouslyHilitedIndexes
                     put true into theSelectionChanged
                  end if
               end if
            else
               put max(1, item (theItemNo - 1) of sIndexSequencing) into theNewIndex
               if theItemNo > 1 then
                  set the dgHilitedIndexes of me to theNewIndex
                  put true into theSelectionChanged
               else if theItemNo is 1 and sHilitedIndexes is not theNewIndex then
                  ## Case for multiple selections going all the way to top
                  set the dgHilitedIndexes of me to item 1 of sIndexSequencing 
                  put true into theSelectionChanged
               end if
            end if
            break
            
         case "down"
            put itemOffset(the last item of sHilitedIndexes, sIndexSequencing) into theItemNo       
            
            if _IsThisModifierSetActive("shift") and the dgProps["multiple lines"] of me then
               if theItemNo > 0 and theItemNo < the number of items of sIndexSequencing then
                  put item (theItemNo + 1) of sIndexSequencing into theNewIndex
                  put itemOffset(theNewIndex, thePreviouslyHilitedIndexes) into theItemNo
                  if theItemNo is 0 then
                     put comma & theNewIndex after thePreviouslyHilitedIndexes
                     put _SortIndexesSequentially(thePreviouslyHilitedIndexes) into thePreviouslyHilitedIndexes
                     put thePreviouslyHilitedIndexes into sHilitedIndexes   
                     ScrollIndexIntoView theNewIndex
                     _HiliteIndexesInVisibleControls
                     put true into theSelectionChanged
                  end if 
               end if
            else
               local theIndexCount
               put the number of items of sIndexSequencing into theIndexCount
               put item (theItemNo + 1) of sIndexSequencing into theNewIndex
               if theItemNo > 0 and theItemNo < theIndexCount then
                  set the dgHilitedIndexes of me to theNewIndex
                  put true into theSelectionChanged
               else if theItemNo is theIndexCount and sHilitedIndexes is not theNewIndex then
                  ## Case for multiple selections going all the way to bottom
                  set the dgHilitedIndexes of me to the last item of sIndexSequencing 
                  put true into theSelectionChanged
               end if
            end if
            break
      end switch
      
   else if the dgNumberOfRecords of me > 0 then
      set the dgHilitedIndexes of me to 1
   end if
   
   if theSelectionChanged then _SelectionChanged thePreviouslyHilitedIndexes
   
   unlock screen
   
   return false
end dgArrowKey
 
 
## Scrolls the group vertically when using the scroll wheel
before rawKeyDown pKeyNum
   ## exit immediately if an editable field is the target and action isn't scroll wheel.
   set the wholeMatches to true
   if word 1 of the target is "field" and not the lockText of the target and pKeyNum is not among the items of "65308,65309,65310,65311" then pass rawkeydown
   
   -- 65308 - Mouse wheel down
   -- 65309 - Mouse wheel up
   -- 65310 - Mouse wheel right
   -- 65311 - Mouse wheel left
   -- 65365 - page up
   -- 65366 - page down
   -- 65360 - home
   -- 65367 - end
   
   ## Note: Messages are locked when setting thumbpostion and we call scrolling code directly.
   ##          This is done so that scrolling works when scrollbars are hidden.
   switch pKeyNum
      case "65360"
         ## home
         if the visible of scrollbar "dgScrollbar" of me or the dgProps["scroll when vScrollbar is hidden"] of me then
            _SetVScroll 0
         end if
         break
      case "65367"
         ## end
         if the visible of scrollbar "dgScrollbar" of me or the dgProps["scroll when vScrollbar is hidden"] of me then
            _SetVScroll the endValue of scrollbar "dgScrollbar" of me
         end if
         break
      case "65365"
         ## scroll page up
         if the visible of scrollbar "dgScrollbar" of me or the dgProps["scroll when vScrollbar is hidden"] of me then
            _SetVScroll the thumbPosition of scrollbar "dgScrollbar" of me - \
                  the pageIncrement of scrollbar "dgScrollbar" of me
         end if
         break
      case "65366"
         ## scroll page down
         if the visible of scrollbar "dgScrollbar" of me or the dgProps["scroll when vScrollbar is hidden"] of me then
            _SetVScroll the thumbPosition of scrollbar "dgScrollbar" of me + \
                  the pageIncrement of scrollbar "dgScrollbar" of me
         end if
         break
      case "65309"	# scroll up
         ## mouse wheel up
         if the visible of scrollbar "dgScrollbar" of me or the dgProps["scroll when vScrollbar is hidden"] of me then
            local theAvailHeight
            put the height of group "dgListMask" of me into theAvailHeight
            
            local theScroll
            put round(theAvailHeight * .1) into theScroll
            _SetVScroll round(the thumbPosition of scrollbar "dgScrollbar" of me) - theScroll
         end if
         break
      case "65308"	# scroll down
         ## mouse wheel down
         if the visible of scrollbar "dgScrollbar" of me or the dgProps["scroll when vScrollbar is hidden"] of me then
            put the height of group "dgListMask" of me into theAvailHeight
            put round(theAvailHeight * .1) into theScroll
            _SetVScroll round(the thumbPosition of scrollbar "dgScrollbar" of me) + theScroll
         end if
         break
      case "65310"
         ## mouse wheel right
         if _ControlType() is "table" and (the visible of group "dgHorizontalComponents" of me or the dgProps["scroll when hScrollbar is hidden"] of me) then
            local theAvailWidth
            put the width of group "dgList" of me into theAvailWidth
            put round(theAvailWidth * .1) into theScroll
            _SetHScroll round(the thumbPosition of scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me) + theScroll
         end if
         break
      case "65311"
         ## mouse wheel left
         if _ControlType() is "table" and (the visible of group "dgHorizontalComponents" of me or the dgProps["scroll when hScrollbar is hidden"] of me) then
            put the width of group "dgList" of me into theAvailWidth
            put round(theAvailWidth * .1) into theScroll
            _SetHScroll round(the thumbPosition of scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me) - theScroll
         end if
         break
      default
         pass rawKeyDown
   end SWITCH
end rawKeyDown


before mouseDown pMouseBtnNum
   // Mikey-2015-05-19: [[ Bug 15387 ]] Don't send dgMouseDown on mobile on mouseUp
   if the environment is "mobile" then exit mouseDown
    dgMouseDown pMouseBtnNum
    pass mousedown
end mouseDown

// Mikey-2015-05-19: [[ Bug 15387 ]] Use touchStart for mobile
before touchStart
   dgMouseDown 1
   pass touchStart
end touchStart


getprop dgClickLine
   local theIndex
   put the dgClickIndex of me into theIndex
   if theIndex > 0 then return the dgLineOfIndex[theIndex] of me
   else return empty
end dgClickLine


getprop dgClickIndex
   ## figure out the index clicked on
   local theIndex, theControl
   put empty into theIndex
   put _RowControlClickedOn() into theControl
   
   if theControl is not empty then
      put the dgIndex of theControl into theIndex
   end if
   return theIndex
end dgClickIndex


getprop dgClickedInDataView
   ## Note that Rev doesn't report scrollbars as mousecontrol if thumb is not
   ## showing. Hence the checks for visibility and click not within of vertical scrollbar 
   ## (dglist overlaps with rect of vertical scrollbar)
   local theClickLoc
   put the clickLoc into theClickLoc
   return theClickLoc is within the rect of group "dgListMask" of me \
         and (not the visible of scrollbar "dgScrollbar" of me \
         or (the visible of scrollbar "dgScrollbar" of me and theClickLoc is not within the rect of scrollbar "dgScrollbar" of me))
end dgClickedInDataView
 
 
private function _RowControlClickedOn
   local theControl
   
   ## figure out the index clicked on
   put the dgDataControl of the target into theControl
   
   local theY, theRect
   ## Make sure user clicked in valid area.
   if theControl is empty and the dgClickedInDataView of me then
      ## Perhaps no column in clicked area or no mouse receiving controls in column
      put the clickV into theY
      repeat for each line thePotentialControl in _ListOfVisibleControls()
         put the rect of thePotentialControl into theRect
         if theY >= item 2 of theRect and theY <= item 4 of theRect then
            put thePotentialControl into theControl
            exit repeat
         end if
      end repeat
   end if
   
   return theControl
end _RowControlClickedOn 
 
 
command dgMouseDown pMouseBtnNum   
   ## figure out the index clicked on
   local theIndex, theControl
   put empty into theIndex
   put _RowControlClickedOn() into theControl   
   if theControl is not empty then
      put the dgIndex of theControl into theIndex
   end if
   
   ## Bring focus into control. Do this before any possible exit points.
   if theIndex is not empty then
      ## Clicked on a control. Bring focus into control but away from scrollbar.
      if the long ID of me is not in the long ID of the focusedObject or word 1 of the target is "scrollbar" or \
            (sFieldEditor is not empty and sFieldEditor is the long ID of the focusedObject) then
         focus on graphic "dgBackground" of me
      end if 
   else
      ## clicked in space but no on list control
      focus on graphic "dgBackground" of me
   end if
   
   if the dgProps["auto hilite"] of me is false then return empty
   
   local theSelectionChanged
   put false into theSelectionChanged
   
   local unlockTheScreen
   put true into unlockTheScreen
   
   lock screen
   set the wholeMatches to true
   
   ## Close field editor. Note: I don't think the target can ever be sFieldEditor
   if sFieldEditor is not empty and the long ID of the target is not sFieldEditor then
      DeleteFieldEditor true
   end if
   
   ## No do what we need to do
   if theIndex is not empty then
      local theHilitedIndexes, thePreviouslyHilitedIndexes
      put sHilitedIndexes into theHilitedIndexes
      put sHilitedIndexes into thePreviouslyHilitedIndexes
      
      if pMouseBtnNum is 1 then
         // Mikey-2015-05-19: [[ Bug 15240 ]] for mobile, if "multiple lines", then every tap selects/deselects a line
         if (_IsThisModifierSetActive("command") or the environment is "mobile") and the dgProps["multiple lines"] of me then
            ## Add or remove hilite
            local theItemNo
            put itemOffset(theIndex, theHilitedIndexes) into theItemNo
            if theItemNo > 0 then
               delete item theItemNo of theHilitedIndexes
            else
               put theIndex into item (the number of items of theHilitedIndexes + 1) of theHilitedIndexes
               ScrollIndexIntoView theIndex
            end if
            put _SortIndexesSequentially(theHilitedIndexes) into theHilitedIndexes
            ## At this point we want to hilite controls but not scroll them
            put theHilitedIndexes into sHilitedIndexes   
            _HiliteIndexesInVisibleControls
            put true into theSelectionChanged
            
            ## Update reference for shift clicking
            if theHilitedIndexes is empty then
               put empty into sFirstIndexClickedWithShiftKeyDown
            else if the number of items of theHilitedIndexes is 1 then
               put theIndex into sFirstIndexClickedWithShiftKeyDown
            end if
            
         else if _IsThisModifierSetActive("shift") and the dgProps["multiple lines"] of me then
            if theHilitedIndexes is empty then put theIndex into theHilitedIndexes
            
            if sFirstIndexClickedWithShiftKeyDown is empty then
               ## If no first index has been logged then index becomes first index
               put theIndex into sFirstIndexClickedWithShiftKeyDown
            end if
            
            local theIndexItemNo, theShiftKeyIndexItemNo
            put itemOffset(theIndex, sIndexSequencing) into theIndexItemNo
            put itemOffset(sFirstIndexClickedWithShiftKeyDown, sIndexSequencing) into theShiftKeyIndexItemNo
            
            if theIndexItemNo < theShiftKeyIndexItemNo then
               put item theIndexItemNo to theShiftKeyIndexItemNo of sIndexSequencing into theHilitedIndexes
            else if theIndexItemNo > theShiftKeyIndexItemNo then
               put item theShiftKeyIndexItemNo to theIndexItemNo of sIndexSequencing into theHilitedIndexes
            else
               put theIndex into theHilitedIndexes
            end if
            
            put _SortIndexesSequentially(theHilitedIndexes) into theHilitedIndexes
            put theHilitedIndexes into sHilitedIndexes   
            _HiliteIndexesInVisibleControls
            put true into theSelectionChanged
            
         else
            ## If clicking on a selected control then delay deselecting until mouseUp.
            ## This allows for drag/drop of multi controls.
            ## Only applies if not modifier is down.
            if the dgProps["multiple lines"] of me and theIndex is among the items of sHilitedIndexes and _IsThisModifierSetActive("") then
               put true into sDeselectOnMouseUp
            else
               unlock screen ## selectionChanged will be sent. Unlock so UI can update. 
               _SelectTargetControl theControl ## pass in since tables might not have control clicked on
               put false into unlockTheScreen ## Don't unlock screen at end of handler.
            end if
         end if
         
      else if pMouseBtnNum is 3 then
         ## right-click only changes selection if clicking on index that isn't highlighted
         if theIndex is not among the items of theHilitedIndexes then
            ## Same behavior as mouseclick 1
            ## single click always inserts index into first index var
            put theIndex into sFirstIndexClickedWithShiftKeyDown
            
            put theIndex into sHilitedIndexes
            _HiliteIndexesInVisibleControls
            put true into theSelectionChanged
         end if
      end if
      
      ## moved to top in 1.0.0 b4
      -- ## Clicked on a control. Bring focus into control but away from scrollbar.
      -- if the long id of me is not in the long id of the focusedobject or word 1 of the target is "scrollbar" or \
            -- (sFieldEditor is not empty and sFieldEditor is the long id of the focusedObject) then
      -- focus on graphic "dgBackground" of me
      -- end if 
   else
      ## moved to top in 1.0.0 b4
      -- ## clicked in space but no on list control
      -- focus on graphic "dgBackground" of me
   end if
   
   if unlockTheScreen then unlock screen
   
   if theSelectionChanged then _SelectionChanged thePreviouslyHilitedIndexes
end dgMouseDown


before mouseUp pMouseBtnNum
   // Mikey-2015-05-19: [[ Bug 15387 ]] Don't send dgMouseUp on mobile before mouseUp
   if the environment is "mobile" then exit mouseUp
    dgMouseUp pMouseBtnNum
    pass mouseUp
end mouseUp


// Mikey-2015-05-19: [[ Bug 15387 ]] Use touchEnd on mobile
before touchEnd
   dgMouseUp 1
   pass touchEnd
end touchEnd


on dgMouseUp pMouseBtnNum
    if sDeselectOnMouseUp then
        _SelectTargetControl
        put false into sDeselectOnMouseUp
    end if
end dgMouseUp


before mouseRelease pMouseBtnNum
    dgMouseRelease pMouseBtnNum
    pass mouseRelease
end mouseRelease


on dgMouseRelease pMouseBtnNum
    put false into sDeselectOnMouseUp
end dgMouseRelease
 
 
--> Commands (Data Manipulation)


command SelectAll
   local thePreviouslyHilitedIndexes, theOrigValue, theSelectionWasChanged
   put sHilitedIndexes into thePreviouslyHilitedIndexes
   
   put the dgProps["scroll selections into view"] of me is not false into theOrigValue
   set the dgProps["scroll selections into view"] of me to false
   try
      local theError
      
      set the dgHilitedIndexes of me to sIndexSequencing
      put the result into theSelectionWasChanged
   catch e
      put e into theError
   end try
   set the dgProps["scroll selections into view"] of me to theOrigValue
   
   if theError is not empty then throw theError
   
   if theSelectionWasChanged then
      _SelectionChanged thePreviouslyHilitedIndexes
   end if
end SelectAll


function GetDataOfIndex pIndex, pKey
    if pKey is not empty or pKey is an array then
        return sDataArray[pIndex][pKey]
    else
        return sDataArray[pIndex]
    end if
end GetDataOfIndex


command SetDataOfIndex pIndex, pKey, pValue
   repeat with i = 2 to the paramcount
      put param(i) into pKey
      if pKey is not empty or pKey is an array then
         put param(i+1) into sDataArray[pIndex][pKey]
      else
         put param(i+1) into sDataArray[pIndex]
      end if
      add 1 to i
   end repeat 
   
   _StorePersistentData
   return empty
end SetDataOfIndex


function GetDataOfLine pLine, pKey
    set the wholeMatches to true
    return GetDataOfIndex(item pLine of sIndexSequencing, pKey) 
end GetDataOfLine


command SetDataOfLine pLine, pKey, pValue
   set the wholematches to true
   
   local theIndex
   put item pLine of sIndexSequencing into theIndex
   repeat with i = 2 to the paramcount
      put param(i) into pKey
      if pKey is not empty or pKey is an array then
         put param(i+1) into sDataArray[theIndex][pKey]
      else
         put param(i+1) into sDataArray[theIndex]
      end if
      add 1 to i
   end repeat 
   
   _StorePersistentData
   return empty
end SetDataOfLine


private command _DataCanBeRepresentedAsText pBoolean
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   lock messages
   set the dgProps["data can be represented as text"] of me to pBoolean is true
   set the lockMessages to msgsAreLocked
end _DataCanBeRepresentedAsText


command EditCell pColumn, pLineNo
   local theIndex
   put the dgIndexOfLine[pLineNo] of me into theIndex
   EditCellOfIndex pColumn, theIndex
   if the result is not empty then
      return "no control exists for line column"
   else
      return empty
   end if
end EditCell


command EditCellOfIndex pColumn, pIndex
   lock screen
   ScrollIndexIntoView pIndex
   
   local theControl
   put ColumnControlOfIndex(pColumn, pIndex) into theControl
   
   if _ControlType() is "table" then _table.ScrollColumnIntoView pColumn
   
   if theControl is not empty then
      dispatch "EditValue" to theControl with pColumn
      unlock screen
      return empty
   else
      unlock screen
      return "no control exists for index column"
   end if
end EditCellOfIndex


command EditKey pKey, pLineNo
   local theIndex
   put the dgIndexOfLine[pLineNo] of me into theIndex
   EditKeyOfIndex pKey, theIndex
   if the result is not empty then
      return "no control exists for line"
   else
      return empty
   end if
end EditKey


command EditKeyOfIndex pKey, pIndex
    lock screen
    ScrollIndexIntoView pIndex
    local theControl
    put the dgDataControlOfIndex[pIndex] of me into theControl
    
    if theControl is not empty then
        dispatch "EditValue" to theControl with pKey
        unlock screen
        return empty
    else
        unlock screen
        return "no control exists for index"
    end if
end EditKeyOfIndex


## Use to add data to the data array
command AddData pDataArray, pSequence
    local theError
    local theIndex
     
    set the wholeMatches to true
     
    _DataCanBeRepresentedAsText false
     
    put item 2 of the extents of sDataArray + 1 into theIndex
    put pDataArray into sDataArray[theIndex]
     
    ## Add to list or setting sequence won't work well
    put theIndex into item (the number of items of sIndexSequencing + 1) of sIndexSequencing
     
    if pSequence is not empty then
        _SetSequenceOfIndex theIndex, pSequence
        put the result into theError
    end if
     
    if theError is empty then
        _StorePersistentData
        _ProcessNewIndexData theIndex
        _RedrawList
    else
        ## Reset
        delete item (itemOffset(theIndex, sIndexSequencing)) of sIndexSequencing
        delete local sDataArray[theIndex]
    end if
     
    if theError is empty then
        return theIndex
    else
        return theError
    end if
end AddData


command AddLine pText, pColumns, pLineNo
    -----
    local theResult
    -----
    switch _ControlType()
        case "table"
            _table.AddLine pText, pColumns, pLineNo
            break
        case "form"
        default
            _list.AddLine pText, pColumns, pLineNo
    end switch    
    put the result into theResult
     
    if theResult is an integer then
        ## Return line number
        set the wholeMatches to true
        return itemOffset(theResult, sIndexSequencing)
    else
        return theResult
    end if
end AddLine


command DeleteLine pLine
   -- Use the new DataGrid 2 animations for single deletes.
   DeleteIndex the dgIndexOfLine[pLine] of me
    return the result
end DeleteLine


command DeleteLines pLines
    -----
    local theIndexes
    local theLine
    -----
    repeat for each item theLine in pLines
        put the dgIndexOfLine [theLine] of me & comma after theIndexes
    end repeat
    delete the last char of theIndexes
    DeleteIndexes theIndexes
    return the result
end DeleteLines


command DeleteIndex pIndex
   -- Use the new DataGrid 2 animations for single deletes.
   if the dgProps["cache controls"] of me then
      -- We need to send in time here as this handler could be potentially
      -- be called from a control we are about to delete!
      send "DG2_DeleteIndex" && pIndex to me in 0 seconds
      return empty
   else
      DG2_DeleteIndex pIndex
    return the result
   end if
end DeleteIndex


command DeleteIndexes pIndexes
    -----
    local theIndex
    local theItemNo
    local theLineNo
    -----
    lock screen
    set the wholeMatches to true
     
    ## Clear out any instances of this index
    repeat for each item theIndex in pIndexes
        put itemOffset(theIndex, sHilitedIndexes) into theItemNo
        if theItemNo > 0 then
            delete item theItemNo of sHilitedIndexes
        end if
         
        ## Clear controls when cached
        if the dgProps["cache controls"] of me then
            if there is a sControlOfIndexA[theIndex] then
                ## So that all updates happen on refresh
                delete sControlOfIndexA[theIndex]
                put lineOffset(sControlOfIndexA[theIndex], sTableObjectsA["all row controls"]) into theLineNo
                if theLineNo > 0 then
                    delete line theLineNo of sTableObjectsA["all row controls"]
                    subtract 1 from sTableObjectsA["row control count"]
                end if
                put lineOffset(sControlOfIndexA[theIndex], sTableObjectsA["visible row controls"]) into theLineNo
                if theLineNo > 0 then
                    delete line theLineNo of sTableObjectsA["visible row controls"]
                end if
            end if
        end if
         
        put itemOffset(theIndex, sIndexSequencing) into theItemNo
        if theItemNo > 0 then
            delete item theItemNo of sIndexSequencing
             
            ## Update Formatted Height and UI if already calculated
            if sFormattedHeight is not empty then
                if the dgProps["fixed row height"] of me then
                    subtract sControlHeights from sFormattedHeight
                else
                    subtract sControlHeights[theIndex] from sFormattedHeight
                end if
            end if
        end if
         
        delete local sDataArray[theIndex]
    end repeat
     
    _StorePersistentData
     
    if sFormattedHeight is not empty then
        _ConfigureScrollbar
        _AutoHideVScrollbar ## only works for fixed height
    end if
     
    ## Count and position has changed. Update alternating rows.
    _DrawAlternatingRows
     
    if the keys of sDataArray is not empty then
        _RedrawList
    else
        _ResetData
    end if
     
    unlock screen
     
    return empty
end DeleteIndexes


--> Commands (Sorting)


command SortDataByKey pKey, pType, pDirection, pCaseSensitive
    -----
    local msgsAreLocked
    local theIndex
    local theData
    local theDo
    local theLine
    -----
    if pType is not among the items of kSortTypes then put "text" into pType
    if pDirection is not "descending" then put "ascending" into pDirection
     
    if pKey is empty then
        sort items of sIndexSequencing numeric ascending
    else
        ## so we get a stable sort
        repeat for each item theIndex in sIndexSequencing
            -- repeat for each key theIndex in sDataArray
            put theIndex & tab & line 1 of sDataArray[theIndex][pKey] & cr after theData
        end repeat
        delete the last char of theData
        set the itemDelimiter to tab
         
        set the caseSensitive to pCaseSensitive is true
         
        if pType is "system datetime" then
            set the useSystemDate to true
            delete word 1 of pType
        end if
         
        put "sort lines of theData" && pType && pDirection && "by item 2 to -1 of each" into theDo
        do theDo
         
        put empty into sIndexSequencing
        repeat for each line theLine in theData
            put item 1 of theLine & comma after sIndexSequencing
        end repeat
        delete the last char of sIndexSequencing
    end if
    
    _StorePersistentSequence
     
    lock screen
    _ResetIndexesOnControls
    _RedrawList
    unlock screen
    
    return empty
end SortDataByKey


## Reverses order of current sequence of data
command ReverseSort pColumn
   lock screen
   
   if sIndexSequencing is not empty then
      local theNewSequence
      repeat for each item theIndex in sIndexSequencing 
         put comma & theIndex before theNewSequence
      end repeat
      delete the first char of theNewSequence
      put theNewSequence into sIndexSequencing 
      
      _ResetIndexesOnControls
      _RedrawList
   end if
   
   if pColumn is not empty then
      HiliteAndStoreSortByColumn pColumn
   end if
   
   unlock screen
   
   return empty
end ReverseSort


command HiliteAndStoreSortByColumn pColumn
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   unlock messages
   
   lock screen
   
   local theOldSortKey
   put the dgProps["sort by column"] of me into theOldSortKey
   
   if theOldSortKey is not empty and there is a sTableObjectsA["columns"][ theOldSortKey ]["header"]["group"] then
      set the dgHilite of sTableObjectsA["columns"][ theOldSortKey ]["header"]["group"] to false
      dispatch "LayoutControl" to sTableObjectsA["columns"][ theOldSortKey ]["header"]["group"] \
            with the rect of sTableObjectsA["columns"][ theOldSortKey ]["header"]["group"] 
   end if
   
   if pColumn is not empty and there is a sTableObjectsA["columns"][ pColumn ]["header"]["group"] then
      set the dgHilite of sTableObjectsA["columns"][ pColumn ]["header"]["group"] to true
      dispatch "LayoutControl" to sTableObjectsA["columns"][ pColumn ]["header"]["group"] \
            with the rect of sTableObjectsA["columns"][ pColumn ]["header"]["group"]
   end if
   
   lock messages
   set the dgProps["sort by column"] of me to pColumn
   unlock screen
   set the lockMessages to msgsAreLocked
end HiliteAndStoreSortByColumn


## Used internally to dispatch the "SortDataGridColumn" message
private command _SortByColumn pColumn
    lock screen
    dispatch "SortDataGridColumn" to me with pColumn
    if it is not "handled" then
        SortByColumn pColumn
    end if
    unlock screen
end _SortByColumn


command SortByColumn pColumn
   if _ControlType() is not "table" then _ThrowError kErrPropDoesntExist, "only tables can be sorted by columns"
   
   local theColPropsA
   put the dgProps["column properties"] of me into theColPropsA
   
   if pColumn is not empty and pColumn is not among the keys of theColPropsA then
      _ThrowError kErrInvalidProperty, "column '" & pColumn & "' does not exist"
   end if
   
   lock screen
   
   ## sort and hilite
   SortDataByKey pColumn, theColPropsA[pColumn]["sort type"], \
         theColPropsA[pColumn]["sort direction"], theColPropsA[pColumn]["sort is case sensitive"]
   
   HiliteAndStoreSortByColumn pColumn
   
   unlock screen
   
   return empty
end SortByColumn


--> Commands (Control)

local sResizingToFit
local sResendResizeToFit


command ResizeToFit
   -----
   local theError
   local theLockLoc
   local theOffset
   local theRect
   -----
   ## Throttle just in case developer tries to call this from different timers
   if sResizingToFit then
      put true into sResendResizeToFit
      return empty
   end if
   
   put true into sResizingToFit
   
   lock screen
   put the lockloc of me into theLockLoc
   set the lockloc of me to true
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   set the lockMessages to true
   
   try ## Try so we don't leave group locked
      ## Clear cache
      put empty into sControlsRequiredToFillSpace
      
      put _WorkingGroupRect(the long ID of me) into theRect
      
      set the rect of button "dgEventCatcher" of me to theRect
      set the rect of graphic "dgBackground" of me to theRect
      
      ## Account for table elements
      if _ControlType() is "table" then
         _table.LayoutDataArea
      else
         if the environment is not "mobile" then
            if the visible of scrollbar "dgScrollbar" of me then 
               subtract the width of scrollbar "dgScrollbar" of me from item 3 of theRect
            end if
            if the visible of scrollbar "dgScrollbar" of me then
               set the rect of scrollbar "dgScrollbar" of me to item 3 of theRect, \
                     item 2 of theRect, item 3 of theRect + the width of scrollbar "dgScrollbar" of me, \
                     item 4 of theRect - the dgProps["scrollbar corner offset"] of me
            else
               set the rect of scrollbar "dgScrollbar" of me to item 3 of theRect - the width of scrollbar "dgScrollbar" of me, \
                     item 2 of theRect, item 3 of theRect, \
                     item 4 of theRect - the dgProps["scrollbar corner offset"] of me
            end if
         else if __HasMobileScroller() then
            mobileControlSet sScrollerId, "rect", theRect
         end if
         set the rect of group "dgListMask" of me to theRect
         set the rect of group "dgAlternatingRowsMask" of me to theRect
         set the topLeft of group "dgList" of me to item 1 to 2 of theRect ## Shift all children of group along with group
         set the rect of group "dgList" of me to theRect
      end if
      
      ## Redo calculations
      if the dgProps["cache controls"] of me then
         _ResizeCachedControls
      else if sFormattedHeight is empty or not the dgProps["fixed row height"] of me then
         # Only recalculate if not fixed height or formatted height hasn't been calculated
         # since teal-time drawing adjusts rect every time anyway.
         _CalculateFormattedHeight
      else
         _AutoHideVScrollbar ## only works for fixed height
      end if
      
      _ConfigureScrollbar
      _ConfigureHScrollbar
      
      _RedrawList
      
   catch e
      put e into theError
      -- put e
   finally
      set the lockloc of me to theLockLoc
   end try
   
   set the lockMessages to msgsAreLocked
   unlock screen
   
   put false into sResizingToFit
   
   if theError is not empty then throw theError
   
   if sResendResizeToFit then
      send "ResizeToFit" to me in 0 seconds
      put false into sResendResizeToFit
   end if
end ResizeToFit
 
 
private command _DrawList
   lock screen
   
   local weHaveSomethingToDraw
   put the keys of sDataArray is not empty into weHaveSomethingToDraw
   if weHaveSomethingToDraw and sFormattedHeight is empty then
      if the dgProps["cache controls"] of me then
         _CacheControls
      else
         _CalculateFormattedHeight
      end if
   end if
   
   ## Update column control cache each time drawing is specifically called
   if _ControlType() is "table" then
      _table.CacheCustomTemplateUsage
   end if
   
   if weHaveSomethingToDraw then
      _DrawListWithProperties empty, empty, true
      _DrawAlternatingRows
      _ShowAlternatingRows
      
   end if
   
   unlock screen
end _DrawList


command ResetList
   dgResetList
   return empty
end ResetList


/**
* \brief Allows developer to intercept ResetList and manually call code to reset.
*
* \return empty
*/
command dgResetList
   DG2_ClearVars

   lock screen
   
   ## For cases where user copied/pasted
   if not sInit then _Initialize
   
   local theOrigVScroll, theOrigHScroll
   put _GetVScrollPercent() into theOrigVScroll
   put _GetHScrollPercent() into theOrigHScroll
   _ResetScrollsToZero
   
   _DeleteControls
   
   _ResetInternalCaches
   
   if _ControlType() is "table" then
      _table.CreateColumns
   end if
   
   ResizeToFit
   
   _DrawAlternatingRows
   _ShowAlternatingRows
   
   _SetHScrollPercent theOrigHScroll
   _SetVScrollPercent theOrigVScroll
   unlock screen
   
   return empty
end dgResetList
 
 
command RefreshList
   if the keys of sDataArray is not empty then
      if the dgProps["cache controls"] of me then
         lock screen
         _LayoutCachedControls
         _RedrawList
         unlock screen
      else
         _ResetIndexesOnControls
         _RedrawList
      end if
      
      _HiliteIndexesInVisibleControls
   else
      _ResetData
   end if
   
   return empty
end RefreshList

 
on RefreshIndex pIndex
    _RefreshIndexes pIndex
end RefreshIndex


command RefreshLine pLine
   local theIndex
   put the dgIndexOfLine [pLine] of me into theIndex
   if theIndex > 0 then _RefreshIndexes theIndex
end RefreshLine


private command _ResetIndexesOnControls
    switch _ControlType()
        case "table"
            lock messages
            repeat for each line theColumn in the dgProps["columns"] of me
                repeat for each line theControl in sTableObjectsA["columns"][theColumn]["row controls"]
                    set the dgIndex of theControl to empty
                end repeat 
            end repeat
            unlock messages
            break
            
        case "form"
        default
            if not the dgProps["cache controls"] of me then
                lock messages
                repeat for each line theControl in sTableObjectsA["all row controls"]
                    set the dgIndex of theControl to empty
                end repeat 
                unlock messages
            end if
    end switch
end _ResetIndexesOnControls


private command _ResetControlsOfIndex pIndex
    switch _ControlType()
        case "table"
            lock messages
            repeat for each line theColumn in the dgProps["columns"] of me
                repeat for each line theControl in sTableObjectsA["columns"][theColumn]["row controls"]
                    if the dgIndex of theControl is pIndex then
                        set the dgIndex of theControl to empty
                    end if
                end repeat 
            end repeat
            unlock messages
            break
            
        case "form"
        default
            ## Cached controls aren't drawing new data into the same controls so
            ## we don't reset indexes on them.
            if not the dgProps["cache controls"] of me then
                lock messages
                repeat for each line theControl in sTableObjectsA["all row controls"]
                    if the dgIndex of theControl is pIndex then
                        set the dgIndex of theControl to empty
                    end if
                end repeat
                unlock messages
            end if
    end switch
end _ResetControlsOfIndex


private command _RedrawList pVScrollPercent
   -----
   local thePercent
   -----
   
   if the keys of sDataArray is not empty then
      if pVScrollPercent is empty then
         put _GetVScrollPercent() into pVScrollPercent
      end if
      local theVScroll
      put round(pVScrollPercent * (the endValue of scrollbar "dgScrollbar" of me - the thumbSize of scrollbar "dgScrollbar" of me)) into theVScroll
      
      if sFormattedHeight is empty then
         if the dgProps["cache controls"] of me then
            _CacheControls
         else
            _CalculateFormattedHeight
         end if
      end if
      
      _ScrollListV theVScroll, true
      _ShowAlternatingRows
   else
      _ShowAlternatingRows
   end if
   
   return empty
end _RedrawList


command ScrollLineIntoView pLine
    set the wholeMatches to true
    ScrollIndexIntoView item pLine of sIndexSequencing
end ScrollLineIntoView
 
 
command ScrollIndexIntoView pIndex
   local theError
   
   ## Work off of a 0 based rect, not actual position on card
   local theMaskHeight, theOffset, theMaskRect
   put the height of group "dgListMask" of me into theMaskHeight
   
   put the dgVScroll of me into theOffset -- round needed for engine bug
   put "0," & theOffset & ",0," & theMaskHeight + theOffset into theMaskRect
   
   local theSequence
   put the dgLineOfIndex[pIndex] of me into theSequence
   if theSequence is 0 then put "index not found" into theError
   
   local theTopOfControl, theBottomOfControl, theFormattedHeight
   if theError is empty then
      ## Determine top and bottom of control
      if the dgProps["fixed row height"] of me then
         put (theSequence - 1) * sControlHeights into theTopOfControl
         put theSequence * sControlHeights into theBottomOfControl             
      else
         ## Random sized Controls
         repeat for each item theIndex in sIndexSequencing                 
            add sControlHeights[theIndex] to theFormattedHeight
            
            if pIndex is theIndex then
               put theFormattedHeight - sControlHeights[theIndex] into theTopOfControl
               put theFormattedHeight into theBottomOfControl
               exit repeat
            end if
         end repeat
      end if
      
      ## If index is off the top then scroll to top of group
      ## else if index is off the bottom then scroll to the bottom
      
      ## We lock messages so no scrollbarDrag message is sent. scrollbarDrag may use a slight delay when
      ## drawing so that fast scrolling doesn't cue up redraws. We bypass the message
      ## and call _ScrollListV directly so that screen is updated immediately regardless of how
      ## scrollbarDrag is finally implemented.
      
      -- ======================
      local scrollTheList, theNewVScroll, theControlIsAtLeastAsTallAsMask
      put false into scrollTheList
      
      if theBottomOfControl <= item 2 of theMaskRect or theTopOfControl < item 2 of theMaskRect then
         ## control is off the top of view OR top edge is clipped off
         put theTopOfControl into theNewVScroll
         put true into scrollTheList
         
      else if theTopOfControl >= item 4 of theMaskRect or theBottomOfControl > item 4 of theMaskRect then
         ## control is off the bottom of view or bottom edge is clipped off      
         put theBottomOfControl - theMaskHeight into theNewVScroll
         put true into scrollTheList
      end if         
      
      if scrollTheList then
         ## If as tall as mask group then scroll top into view.
         ## Otherwise follow regular rules
         put theBottomOfControl - theTopOfControl >= theMaskHeight into theControlIsAtLeastAsTallAsMask
         if theControlIsAtLeastAsTallAsMask then
            put theTopOfControl into theNewVScroll
         end if
         
         if the dgProps["animate selections"] of me and sPendingMsgsA["UpdateScrollAnimation"] is empty then
            StartScrollAnimation theNewVScroll
         else
            cancel sPendingMsgsA["UpdateScrollAnimation"]
            put empty into sPendingMsgsA["UpdateScrollAnimation"]
            put false into sIsAnimating
            
            _SetVScroll theNewVScroll
         end if
      end if
   end if
   
   return theError
end ScrollIndexIntoView


## See dgRectOfIndex in order to get rect of a control in the data grid.
command ScrollRectIntoView pRect, pPadding
   -----
   local theItemNo
   local theMaskRect
   local theScrollToOffset, theVScroll
   -----
   
   if pPadding is an integer then
      put pPadding & comma & pPadding & comma & pPadding into item 2 of pPadding
   else if pPadding is not empty and pPadding is not a rect then
      _ThrowError kErrInvalidRect, pPadding && "is not a valid margins value"
   else if pPadding is empty then
      put 0,0,0,0 into pPadding
   end if
   
   ## Mask rect is rect of this group with vscroll taken into account
   put the rect of group "dgListMask" of me into theMaskRect
   
   local theCurrentVScroll
   put the dgVScroll of me into theCurrentVScroll
   
   ## left,right are ignored right now
   add item 1 of pPadding to item 1 of theMaskRect
   add item 2 of pPadding to item 2 of theMaskRect
   subtract item 3 of pPadding from item 3 of theMaskRect
   subtract item 4 of pPadding from item 4 of theMaskRect
   
   ## If mask height is less than rect height than we focus on top of pRect.
   ## Otherwise we focus on bottom of pRect.
   if item 4 of theMaskRect - item 2 of theMaskRect < item 4 of pRect - item 2 of pRect then
      put 2 into theItemNo
      put item 4 of theMaskRect - item 2 of theMaskRect into theScrollToOffset
   else
      put 4 into theItemNo
      put 0 into theScrollToOffset
   end if
   
   -- Debugging
   -- put "theMaskRect:" && theMaskRect & cr & \
         -- "pRect:" && pRect & cr & \
         -- "theItemNo:" && theItemNo & cr & \
         -- "theScrollToOffset:" && theScrollToOffset & cr & \
         -- "theCurrentVScroll:" && theCurrentVScroll
   
   if _RectIsAtLeastAsTallAsMask(pRect, theMaskRect) then
      if _RectCoversMask(pRect, theMaskRect) then
         ## Rect covers entire visible area. Do nothing.
      else
         ## If rect top or bottom is visible then do nothing. Otherwise scroll top in.
         if _TopIsVisible(pRect, theMaskRect) or _BottomIsVisible(pRect, theMaskRect) then
            ## Nothing
         else
            ## Scroll up to top of control
            put theCurrentVScroll - abs(item 2 of theMaskRect - item 2 of pRect) into theVScroll
         end if
      end if
   else if _TopIsClipped(pRect, theMaskRect) then
      ## Scroll up to top of control
      put theCurrentVScroll - abs(item 2 of theMaskRect - item 2 of pRect) into theVScroll
      
   else if _BottomIsClipped(pRect, theMaskRect) then
      ## scroll down to bottom of control
      put theCurrentVScroll - (item 4 of theMaskRect - item theItemNo of pRect) into theVScroll
      add theScrollToOffset to theVScroll
      
   else if _TopAndBottomAreClipped(pRect, theMaskRect) then
      if item 2 of pRect >= item 4 of theMaskRect then
         ## scroll down so bottom to bottom of control
         put theCurrentVScroll - (item 4 of theMaskRect - item theItemNo of pRect) into theVScroll
         add theScrollToOffset to theVScroll
      else
         ## scroll up to top of control
         put theCurrentVScroll - abs(item 2 of theMaskRect - item 2 of pRect) into theVScroll
      end if
   end if
   
   if theVScroll is not empty then         
      if the dgProps["animate selections"] of me then
         StartScrollAnimation theVScroll
      else
         set the dgVScroll of me to theVScroll
      end if
   end if
end ScrollRectIntoView

 
command ResetControl
    lock screen
    try
        ## So we don't confuse the engine
        if the long ID of me is in the long ID of the focusedObject then focus on graphic "dgBackground" of me
         
        _DeleteControls
        _ResetData
         
        if _ControlType() is "table" then
            _table.RegenerateColumns
        end if
    catch e
        put e
    end try
    unlock screen
     
    return empty
end ResetControl


-- Resets all controls in the data grid
private command _ResetAllControls
   lock screen
   local theControls
   if _ControlType() is "table" then
      repeat for each key theColumn in sTableObjectsA["columns"]
         if sTableObjectsA["columns"][theColumn]["row controls"] is not empty then
            put sTableObjectsA["columns"][theColumn]["row controls"] & cr after theControls
         end if
      end repeat
      delete the last char of theControls
   else
      put sTableObjectsA["all row controls"] into theControls
   end if
   
   local theCleansedControls
   ## Make sure controls exist
   repeat for each line theControl in theControls
      if there is a theControl then
         put theControl & cr after theCleansedControls
      end if
   end repeat
   
   _ResetControls theCleansedControls
   
   put empty into sTableObjectsA["current"]
   
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   lock messages
   if __HasMobileScroller() then
      mobileControlSet sScrollerId, "vScroll", 0
   end if
   set the thumbPosition of scrollbar "dgScrollbar" of me to 0
   set the lockMessages to msgsAreLocked
   unlock screen
end _ResetAllControls


private command _ResetScrollbarsAndRows
   ## This will call scrollbardrag. We set all structures before this happens.
   if __HasMobileScroller() then
      mobileControlSet sScrollerId, "vScroll", 0
   end if
   set the thumbPosition of scrollbar "dgScrollbar" of me to 0
   if _ControlType() is "table" then
      if __HasMobileScroller() then
         mobileControlSet sScrollerId, "hScroll", 0
      end if
      set the thumbPosition of scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me to 0
   end if
   
   _ConfigureScrollbar
   _ConfigureHScrollbar
   
   if the dgProps["fixed row height"] of me then
      _AutoHideVScrollbar ## only works for fixed height
   end if
   
   _DrawAlternatingRows
   _ShowAlternatingRows
end _ResetScrollbarsAndRows


-- Send ResetControl message to any controls that aren't visible.
-- Reset dgIndex
private command _ResetControls pControls
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   lock messages
   
   ## Hide any controls in "all row controls" that aren't part of "visible list controls"
   repeat for each line theControl in pControls
      if the visible of theControl then
         dispatch "ResetData" to theControl
         set the visible of theControl to false
         set the dgIndex of theControl to empty
      end if
   end repeat
   
   set the lockMessages to msgsAreLocked
end _ResetControls


private command _ResetData
   
   ## In case developer redraws while editor is open
   DeleteFieldEditor true
   
   lock screen
   ## So we don't confuse the engine
   if the long ID of me is in the long ID of the focusedObject then focus on graphic "dgBackground" of me
   
   ## Time intensive start
   -- _ResetAllControls
   _DeleteDataControls ## Replaced with above in 1.0.2 build 6. No more errors when deleting control running script!
   
   put empty into sDataArray
   ## time intensive end
   put empty into sIndexSequencing
   
   _StorePersistentData
   
   _ResetInternalCaches
   _DataCanBeRepresentedAsText true
   
   ## This will call scrollbardrag. We set all structures before this happens.
   if __HasMobileScroller() then
      mobileControlSet sScrollerId, "vScroll", 0
   end if
   set the thumbPosition of scrollbar "dgScrollbar" of me to 0
   if _ControlType() is "table" then
      if __HasMobileScroller() then
         mobileControlSet sScrollerId, "hScroll", 0
      end if
      set the thumbPosition of scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me to 0
   end if
   
   _ConfigureScrollbar
   _ConfigureHScrollbar
   
   if the dgProps["fixed row height"] of me then
      _AutoHideVScrollbar ## only works for fixed height
   end if
   
   _DrawAlternatingRows
   _ShowAlternatingRows
   
   unlock screen
end _ResetData


private command _ResetInternalCaches
    put empty into sControlOfIndexA
    put empty into sControlHeights
    put empty into sFormattedHeight
    put empty into sHilitedIndexes
    put empty into sControlsRequiredToFillSpace
    put empty into sFirstIndexClickedWithShiftKeyDown
    put empty into sDeselectOnMouseUp
end _ResetInternalCaches


--> Commands (Find)

## pKey can be a string or an array keyed index.
function GetKeyValuesOfIndexes pIndexes, pDelimiter, pKey --, ...
   local theIndex,theValues
   
   if pDelimiter is empty then put comma into pDelimiter 
   
   local theParamCount, theDelimLength
   put the paramCount into theParamCount
   put length(pDelimiter) into theDelimLength
   
   repeat for each item theIndex in pIndexes
      repeat with i = 3 to theParamCount
         put sDataArray[theIndex][param(i)] & pDelimiter after theValues
      end repeat
      delete char -theDelimLength to -1 of theValues
      put cr after theValues
   end repeat
   delete the last char of theValues
   return theValues
end GetKeyValuesOfIndexes


## pSearchA is array-valued index for accessing sDataArray
## pSearchA[1] = key_1
## pSearchA[2] = key_2
command FindIndex pKeyIndexA, pSearchString --, ...
   -----
   local foundAMatch, theFoundIndex
   local i
   local theIndex
   -----
   
   repeat for each key theIndex in sDataArray
      ## Developer can pass in multiple search strings to perform an AND search
      repeat with i = 1 to the paramCount step 2 
         if sDataArray[theIndex][param(i)] is param(i+1) then
            put true into foundAMatch
         else
            put false into foundAMatch
         end if
         
         ## AND search didn't pan out. Move on to next index.
         if not foundAMatch then exit repeat
      end repeat
      
      if foundAMatch then
         put theIndex into theFoundIndex
         exit repeat
      end if
   end repeat
   
   return max(0, theFoundIndex)
end FindIndex


command FindLine pKeyIndexA, pSearchString
    -----
    local theIndex
    -----
    FindIndex pKeyIndexA, pSearchString
    put the result into theIndex
    if theIndex > 0 then
        return the dgLineOfIndex[theIndex] of me
    else
        return 0
    end if
end FindLine


--> Type: Template Handlers


private command _ToggleVScrollBarVisibility pBoolean
   lock screen
   set the visible of scrollbar "dgScrollbar" of me to pBoolean
   
   switch _ControlType()
      case "table"
         local theOrigHScroll
         put _GetHScrollPercent() into theOrigHScroll
         _ResetHScrollToZero
         _AutoHideHScrollbar
         
         _table.LayoutDataArea
         _table.RepositionHeaders
         
         _ConfigureHScrollbar
         RefreshList
         _SetHScrollPercent theOrigHScroll         
         break
         
      case "form"
      default
         local theRect
         put the rect of group "dgList" of me into theRect
         if the visible of scrollbar "dgScrollbar" of me then
            put the left of scrollbar "dgScrollbar" of me into item 3 of theRect
         else
            put the right of scrollbar "dgScrollbar" of me into item 3 of theRect
         end if
         
         set the rect of group "dgListMask" of me to theRect
         set the rect of group "dgList" of me to theRect
         set the rect of group "dgAlternatingRowsMask" of me to theRect
         
         if not the dgProps["fixed row height"] of me then
            _CalculateFormattedHeight
         end if
         
         RefreshList
   end switch
   unlock screen
end _ToggleVScrollBarVisibility


private command _ToggleHScrollBarVisibility pBoolean
   lock screen
   ## todo: can we only perform actions if visible of scrollbar is different than pBoolean?
   set the visible of group "dgHorizontalComponents" of me to pBoolean
   
   switch _ControlType()
      case "table"
         local theOrigVScroll
         put _GetVScrollPercent() into theOrigVScroll
         _ResetVScrollToZero
         
         _table.LayoutDataArea
         
         local theSetting
         put the visible of scrollbar "dgScrollbar" of me into theSetting
         _AutoHideVScrollbar
         if the visible of scrollbar "dgScrollbar" of me is not theSetting then
            _table.LayoutDataArea
         end if
         
         _ShowAlternatingRows
         _ConfigureScrollbar
         RefreshList
         
         _SetVScrollPercent theOrigVScroll
         break
      case "form"
      default
   end switch
   unlock screen
end _ToggleHScrollBarVisibility


private command _DrawListWithProperties pStartingSequence, pSetVScrollTo, pForceRefresh, pCallback, pCallbackContext
    lock screen
    
    ## For cases where user copied/pasted
    if not sInit then _Initialize
    
    DeleteFieldEditor
    
    local theControl
    put the long ID of the focusedObject into theControl
    
    local msgsAreLocked, theStart
    put the lockMessages into msgsAreLocked
    put the milliseconds into theStart
    
    if pStartingSequence is not an integer or pStartingSequence < 1 then put 1 into pStartingSequence
    if pSetVScrollTo is not an integer then put 0 into pSetVScrollTo
    
    ## Store sequence that visible controls start drawing from
    put pStartingSequence into sTableObjectsA["base sequence for visible controls"]
     
    switch _ControlType()
        case "table"
            _table.DrawWithProperties pSetVScrollTo, pForceRefresh
            break
        case "form"
        default
         _list.DrawWithProperties pSetVScrollTo, pForceRefresh, pCallback, pCallbackContext
    end switch
    
    ## Make sure focus stays with us
    if the long ID of me is in theControl then
        lock messages
        if there is not a theControl then
          ## [[ FocusRedraw ]] Make sure focus is only changed if the target is
          ## not already focused.
          if the long id of the focusedObject is not the long id of graphic "dgBackground" of me then
            focus on graphic "dgBackground" of me
          end if
        else
          ## [[ FocusRedraw ]] Make sure focus is only changed if the target is
          ## not already focused.
          if the long id of the focusedObject is not theControl then
            focus on theControl
          end if
        end if
        unlock messages
    end if
    
    -- put "time spent in" && param(0) & ":" && the milliseconds - theStart & cr after msg
    
    unlock screen
    set the lockMessages to msgsAreLocked
    -- put "time spent in" && param(0) & ":" && the milliseconds - theStart & cr after msg
end _DrawListWithProperties

private command _DeleteControls
   local i,theControl,msgsAreLocked
   
   lock screen
   
   switch _ControlType()
      case "table"
         _table.DeleteColumnControls
         break
      case "form"
      default
   end switch
   
   _DeleteDataControls
   _ResetScrollsToZero
   
   ## In case one gets left around
   if there is a field kFieldEditorName of group "dgListMask" of me then
      put the lockMessages into msgsAreLocked
      lock messages
      delete field kFieldEditorName of group "dgListMask" of me
      set the lockMessages to msgsAreLocked
   end if
   
   unlock screen
end _DeleteControls


private command _DeleteDataControls
   lock screen
   
   switch _ControlType()
      case "table"
         _table.DeleteDataControls
         break
      case "form"
      default
         _list.DeleteControls
   end switch
   
   put empty into sTableObjectsA["current"]
   put 0 into sTableObjectsA["row control count"]
   
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   lock messages
   if __HasMobileScroller() then
      mobileControlSet sScrollerId, "vScroll", 0
   end if
   set the thumbPosition of scrollbar "dgScrollbar" of me to 0
   set the lockMessages to msgsAreLocked
   unlock screen
end _DeleteDataControls


private command _CalculateFormattedHeight
    put empty into sControlHeights
    put 0 into sFormattedHeight
    if item 2 of line 1 of the extents of sDataArray < 1 then
        put kDefaultRowHeight into sControlHeights
        return empty
    end if
    
    lock screen
    
    switch _ControlType()
        case "table"
            _table.CalculateFormattedHeight
            break
        case "form"
        default
            _list.CalculateFormattedHeight
    end switch
    
    _ConfigureScrollbar
    _AutoHideVScrollbar ## only works for fixed height
    
    unlock screen
end _CalculateFormattedHeight


## Makes sure that enough controls exist to fill up the visible space
## Returns true if the number of controls required to display all records increased.
private command _FillListWithJustEnoughControls
   lock screen
   
   switch _ControlType()
      case "table"
         _table.FillListWithJustEnoughControls
         break
      case "form"
      default
         _list.FillListWithJustEnoughControls
   end switch
   local theControlCountChanged
   put the result into theControlCountChanged
   
   unlock screen
   
   return theControlCountChanged
end _FillListWithJustEnoughControls 


private command _HiliteIndexesInVisibleControls
    switch _ControlType()
        case "table"
            _table.HiliteIndexesInVisibleControls
            break
        case "form"
        default
            _list.HiliteIndexesInVisibleControls
    end switch
end _HiliteIndexesInVisibleControls


private command _UpdateHiliteColor
    lock screen
    
    if _ControlType() is "table" then
        _table.LayoutRowHilites ## changes colors
    end if
    
    _HiliteIndexesInVisibleControls
    unlock screen
end _UpdateHiliteColor


--> Type: List


private function _list.GetText pIncludeKeys
    -----
    local theIndex
    local theKey
    local theKeys
    local theText
    -----
    put the keys of sDataArray[item 1 of sIndexSequencing] into theKeys
    sort lines of theKeys
    
    if pIncludeKeys then
        put theKeys into theText
        replace cr with tab in theText
        put cr after theText
    end if
    
    repeat for each item theIndex in sIndexSequencing 
        repeat for each line theKey in theKeys
            put sDataArray[theIndex][theKey] & tab after theText
        end repeat
        put cr into the last char of theText
    end repeat
    delete the last char of theText
    return theText
end _list.GetText


private command _list.SetText pText, pKeys
   -----
   local theColNum
   local theDataA
   local theItem
   local theLine
   local theSequencing
   -----
   lock screen
   set the itemDelimiter to tab
   
   if pKeys is not empty then
      ## Developer specified item to key mapping
      local theColCount, theColLookupA
      put the number of lines of pKeys into theColCount
      
      put 0 into theColNum
      repeat for each line theColumn in pKeys
         add 1 to theColNum
         put theColumn into theColLookupA[theColNum]
      end repeat
      
      local theRow
      repeat for each line theLine in pText
         add 1 to theRow
         put 0 into theColNum
         put theRow & comma after theSequencing
         if theLine is empty then
            ## Fill in empty records for empty lines
            repeat for each line theColumn in pKeys
               put empty into theDataA[theRow][theColumn]
            end repeat
         else
            repeat for each item theItem in theLine
               add 1 to theColNum
               put theItem into theDataA[theRow][ theColLookupA[theColNum] ]
               if theColNum is theColCount then exit repeat
            end repeat
         end if
      end repeat
      
   else
      ## No columns provided. We just create columns named "Label COL_NUM"
      repeat for each line theLine in pText
         add 1 to theRow
         put 0 into theColNum
         put theRow & comma after theSequencing
         if theLine is empty then
            ## Fill in empty value for one key
            put empty into theDataA[theRow][ "Label 1"]
         else
            repeat for each item theItem in theLine
               add 1 to theColNum
               put theItem into theDataA[theRow][ "Label" && theColNum ]
            end repeat
         end if
      end repeat
   end if
   delete the last char of theSequencing
   
   set the dgData [theSequencing] of me to theDataA
   
   unlock screen
   return empty
end _list.SetText


private command _list.AddLine pText, pKeys, pLineNo
   -----
   local theColNum
   local theDataA
   local theItem
   local theLine,theResult
   -----
   lock screen
   set the itemDelimiter to tab
   
   if pKeys is not empty then
      ## Developer specified mapping of data to keys
      local theColCount, theColLookupA
      put the number of lines of pKeys into theColCount
      
      put 0 into theColNum
      repeat for each line theColumn in pKeys
         add 1 to theColNum
         put theColumn into theColLookupA[theColNum]
      end repeat
      
      repeat for each line theLine in pText
         put 0 into theColNum
         repeat for each item theItem in theLine
            add 1 to theColNum
            put theItem into theDataA[ theColLookupA[theColNum] ]
            if theColNum is theColCount then exit repeat
         end repeat
         
         AddData theDataA, pLineNo
         put the result into theResult
         if pLineNo is not empty then add 1 to pLineNo
      end repeat
   else
      ## No columns provided. We just create columns named "Label COL_NUM"
      repeat for each line theLine in pText
         put 0 into theColNum
         repeat for each item theItem in theLine
            add 1 to theColNum
            put theItem into theDataA[ "Label" && theColNum ]
         end repeat
         
         AddData theDataA, pLineNo
         put the result into theResult
         if pLineNo is not empty then add 1 to pLineNo
      end repeat
   end if
   
   unlock screen
   return theResult
end _list.AddLine


private command _list.DrawWithProperties  pSetVScrollTo, pForceRefresh, pCallback, pCallbackContext
    -----
    local theError
    -----
    lock messages
    set the vScroll of group "dgList" of me to 0
    unlock messages
    
    ## Easier to read code
    if the dgProps["cache controls"] of me then
      _list.DrawCachedControlList pForceRefresh, pCallback, pCallbackContext
    else
      _list.DrawControlsInRealTime pForceRefresh, pCallback, pCallbackContext
    end if
    
    # Update VScroll every time
    lock messages
    set the vScroll of group "dgList" of me to pSetVScrollTo
    unlock messages
    
   -- We've potentially scrolled, so reposition any overlays.
   DG2_EditModeActionControlHolderReposition
   DG2_SwipeControlHolderReposition

    return theError
end _list.DrawWithProperties


private command _list.DeleteControls
    -----
    local i
    local msgsAreLocked
    local theControl
    -----
    put the lockMessages into msgsAreLocked
    lock messages ## for speed
     
    repeat for each line theControl in sTableObjectsA["all row controls"]
        if there is a control theControl then
            delete theControl
        end if
    end repeat
     
    ## Any extra cleanup
    repeat until there is not a (group 1 of group "dgList" of me)
        delete group 1 of group "dgList" of me
    end repeat
    repeat until there is not a control 1 of group "dgList" of me
        delete control 1 of group "dgList" of me
    end repeat
     
    put empty into sTableObjectsA["all row controls"]
    put empty into sTableObjectsA["visible row controls"]
     
    set the lockMessages to msgsAreLocked
end _list.DeleteControls


private command _list.FillListWithJustEnoughControls
   local controlCountChanged,i
   local theControl,theCurrentControlCount,theMsgsAreLocked,theRequiredControlCount
   local theTemplateGroup
   
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   
   put false into controlCountChanged
   put the dgProps["row template"] of me into theTemplateGroup
   
   ## Determine required control count
   put _ControlsRequiredToFillSpace() into theRequiredControlCount
   
   ## Make sure we have enough controls to fill visible space
   put sTableObjectsA["row control count"] into theCurrentControlCount
   
   if theRequiredControlCount > theCurrentControlCount then
      if sTableObjectsA["all row controls"] is not empty then put cr after sTableObjectsA["all row controls"]
      
      ## Create enough controls
      lock messages ## for speed
      repeat with i = theCurrentControlCount + 1 to theRequiredControlCount
         copy theTemplateGroup to group "dgList" of me
         put it into theControl
         set the layerMode of theControl to "dynamic"
         set the name of theControl to the short name of theControl && format("%04d", i)
         put "control id" && word 3 of theControl && "of me" & cr after sTableObjectsA["all row controls"]
         
         ## take over geometry
         set the lockloc of theControl to true
      end repeat
      unlock messages
      
      delete the last char of sTableObjectsA["all row controls"]
      put the number of lines of sTableObjectsA["all row controls"] into sTableObjectsA["row control count"]
      
      put true into controlCountChanged
      
   else if theRequiredControlCount < theCurrentControlCount then
      ## To many controls. That is okay. They just hang around invisible.
   else
      ## We have just enough controls
   end if
   
   set the lockMessages to msgsAreLocked
   
   return controlCountChanged
end _list.FillListWithJustEnoughControls


private command _list.UpdateAlternatingRowColors
   lock screen
   
   local theRow1Color, theRow2Color, theControl, theIndex
   put _GetEffectiveColor("row color") into theRow1Color
   put _GetEffectiveColor("alternate row color") into theRow2Color
   
   set the wholeMatches to true 
   
   repeat for each line theControl in sTableObjectsA["visible row controls"]
      put the dgDataControl of theControl into theControl
      if there is a graphic "Background" of theControl then
         put the dgIndex of theControl into theIndex
         
         ## don't color hilited lines
         if theIndex is among the items of sHilitedIndexes then next repeat
         
         local theLine
         put itemOffset(theIndex, sIndexSequencing) into theLine
         if theLine mod 2 is kAlternatingRowModValue then
            set the backgroundColor of graphic "Background" of theControl to theRow2Color
         else
            set the backgroundColor of graphic "Background" of theControl to theRow1Color
         end if
      end if
   end repeat
   
   unlock screen
   return empty
end _list.UpdateAlternatingRowColors


-- pControls is "all list controls" for a form or column row controls for a table
private function _GenerateReorderedControlList pControls, pIndexes
    local theControl,theControlIndexesA,theControlsWithoutAHome,theIndex,theList  
    
    set the wholeMatches to true
    ## Separate controls based on whether or not they have an index
    repeat for each line theControl in pControls
        put the dgIndex of theControl into theIndex
        
        if theIndex is among the items of pIndexes then
            put theControl into theControlIndexesA[theIndex]
        else
            put theControl & cr after theControlsWithoutAHome
        end if
    end repeat
    delete the last char of theControlsWithoutAHome
    
    ## Now order everything
    repeat for each item theIndex in pIndexes
        if theControlIndexesA[theIndex] is not empty then
            put theControlIndexesA[theIndex] & cr after theList
        else
            put line 1 of theControlsWithoutAHome & cr after theList
            delete line 1 of theControlsWithoutAHome
        end if
    end repeat
    put theControlsWithoutAHome after theList
    if the last char of theList is cr then delete the last char of theList
     
    return theList
end _GenerateReorderedControlList


private command _list.DrawControlsInRealTime pForceRefresh, pCallback, pCallbackContext
   -----
   local controlCountWasModified
   local i
   local msgsAreLocked
   local noRedrawNeeded
   local theControl, theControlIndex
   local theEffectiveControl
   local theIndex
   local theIndexesInSequence
   local theListGroupRect
   local theMaxControlNumber
   local theRect
   local theRowColor
   local theSequence
   local theTopLeft
   -----
   ## Get geometry properties
   put _WorkingGroupRect(the long ID of group "dgList" of me) into theListGroupRect
   put item 1 to 2 of theListGroupRect into theTopLeft
   put 0 into theControlIndex
   
   ## Make sure there are enough controls
   _FillListWithJustEnoughControls
   put the result into controlCountWasModified
   
   ## We use sequencing to draw, not indexes
   set the wholeMatches to true
   put item sTableObjectsA["base sequence for visible controls"] to -1 of sIndexSequencing into theIndexesInSequence
   put _ControlsRequiredToFillSpace() into theMaxControlNumber
   
   ## filter the list of sequences
   put item 1 to theMaxControlNumber of theIndexesInSequence into theIndexesInSequence
   
   ## Get lookup table for indexes that already have controls with correct data
   local theMasterControlList
   put _GenerateReorderedControlList(sTableObjectsA["all row controls"], theIndexesInSequence) into theMasterControlList
   
   put the lockMessages into msgsAreLocked
   
   put not controlCountWasModified and sTableObjectsA["current"]["indexes"] is theIndexesInSequence into noRedrawNeeded
   -- put theIndexesInSequence && the milliseconds & cr into msg

   ## [[ DG2Layout ]] If edit mode or enable swipe is enabled or if minimal
   ## layout is not enabled then we must still call LayoutControl on each
   ## iteration.
   local theMustLayout
   put sEditMode or \
        the dgProps["enable swipe"] of me or \
        not the dgProps["minimal layout"] of me into theMustLayout
   
   if not noRedrawNeeded or pForceRefresh then
      put empty into sTableObjectsA["visible row controls"]
      
      local theRow1Color, theRow2Color, controlHeightIsFixed
      put _GetEffectiveColor("row color") into theRow1Color
      put _GetEffectiveColor("alternate row color") into theRow2Color
      
      put sTableObjectsA["base sequence for visible controls"] - 1 into theSequence
      put the dgProps["fixed row height"] of me into controlHeightIsFixed
      
      if pCallback is not empty then
         dispatch pCallback & "Start" to me with pCallbackContext, theTopLeft
      end if

      repeat for each item theIndex in theIndexesInSequence
         ## Get control reference
         add 1 to theControlIndex
         add 1 to theSequence
         
         ## This will speed things up and keep us from experiencing visual lag
         lock messages
         
         put line theControlIndex of theMasterControlList into theControl
         if there is not a theControl then _ThrowError kErrCantFindObject, "control not found when drawing form:" && theControl
         
         unlock messages
         set the visible of theControl to true
         put theControl & cr after sTableObjectsA["visible row controls"]
         put the dgDataControl of theControl into theEffectiveControl
         lock messages
         
         ## Set geometry
         if controlHeightIsFixed then 
            put theTopLeft & comma & item 3 of theListGroupRect & comma & item 2 of theTopLeft + sControlHeights into theRect
         else
            put theTopLeft & comma & item 3 of theListGroupRect & comma & item 2 of theTopLeft + the height of theControl into theRect
         end if
         
         ## Set row color
         if there is a graphic "Background" of theEffectiveControl then
            ## Compute the new row color based on the alternating index
            local theNewRowColor
            if theSequence mod 2 is kAlternatingRowModValue then
              put theRow2Color into theNewRowColor
            else
              put theRow1Color into theNewRowColor
            end if

            ## [[ ColorRedraw ]] Only change the backgroundColor of the control
            ## if it has changed.
            if the backgroundColor of graphic "Background" of theEffectiveControl is not theNewRowColor then
              set the backgroundColor of graphic "Background" of theEffectiveControl to theNewRowColor
            end if
         end if
         
         ## If control index is not the index we are working on then
         ## Load new data
         local theCurrentIndex, theNeedsLayout
         put the dgIndex of theControl into theCurrentIndex
         if theCurrentIndex is not theIndex then
            ## Allow developer to do something if unloading control
            if theCurrentIndex is not empty then
               unlock messages
               dispatch "PreFillInData" to theControl ## standardized and documented in 1.0.2 build 6
               -- dispatch "ResetDataGridControl" to theControl
               lock messages
            end if
            
            set the dgIndex of theControl to theIndex
            
            local theDataA
            if sDataArray[theIndex] is NULL then
               unlock messages
               GetDataForLine theSequence, theDataA
               dispatch "FillInData" to theControl with theDataA
               lock messages
            else
               unlock messages
               dispatch "FillInData" to theControl with sDataArray[theIndex]
               lock messages
            end if

            ## If data was changed, then the control must layout
            put true into theNeedsLayout
         else
            -- put "not drawing index:" && theIndex & cr after msg

            ## If data has not changed then only layout if DG2 features are
            ## active
            put theMustLayout into theNeedsLayout
         end if
         
         ## Set the rect AFTER filling in data in case filling in data causes the group to resize
         unlock messages
         if pCallback is not empty then
            dispatch pCallback to me with pCallbackContext, theControl, theSequence, theRect, theTopLeft
         end if

         ## Always set the topLeft of the row template - this causes unchanged
         ## rows to scroll, and ensure that changed rows controls are where they
         ## expect.
         set the topLeft of theControl to item 1 to 2 of theRect

         ## If the width or height of the row template has changed then get the
         ## user script to layout it out again.
         if theNeedsLayout or \
            the width of theControl is not (item 3 of theRect - item 1 of theRect) or \
            the height of theControl is not (item 4 of theRect - item 2 of theRect) then
            lock messages
            set the rect of theControl to theRect
            unlock messages

            set the lockUpdates of theControl to true
            dispatch "LayoutControl" to theControl with theRect, DG2_GetWorkingRectOfControlFromControlRect(theControl, theRect)
            set the lockUpdates of theControl to false

            ## Resize to fit height
            if not controlHeightIsFixed then
               lock messages
               put item 2 of theRect + the formattedHeight of theControl into item 4 of theRect
               set the rect of theControl to theRect
               unlock messages
            end if
         end if
         
         put the bottom of theControl into item 2 of theTopLeft
         
         ## [[ HiliteAll ]] Update the hilite of the row template - ideally
         ## this would only be done *if* the hilite of the row has changed
         ## or the row template has been reused or the data for the row has
         ## changed. 
         if theIndex is among the items of sHilitedIndexes then
            _HiliteControl theEffectiveControl, true
         else
            _HiliteControl theEffectiveControl, false
         end if
      end repeat
      
      ## Store current sequences in list
      put theIndexesInSequence into sTableObjectsA["current"]["indexes"]

      if pCallback is not empty then
         dispatch pCallback & "End" to me with pCallbackContext
      end if
   end if
   
   ## Filter control list and reset controls that aren't part of visible list
   put line (the number of lines of sTableObjectsA["visible row controls"] + 1) to -1 of theMasterControlList into theMasterControlList
   _ResetControls theMasterControlList

   return empty
end _list.DrawControlsInRealTime

private command _list.DrawCachedControlList pForceRefresh, pCallback, pCallbackContext
   -----
   local isVisible
   local msgsAreLocked
   local noRedrawNeeded
   local theControl
   local theFirstControlHeight
   local theIndex
   local theIndexesInSequence
   local theListGroupRect, theListGroupWidth
   local theOldListControls
   local theRowColor
   local theSequence
   local theTopLeft
   -----

   # If controls haven't been cached yet then exit
   if sControlOfIndexA is not an array then return empty

   put false into noRedrawNeeded
   put empty into theFirstControlHeight
   
   put the lockMessages into msgsAreLocked
   
   ## Get geometry properties
   put _WorkingGroupRect(the long ID of group "dgList" of me) into theListGroupRect
   put item 1 to 2 of theListGroupRect into theTopLeft
   put item 3 of theListGroupRect - item 1 of theListGroupRect into theListGroupWidth
   
   ## We use sequencing to draw, not indexes
   set the wholeMatches to true
   put item sTableObjectsA["base sequence for visible controls"] to -1 of sIndexSequencing into theIndexesInSequence
   
   ## Do we need to redraw?
   put line 1 of sTableObjectsA["visible row controls"] into theControl
   
   if there is a theControl then
      put the dgIndex of theControl is item 1 of theIndexesInSequence into noRedrawNeeded
   end if
   
   if not noRedrawNeeded or pForceRefresh then  
      -- put "calling " & param(0) & cr after msg ## important log
      
      ## Cache currently visible controls
      put sTableObjectsA["visible row controls"] into theOldListControls
      put empty into sTableObjectsA["visible row controls"]
      put empty into sTableObjectsA["current"]["indexes"]
      
      local theRow1Color, theRow2Color
      put _GetEffectiveColor("row color") into theRow1Color
      put _GetEffectiveColor("alternate row color") into theRow2Color
      
      put sTableObjectsA["base sequence for visible controls"] - 1 into theSequence
      
      if pCallback is not empty then
         dispatch pCallback & "Start" to me with pCallbackContext, theTopLeft
      end if

      ## This will speed things up and keep us from experiencing visual lag
      lock messages
      
      -- put "theIndexesInSequence:" && theIndexesInSequence & cr after msg ## important log
      repeat for each item theIndex in theIndexesInSequence
         add 1 to theSequence
         put theIndex & comma after sTableObjectsA["current"]["indexes"]
         
         ## Get control reference
         -- put "control (" & theIndex & "):" && theControl & cr after msg ## important log
         put sControlOfIndexA[theIndex] into theControl
         put theControl & cr after sTableObjectsA["visible row controls"]
         
         unlock messages
         local theEffectiveControl
         put the dgDataControl of theControl into theEffectiveControl
         lock messages
         
         ## Set row color
         if there is a graphic "Background" of theEffectiveControl then
            if theSequence mod 2 is kAlternatingRowModValue then
               set the backgroundColor of graphic "Background" of theEffectiveControl to theRow2Color
            else
               set the backgroundColor of graphic "Background" of theEffectiveControl to theRow1Color
            end if
         end if
         
         unlock messages
         put the visible of theControl into isVisible
         set the visible of theControl to true
         if not isVisible then
            dispatch "ShowDataGridControl" to theControl
         end if
         
         ## Set coordinates
         set the topLeft of theControl to theTopLeft             
         put the bottom of theControl into item 2 of theTopLeft
         
         if pCallback is not empty then
            local theRect
            put the rect of theControl into theRect
            dispatch pCallback to me with pCallbackContext, theControl, theSequence, theRect, theTopLeft
         end if

         ## Hilited index?
         if theIndex is among the items of sHilitedIndexes then
            _HiliteControl theEffectiveControl, true
         else
            _HiliteControl theEffectiveControl, false
         end if
         lock messages
         
         ## We need to know the height of first control as it must be able to scroll off screen
         if theFirstControlHeight is empty then
            put the height of theControl into theFirstControlHeight
         end if
         
         ## Check for exit
         if item 2 of theTopLeft >= item 4 of theListGroupRect + theFirstControlHeight then
            exit repeat
         end if
      end repeat
      delete the last char of sTableObjectsA["visible row controls"]
      delete the last char of sTableObjectsA["current"]["indexes"]
      -- put "----" & cr after msg ## important log
      
      ## We end repeat loop with locked messages
      unlock messages
      
      ## Hide previously visible list controls that are no longer visible.
      ## This is performed after we know which controls are visible this time around so
      ## that controls that are visible are not hid then shown again.
      repeat for each line theControl in theOldListControls
         if theControl is not among the lines of sTableObjectsA["visible row controls"] then
            try
               set the visible of theControl to false
            catch e
               -- put theOrigListControls
               -- put cr & "---" & cr & the short name of the me & cr & "can't set visible of:" && theControl & cr & theIndexesInSequence after msg
            end try
            -- dispatch "HideDataGridControl" to theControl
            dispatch "HideControl" to theControl ## standardized in 1.0.2 build 6
         end if
      end repeat

      if pCallback is not empty then
         dispatch pCallback & "End" to me with pCallbackContext
      end if
   end if
   
   set the lockMessages to msgsAreLocked
   
   return empty
end _list.DrawCachedControlList


private command _list.CalculateFormattedHeight
   -----
   local msgsAreLocked
   local theControl
   local theIndex
   local theListGroupRect
   local theRect
   local theTemplateGroup
   local theTopLeft
   local theDataA
   local theError
   -----
   
   ## If height is not fixed then we calculate height by looping through data and drawing controls.
   put the dgProps["row template"] of me into theTemplateGroup
   if theTemplateGroup is empty then return empty
   
   ## This handler loops through all records and gets the height of each one. The total height is then stored
   lock screen
   put the lockMessages into msgsAreLocked
   
   put _WorkingGroupRect(the long ID of group "dgList" of me) into theListGroupRect
   
   lock messages
   copy theTemplateGroup to group "dgList" of me
   put it into theControl
   set the layerMode of theControl to "dynamic"
   unlock messages
   
   try ## Watch for user errors
      
      put item 1 to 2 of theListGroupRect into theTopLeft
      put theTopLeft & comma & item 3 of theListGroupRect & comma & item 2 of theListGroupRect + the height of theControl into theRect
      lock messages
      set the rect of theControl to theRect ## Only do this once.
      unlock messages
      
      if the dgProps["fixed row height"] of me then
         put the dgProps["row height"] of me into sControlHeights
         if sControlHeights is not an integer or sControlHeights < 1 then
            if sDataArray[1] is NULL then
               GetDataForLine 1, theDataA
               dispatch "FillInData" to theControl with theDataA
            else
               dispatch "FillInData" to theControl with sDataArray[1]
            end if
            
            dispatch "LayoutControl" to theControl with theRect, DG2_GetWorkingRectOfControlFromControlRect(theControl, theRect)
            put the formattedHeight of theControl into sControlHeights
         end if
         put sControlHeights * the number of elements of sDataArray into sFormattedHeight
      else
         repeat for each key theIndex in sDataArray 
            local theSequence              
            add 1 to theSequence  
            ## Get height
            if sDataArray[theIndex] is NULL then
               GetDataForLine theSequence, theDataA
               
               dispatch "CalculateFormattedHeight" to theControl with theDataA
               if it is "not handled" or it is "unhandled" then
                  dispatch "FillInData" to theControl with theDataA
                  
                  set the topLeft of theControl to theTopLeft ## So developer can rely on topleft of controls in template code.
                  lock messages
                  set the rect of theControl to theRect
                  unlock messages
                  dispatch "LayoutControl" to theControl with theRect, DG2_GetWorkingRectOfControlFromControlRect(theControl, theRect)
                  put the formattedHeight of theControl into sControlHeights[theIndex]
               else
                  put the result into sControlHeights[theIndex]
               end if
               
            else
               dispatch "CalculateFormattedHeight" to theControl with sDataArray[theIndex]
               if it is "not handled" or it is "unhandled" then
                  dispatch "FillInData" to theControl with sDataArray[theIndex]
                  
                  set the topLeft of theControl to theTopLeft ## So developer can rely on topleft of controls in template code.
                  lock messages
                  set the rect of theControl to theRect
                  unlock messages
                  dispatch "LayoutControl" to theControl with theRect, DG2_GetWorkingRectOfControlFromControlRect(theControl, theRect)
                  put the formattedHeight of theControl into sControlHeights[theIndex]
               else
                  put the result into sControlHeights[theIndex]
               end if
            end if
            
            add sControlHeights[theIndex] to sFormattedHeight
         end repeat
      end if
      
   catch e
      put e into theError
   end try
   
   lock messages
   delete theControl
   unlock messages
   
   unlock screen
   set the lockMessages to msgsAreLocked
   
   if theError is not empty then throw theError
end _list.CalculateFormattedHeight


private command _list.HiliteIndexesInVisibleControls
   lock screen
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   set the lockMessages to false
   set the wholeMatches to true
   repeat for each line theControl in sTableObjectsA["visible row controls"]
      local theBoolean
      put the dgIndex of theControl is among the items of sHilitedIndexes into theBoolean
      _HiliteControl the dgDataControl of theControl, theBoolean      
   end repeat
   set the lockMessages to msgsAreLocked
   unlock screen
end _list.HiliteIndexesInVisibleControls


--> Type: Table


private command _table.UpdateHeaderLabel pColumn, pLabel, pEncoding
   if the paramCount is 1 then
      local theColsA
      put the dgProps["column properties"] of me into theColsA
      put theColsA[pColumn]["label"] into pLabel
      put theColsA[pColumn]["encoding"] into pEncoding
   end if
   
   local theGroup
   put sTableObjectsA["columns"][pColumn]["header"]["group"] into theGroup
   if theGroup is not empty then
      if pLabel is empty then put pColumn into pLabel
      set the dgLabel [pEncoding] of theGroup to pLabel
   end if
end _table.UpdateHeaderLabel


private command _table.UpdateHeaderTooltip pColumn, pTooltip
   local theColsA, theGroup
   if the paramCount is 1 then
      put the dgProps["column properties"] of me into theColsA
      put theColsA[pColumn]["tooltip"] into pTooltip
   end if
   
   put sTableObjectsA["columns"][pColumn]["header"]["group"] into theGroup
   if theGroup is not empty then
      set the dgTooltip of theGroup to pTooltip
   end if
end _table.UpdateHeaderTooltip


private command _table.ScrollColumnIntoView pColumn
   local theColGroup, theColRect, theMaskRect, theDiff
   put sTableObjectsA["columns"][pColumn]["group"] into theColGroup
   if theColGroup is empty then return empty
   
   put the rect of theColGroup into theColRect
   put the rect of group "dgListMask" into theMaskRect
   if the visible of scrollbar "dgScrollbar" of me then
      put the left of scrollbar "dgScrollbar" of me into item 3 of theMaskRect
   end if
   
   put item 1 of theColRect - item 1 of theMaskRect into theDiff
   if theDiff > 0 then
      put item 3 of theColRect - item 3 of theMaskRect into theDiff
      if theDiff < 0 then
         put 0 into theDiff
      end if
   end if
   
   if theDiff is not 0 then
      local msgsAreLocked
      put the lockMessages into msgsAreLocked
      unlock messages
      if __HasMobileScroller() then
         mobileControlSet sScrollerId, "hScroll", mobileControlGet(sScrollerId, "hScroll") + theDiff
      end if
      set the thumbPosition of scrollbar "dgHScrollbar" of me to the thumbPosition of scrollbar "dgHScrollbar" of me + theDiff
      set the lockMessages to msgsAreLocked
   end if
   
   return empty
end _table.ScrollColumnIntoView


private command _table.LayoutDataArea
   local theViewRect, theRect
   put _WorkingGroupRect(the long ID of me) into theViewRect
   put theViewRect into theRect
   
   local tHeaderComponents, tHorizontalComponents
   local tVScrollbar, tHScrollbar, tCornerPiece
   put the long id of group "dgHeaderComponents" of me into tHeaderComponents
   put the long id of group "dgHorizontalComponents" of me into tHorizontalComponents
   put the long id of scrollbar "dgScrollbar" of me into tVScrollbar
   put the long id of scrollbar "dgHScrollbar" of tHorizontalComponents into tHScrollbar
   put the long id of graphic "dgCornerPiece" of tHorizontalComponents into tCornerPiece
   
   ## Shift all content
   set the topLeft of tHeaderComponents to item 1 to 2 of theRect
   
   if the visible of tHeaderComponents then
      # Set the rect of the header mask
      local tHeaderMaskRect
      put theRect into tHeaderMaskRect
      put the bottom of group "dgHeaderMask" of tHeaderComponents into item 4 of tHeaderMaskRect            
      set the rect of group "dgHeaderMask" of tHeaderComponents to tHeaderMaskRect
      ## Define new top of content rect
      put item 4 of tHeaderMaskRect into item 2 of theRect                 
   end if
   
   if the environment is not "mobile" then
      ## Reposition bottom element
      local theSBWidth
      if the visible of tVScrollbar then 
         put the width of tVScrollbar into theSBWidth
      else 
         put the dgProps["scrollbar corner offset"] of me into theSBWidth
      end if
      # If the hscrollbar is not shown, then the horizontal components group
      # containing it is invisible, so the corner piece is also invisible.
      # So we can just set visibility of corner piece to the visible of the 
      # vscrollbar
      set the visible of tCornerPiece to the visible of tVScrollbar
      
      set the rect of tHScrollbar to \
            item 1 of theRect, \
            item 4 of theRect - the height of tHScrollbar, \
            item 3 of theRect - theSBWidth, item 4 of theRect
      
      if the visible of tHorizontalComponents then
         put the top of tHScrollbar into item 4 of theRect
      else
         put item 4 of theViewRect - the dgProps["scrollbar corner offset"] of me \
               into item 4 of theRect
      end if
      
      ## V Scrollbar and corner piece    
      set the rect of tVScrollbar to \
            item 3 of theRect - the width of tVScrollbar, \
            item 2 of theRect, item 3 of theRect, \
            item 4 of theRect
      
      set the rect of tCornerPiece to \
            item 3 of theRect - the width of tVScrollbar, \
            the top of tHScrollbar, \
            item 3 of theRect, \
            the bottom of tHScrollbar
      
      ## Masks
      ## AL-2013-07-30 [[ Bug 10108 ]]  Thumb and scrollbar appear over top of DataGrid
      if the visible of tVScrollbar then 
         put item 3 of theRect - theSBWidth into item 3 of theRect
      end if
   else if __HasMobileScroller() then
      mobileControlSet sScrollerId, "rect", theRect
   end if
   
   set the topLeft of group "dgListMask" of me to item 1 to 2 of theRect
   set the rect of group "dgListMask" of me to theRect
   set the rect of group "dgAlternatingRowsMask" of me to theRect
   
   ## Shift List Group
   _table.ResizeHeaderBackground   
   _table.ResizeList
   _table.RepositionColumns
   _table.LayoutRowHilites   
end _table.LayoutDataArea


private command _table.SetHeaderBkgrndHiliteColor pColor
   repeat for each line theColumn in the dgProps["columns"] of me
      local theGroup
      put sTableObjectsA["columns"][theColumn]["header"]["group"] into theGroup
      if there is a theGroup then
         _table.HiliteHeaderBackground theGroup, pColor
      end if
   end repeat
end _table.SetHeaderBkgrndHiliteColor


private command _table.HiliteHeaderBackground pHeaderGroup, pColor
   local setFillGradient, useAGradient
   put pColor is an array into setFillGradient
   put the number of lines of pColor is 2 into useAGradient
   
   if there is a graphic "Background" of pHeaderGroup then
      if setFillGradient then
         repeat for each key theKey in pColor
            set the fillGradient[theKey] of graphic "Background" of pHeaderGroup to pColor[theKey]
         end repeat
      else if useAGradient then
         _SetGraphicGradient the long ID of graphic "Background" of pHeaderGroup, line 1 of pColor, line 2 of pColor
      else
         set the backgroundColor of graphic "Background" of pHeaderGroup to pColor
      end if
   end if
end _table.HiliteHeaderBackground


-- pTarget is optional and allows you to target a hilite background
private command _table.SetHeaderBkgrndGradient pStartColor, pEndColor
    _SetGraphicGradient the long ID of graphic "dgBackground" of group "dgHeaderMask" of group "dgHeaderComponents" of me, \
            pStartColor, pEndColor
end _table.SetHeaderBkgrndGradient


private command _table.UpdateHeaderDividerColors
   repeat for each line theColumn in the dgProps["columns"] of me
      local theGroup
      put sTableObjectsA["columns"][theColumn]["header"]["group"] into theGroup
      if there is a theGroup then
         set the foregroundColor of graphic "RightHilite" of theGroup to the dgProps["header divider color"] of me
         set the foregroundColor of graphic "LeftHilite" of theGroup to the dgProps["header divider threeD color"] of me
      end if
   end repeat
end _table.UpdateHeaderDividerColors


private function _table.GetText pIncludeColumns
    -----
    local theColumn, theColumns
    local theIndex
    local theText
    -----
    put the dgProps["columns"] of me into theColumns
    
    if pIncludeColumns then
        put theColumns into theText
        replace cr with tab in theText
        put cr after theText
    end if
    
    repeat for each item theIndex in sIndexSequencing 
        repeat for each line theColumn in theColumns
            put sDataArray[theIndex][theColumn] & tab after theText
        end repeat
        put cr into the last char of theText
    end repeat
    delete the last char of theText
    return theText
end _table.GetText


private command _table.SetText pText, pColumns
   -----
   local i
   local theColNum, theColumn, theColumns, theItemNoColumnA
   local theDataA
   local theItem
   local theLine
   local theSequencing
   -----
   lock screen
   
   set the itemDelimiter to tab
   if pColumns is empty then
      put the dgProps["columns"] of me into pColumns
      
      ## Make sure we have some columns defined
      local theColCount
      put the number of lines of pColumns into theColCount
      if the number of lines of pColumns < the number of items of line 1 of pText then
         if pColumns is not empty then put cr after pColumns
         repeat with i = 1 to the number of items of line 1 of pText
            if i > theColCount then
               put "Col" && i & cr after pColumns
            end if
         end repeat
         delete the last char of pColumns
         set the dgProps["columns"] of me to pColumns
      end if
   end if
   put the number of lines of pColumns into theColCount
   
   ## Store column item no's and total column count
   put 0 into i
   repeat for each line theColumn in pColumns
      add 1 to i
      put theColumn into theItemNoColumnA[i]
   end repeat
   
   repeat for each line theLine in pText
      local theRow
      add 1 to theRow
      put 0 into theColNum
      put theRow & comma after theSequencing
      if theLine is empty then
         ## Fill in empty records for empty lines
         repeat for each line theColumn in pColumns
            put empty into theDataA[theRow][theColumn]
         end repeat
      else
         repeat for each item theItem in theLine
            add 1 to theColNum
            put theItem into theDataA[theRow][ theItemNoColumnA[theColNum] ]
            
            if theColNum is theColCount then exit repeat
         end repeat
      end if
   end repeat
   delete the last char of theSequencing
   
   set the dgData [theSequencing] of me to theDataA
   
   unlock screen
end _table.SetText


private command _table.AddLine pText, pColumns, pLineNo
   -----
   local i
   local theColNum, theColumn, theColumns, theItemNoColumnA
   local theDataA
   local theItem
   local theLine,theResult
   -----
   lock screen
   
   set the itemDelimiter to tab
   if pColumns is empty then
      put the dgProps["columns"] of me into pColumns
      
      ## Make sure we have some columns defined
      local theColCount
      put the number of lines of pColumns into theColCount
      if the number of lines of pColumns < the number of items of line 1 of pText then
         if pColumns is not empty then put cr after pColumns
         repeat with i = 1 to the number of items of line 1 of pText
            if i > theColCount then
               put "Col" && i & cr after pColumns
            end if
         end repeat
         delete the last char of pColumns
         set the dgProps["columns"] of me to pColumns
      end if
   end if
   put the number of lines of pColumns into theColCount
   
   ## Store column item no's and total column count
   put 0 into i
   repeat for each line theColumn in pColumns
      add 1 to i
      put theColumn into theItemNoColumnA[i]
   end repeat
   
   ## add lines
   repeat for each line theLine in pText
      put 0 into theColNum
      put empty into theDataA
      repeat for each item theItem in theLine
         add 1 to theColNum
         put theItem into theDataA[ theItemNoColumnA[theColNum] ]
         if theColNum is theColCount then exit repeat
      end repeat
      
      ## Note: This redraws list each time. Officially we only support one line of text right
      ## now but we could bring the logic of AddData inline and not redraw until the end.
      AddData theDataA, pLineNo
      put the result into theResult
      
      if pLineNo is not empty then add 1 to pLineNo
   end repeat
   
   unlock screen
   
   return theResult
end _table.AddLine


private command _table.DrawWithProperties pSetVScrollTo, pForceRefresh
    ## We only scroll by entire records so if any scrolling is supposed to occur then
    ## start 1 higher
    if pSetVScrollTo > 0 then add 1 to sTableObjectsA["base sequence for visible controls"]
    
    _table.DrawControlsInRealTime pForceRefresh
    if sTableObjectsA["base sequence for visible controls"] mod 2 is kAlternatingRowModValue then
        set the top of graphic "dgAlternatingRows" of me to the top of group "dgAlternatingRowsMask" of me - sControlHeights  
    else
        set the top of graphic "dgAlternatingRows" of me to the top of group "dgAlternatingRowsMask" of me
    end if
end _table.DrawWithProperties


private command _table.DeleteColumn pColumn
    -----
    local msgsAreLocked
    local theColPropsA
    local theControl
    -----
    lock screen
    put sTableObjectsA["columns"][pColumn]["header"]["group"] into theControl
    if there is a theControl then delete theControl
     
    put sTableObjectsA["columns"][pColumn]["group"] into theControl
    if there is a theControl then delete theControl
     
    put sTableObjectsA["columns"][pColumn]["divider control"] into theControl
    if there is a theControl then delete theControl
    delete local sTableObjectsA["columns"][pColumn]
     
    ## column properties
    put the dgProps["column properties"] of me into theColPropsA
    delete local theColPropsA[pColumn]
     
    put the lockMessages into msgsAreLocked
    lock messages
    set the dgProps["column properties"] of me to theColPropsA
    set the lockMessages to msgsAreLocked
     
    unlock screen
end _table.DeleteColumn


private command _table.DeleteColumnControls
   -----
   local i
   local msgsAreLocked
   local theColumn
   -----
   put the lockMessages into msgsAreLocked
   lock messages ## for speed
   
   repeat until there is not a group 1 of group "dgList" of group "dgListMask" of me
      ## Nested groups will mess up the count as we delete
      delete group 1 of group "dgList" of group "dgListMask" of me
   end repeat
   repeat with i = 1 to the number of controls of group "dgList" of group "dgListMask" of me
      delete control 1 of group "dgList" of group "dgListMask" of me
   end repeat
   
   repeat until there is not a group 1 of group "dgDividers" of group "dgListMask" of me
      delete group 1 of group "dgDividers" of group "dgListMask" of me
   end repeat
   
   repeat with i = 1 to the number of controls of group "dgDividers" of group "dgListMask" of me
      delete control 1 of group "dgDividers" of group "dgListMask" of me
   end repeat
   
   repeat until there is not a group 1 of group "dgHeader" of group "dgHeaderComponents" of me
      delete group 1 of group "dgHeader" of group "dgHeaderComponents" of me
   end repeat
   
   repeat with i = 1 to the number of controls of group "dgHeader" of group "dgHeaderComponents" of me
      delete control 1 of group "dgHeader" of group "dgHeaderComponents" of me
   end repeat
   
   repeat for each line theColumn in the dgProps["columns"] of me
      delete local sTableObjectsA["columns"][theColumn]
   end repeat
   
   set the lockMessages to msgsAreLocked
end _table.DeleteColumnControls


private command _table.DeleteDataControls
    -----
    local i
    local msgsAreLocked
    local theColGroup, theColumn
    -----
    put the lockMessages into msgsAreLocked
    lock messages ## for speed
     
    ##  cleanup
     
    ## Hilite graphics
    repeat for each line theControl in sTableObjectsA["row hilite controls"]
        delete theControl
    end repeat
    put empty into sTableObjectsA["row hilite controls"]
     
    repeat with i = 1 to the number of controls of group "dgHighlights" of group "dgListMask" of me
        delete control 1 of group "dgHighlights" of group "dgListMask" of me
    end repeat
     
    ## Columns
    repeat for each line theColumn in the dgProps["columns"] of me
        put sTableObjectsA["columns"][theColumn]["group"] into theColGroup
        if theColGroup is empty then next repeat
         
        ## stored
        repeat for each line theControl in sTableObjectsA["columns"][theColumn]["row controls"]
            delete theControl
        end repeat
         
        ## cleanup
        repeat with i = 1 to the number of groups of theColGroup
            delete group 1 of theColGroup
        end repeat
         
        repeat with i = 1 to the number of controls of theColGroup
            delete control 1 of theColGroup
        end repeat
         
        put empty into sTableObjectsA["columns"][theColumn]["row controls"]
    end repeat
     
    set the lockMessages to msgsAreLocked
end _table.DeleteDataControls


private command _table.LayoutRowHilites
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   lock messages
   
   local theRect
   put the rect of group "dgList" of group "dgListMask" of me into theRect
   put item 2 of theRect + sControlHeights into item 4 of theRect
   repeat for each line theControl in sTableObjectsA["row hilite controls"]
      set the rect of theControl to theRect
      local theTop
      put item 4 of theRect into theTop
      put theTop into item 2 of theRect
      put theTop + sControlHeights  into item 4 of theRect
      set the backgroundColor of theControl to _GetHiliteColor()
   end repeat    
   
   set the lockMessages to msgsAreLocked
end _table.LayoutRowHilites


private command _table.FillListWithJustEnoughControls
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   
   local controlCountChanged, theTemplateGroup, theColumns, theResourceStack, theRequiredControlCount, theCurrentControlCount
   put false into controlCountChanged
   put the dgProps["row template"] of me into theTemplateGroup
   put _table.VisibleColumns() into theColumns
   put _ResourceStack() into theResourceStack
   
   ## Determine required control count
   put _ControlsRequiredToFillSpace() into theRequiredControlCount
   
   ## Make sure we have enough controls to fill visible space
   put sTableObjectsA["row control count"] into theCurrentControlCount
   -- put the number of lines of (sTableObjectsA["columns"][line 1 of theColumns]["row controls"]) into theCurrentControlCount
   
   lock messages ## for speed
   
   if theRequiredControlCount > theCurrentControlCount then     
      ##
      ## Create highlight graphics
      ##
      reset the templategraphic
      set the opaque of the templategraphic to true
      set the lineSize of the templategraphic to 0
      set the antialiased of the templategraphic to false
      
      --      put _CardOf() into theDGCard
      
      if sTableObjectsA["row hilite controls"] is not empty then put cr after sTableObjectsA["row hilite controls"]
      
      repeat with i = theCurrentControlCount + 1 to theRequiredControlCount
         create graphic ("hilite" && format("%04d", i)) in group "dgHighlights" of group "dgListMask" of me
         put "control id" && word 3 of it && "of me" & cr after sTableObjectsA["row hilite controls"]
         set the visible of it to false
      end repeat
      delete the last char of sTableObjectsA["row hilite controls"]
      reset the templategraphic
      
      _table.LayoutRowHilites
      
      ##
      ## Create column controls
      ##
      _table.CreateControlsForColumns theColumns, theRequiredControlCount
      
      ## Store first column in list of all controls so other handler can use it for information purposes
      put true into controlCountChanged
      
   else if theRequiredControlCount < theCurrentControlCount then
      ## To many controls: Leave as is for later. //Delete them as this makes management much easier with controls spread across multiple columns.
   else
      ## We have just enough controls
   end if
   
   set the lockMessages to msgsAreLocked
   
   return controlCountChanged
end _table.FillListWithJustEnoughControls


private command _table.CreateControlsForColumns pColumns, pRequiredControlCount
   -----
   local i
   local msgsAreLocked
   local theColPropsA, theColumn, theColWidth
   local theControl
   local theCurrentControlCount
   local theResourceStack
   local theTemplateGroup
   local theTopLeft
   local theMargins
   -----
   put the lockMessages into msgsAreLocked
   unlock messages
   put the dgProps["column margins"] of me into theMargins
   lock messages
   
   if sTableObjectsA["row control count"] is not an integer then put 0 into sTableObjectsA["row control count"]
   if pRequiredControlCount is not an integer or pRequiredControlCount < 0 then put sTableObjectsA["row control count"] into pRequiredControlCount
   
   ## Initialize
   put the dgProps["row template"] of me into theTemplateGroup
   put _ResourceStack() into theResourceStack
   --    put _CardOf() into theDGCard
   put the dgProps["column properties"] of me into theColPropsA
   
   ## Create
   repeat for each line theColumn in pColumns
      put the number of lines of sTableObjectsA["columns"][theColumn]["row controls"] into theCurrentControlCount
      if theCurrentControlCount >= pRequiredControlCount then next repeat
      
      ## We store each column's controls in separate list
      ## Initialize geometry vars for this column
      if sTableObjectsA["columns"][theColumn]["row controls"] is not empty then
         put the bottomLeft of (the last line of sTableObjectsA["columns"][theColumn]["row controls"]) into theTopLeft
         put cr after sTableObjectsA["columns"][theColumn]["row controls"]
      else
         put the topLeft of group theColumn of group "dgList" of me into theTopLeft
      end if
      put the width of group theColumn of group "dgList" of me into theColWidth
      
      repeat with i = theCurrentControlCount + 1 to pRequiredControlCount
         if sTableObjectsA["columns"][theColumn]["uses custom template"] then
            copy control theColumn of theTemplateGroup to group theColumn of group "dgList" of me
            ## Use default behavior if control doesn't have one assigned.
            if the behavior of it is empty then
               if the dgProps["default column behavior"] of me is empty then
                  set the behavior of it to the long ID of button "Default Column" of theResourceStack
               else
                  set the behavior of it to the dgProps["default column behavior"] of me
               end if
            end if
         else
            _table.ConfigureTemplateFieldForColumn line 1 of pColumns
            create field in group theColumn of group "dgList" of me
            set the textAlign of it to theColPropsA[theColumn]["alignment"]
            set the margins of it to theMargins
            if the dgProps["default column behavior"] of me is empty then
               set the behavior of it to the long ID of button "Default Column" of theResourceStack
            else
               set the behavior of it to the dgProps["default column behavior"] of me
            end if
         end if
         put it into theControl
         set the name of theControl to theColumn && format("%04d", i)
         
         ## Take control of geometry
         set the lockloc of theControl to true
         
         local theRect
         put theTopLeft into theRect
         put item 1 of theRect + theColWidth into item 3 of theRect
         put item 2 of theRect + sControlHeights into item 4 of theRect
         
         set the topLeft of theControl to theTopLeft
         set the rect of theControl to theRect
         unlock messages
         dispatch "LayoutControl" to theControl with theRect
         lock messages
         add sControlHeights to item 2 of theTopLeft
         
         ## We store each column's controls in separate list
         put "control id" && word 3 of theControl && "of me" & cr after sTableObjectsA["columns"][theColumn]["row controls"]
      end repeat
      
      delete the last char of sTableObjectsA["columns"][theColumn]["row controls"]
   end repeat
   
   put the number of lines of sTableObjectsA["columns"][line 1 of pColumns]["row controls"] into sTableObjectsA["row control count"]
   
   unlock messages
   
   set the lockMessages to msgsAreLocked
   return empty
end _table.CreateControlsForColumns


private command _table.DrawControlsInRealTime pForceRefresh
   local theColumnsA
   put _table.AreColumnsVisibleWithinMask() into theColumnsA
   
   if the keys of sTableObjectsA["columns"] is empty or sTableObjectsA["columns"][line 1 of theColumnsA["visible"]]["group"] is empty then
      _table.CreateColumns
   end if
   
   ## Make sure there are enough controls
   _table.FillListWithJustEnoughControls
   local controlCountWasModified
   put the result into controlCountWasModified
   
   ## We use sequencing to draw, not indexes
   set the wholeMatches to true
   local theIndexesInSequence
   put item sTableObjectsA["base sequence for visible controls"] to -1 of sIndexSequencing into theIndexesInSequence
   local theControlIndex
   put 0 into theControlIndex
   
   ## Do we need to redraw?
   local noRedrawNeeded
   put not controlCountWasModified and \
         sTableObjectsA["base sequence for last rendering"] is sTableObjectsA["base sequence for visible controls"] into noRedrawNeeded
   
   if not noRedrawNeeded or pForceRefresh then  
      if pForceRefresh then
         ## force refresh should redraw all columns at once
         _table.DrawColumns _table.VisibleColumns()
         -- put "drawing all columns:" && the milliseconds
      else
         _table.DrawColumns theColumnsA["visible"] --the dgProps["columns"] of me
         
         ## If user is interacting with scrollbar then no need to throttle.
         ## Just redraw on mouseUp
         cancel sPendingMsgsA["draw hidden columns"]
         if not sRunningActionsA["user is vscrolling"] then
            local theHiddenColumns
            put theColumnsA["hidden"] into theHiddenColumns
            send "table.DrawColumns theHiddenColumns" to me in 200 milliseconds
            put the result into sPendingMsgsA["draw hidden columns"]
         end if
      end if
      
      ## Cache what we started on last time
      put sTableObjectsA["base sequence for visible controls"] into sTableObjectsA["base sequence for last rendering"]
   end if
   
   return empty
end _table.DrawControlsInRealTime


## Needed for send call in _table.DrawControlsInRealTime
command table.DrawColumns pColumns, pIndexesToDraw
    _table.DrawColumns pColumns, pIndexesToDraw
end table.DrawColumns


private command _table.DrawColumns pColumns, pIndexesToDraw
   local theStart
   put the milliseconds into theStart #####!!!!!
   
   if pColumns is empty then return empty
   
   lock screen
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   set the wholeMatches to true
   
   ## Default is not to pass in value for pIndexes to draw in which case
   ## we use the base sequence for visible controls to determine indexes to draw
   if pIndexesToDraw is not empty then
      local theSequence
      put itemOffset(item 1 of pIndexesToDraw, sIndexSequencing) - 1 into theSequence
   else
      put item sTableObjectsA["base sequence for visible controls"] to \
            (sTableObjectsA["base sequence for visible controls"] + sTableObjectsA["row control count"] - 1) of sIndexSequencing into pIndexesToDraw
      put sTableObjectsA["base sequence for visible controls"] - 1 into theSequence
   end if
   
   ## Initialize now as this is used regardless of whether or not we have indexes to draw
   local theControlIndex
   put 0 into theControlIndex
   
   if pIndexesToDraw is not empty then
      ## Get geometry properties
      local theListGroupRect, theTopLeft
      put _WorkingGroupRect(the long ID of group "dgList" of me) into theListGroupRect
      put item 1 to 2 of theListGroupRect into theTopLeft
      
      ## How many vertical controls do we need to draw?
      -- put _ControlsRequiredToFillSpace() into theMaxControlNumber
      
      repeat for each line theColumn in pColumns
         ## Get lookup table for indexes that already have controls with correct data
         local theTopLeftA, theMasterControlList
         put the topLeft of sTableObjectsA["columns"][theColumn]["group"] into theTopLeftA[theColumn]
         put _GenerateReorderedControlList(sTableObjectsA["columns"][theColumn]["row controls"], pIndexesToDraw) into theMasterControlList[theColumn]
         
         ## Store line indexes
         put empty into sTableObjectsA["columns"][theColumn]["control line numbers"]
         repeat for each line theControl in theMasterControlList[theColumn]
            put lineOffset(theControl, sTableObjectsA["columns"][theColumn]["row controls"]) & comma after sTableObjectsA["columns"][theColumn]["control line numbers"]
         end repeat
         delete the last char of sTableObjectsA["columns"][theColumn]["control line numbers"]
      end repeat
      -- PrintKeys theMasterControlList 
      -- put cr & cr & the executioncontexts after msg
      
      ## Draw it
      unlock messages
      repeat for each item theIndex in pIndexesToDraw
         add 1 to theControlIndex
         add 1 to theSequence
         
         ## get row data
         local theDataA
         if sDataArray[theIndex] is NULL then
            GetDataForLine theSequence, theDataA
         end if
         
         ## Deal with rows controls
         repeat for each line theColumn in pColumns
            put line theControlIndex of theMasterControlList[theColumn] into theControl
            
            -- if there is not a theControl then
            -- put "Control for index " & theControlIndex & " does not exist for column " & theColumn & cr & cr & \
                  -- the executioncontexts & cr & cr &  \
            -- "theMasterControlList:" & cr & _PrintKeys(theMasterControlList) & cr & cr & \
                  -- "sDataArray:" && _PrintKeys(sDataArray) after msg
            -- end if
            local theCurrentIndex
            put the dgIndex of theControl into theCurrentIndex
            if theIndex is not theCurrentIndex then
               ## Allow developer to do something if unloading control
               if theCurrentIndex is not empty then
                  unlock messages
                  dispatch "PreFillInData" to theControl
                  lock messages
               end if
               
               set the visible of theControl to true
               lock messages
               set the dgIndex of theControl to theIndex
               unlock messages
               if sDataArray[theIndex] is NULL then
                  dispatch "FillInData" to theControl with theDataA[theColumn]
               else
                  dispatch "FillInData" to theControl with sDataArray[theIndex][theColumn]
               end if
            else
               -- put "not drawing index " & theIndex & " for column" && theColumn & cr after msg
               -- no need to redraw
            end if
            
            set the topLeft of theControl to theTopLeftA[theColumn]
            add sControlHeights to item 2 of theTopLeftA[theColumn]
         end repeat
         
         ## Hilited index?            
         if theIndex is among the items of sHilitedIndexes then
            _table.HiliteRow theControlIndex, true
         else
            _table.HiliteRow theControlIndex, false
         end if
      end repeat
      
      put pIndexesToDraw into sTableObjectsA["current"]["indexes"]
   end if
   
   ## Reset hilites and hide any extra controls for columns
   lock messages
   repeat for each line theColumn in pColumns
      _ResetControls line (theControlIndex + 1) to -1 of theMasterControlList[theColumn]
   end repeat
   repeat with theControlIndex = theControlIndex + 1 to the number of lines of theMasterControlList[line 1 of pColumns]
      _table.HiliteRow theControlIndex, false         
   end repeat
   unlock messages
   
   -- put "time spent in" && param(0) & ":" && the milliseconds - theStart & cr --after msg
   
   set the lockMessages to msgsAreLocked
   unlock screen    
   
   -- put theLog & cr after msg
   return empty
end _table.DrawColumns


private command _table.HiliteIndexesInVisibleControls
   local theColumn, i, theIndexes, theBoolean
   put line 1 of _table.VisibleColumns() into theColumn
   if theColumn is empty then return empty
   
   set the wholeMatches to true
   lock screen
   put 0 into i
   put item sTableObjectsA["base sequence for visible controls"] to \
         (sTableObjectsA["base sequence for visible controls"] + sTableObjectsA["row control count"]) of sIndexSequencing into theIndexes
   repeat for each item theIndex in theIndexes
      add 1 to i
      put theIndex is among the items of sHilitedIndexes into theBoolean
      _table.HiliteRow i, theBoolean
   end repeat
   unlock screen
end _table.HiliteIndexesInVisibleControls


private command _table.HiliteRow pRow, pBoolean
   local theControl, theColumns
   put line pRow of sTableObjectsA["row hilite controls"] into theControl
   if theControl is empty then return empty
   
   put _table.VisibleColumns() into theColumns
   
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   unlock messages
   
   lock screen
   set the visible of theControl to pBoolean
   
   repeat for each line theColumn in theColumns
      local theLineNo
      put item pRow of sTableObjectsA["columns"][theColumn]["control line numbers"] into theLineNo
      put line theLineNo of sTableObjectsA["columns"][theColumn]["row controls"] into theControl
      if theControl is empty then exit repeat
      set the dgHilite of theControl to pBoolean
   end repeat
   unlock screen
   set the lockMessages to msgsAreLocked
end _table.HiliteRow


private command _table.ConfigureTemplateFieldForColumn pColumn, pFieldHeight
    reset the templatefield
    
    if pFieldHeight is empty then put kDefaultRowHeight into pFieldHeight
    
    set the traversalOn of the templatefield to false
    set the autoTab of the templatefield to true
    set the dontWrap of the templatefield to true
    set the showBorder of the templatefield to false
    set the borderWidth of the templatefield to 2
    set the margins of the templatefield to 8
    set the lockText of the templatefield to true
    set the opaque of the templatefield to false
    set the height of the templatefield to pFieldHeight
    
    return empty
end _table.ConfigureTemplateFieldForColumn


private command _table.CacheCustomTemplateUsage
   local theTemplateGroup, theColumns, templateExists
   put the dgProps["row template"] of me into theTemplateGroup
   put the dgProps["columns"] of me into theColumns
   
   put there is a theTemplateGroup into templateExists
   repeat for each line theColumn in theColumns
      if templateExists then
         put there is a control theColumn of theTemplateGroup \
               and the long ID of the owner of control theColumn of theTemplateGroup is the long ID of theTemplateGroup \
               into sTableObjectsA["columns"][theColumn]["uses custom template"]
         put there is a control (theColumn && "[Header]") of theTemplateGroup \
               and the long ID of the owner of control (theColumn && "[Header]") of theTemplateGroup is the long ID of theTemplateGroup \
               into sTableObjectsA["columns"][theColumn]["header"]["uses custom template"]
      else
         put false into sTableObjectsA["columns"][theColumn]["uses custom template"]
         put false into sTableObjectsA["columns"][theColumn]["header"]["uses custom template"]
      end if
   end repeat
end _table.CacheCustomTemplateUsage


private command _table.CalculateFormattedHeight    
    ## Cache which are custom
    _table.CacheCustomTemplateUsage
    
    ## Fill in row height
    put the dgProps["row height"] of me into sControlHeights
    if sControlHeights is not an integer or sControlHeights < 1 then put kDefaultRowHeight into sControlHeights
    put sControlHeights * the number of elements of sDataArray into sFormattedHeight
end _table.CalculateFormattedHeight


private command _table.RegenerateColumns
    lock screen
    _table.CreateColumns
    
    _table.LayoutRowHilites
    _table.CreateControlsForColumns _table.VisibleColumns()
    -- set the uEffectiveColumnWidths of group "dgHeader" of group "dgHeaderMask" of group "dgHeaderComponents" of me \
            -- to _table.GetEffectiveColumnWidths()
     
    unlock screen
end _table.RegenerateColumns


## Return list of visible controls in proper order
private function _ListOfVisibleControls
   local theControls
   if _ControlType() is "table" then
      ## list of controls for a column contains all visible controls.
      ## There might be less data than controls.
      repeat for each line theControl in sTableObjectsA["columns"][ _table.FirstVisibleColumn() ]["row controls"]
         if the visible of theControl then
            put theControl & cr after theControls
         end if
      end repeat
      delete the last char of theControls
      return _GenerateReorderedControlList(theControls, sTableObjectsA["current"]["indexes"])
   else
      return sTableObjectsA["visible row controls"]
   end if
end _ListOfVisibleControls


private function _table.FirstVisibleColumn
    -----
    local theColPropsA, theColumn, theColumns
    local theVisibleColumns
    -----
    put the dgProps["columns"] of me into theColumns
    put the dgProps["column properties"] of me into theColPropsA
    repeat for each line theColumn in theColumns
        if theColPropsA[theColumn]["visible"] is not false then
            return theColumn
        end if
    end repeat
    return empty
end _table.FirstVisibleColumn


private function _table.VisibleColumns
    -----
    local theColPropsA, theColumn, theColumns
    local theVisibleColumns
    -----
    put the dgProps["columns"] of me into theColumns
    put the dgProps["column properties"] of me into theColPropsA
    repeat for each line theColumn in theColumns
        if theColPropsA[theColumn]["visible"] is not false then
            put theColumn & cr after theVisibleColumns
        end if
    end repeat
    delete the last char of theVisibleColumns
    return theVisibleColumns
end _table.VisibleColumns


## Returns array [hidden|visible] containing list of column
## names that are hidden and visible within the list mask
private function _table.AreColumnsVisibleWithinMask
   local theColumns, theWidths
   put _table.VisibleColumns() into theColumns
   put _table.GetEffectiveColumnWidths() into theWidths
   
   local theMinX, theRect, theVisibleWidth, theMaxX, theItemNo, theTotalWidth
   put the dgHScroll of me into theMinX
   put _WorkingGroupRect(the long ID of group "dgListMask" of me) into theRect
   put the left of scrollbar "dgScrollbar" of me - item 1 of theRect into theVisibleWidth
   put theMinX + theVisibleWidth into theMaxX
   
   put 0 into theItemNo
   put 0 into theTotalWidth
   repeat for each line theColumn in theColumns
      local theColumnsA
      if theTotalWidth > theMaxX then
         put theColumn & cr after theColumnsA["hidden"]
      else
         add 1 to theItemNo
         local theColWidth
         put item theItemNo of theWidths into theColWidth
         if theTotalWidth + theColWidth < theMinX then
            put theColumn & cr after theColumnsA["hidden"]
            add theColWidth to theTotalWidth
         else
            put theColumn & cr after theColumnsA["visible"]
            add theColWidth to theTotalWidth
         end if
      end if
   end repeat
   
   return theColumnsA
end _table.AreColumnsVisibleWithinMask


private command _table.CreateColumns
   lock screen
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   lock messages
   
   local theResourceStack
   put _ResourceStack() into theResourceStack
   
   local theOrigHScroll
   put _GetHScrollPercent() into theOrigHScroll
   _ResetHScrollToZero
   
   ## Note: We generate a group for all columns whether visible or not
   ## This is just easier for the time being. Perhaps change later.
   local theColumns, theTopLeft
   put the dgProps["columns"] of me into theColumns
   put item 1 to 2 of the rect of group "dgList" of me into theTopLeft
   
   ## Loop through existing columns and delete out those that are no
   ## longer included
   set the wholeMatches to true
   repeat for each key theColumn in sTableObjectsA["columns"]
      if theColumn is not among the lines of theColumns then
         _table.DeleteColumn theColumn
      end if
   end repeat
   
   ## delete column props (I don't think this is necessary since
   ## adding _table.deleteColumn but haven't tested yet)
   local theColPropsA
   put the dgProps["column properties"] of me into theColPropsA
   repeat for each key theColumn in theColPropsA
      if theColumn is not among the lines of theColumns then
         delete local theColPropsA[theColumn]
      end if
   end repeat
   
   _table.CacheCustomTemplateUsage
   
   _table.CreateHeaders
   
   ## Prepare to create controls
   reset the templategroup
   set the lockloc of the templategroup to true
   set the showBorder of the templategroup to false
   set the margins of the templategroup to 0
   set the borderWidth of the templategroup to 0
   set the showName of the templategroup to false
   
   reset the templategraphic
   
   --    put _CardOf() into theDGCard
   
   ## Create controls
   repeat for each line theColumn in theColumns
      ## Set default values
      if theColumn is not among the keys of theColPropsA then
         put true into theColPropsA[theColumn]["visible"]
         put "left" into theColPropsA[theColumn]["alignment"]
         put "ascending" into theColPropsA[theColumn]["sort direction"]
         put "text" into theColPropsA[theColumn]["sort type"]
         put false into theColPropsA[theColumn]["sort is case sensitive"]
         put 100 into theColPropsA[theColumn]["width"]
         put 40 into theColPropsA[theColumn]["min width"]
         put 1000 into theColPropsA[theColumn]["max width"]
         put true into theColPropsA[theColumn]["resizable"]
      end if
      
      ## Column
      if sTableObjectsA["columns"][theColumn]["group"] is empty then
         create group theColumn in group "dgList" of me
         put "control id" && word 3 of it && "of me" into sTableObjectsA["columns"][theColumn]["group"]
         set the topLeft of it to theTopLeft
         set the visible of it to theColPropsA[theColumn]["visible"]
         set the behavior of it to the long ID of button "Column Group" of group "Behaviors" of theResourceStack
      end if
      
      ## column divider
      if sTableObjectsA["columns"][theColumn]["divider control"] is empty then
         create graphic in group "dgDividers" of group "dgListMask" of me
         put "control id" && word 3 of it && "of me" into sTableObjectsA["columns"][theColumn]["divider control"]
         set the enabled of it to false ## don't want it to get messages
         set the foregroundColor of it to the dgProps["column divider color"] of me
         set the rect of it to theTopLeft, item 1 of theTopLeft + 1, item 2 of theTopLeft + 1
      end if
   end repeat
   
   reset the templategroup
   reset the templategraphic
   
   ## Toggle visibility controls
   repeat for each line theColumn in theColumns
      set the visible of sTableObjectsA["columns"][theColumn]["group"] to theColPropsA[theColumn]["visible"]
      set the visible of sTableObjectsA["columns"][theColumn]["header"]["group"] to theColPropsA[theColumn]["visible"]
   end repeat
   
   set the dgProps["column properties"] of me to theColPropsA
   
   _table.ResizeColumns
   
   unlock messages
   
   ## Outside of locked messages so content draws
   _SetHScrollPercent theOrigHScroll
   
   set the lockMessages to msgsAreLocked
   
   unlock screen
end _table.CreateColumns


private command _table.CreateHeaders
   local theResourceStack
   put _ResourceStack() into theResourceStack
   --   put _CardOf() into theDGCard
   local theColumns, theHeaderGroup, theHeaderRect
   put the dgProps["columns"] of me into theColumns
   put the long ID of group "dgHeaderMask" of group "dgHeaderComponents" of me into theHeaderGroup
   
   put the rect of theHeaderGroup into theHeaderRect
   put item 2 of theHeaderRect + the height of theHeaderGroup into item 4 of theHeaderRect
   
   ## Clear out existing headers that don't exist
   set the wholeMatches to true
   repeat for each key theColumn in sTableObjectsA["columns"]
      if theColumn is not among the lines of theColumns and sTableObjectsA["columns"][theColumn]["header"]["group"] is not empty then
         local theControl
         put sTableObjectsA["columns"][theColumn]["header"]["group"] into theControl
         delete theControl
         delete local sTableObjectsA["columns"][theColumn]["header"]
      end if
   end repeat
   
   local theTemplateGroup
   put the dgProps["row template"] of me into theTemplateGroup
   
   ## Create header groups
   local theColsA, sortByThisColumn
   put the dgProps["column properties"] of me into theColsA
   put the dgProps["sort by column"] of me into sortByThisColumn
   repeat for each line theColumn in theColumns
      ## Column
      if sTableObjectsA["columns"][theColumn]["header"]["group"] is empty then
         if sTableObjectsA["columns"][theColumn]["header"]["uses custom template"] and \
               theTemplateGroup is not empty then
            ## Use custom template provided by user...
            copy control (theColumn && "[Header]") of theTemplateGroup to group "dgHeader" of me
            local theGroup
            put it into theGroup
            set the name of theGroup to theColumn
            set the lockloc of theGroup to true
            put "control id" && word 3 of theGroup && "of me" into sTableObjectsA["columns"][theColumn]["header"]["group"]
            local theRect
            put item 1 to 2 of theHeaderRect, item 1 of theHeaderRect + 10, item 4 of theHeaderRect into theRect
            set the rect of theGroup to theRect
         else
            _table.CreateDefaultHeaderGroup theColumn, theHeaderRect
            put the result into theGroup
            
            if the dgProps["default header behavior"] of me is empty then
               set the behavior of theGroup to the long ID of button "Default Header" of theResourceStack
            else
               set the behavior of theGroup to the dgProps["default header behavior"] of me
            end if
         end if
         
         unlock messages             
         if theColsA[theColumn]["label"] is not empty then
            set the dgLabel [theColsA[theColumn]["encoding"]] of theGroup to theColsA[theColumn]["label"]
         else
            set the dgLabel of theGroup to theColumn
         end if
         set the dgTooltip of theGroup to theColsA[theColumn]["tooltip"]
         set the dgHilite of theGroup to theColumn is sortByThisColumn
         set the dgAlignment of theGroup to theColsA[theColumn]["header"]["alignment"]
         lock messages
      end if
   end repeat
end _table.CreateHeaders


private command _table.CreateDefaultHeaderGroup pColumn, pHeaderRect
   local theHeaderGroup
   put the long ID of group "dgHeaderMask" of group "dgHeaderComponents" of me into theHeaderGroup
   
   reset the templategroup
   set the lockloc of the templategroup to true
   set the showBorder of the templategroup to false
   set the margins of the templategroup to 0
   set the borderWidth of the templategroup to 0
   set the showName of the templategroup to false
   
   reset the templatefield
   
   set the borderWidth of the templatefield to 0
   set the showFocusBorder of the templatefield to false
   set the autoHilite of the templatefield to false
   set the threeD of the templatefield to false
   set the lockText of the templatefield to true
   set the dontWrap of the templatefield to true
   set the opaque of the templatefield to false
   set the textAlign of the templatefield to "left"
   set the height of the templatefield to the textSize of the templatefield + 4
   set the traversalOn of the templateField to false
   
   --    put _CardOf() into theDGCard
   
   create group pColumn in group "dgHeader" of theHeaderGroup
   local theGroup
   put it into theGroup
   put "control id" && word 3 of theGroup && "of me" into sTableObjectsA["columns"][pColumn]["header"]["group"]
   local theRect
   put item 1 to 2 of pHeaderRect, item 1 of pHeaderRect + 10, item 4 of pHeaderRect into theRect
   set the rect of theGroup to theRect
   
   ## Background
   reset the templategraphic
   set the style of the templategraphic to "rectangle"
   set the opaque of the templategraphic to true
   set the backgroundColor of the templategraphic to empty
   set the lineSize of the templategraphic to 0
   set the antialiased of the templategraphic to true
   create graphic "Background" in theGroup
   set the rect of it to theRect
   
   _table.HiliteHeaderBackground theGroup, the dgProps["header background hilite color"] of me
   
   ## Field
   set the width of the templatefield to item 3 of theRect - item 1 of theRect
   create field "HeaderLabel" in theGroup
   local theField
   put it into theField
   
   ## EJB - fix for bug 9575 21/02/12
   ## Old line
   ## set the height of it to the formattedHeight of it - the bottomMargin of it
   ## Now checking the height is > 0 as this line was failing where the dg was on a card that had not been opened
   ## as the formattedHeight was 0
   
   local tHeight
   put the formattedHeight of it - the bottomMargin of it into tHeight
   if tHeight < 1 then
      ## nothing
   else
      set the height of it to tHeight
   end if
   
   set the topLeft of theField to item 1 to 2 of theRect
   
   ## left hilite
   set the lineSize of the templategraphic to 1
   set the antialiased of the templategraphic to false
   create graphic "LeftHilite" in theGroup
   set the foregroundColor of it to the dgProps["header divider threeD color"] of me
   set the rect of it to item 1 of theRect + 1, item 2 of theRect, item 1 of theRect + 2, item 4 of theRect
   
   ## right hilite
   create graphic "RightHilite" in theGroup
   set the foregroundColor of it to the dgProps["header divider color"] of me
   set the rect of it to item 3 of theRect - 1, item 2 of theRect, item 3 of theRect, item 4 of theRect
   
   ## Sort arrow
   reset the templatebutton
   set the style of the templatebutton to "transparent"
   set the opaque of the templatebutton to false
   set the showName of the templatebutton to false
   set the threeD of the templatebutton to false
   set the showBorder of the templatebutton to false
   set the hiliteBorder of the templatebutton to false
   set the borderWidth of the templatebutton to 0
   set the width of the templatebutton to 9
   set the height of the templatebutton to 8
   create button "SortArrow" in theGroup
   
   reset the templategroup
   reset the templatefield
   reset the templategraphic
   reset the templatebutton
   
   return theGroup
end _table.CreateDefaultHeaderGroup


private command _table.RepositionHeadersAndColumns
   lock screen
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   
   local theOrigHScrollPercent
   put _GetHScrollPercent() into theOrigHScrollPercent
   _ResetHScrollToZero
   
   lock messages
   
   _table.ResizeColumns
   _table.RepositionHeaders
   _table.RepositionColumns    
   
   ## Restore H Scroll
   _ConfigureHScrollbar
   
   set the lockMessages to msgsAreLocked
   
   ## Outside of lock messages so content redraws
   _SetHScrollPercent theOrigHScrollPercent
   
   unlock screen
end _table.RepositionHeadersAndColumns


private command _table.ResizeColumns
   ## in case it gets called before initialization
   if the keys of sTableObjectsA["columns"] is empty then return empty
   
   put 0 into sFormattedWidth
   lock screen
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   
   ## Start at 0 point
   local theOrigVScrollPercent, theOrigHScrollPercent
   put _GetVScrollPercent() into theOrigVScrollPercent
   put _GetHScrollPercent() into theOrigHScrollPercent
   _ResetScrollsToZero
   
   lock messages
   
   ## First resize headers
   _table.ResizeHeaders
   
   ## Now resize columns
   local theColumns
   put _table.VisibleColumns() into theColumns
   
   ## Get in column widths
   local theColWidths
   put _table.GetEffectiveColumnWidths() into theColWidths
   
   ## Set rects
   local theItemNo, theColWidth, theGroup, theRect
   repeat for each line theColumn in theColumns
      add 1 to theItemNo
      put item theItemNo of theColWidths into theColWidth
      add theColWidth to sFormattedWidth
      
      put sTableObjectsA["columns"][theColumn]["group"] into theGroup
      put the rect of theGroup into theRect
      put item 1 of theRect + theColWidth into item 3 of theRect
      set the rect of theGroup to theRect
      
      put item 2 of theRect + sControlHeights into item 4 of theRect
      repeat for each line theControl in sTableObjectsA["columns"][theColumn]["row controls"]
         put the rect of theControl into theRect
         put item 1 of theRect + theColWidth into item 3 of theRect
         set the rect of theControl to theRect
         unlock messages
         dispatch "LayoutControl" to theControl with theRect
         lock messages
      end repeat
   end repeat
   
   _AutoHideHScrollbar
   
   _table.LayoutDataArea
   ## Old methods below. Didn't deal with auto hiding hscrollbar though.
   -- _table.RepositionColumns
   -- _table.ResizeList
   -- _table.LayoutRowHilites
   
   ## Restore H Scroll
   _ConfigureHScrollbar
   _ConfigureScrollbar
   
   set the lockMessages to msgsAreLocked
   
   ## Outside of lockmessages so they redraw 
   _SetHScrollPercent theOrigHScrollPercent
   _SetVScrollPercent theOrigVScrollPercent
   
   unlock screen
end _table.ResizeColumns


private command _table.ResizeList
   local theRect
   put the rect of group "dgList" of me into theRect
   put the top of group "dgListMask" of me into item 2 of theRect
   put item 1 of theRect + the width of graphic "dgBackground" of group "dgHeaderMask" of group "dgHeaderComponents" of me into item 3 of theRect
   put the bottom of group "dgListMask" of me into item 4 of theRect
   set the rect of group "dgList" of me to theRect
end _table.ResizeList


private command _table.ResizeHeaders
   local theOrigHScroll
   put _GetHScrollPercent() into theOrigHScroll
   _ResetHScrollToZero   
   
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   lock messages
   
   local theColumns, includeAllColumns, theColWidths, theGroupHeight, theTopLeft
   put the dgProps["columns"] of me into theColumns
   put true into includeAllColumns
   put _table.GetEffectiveColumnWidths(includeAllColumns) into theColWidths
   put the height of group "dgHeaderMask" of me into theGroupHeight
   put item 1 to 2 of the rect of group "dgHeaderComponents" of me into theTopLeft
   
   local theHeaderWidth, theReduction
   put 0 into theHeaderWidth
   put 0 into theReduction
   
   repeat for each line theColumn in theColumns
      local theItemNo, theColWidth, theRect
      add 1 to theItemNo
      put item theItemNo of theColWidths into theColWidth
      
      put theTopLeft into theRect
      put item 1 of theRect + (theColWidth- theReduction) into item 3 of theRect 
      put item 2 of theRect + theGroupHeight into item 4 of theRect
      
      local theGroup
      put sTableObjectsA["columns"][theColumn]["header"]["group"] into theGroup
      set the rect of theGroup to theRect
      
      unlock messages
      dispatch "LayoutControl" to theGroup with theRect
      lock messages
      
      put item 3 of theRect & "," & item 2 of theRect into theTopLeft
      
      add theColWidth to theHeaderWidth
      
      ## all columns after 1 need to be reduced in width in order to make room for divider
      -- put 1 into theReduction
   end repeat
   
   _table.ResizeHeaderBackground    
   _table.RepositionHeaders
   
   unlock messages
   _SetHScrollPercent theOrigHScroll
   
   set the lockMessages to msgsAreLocked
end _table.ResizeHeaders


private command _table.ResizeHeaderBackground
   local theRect, theHeaderWidth, theSBWidth
   ## Resize Background to fill visible space. Covers at least width of list group
   if the width of group "dgHeader" of group "dgHeaderMask" of group "dgHeaderComponents" of me > \
         the width of group "dgHeaderMask" of group "dgHeaderComponents" of me then
      put the rect of group "dgHeader" of group "dgHeaderMask" of group "dgHeaderComponents" of me into theRect
   else
      put the rect of group "dgHeaderMask" of group "dgHeaderComponents" of me into theRect
   end if
   put item 3 of theRect - item 1 of theRect into theHeaderWidth
   
   if the visible of scrollbar "dgScrollbar" of me then put the width of scrollbar "dgScrollbar" of me into theSBWidth
   else put 0 into theSBWidth
   
   put item 1 of theRect + max(the width of me, theHeaderWidth + theSBWidth) into item 3 of theRect
   put item 2 of theRect + the height of group "dgHeaderMask" of group "dgHeaderComponents" of me into item 4 of theRect
   set the rect of graphic "dgBackground" of group "dgHeaderMask" of group "dgHeaderComponents" of me to theRect
   set the rect of graphic "dgHeaderBottomBorder" of group "dgHeaderMask" of group "dgHeaderComponents" of me to item 1 of theRect, \
         item 4 of theRect - 1, item 3 of theRect, item 4 of theRect
end _table.ResizeHeaderBackground


private command _table.RepositionHeaders
   local theColumns, theHeaderGroup, theTopLeft, theItemNo, theGroup
   put _table.VisibleColumns() into theColumns
   put the long ID of group "dgHeader" of group "dgHeaderMask" of group "dgHeaderComponents" of me into theHeaderGroup
   
   put item 1 of the rect of group "dgHeaderComponents" of me into theTopLeft
   put the top of theHeaderGroup into item 2 of theTopLeft
   
   repeat for each line theColumn in theColumns
      add 1 to theItemNo
      
      ## Headers
      put sTableObjectsA["columns"][theColumn]["header"]["group"] into theGroup
      if the visible of theGroup then
         set the topLeft of theGroup to theTopLeft
         put the right of theGroup into item 1 of theTopLeft
      end if
   end repeat
end _table.RepositionHeaders


private command _table.RepositionColumns
   lock screen
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   lock messages
   
   local theColumns
   put _table.VisibleColumns() into theColumns
   
   local theOffset, theMasterRect, theTopLeft
   put the hScroll of group "dgListMask" of me into theOffset
   put the rect of group "dgListMask" of me into theMasterRect
   subtract theOffset from item 1 of theMasterRect
   subtract theOffset from item 3 of theMasterRect
   put item 1 to 2 of theMasterRect into theTopLeft
   
   local theGroup, theGraphic
   repeat for each line theColumn in theColumns
      ## columns
      put sTableObjectsA["columns"][theColumn]["group"] into theGroup
      
      if theGroup is not empty and the visible of theGroup then
         set the topLeft of theGroup to theTopLeft
         set the rect of theGroup to theTopLeft, the right of theGroup, item 4 of theMasterRect
         put the right of theGroup into item 1 of theTopLeft
         
         ## Column dividers
         put sTableObjectsA["columns"][theColumn]["divider control"] into theGraphic
         set the rect of theGraphic to item 1 of theTopLeft - 1, item 2 of theTopLeft, \
               item 1 of theTopLeft, item 4 of theMasterRect
      end if
   end repeat
   
   set the lockMessages to msgsAreLocked
   unlock screen
end _table.RepositionColumns


private function _table.GetEffectiveColumnWidths pIncludeAllColumns
    -----
    local i
    local theColPropsA, theColumn, theColumns
    local theFillerWidth
    local theWidths
    -----
    if pIncludeAllColumns then
        put the dgProps["columns"] of me into theColumns
    else
        put _table.VisibleColumns() into theColumns
    end if
    put the dgProps["column properties"] of me into theColPropsA
    repeat for each line theColumn in theColumns
        if theColPropsA[theColumn]["width"] is empty then
            put kDefaultTableColWidth & comma after theWidths
        else
            put theColPropsA[theColumn]["width"] & comma after theWidths
        end if
    end repeat
    delete the last char of theWidths
    
    -- put max(the last item of theWidths, kDefaultTableColWidth) into theFillerWidth
    -- repeat with i = the number of items of theWidths to the number of lines of theColumns
    -- put theFillerWidth into item i of theWidths
    -- end repeat
    
    return theWidths
end _table.GetEffectiveColumnWidths


--> Custom Properties (Data Manipulation)


setprop dgText [pTextIncludesColumnNames] pText
   -----
   local theError
   local theResult
   local theColumns, theStartLineNo
   -----
   lock screen
   try
      if pTextIncludesColumnNames is true then
         put line 1 of pText into theColumns
         replace tab with cr in theColumns
         put 2 into theStartLineNo
      else
         put empty into theColumns
         put 1 into theStartLineNo
      end if
      
      switch _ControlType()
         case "table"
            _table.SetText line theStartLineNo to -1 of pText, theColumns
            break
         case "form"
         default
            _list.SetText line theStartLineNo to -1 of pText, theColumns
      end switch    
      put the result into theResult
      _DataCanBeRepresentedAsText true
   catch e
      put e into theError
   end try
   unlock screen
   
   if theError is not empty then throw theError
   
   return theResult
end dgText


getprop dgText [pIncludeColumnNames]
   if the keys of sDataArray is empty then _RestorePersistentData ## In case control hasn't been opened yet
   
   switch _ControlType()
      case "table"
         return _table.GetText(pIncludeColumnNames)
         break
      case "form"
      default
         return _list.GetText(pIncludeColumnNames)
   end switch    
end dgText


getprop dgDataOfIndex [pIndex]
    return sDataArray[pIndex]
end dgDataOfIndex


setprop dgDataOfIndex [pIndex] pDataArray
    _DataCanBeRepresentedAsText false
    
    put pDataArray into sDataArray[pIndex]
    _StorePersistentData
    _RefreshIndexes pIndex
end dgDataOfIndex


getprop dgDataOfLine [pLine]
   local theIndex
   put the dgIndexOfLine [pLine] of me into theIndex
   return sDataArray[theIndex]
end dgDataOfLine


setprop dgDataOfLine [pLine] pDataArray
   _DataCanBeRepresentedAsText false
   
   local theIndex
   put the dgIndexOfLine [pLine] of me into theIndex
   put pDataArray into sDataArray[theIndex]
   _StorePersistentData
   _RefreshIndexes theIndex
end dgDataOfLine


getprop dgData
   if the keys of sDataArray is empty then _RestorePersistentData ## In case control hasn't been opened yet
   
   return sDataArray
end dgData


setprop dgData [pSequencing] pDataArray
    lock screen
    
    ## We must initialize before going on
    if not sInit then _Initialize
    
    _ResetData
    put pDataArray into sDataArray
    if pSequencing is not empty then
        put pSequencing into sIndexSequencing
    else
        ## Populate sequencing. This determines order of indexes in array
        put the keys of sDataArray into sIndexSequencing 
        sort lines of sIndexSequencing numeric
        replace cr with comma in sIndexSequencing 
    end if
     
    switch _ControlType()
        case "table"
            if the dgProps["sort by column"] of me is not empty then
                SortByColumn the dgProps["sort by column"] of me
            end if
            break        
    end switch
    
    _StorePersistentData
    _DrawList
    
    unlock screen
end dgData


## We can set the number of records. You can only get the number of lines as the number
## of lines is representative of the number of records.
getprop dgNumberOfLines
    return max(0, the number of elements of sDataArray)
end dgNumberOfLines


getprop dgNumberOfRecords
    return max(0, the number of elements of sDataArray)
end dgNumberOfRecords


## Calling this wipes out the array and creates empty values for
## records up to pNumber. These records will be filled in on an as needed basis
## when scrolling through the list.
setprop dgNumberOfRecords pNumber
    _DataCanBeRepresentedAsText false
    
    if pNumber is not an integer or pNumber < 0 then put 0 into pNumber
    set the dgProps["persistent data"] of me to false ## can't be persistent 
    put empty into sDataArray
    put empty into sIndexSequencing
    
    repeat with i = 1 to pNumber
        put NULL into sDataArray[i]
        put i & comma after sIndexSequencing
    end repeat
    delete the last char of sIndexSequencing
    
    _DrawList
end dgNumberOfRecords
 
 
--> Custom Properties (General)


private function _ControlType
    return the dgProps["style"] of me
end _ControlType

getprop dgAnimating
    return sIsAnimating
end dgAnimating


getprop uScriptLocal [pVarName]
   local theDo
   put "return" && pVarName into theDo
   do theDo
end uScriptLocal


setprop dgFocus pValue
    if pValue then
        ## Don't pull focus from child control
        if the long ID of me is not in the long ID of the focusedObject then 
            focus on graphic "dgBackground" of me
            _UpdateHiliteColor
        end if
    else
        focus on nothing
    end if
end dgFocus


-- Returns column number of the target. Number is relative to visible columns.
getprop dgColumnNumber
   local theColumn
   put the dgColumn of the target into theColumn
   if theColumn is not empty then
      set the wholeMatches to true
      return lineOffset(theColumn, _table.VisibleColumns())
   else
      return 0
   end if
end dgColumnNumber


## This property is dynamic so we don't have to 
## constantly update property as we add/delete controls
## The target is a list control
getprop dgLine
   local theControl
   put the dgDataControl of the target into theControl
   if the long ID of theControl is not the long ID of the target then pass dgLine
   
   local theIndex
   put the dgIndex of theControl into theIndex
   return the dgLineOfIndex[theIndex] of me
end dgLine


## Returns indexes in order of sequencing
getprop dgIndexes
    return sIndexSequencing
end dgIndexes


setprop dgIndexes pIndexes
    put pIndexes into sIndexSequencing
    
    _StorePersistentSequence
     
    lock screen
    _ResetIndexesOnControls
    _RedrawList
    unlock screen
end dgIndexes


## Lines and sequences are synonymous
getprop dgIndexOfLine [pLine]
    set the wholeMatches to true
    return item pLine of sIndexSequencing 
end dgIndexOfLine
 
 
## Use to reorder an index
setprop dgLineOfIndex [pIndex] pLine
    _SetSequenceOfIndex pIndex, pLine
    RefreshList
end dgLineOfIndex


getprop dgLineOfIndex [pIndex]
    set the wholeMatches to true
    return itemOffset(pIndex, sIndexSequencing)
end dgLineOfIndex


## doesn't refresh
command SetLineOfIndex pIndex, pLine
    _SetSequenceOfIndex pIndex, pLine
end SetLineOfIndex


getprop dgVisibleLines
    return _VisibleSequences()
end dgVisibleLines


private function _VisibleSequences
   local theControls
   put _ListOfVisibleControls() into theControls
   if theControls is empty or the keys of sDataArray is empty then return "0,0"
   
   local theMaskRect, theFirstSequence, theLastSequence
   put the rect of group "dgList" of me into theMaskRect
   
   put empty into theFirstSequence
   put empty into theLastSequence
   
   repeat for each line theControl in theControls
      local theRect, theLineNo
      put the rect of theControl into theRect
      ## When checking if opposite coordinate is in view don't use =. = does not mean visible in this case.
      ## e.g. is top of control above the bottom of the mask rect?
      if (item 2 of theRect >= item 2 of theMaskRect and item 2 of theRect < item 4 of theMaskRect) or \
            (item 4 of theRect > item 2 of theMaskRect and item 4 of theRect <= item 4 of theMaskRect) then
         put the dgLine of theControl into theLineNo
         if theLineNo > 0 then
            if theFirstSequence is empty then put theLineNo into theFirstSequence
            else put min(theLineNo, theFirstSequence) into theFirstSequence
            if theLastSequence is empty then put theLineNo into theLastSequence
            else put max(theLineNo, theLastSequence) into theLastSequence
         end if
      end if
   end repeat
   
   return theFirstSequence & comma & theLastSequence
end _VisibleSequences


## Returns a return delimited list of the value of pKey for all highlighted indexes.
getprop dgKeyValuesOfHilitedIndexes [pKey]
    return GetKeyValuesOfIndexes(sHilitedIndexes, cr, pKey)
end dgKeyValuesOfHilitedIndexes


getprop dgFormattedHeight
    return sFormattedHeight
end dgFormattedHeight


getprop dgFormattedWidth
    return sFormattedWidth
end dgFormattedWidth


## temporary aliases
setprop uProps [pProp] pValue
    if the target is not me then pass uProps
    set the dgProps[pProp] of me to pValue
end uProps


getprop uProps[pProp]
    if the target is not me then pass uProps
    return the dgProps[pProp] of me
end uProps
## end temporary aliases


setprop dgProp [pProp] pValue
    set the dgProps[pProp] of me to pValue
end dgProp


getprop dgProp [pProp]
    return the dgProps[pProp] of me
end dgProp


private function _IsListOPositivefIntegers pList, pMatchCount
    if pMatchCount and the number of items of pList is not pMatchCount then return false
    
    repeat for each item theItem in pList
        if theItem is not an integer or theItem < 0 then return false
    end repeat
    
    return true
end _IsListOPositivefIntegers

 
## Setting this property resets control height properties
setprop dgProps [pProp] pValue
   if the target is not me then pass dgProps
   
   switch pProp
      case "ascending sort icon"
      case "descending sort icon"
         if pValue is not empty and pValue is not an integer then _ThrowError kErrInvalidInteger, pValue && "is not an integer"
         lock messages
         set the dgProps[pProp] of me to pValue
         unlock messages
         
         lock screen
         local theSortBy
         put the dgProps["sort by column"] of me into theSortBy
         repeat for each key theColumn in sTableObjectsA["columns"]
            repeat for each line theControl in sTableObjectsA["columns"][theColumn]["header"]["group"]
               set the dgHilite of theControl to theColumn is theSortBy
            end repeat
         end repeat
         unlock screen
         break
         
      case "border color"
         if pValue is not a color and pValue is not empty then 
            _ThrowError kErrInvalidColor, pValue && "is not a color"
         end if
         
         lock screen
         set the borderColor of me to pValue
         set the foregroundColor of graphic "dgHeaderBottomBorder" of me to pValue
         unlock screen
         break
         
      case "header margins"
      case "column margins"
         if pValue is not empty and pValue is not an integer and not (_IsListOPositivefIntegers(pValue, 4)) then
            _ThrowError kErrInvalidProperty, "'" & pValue & "' is not a valid margin"
         end if
         
         if pValue is an integer then
            get pValue
            repeat with i = 2 to 4
               put it into item i of pValue
            end repeat
         end if
         
         lock messages
         set the dgProps[pProp] of me to pValue
         unlock messages
         
         if pProp is "header margins" then
            repeat for each key theColumn in sTableObjectsA["columns"]
               repeat for each line theControl in sTableObjectsA["columns"][theColumn]["header"]["group"]
                  dispatch "LayoutControl" to theControl with the rect of theControl
               end repeat
            end repeat
         else
            ResetList
         end if
         break
         
      case "scrollbar width"
         if pValue is not "auto" and (pValue is not an integer or pValue < 0) then \
               then _ThrowError kErrInvalidInteger, pValue && "is not an integer >= 0 or 'auto'"
         
         lock messages
         set the dgProps[pProp] of me to pValue 
         unlock messages
         
         lock screen
         _SetScrollbarWidth pValue
         
         if _ControlType() is "table" then
            _table.LayoutDataArea
            RefreshList
         end if
         unlock screen
         break
         
      case "header height"
         if pValue is not an integer or pValue < 0 then _ThrowError kErrInvalidInteger, pValue && "is not an integer >= 0"
         lock screen
         local theOrigVScroll, theRect
         put _GetVScrollPercent() into theOrigVScroll
         put the rect of group "dgHeaderMask" of me into theRect
         put item 2 of theRect + pValue into item 4 of theRect
         set the rect of group "dgHeaderMask" of me to theRect
         _table.LayoutDataArea
         _table.ResizeHeaders
         #<mikey>
         # Attempt to fix bug 12427 - resizing a header vertically doesn't resize the column dividers (also called the leftHilite and rightHilight).
         # We do it here instead of _table.resizeHeader or _table.repositionHeaders b/c those handlers are designed to handle the user resizing the column by dragging
         # on it.  To resize the column dividers there would mess with performance.  _table.ResizeHeaderBackground does not touch the column headers.
         local rectOfMe
         repeat for each line theColumn in the childControlNames of group "dgHeader" of group "dgHeaderMask" of group "dgHeaderComponents" of me
            put the rect of graphic "leftHilite" of group theColumn of group "dgHeader" of group "dgHeaderMask" of group "dgHeaderComponents" of me into rectOfMe
            put item 4 of theRect into item 4 of rectOfMe
            set the rect of graphic "leftHilite" of group theColumn of group "dgHeader" of group "dgHeaderMask" of group "dgHeaderComponents" of me to rectOfMe 
                        		
            put the rect of graphic "rightHilite" of group theColumn of group "dgHeader" of group "dgHeaderMask" of group "dgHeaderComponents" of me into rectOfMe
            put item 4 of theRect into item 4 of rectOfMe
            set the rect of graphic "rightHilite" of group theColumn of group "dgHeader" of group "dgHeaderMask" of group "dgHeaderComponents" of me to rectOfMe 
         end repeat # for each line theColumn of the childControlNames of group "dgHeader" of group "dgHeaderMask" of group "dgHeaderComponents" of me
         #</mikey>
         ResizeToFit # TDK-2014-07-25: The list needs to be redrawn to fit in the new mask area.
         unlock screen
         break
         
      case "text font"
         lock screen
         if pValue is empty then
            set the textFont of group "dgList" of me to pValue
         else
            local theStyle, theSize
            put the textStyle of group "dgList" of me into theStyle
            put the textSize of group "dgList" of me into theSize
            set the textFont of group "dgList" of me to pValue
            set the textStyle of group "dgList" of me to theStyle
            set the textSize of group "dgList" of me to theSize
         end if
         unlock screen
         break
         
      case "text style"
         set the textStyle of group "dgList" of me to pValue
         break
         
      case "text size"
         set the textSize of group "dgList" of me to pValue
         break
         
      case "text color"
         set the textColor of group "dgList" of me to _ColorToRGB(pValue)
         break
         
      case "header text font"
         lock screen
         if pValue is empty then
            set the textFont of group "dgHeader" of me to pValue
         else
            put the textStyle of group "dgHeader" of me into theStyle
            put the textSize of group "dgHeader" of me into theSize
            set the textFont of group "dgHeader" of me to pValue
            set the textStyle of group "dgHeader" of me to theStyle
            set the textSize of group "dgHeader" of me to theSize
         end if
         unlock screen
         break
         
      case "header text style"
         lock screen
         set the textStyle of group "dgHeader" of me to pValue
         unlock screen
         break
         
      case "header text size"
         lock screen
         set the textSize of group "dgHeader" of me to pValue
         unlock screen
         break
         
      case "header text color"
         lock screen
         set the textColor of group "dgHeader" of me to _ColorToRGB(pValue)
         unlock screen
         break
         
      case "show vscrollbar"
         lock messages
         if pValue is "auto" then
            set the dgProps[pProp] of me to pValue
         else
            put pValue is true into pValue
            set the dgProps[pProp] of me to pValue
         end if
         unlock messages
         if pValue is "auto" then
            _ToggleVScrollBarVisibility the thumbSize of scrollbar "dgScrollbar" of me < the endValue of scrollbar "dgScrollbar" of me
         else
            _ToggleVScrollBarVisibility the dgProps[pProp] of me
         end if
         break
         
      case "show hscrollbar"
         lock messages
         if pValue is "auto" then
            set the dgProps[pProp] of me to pValue
         else
            put pValue is true into pValue
            set the dgProps[pProp] of me to pValue
         end if
         unlock messages
         if _ControlType() is "table" then
            if pValue is "auto" then
               _ToggleHScrollBarVisibility the thumbSize of scrollbar "dgHScrollbar" of me < the endValue of scrollbar "dgHScrollbar" of me
            else
               _ToggleHScrollBarVisibility the dgProps[pProp] of me
            end if
         end if
         break
         
      case "corner color"
         local theGraphic
         put the long ID of graphic "dgCornerPiece" of group "dgHorizontalComponents" of me into theGraphic
         set the backgroundColor of theGraphic to empty
         
         if pValue is an array then
            ## Setting fillGradient
            repeat for each key theKey in pValue
               set the fillGradient[theKey] of theGraphic to pValue[theKey]
            end repeat
            
         else if the number of lines of pValue is 2 and line 1 of pValue is a color and line 2 of pValue is a color then
            ## Create gradient for developer
            _SetGraphicGradient theGraphic, line 1 of pValue, line 2 of pValue
         else if pValue is a color then
            set the backgroundColor of theGraphic to pValue
         else
            set the backgroundColor of theGraphic to kDefaultCornerColor
            put kDefaultCornerColor into pValue
         end if
         lock messages
         set the dgProps[pProp] of me to pValue
         unlock messages
         unlock screen
         break
         
      case "header background color"
         lock screen
         
         put the long ID of graphic "dgBackground" of group "dgHeaderMask" of group "dgHeaderComponents" of me into theGraphic
         set the backgroundColor of theGraphic to empty
         
         if pValue is an array then
            ## Setting fillGradient
            repeat for each key theKey in pValue
               set the fillGradient[theKey] of theGraphic to pValue[theKey]
            end repeat
            
         else if the number of lines of pValue is 2 and line 1 of pValue is a color and line 2 of pValue is a color then
            ## Create gradient for developer
            _table.SetHeaderBkgrndGradient line 1 of pValue, line 2 of pValue
         else if pValue is a color then
            set the backgroundColor of theGraphic to pValue
         else
            _table.SetHeaderBkgrndGradient kHeaderBkgrndStartColor, kHeaderBkgrndEndColor
            put kHeaderBkgrndStartColor & cr & kHeaderBkgrndEndColor into pValue
         end if
         lock messages
         set the dgProps[pProp] of me to pValue
         unlock messages
         unlock screen
         break
         
      case "header background hilite color"
         lock screen
         if pValue is not an array and \
               (line 1 of pValue is not a color and line 2 of pValue is not a color) and \
               pValue is not a color then
            put kHeaderBkgrndHiliteStartColor & cr & kHeaderBkgrndHiliteEndColor into pValue
         end if
         _table.SetHeaderBkgrndHiliteColor pValue
         lock messages
         set the dgProps[pProp] of me to pValue
         unlock messages
         unlock screen
         break
         
      case "header divider color"
      case "header divider threed color"
         lock screen
         if pValue is not a color then
            if pProp is "header divider color" then
               put kHeaderDividerColor into pValue
            else
               put kHeaderDividerThreeDColor into pValue
            end if
         else
            put _ColorToRGB(pValue) into pValue
         end if
         lock messages
         set the dgProps[pProp] of me to pValue
         unlock messages
         _table.UpdateHeaderDividerColors pValue
         unlock screen
         break
         
      case "style"
         lock screen
         _DeleteDataControls
         
         if pValue is "table" then
            lock screen
            show group "dgDividers" of group "dgListMask" of me
            set the visible of group "dgHeaderComponents" of me to the dgProps["show header"] of me is true
            show group "dgHorizontalComponents" of me
            _table.RegenerateColumns
            -- set the uEffectiveColumnWidths of group "dgHeader" of group "dgHeaderMask" of group "dgHeaderComponents" of me \
            -- to _table.GetEffectiveColumnWidths()
            
            ## Set any props that have special settings for table.
            lock messages
            set the dgProps["cache controls"] of me to false
            unlock messages      
            unlock screen
         else
            put "form" into pValue
            hide group "dgDividers" of group "dgListMask" of me
            hide group "dgHeaderComponents" of me
            hide group "dgHorizontalComponents" of me
            _table.DeleteColumnControls
            put empty into sTableObjectsA
         end if
         
         lock messages ## in case target is a child of me
         set the dgProps["style"] of me to pValue
         unlock messages      
         
         ResizeToFit
         ResetList
         unlock screen
         break
         
      case "record template" ## early dev versions
      case "row template"
         put "row template" into pProp
         if pValue is not empty and there is not a pValue then
            answer quote & pValue & quote && "does not exist. Cannot set" && pProp & "."
         else if pValue is not empty and word 1 of pValue is not "group" then
            answer quote & pValue & quote && "is not a group. Cannot set" && pProp & "."
         else             
            if pValue is not empty then
               put _CustomControlReference(pValue) into pValue
            end if
            
            lock messages ## in case target is a child of me
            set the dgProps["row template"] of me to pValue
            unlock messages
            put empty into sFormattedHeight
            put empty into sControlHeights
            
            DG2_EnsureRowChainedBehavior
         end if
         break
         
      case "persistent data"
         lock messages ## in case target is a child of me
         set the dgProps["persistent data"] of me to pValue is true
         unlock messages
         
         if pValue then
            _StorePersistentData
         else
            set the customProperties["dgCache"] of me to empty
         end if
         break
         
      case "fixed control height" ## early dev builds
      case "fixed row height"
         put "fixed row height" into pProp
         ## Setting this property resets control height properties
         lock messages
         set the dgProps[pProp] of me to pValue is true
         unlock messages
         put empty into sFormattedHeight
         put empty into sControlHeights
         
         ResetList
         break
         
      case "multiple lines"
      case "cache controls"
      case "auto hilite"
      case "animate selections"
      case "data can be represented as text"
      case "dim on focusOut"
      case "allow editing"
      case "allow column resizing"
      case "scroll when vscrollbar is hidden"
      case "scroll when hscrollbar is hidden"
      case "scroll selections into view"
         
      case "animate actions"
      case "enable swipe"
         lock messages
         set the dgProps[pProp] of me to pValue is true
         unlock messages
         break
         
      case "edit mode action control"
      case "edit mode action select control"
      case "edit mode reorder control"
      case "left swipe control"
      case "right swipe control"
         if pValue is not empty and there is not a pValue then
            answer quote & pValue & quote && "does not exist. Cannot set" && pProp & "."
         else
            if pValue is not empty then
               put _CustomControlReference(pValue) into pValue
            end if
            lock messages
            set the dgProps[pProp] of me to pValue
            unlock messages
            
            -- We're setting new template controls. Redraw the list to take these new controls into account.
            DG2_CustomisableControlsClearByName pProp
            RefreshList
         end if
         break
         
      case "alternate row colors"
         lock messages
         set the dgProps[pProp] of me to pValue is true
         unlock messages
         
         lock screen
         _DrawAlternatingRows
         _ShowAlternatingRows
         
         if _ControlType() is "form" then
            _list.UpdateAlternatingRowColors
         end if
         unlock screen
         break       
         
      case "opaque"
         set the opaque of graphic "dgBackground" of me to pValue is true
         break
         
      case "background color"
         if pValue is a color or pValue is empty then
            put _ColorToRGB(pValue) into pValue
            set the backgroundColor of graphic "dgBackground" of me to pValue
            lock messages
            set the dgProps[pProp] of me to pValue
            unlock messages
         else
            _ThrowError kErrInvalidColor, pValue && "is not a color"
         end if
         break
         
      case "row color"
         if pValue is a color or pValue is empty then
            lock messages
            set the dgProps[pProp] of me to _ColorToRGB(pValue)
            unlock messages
            
            ## Update colors
            lock screen
            _DrawAlternatingRows
            
            if _ControlType() is "form" then
               _list.UpdateAlternatingRowColors
            end if
            unlock screen
         else
            _ThrowError kErrInvalidColor, pValue && "is not a color"
         end if
         break
         
      case "alternate row color"
         if pValue is a color or pValue is empty then
            lock messages
            set the dgProps[pProp] of me to _ColorToRGB(pValue)
            unlock messages
            
            ## Update colors
            lock screen
            _DrawAlternatingRows
            
            if _ControlType() is "form" then
               _list.UpdateAlternatingRowColors
            end if
            unlock screen
         else
            _ThrowError kErrInvalidColor, pValue && "is not a color"
         end if
         break
         
      case "column divider color"
         if pValue is a color or pValue is empty then
            lock messages
            set the dgProps[pProp] of me to _ColorToRGB(pValue)
            unlock messages
            
            repeat for each line theColumn in the dgProps["columns"] of me
               put sTableObjectsA["columns"][theColumn]["divider control"] into theControl
               if there is a theControl then
                  set the foregroundColor of theControl to  _GetEffectiveColor("column divider color")
               end if
            end repeat
         else
            _ThrowError kErrInvalidColor, pValue && "is not a color"
         end if
         break
         
      case "hilite color"
      case "dimmed hilite color"
         if pValue is a color or pValue is empty then
            lock messages
            set the dgProps[pProp] of me to _ColorToRGB(pValue)
            unlock messages
            
            ## update color
            if _ControlType() is "table" then
               _table.LayoutRowHilites
            else
               _HiliteIndexesInVisibleControls
            end if
         else
            _ThrowError kErrInvalidColor, pValue && "is not a color"
         end if
         break
         
      case "hilited text color"
         if pValue is a color or pValue is empty then
            lock messages
            set the dgProps[pProp] of me to _ColorToRGB(pValue)
            unlock messages
         else
            _ThrowError kErrInvalidColor, pValue && "is not a color"
         end if
         break
         
      case "scrollbar offset"
         ## deprecated, no longer used
         if pValue is not a point then
            _ThrowError kErrInvalidPoint, pValue && "is not a point"
         end if
         lock messages
         set the dgProps["scrollbar corner offset"] of me to item 2 of pValue
         unlock messages
         ResizeToFit
         break
         
      case "scrollbar corner offset"
         if pValue is not an integer or pValue < 0 then
            _ThrowError kErrInvalidInteger, pValue && "is not an integer >= 0"
         end if 
         lock messages
         set the dgProps[pProp] of me to pValue
         unlock messages
         ResizeToFit
         break
         
      case "row height"
         if pValue is not empty and (pValue is not an integer or pValue < 0) then
            _ThrowError kErrInvalidInteger, pValue && "is not an integer"
         else
            lock messages
            set the dgProps[pProp] of me to pValue
            unlock messages
            lock screen
            
            -- Update any customisable controls to take into account the row resize.
            DG2_CustomisableControlsResizeDefaults
            DG2_CustomisableControlsClear
            
            ResetList 
            unlock screen
         end if
         break
         
         ## Table   
         
      case "sort by column"
         _SortByColumn pValue
         break
         
      case "show header"
         -- lock messages
         -- set the dgProps [pProp] of me to pValue
         -- unlock messages
         lock screen
         set the visible of group "dgHeaderComponents" of me to pValue is true
         ResizeToFit
         unlock screen
         break
         
      case "columns"
         put word 1 to -1 of pValue into pValue
         repeat for each line theLine in pValue
            if theLine is empty then _ThrowError kErrInvalidProperty, "column name cannot be empty'"
            local theLinesA
            if theLinesA[theLine] is not empty then _ThrowError kErrInvalidProperty, "duplicate column name '" & theLine & "'"
            put 1 into theLinesA[theLine]
         end repeat
         
         lock messages
         set the dgProps [pProp] of me to pValue
         
         ## Don't sort by a non-existent column
         if the dgProps["sort by column"] of me is not empty \
               and the dgProps["sort by column"] of me is not among the lines of pValue then
            set the dgProps["sort by column"] of me to empty
         end if
         
         unlock messages
         
         lock screen
         _table.RegenerateColumns
         
         _table.DrawColumns _table.VisibleColumns()
         unlock screen
         break
         
      case "column labels"
         lock screen
         repeat for each line theColumn in the dgProps["columns"] of me
            add 1 to i
            set the dgColumnLabel [theColumn] of me to line i of pValue
         end repeat
         unlock screen
         break
         
      case "column widths"
         lock screen
         local theLastWidth, theWidth
         put item -1 of pValue into theLastWidth
         if theLastWidth is not an integer then
            _ThrowError kErrInvalidInteger, "invalid column width value '" & pValue & "'"
         end if
         
         repeat for each line theColumn in the dgProps["columns"] of me
            add 1 to i
            put item i of pValue into theWidth
            if theWidth is not an integer then put theLastWidth into theWidth
            _StoreColWidth theColumn, theWidth
         end repeat
         
         _table.ResizeColumns
         
         unlock screen
         break
         
      case "show column dividers"
         set the visible of group "dgDividers" of group "dgListMask" of me to pValue is true
         break
         
      case "column alignments"
         lock screen
         repeat for each line theColumn in the dgProps["columns"] of me
            add 1 to i
            set the dgColumnAlignment [theColumn] of me to item i of pValue
         end repeat
         unlock screen
         break
         
      case "column visibility"
         lock screen
         repeat for each line theColumn in the dgProps["columns"] of me
            add 1 to i
            set the dgColumnIsVisible [theColumn] of me to item i of pValue
         end repeat
         unlock screen
         break
         
      case "default column behavior"
         if pValue is not empty then
            put _CustomControlReference(pValue) into pValue
         end if
         
         lock messages ## in case target is a child of me
         set the dgProps["default column behavior"] of me to pValue
         unlock messages
         break
         
      case "default header behavior"
         if pValue is not empty then
            put _CustomControlReference(pValue) into pValue
         end if
         
         lock messages ## in case target is a child of me
         set the dgProps["default header behavior"] of me to pValue
         unlock messages
         break
         
      case "control type"
         lock messages
         set the dgProps[pProp] of me to "Data Grid"
         unlock messages
         break

      case "minimal layout"
         lock messages
         set the dgProps[pProp] of me to pValue is true
         unlock messages
         break
         
      default
         throw "invalid property '" & pProp & "'"       
   end switch
   
   -- pass dgProps
   return empty
end dgProps


getprop dgProps [pProp]
   if the target is not me then pass dgProps
   
   local theValue
   
   switch pProp
      case "ascending sort icon"
         lock messages
         get the dgProps[pProp] of me
         unlock messages
         if it < 1 then get "103004"
         return it
         break
      case "descending sort icon"
         lock messages
         get the dgProps[pProp] of me
         unlock messages
         if it < 1 then get "103005"
         return it
         break
      case "header margins"
      case "column margins"
         lock messages
         get the dgProps[pProp] of me
         if it is empty then get 8
         unlock messages
         return it
         break
      case "header height"
         return the height of group "dgHeader" of me
         break
         
      case "text font"
         return the textFont of group "dgList" of me
         break
         
      case "effective text font"
         return the effective textFont of group "dgList" of me
         break
         
      case "text style"
         return the textStyle of group "dgList" of me
         break
         
      case "effective text style"
         return the effective textStyle of group "dgList" of me
         break
         
      case "text size"
         return the textSize of group "dgList" of me
         break
         
      case "effective text size"
         return the effective textSize of group "dgList" of me
         break
         
      case "header text font"
         return the textFont of group "dgHeader" of me
         break
         
      case "effective header text font"
         return the effective textFont of group "dgHeader" of me
         break
         
      case "header text style"
         return the textStyle of group "dgHeader" of me
         break
         
      case "effective header text style"
         return the effective textStyle of group "dgHeader" of me
         break
         
      case "header text size"
         return the textSize of group "dgHeader" of me
         break
         
      case "effective header text size"
         return the effective textSize of group "dgHeader" of me
         break
         
      case "header text color"
         return the textColor of group "dgHeader" of me
         break
         
      case "effective header text color"
         return the effective textColor of group "dgHeader" of me
         break
         
      case "effective alternate row color"
      case "effective column divider color"
      case "effective row color"
      case "effective dimmed hilite color"
      case "effective hilite color"
         return _GetEffectiveColor(word 2 to -1 of pProp)
         break
         
      case "effective text color"
         return the effective textColor of group "dgList" of me
         break
         
      case "text color"
         return the textColor of group "dgList" of me
         break
         
      case "hilited text color"
         return _GetEffectiveColor(pProp)
         break
         
      case "border color"
         return the borderColor of me
         break
         
      case "effective border color"
         return the effective borderColor of me
         break
         
      case "background color"
         local tColor
         if the dgProps[pProp] of me is not a color then
            return the backgroundColor of graphic "dgBackground" of me
         else
            return the dgProps[pProp] of me
         end if
         break
         
      case "opaque"
         return the opaque of graphic "dgBackground" of me
         break
         
      case "visible columns"
         if _ControlType() is "table" then
            return _table.VisibleColumns()
         else
            return empty
         end if
         break
         
      case "column widths"
         local theColPropsA
         put the dgProps["column properties"] of me into theColPropsA
         repeat for each line theColumn in the dgProps["columns"] of me
            put theColPropsA[theColumn]["width"] & comma after theValue
         end repeat
         delete the last char of theValue
         return theValue
         break
         
      case "column labels"
         put the dgProps["column properties"] of me into theColPropsA
         repeat for each line theColumn in the dgProps["columns"] of me
            put theColPropsA[theColumn]["label"] & cr after theValue
         end repeat
         delete the last char of theValue
         return theValue
         break
         
      case "column visibility"
         put the dgProps["column properties"] of me into theColPropsA
         repeat for each line theColumn in the dgProps["columns"] of me
            put theColPropsA[theColumn]["visible"] & comma after theValue
         end repeat
         delete the last char of theValue
         return theValue
         break
         
      case "column alignments"
         put the dgProps["column properties"] of me into theColPropsA
         repeat for each line theColumn in the dgProps["columns"] of me
            put theColPropsA[theColumn]["alignment"] & comma after theValue
         end repeat
         delete the last char of theValue
         return theValue
         break
         
      case "show column dividers"
         return the visible of group "dgDividers" of group "dgListMask" of me
         break
         
      case "show header"
         return the visible of group "dgHeaderComponents" of me
         break
         
      case "effective hilite color"
         return _GetHiliteColor()
         break
         
      case "effective scrollbar width"
         return the width of scrollbar "dgScrollbar" of me
         break
         
      case "scrollbar corner offset"
         ## Forced integers >= 0
         lock messages
         put the dgProps[pProp] of me into theValue
         unlock messages
         return max(0, theValue)
         break
         
      case "record template" ## early dev versions
         return the dgProps["row template"] of me
         break
         
      case "fixed control height" ## early dev versions
         return the dgProps["fixed row height"] of me
         break

      case "minimal layout"
         return the dgProps["minimal layout"] of me
         break
   end switch
   
   pass dgProps
end dgProps


## Renames a column
setprop dgColumnName [pColumn] pValue
   if word 1 to -1 of pValue is empty or char 1 of pValue is space or the last char of pValue is space then 
      _ThrowError kErrInvalidProperty, quote & pValue & quote && "is not a valid column name" 
   end if
   
   set the wholeMatches to true
   
   ## Update list of columns, replacing line with old name with new name
   local theColumns, theLineNo, theBadLineNo
   put the dgProps["columns"] of me into theColumns
   put lineOffset(pColumn, theColumns) into theLineNo
   
   if theLineNo is 0 then _ThrowError kErrInvalidProperty, "column '" & pColumn & "' does not exist"
   
   put lineOffset(pValue, theColumns) into theBadLineNo
   if theBadLineNo > 0 then _ThrowError kErrRenameErrorInDestination, "column '" & pValue & "' already exists"
   
   lock screen
   
   local theSortByColumn
   put the dgProps["sort by column"] of me into theSortByColumn
   
   ## Rename column
   put pValue into line theLineNo of theColumns
   lock messages
   set the dgProps["columns"] of me to theColumns
   
   ## rename column properties
   local theColPropsA
   put the dgProps["column properties"] of me into theColPropsA
   put theColPropsA[pColumn] into theColPropsA[pValue]
   set the dgProps["column properties"] of me to theColPropsA
   unlock messages
   
   ## Rename data keys
   repeat for each key theKey in sDataArray        
      put sDataArray[theKey][pColumn] into sDataArray[theKey][pValue]      
      delete local sDataArray[theKey][pColumn]
   end repeat
   
   _table.DeleteColumn pColumn
   
   ## refresh
   _table.RegenerateColumns
   _table.DrawColumns pValue
   
   if theSortByColumn is pColumn then
      _SortByColumn pValue
   end if
   
   _StorePersistentData
   
   unlock screen
end dgColumnName


setprop dgColumnSortType [pColumn] pValue
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if pColumn is not among the keys of theColsA then
      _ThrowError kErrInvalidProperty, "column '" & pColumn & "' does not exist"
   end if
   if pValue is not among the items kSortTypes then
      _ThrowError kErrInvalidProperty, "invalid column sort type value '" & pValue & "'"
   end if
   
   put toLower(pValue) into theColsA[pColumn]["sort type"]
   
   lock messages
   set the dgProps["column properties"] of me to theColsA
   unlock messages
   
   ## Update sort if need be
   if the dgProps["sort by column"] of me is pColumn then
      _SortByColumn pColumn
   end if
end dgColumnSortType

getprop dgColumnSortType [pColumn]
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   return theColsA[pColumn]["sort type"]
end dgColumnSortType


setprop dgColumnSortDirection [pColumn] pValue
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if pColumn is not among the keys of theColsA then
      _ThrowError kErrInvalidProperty, "column '" & pColumn & "' does not exist"
   end if
   if pValue is not among the items "ascending,descending" then
      _ThrowError kErrInvalidProperty, "invalid column sort direction value '" & pValue & "'"
   end if
   
   put toLower(pValue) into theColsA[pColumn]["sort direction"]
   
   lock messages
   set the dgProps["column properties"] of me to theColsA
   unlock messages
   
   ## Update sort if need be
   if the dgProps["sort by column"] of me is pColumn then
      _SortByColumn pColumn
   end if
end dgColumnSortDirection

getprop dgColumnSortDirection [pColumn]
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   return theColsA[pColumn]["sort direction"]
end dgColumnSortDirection


setprop dgColumnSortIsCaseSensitive [pColumn] pValue
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if pColumn is not among the keys of theColsA then
      _ThrowError kErrInvalidProperty, "column '" & pColumn & "' does not exist"
   end if
   if pValue is not a boolean then 
      _ThrowError kErrInvalidBoolean, "invalid boolean value for column sort is case sensitive '" & pValue & "'"
   end if
   
   put toLower(pValue) into theColsA[pColumn]["sort is case sensitive"]
   
   lock messages
   set the dgProps["column properties"] of me to theColsA
   unlock messages
   
   ## Update sort if need be
   if the dgProps["sort by column"] of me is pColumn then
      _SortByColumn pColumn
   end if
end dgColumnSortIsCaseSensitive

getprop dgColumnSortIsCaseSensitive [pColumn]
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   return theColsA[pColumn]["sort is case sensitive"]
end dgColumnSortIsCaseSensitive


setprop dgColumnIsVisible [pColumn] pValue
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if pColumn is not among the keys of theColsA then
      _ThrowError kErrInvalidProperty, "column '" & pColumn & "' does not exist"
   end if
   if pValue is not a boolean then 
      _ThrowError kErrInvalidBoolean, "invalid boolean value for column visibility '" & pValue & "'"
   end if
   
   put toLower(pValue) into theColsA[pColumn]["visible"]
   
   lock messages
   set the dgProps["column properties"] of me to theColsA
   unlock messages
   
   if sTableObjectsA["columns"][pColumn]["group"] is not empty then
      lock screen
      set the visible of sTableObjectsA["columns"][pColumn]["group"] to pValue
      set the visible of sTableObjectsA["columns"][pColumn]["header"]["group"] to pValue
      set the visible of sTableObjectsA["columns"][pColumn]["divider control"] to pValue
      
      _table.RepositionHeadersAndColumns
      
      if sTableObjectsA["row control count"] > 0 then
         _table.CreateControlsForColumns pColumn
         _table.DrawColumns pColumn
         
         ## check for scrollbar show/hide
         if the dgProps["show hscrollbar"] of me is "auto" then
            ## todo: optimize so we don't toggle unless we need to
            local theSetting
            put the visible of group "dgHorizontalComponents" of me into theSetting
            _AutoHideHScrollbar     
            if the visible of group "dgHorizontalComponents" of me is not theSetting then
               _ToggleHScrollBarVisibility the visible of group "dgHorizontalComponents" of me
            end if
         end if
      end if
      unlock screen
   end if
end dgColumnIsVisible


getprop dgColumnIsVisible [pColumn]
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   return theColsA[pColumn]["visible"]
end dgColumnIsVisible


setprop dgColumnLabel [pColumn] pValue
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if pColumn is not among the keys of theColsA then
      _ThrowError kErrInvalidProperty, "column '" & pColumn & "' does not exist"
   end if
   
   put pValue into theColsA[pColumn]["label"]
   if the platform is "macos" then put "mac" into theColsA[pColumn]["encoding"]
   else put "iso" into theColsA[pColumn]["encoding"]
   
   lock messages
   set the dgProps["column properties"] of me to theColsA
   unlock messages
   
   _table.UpdateHeaderLabel pColumn, pValue, theColsA[pColumn]["encoding"]
end dgColumnLabel


getprop dgColumnLabel [pColumn]
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   return theColsA[pColumn]["label"]
end dgColumnLabel


getprop dgColumnLabelEncoding [pColumn]
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   return theColsA[pColumn]["encoding"]
end dgColumnLabelEncoding


setprop dgColumnTooltip [pColumn] pValue
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if pColumn is not among the keys of theColsA then
      _ThrowError kErrInvalidProperty, "column '" & pColumn & "' does not exist"
   end if
   
   put pValue into theColsA[pColumn]["tooltip"]
   
   lock messages
   set the dgProps["column properties"] of me to theColsA
   unlock messages
   
   _table.UpdateHeaderTooltip pColumn, pValue
end dgColumnTooltip


getprop dgColumnTooltip [pColumn]
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   return theColsA[pColumn]["tooltip"]
end dgColumnTooltip


setprop dgColumnIsEditable [pColumn] pBoolean
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   put pBoolean is true into theColsA[pColumn]["editable"]
   lock messages
   set the dgProps["column properties"] of me to theColsA
   unlock messages
   
   return empty
end dgColumnIsEditable

 
getprop dgColumnIsEditable [pColumn]
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   return theColsA[pColumn]["editable"] is not false ## default is true
end dgColumnIsEditable


setprop dgColumnIsResizable [pColumn] pValue
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if pColumn is not among the keys of theColsA then
      _ThrowError kErrInvalidProperty, "column '" & pColumn & "' does not exist"
   end if
   if pValue is not a boolean then 
      _ThrowError kErrInvalidBoolean, "invalid boolean value for column is resizable '" & pValue & "'"
   end if
   
   put toLower(pValue) into theColsA[pColumn]["resizable"]
   
   lock messages
   set the dgProps["column properties"] of me to theColsA
   unlock messages
   
   return empty
end dgColumnIsResizable


getprop dgColumnIsResizable [pColumn]
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   return theColsA[pColumn]["resizable"]
end dgColumnIsResizable


setprop dgColumnAlignment [pColumn] pValue
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if pColumn is not among the keys of theColsA then
      _ThrowError kErrInvalidProperty, "column '" & pColumn & "' does not exist"
   end if
   if pValue is not among the items "left,right,center" then 
      _ThrowError kErrInvalidProperty, "invalid column alignment value '" & pValue & "'"
   end if
   
   put toLower(pValue) into theColsA[pColumn]["alignment"]
   
   lock messages
   set the dgProps["column properties"] of me to theColsA
   unlock messages
   
   ## Update alignment
   lock screen
   if not sTableObjectsA["columns"][pColumn]["uses custom template"] then
      repeat for each line theControl in sTableObjectsA["columns"][pColumn]["row controls"]
         set the textAlign of theControl to pValue 
      end repeat
   end if
   unlock screen
end dgColumnAlignment


getprop dgColumnAlignment [pColumn]
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   return theColsA[pColumn]["alignment"]
end dgColumnAlignment


setprop dgHeaderAlignment [pColumn] pValue
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if pColumn is not among the keys of theColsA then
      _ThrowError kErrInvalidProperty, "column '" & pColumn & "' does not exist"
   end if
   if pValue is not among the items "left,right,center" then 
      _ThrowError kErrInvalidProperty, "invalid header alignment value '" & pValue & "'"
   end if
   
   put toLower(pValue) into theColsA[pColumn]["header"]["alignment"]
   
   lock messages
   set the dgProps["column properties"] of me to theColsA
   unlock messages
   
   ## Update alignment
   lock screen
   if sTableObjectsA["columns"][pColumn]["header"]["group"] is not empty then
      set the dgAlignment of sTableObjectsA["columns"][pColumn]["header"]["group"] to pValue
   end if
   unlock screen
end dgHeaderAlignment


getprop dgHeaderAlignment [pColumn]
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   return theColsA[pColumn]["header"]["alignment"]
end dgHeaderAlignment


setprop dgColumnWidth [pColumn] pValue
    _StoreColWidth pColumn, pValue
    _table.ResizeColumns
end dgColumnWidth


private command _StoreColWidth pColumn, pValue
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if pColumn is not among the keys of theColsA then
      _ThrowError kErrInvalidProperty, "column '" & pColumn & "' does not exist"
   end if
   if pValue is not an integer then
      _ThrowError kErrInvalidInteger, "invalid column width value '" & pValue & "'"
   end if
   
   if theColsA[pColumn]["min width"] is empty then put 40 into theColsA[pColumn]["min width"]
   if theColsA[pColumn]["max width"] is empty then put 1000 into theColsA[pColumn]["max width"]
   
   put max(theColsA[pColumn]["min width"], min(pValue, theColsA[pColumn]["max width"])) into theColsA[pColumn]["width"]
   
   lock messages
   set the dgProps["column properties"] of me to theColsA
   unlock messages
end _StoreColWidth


getprop dgColumnWidth [pColumn]
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if theColsA[pColumn]["width"] is empty then return 100
   else return theColsA[pColumn]["width"]
end dgColumnWidth


function _ColumnHeaderGroup pColumn
    return sTableObjectsA["columns"][pColumn]["header"]["group"]
end _ColumnHeaderGroup


setprop dgColumnMinWidth [pColumn] pValue
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if pColumn is not among the keys of theColsA then
      _ThrowError kErrInvalidProperty, "column '" & pColumn & "' does not exist"
   end if
   if pValue is not an integer then
      _ThrowError kErrInvalidInteger, "invalid column width value '" & pValue & "'"
   end if
   
   put pValue into theColsA[pColumn]["min width"]
   
   lock messages
   set the dgProps["column properties"] of me to theColsA
   unlock messages
   
   ## current size must be at least min size
   if theColsA[pColumn]["width"] is empty or theColsA[pColumn]["min width"] > theColsA[pColumn]["width"] then
      set the dgColumnWidth[pColumn] of me to theColsA[pColumn]["min width"]
   end if
   return empty
end dgColumnMinWidth


getprop dgColumnMinWidth [pColumn]
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if theColsA[pColumn]["min width"] is not empty then
      return theColsA[pColumn]["min width"]
   else
      return 40
   end if
end dgColumnMinWidth


setprop dgColumnMaxWidth [pColumn] pValue
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if pColumn is not among the keys of theColsA then
      _ThrowError kErrInvalidProperty, "column '" & pColumn & "' does not exist"
   end if
   if pValue is not an integer then
      _ThrowError kErrInvalidInteger, "invalid column width value '" & pValue & "'"
   end if
   
   put pValue into theColsA[pColumn]["max width"]
   
   lock messages
   set the dgProps["column properties"] of me to theColsA
   unlock messages
   
   ## current size must be at least min size
   if theColsA[pColumn]["width"] is empty or theColsA[pColumn]["width"] > theColsA[pColumn]["max width"] then
      set the dgColumnWidth[pColumn] of me to theColsA[pColumn]["max width"]
   end if
   return empty
end dgColumnMaxWidth


getprop dgColumnMaxWidth [pColumn]
   local theColsA
   put the dgProps["column properties"] of me into theColsA
   if theColsA[pColumn]["max width"] is not empty then
      return theColsA[pColumn]["max width"]
   else
      return 1000
   end if
end dgColumnMaxWidth


## deprecated
getprop dgColumnCustomControl
    return the dgColumnTemplate of me
end dgColumnCustomControl


getprop dgColumnTemplate [pColumn]
   local theTemplateGroup
   put the dgProps["row template"] of me into theTemplateGroup
   if there is a control pColumn of theTemplateGroup then
      return the long ID of control pColumn of theTemplateGroup
   else
      return empty
   end if
end dgColumnTemplate


getprop dgColumnHeaderTemplate [pColumn]
   local theTemplateGroup
   put the dgProps["row template"] of me into theTemplateGroup
   if there is a control (pColumn && "[Header]") of theTemplateGroup then
      return the long ID of control (pColumn && "[Header]") of theTemplateGroup
   else
      return empty
   end if
end dgColumnHeaderTemplate
 
 
getprop dgWorkingRect
    if the long ID of the target is the long ID of me then
        return _WorkingGroupRect(the long ID of group "dgList" of me)
    else
        return _WorkingGroupRect(the long ID of the target)
    end if
end dgWorkingRect


getprop dgFindIndex [pKeyValues]
    -----
    local foundAMatch, theFoundIndex
    local theIndex
    local theKey
    -----
    
    split pKeyValues by cr and ":" ## Provide multiple lines of key:value to perform AND search
    
    repeat for each key theIndex in sDataArray
        ## Developer can pass in multiple search strings to perform an AND search
        repeat for each key theKey in pKeyValues
            if sDataArray[theIndex][theKey] is word 1 to -1 of pKeyValues[theKey] then
                put true into foundAMatch
            else
                put false into foundAMatch
            end if
            
            ## AND search didn't pan out. Move on to next index.
            if not foundAMatch then exit repeat
        end repeat
        
        if foundAMatch then
            put theIndex into theFoundIndex
            exit repeat
        end if
    end repeat
    
    return max(0, theFoundIndex)
end dgFindIndex


getprop dgFindLine [pKeyValues]
   local theFoundIndex
   put the dgFindIndex [pKeyValues] of me into theFoundIndex
   if theFoundIndex > 0 then
      return the dgLineOfIndex[theFoundIndex] of me
   else
      return 0
   end if
end dgFindLine


getprop dgDataControlOfIndex [pIndex]
    if _ControlType() is "form" then
        if the dgProps["cache controls"] of me then
            return the long ID of sControlOfIndexA[pIndex]
        else
            ## only visible controls are in play
            repeat for each line theControl in sTableObjectsA["visible row controls"]       
                if the dgIndex of theControl is pIndex then
                    return the long ID of theControl
                end if
            end repeat
        end if
    end if
    return empty
end dgDataControlOfIndex


function ColumnControlOfIndex pColumn, pIndex
   if _ControlType() is "table" then
      ## only visible controls are in play
      repeat for each line theControl in sTableObjectsA["columns"][pColumn]["row controls"]
         if the dgIndex of theControl is pIndex then
            return the long id of theControl ## resolve the shortened 'of me' reference
         end if
      end repeat
   end if
   return empty
end ColumnControlOfIndex


function ColumnControlOfLine pColumn, pLine
   local theIndex
   put the dgIndexOfLine [pLine] of me into theIndex
   return ColumnControlOfIndex(pColumn, theIndex)
end ColumnControlOfLine


getprop dgDataControlOfLine [pLine]
   local theIndex
   put the dgIndexOfLine [pLine] of me into theIndex
   return the dgDataControlOfIndex [theIndex] of me
end dgDataControlOfLine


## Returns the rect of the control connected with pIndex. Rect
## is relative to this group but takes into account current vscroll.
## This may not prove very useful if you don't have control caching on.
getprop dgRectOfIndex [pIndex]
   local theControl, theRect, theSequence, theControlBottom
   put the dgDataControlOfIndex[pIndex] of me into theControl
   if theControl is not empty then
      put the rect of theControl into theRect
      
      if the dgProps["fixed row height"] of me then
         put the dgLineOfIndex[pIndex] of me into theSequence
         put sControlHeights * theSequence into item 4 of theRect
         put item 4 of theRect - sControlHeights into item 2 of theRect         
      else
         put 0 into theControlBottom
         repeat for each item theIndex in sIndexSequencing                 
            add sControlHeights[theIndex] to theControlBottom
            
            if theIndex is pIndex then
               exit repeat
            end if
         end repeat
         
         put theControlBottom into item 4 of theRect
         put theControlBottom - sControlHeights[theIndex] into item 2 of theRect
      end if
      
      ## Adjust for vscroll
      local theVScroll
      put the dgVScroll of me into theVScroll
      subtract theVScroll from item 2 of theRect
      subtract theVScroll from item 4 of theRect
      
      ## Now adjust for position of control
      add the top of group "dgListMask" of me to item 2 of theRect
      add the top of group "dgListMask" of me to item 4 of theRect
   end if
   
   return theRect
end dgRectOfIndex


getprop dgControl
    return the long ID of me
end dgControl
 
 
getprop dgVScroll
   if __HasMobileScroller() then
      return mobileControlGet(sScrollerId, "vScroll")
   end if
   return round(the thumbPosition of scrollbar "dgScrollbar" of me)
end dgVScroll
 
 
setprop dgVScroll pValue
    _SetVScroll pValue
end dgVScroll


private command _SetVScroll pValue
   lock screen
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   lock messages
   set the thumbPosition of scrollbar "dgScrollbar" of me to pValue
   put the thumbPosition of scrollbar "dgScrollbar" of me into pValue
   
   if __HasMobileScroller() then
      mobileControlSet sScrollerId, "vScroll", pValue
   end if
   
   set the lockMessages to msgsAreLocked
   
   if not msgsAreLocked and the visible of scrollbar "dgScrollbar" of me then
      send "scrollbarDrag  pValue" to scrollbar "dgScrollbar" of me
      ## dispatch slows things down terribly here
      -- dispatch "scrollbarDrag" to scrollbar "dgScrollbar" of me with pValue
   else
      _ScrollListV pValue
   end if
   
   unlock screen
end _SetVScroll


## Vscroll percentage is useful when refreshing the list with new data and keeping the scroll in relatively the same position
getprop dgVScrollPercent
    return _GetVScrollPercent()
end dgVScrollPercent


private function _GetVScrollPercent
   local theWorkingEndValue
   put __WorkingScrollVEndValue() into theWorkingEndValue
   if theWorkingEndValue > 0 then
      if __HasMobileScroller() then
         return mobileControlGet(sScrollerId, "vScroll") / theWorkingEndValue
      end if
      return round(the thumbPosition of scrollbar "dgScrollbar" of me) / theWorkingEndValue
   else
      return 0
   end if
end _GetVScrollPercent


setprop dgVScrollPercent pPercent
    _SetVScrollPercent pPercent
end dgVScrollPercent

private function __WorkingScrollVEndValue
   local theWorkingEndValue
   if the environment is not "mobile" then
      put the endValue of scrollbar "dgScrollbar" of me - the thumbSize of scrollbar "dgScrollbar" of me into theWorkingEndValue
   else if __HasMobileScroller() then
      local tContentRect
      put mobileControlGet(sScrollerId, "contentrect") into tContentRect
      put item 4 of tContentRect - the height of group "dgList" of me into theWorkingEndValue
   else
      put 0 into theWorkingEndValue
   end if
   return theWorkingEndValue
end __WorkingScrollVEndValue

private command _SetVScrollPercent pPercent
   _SetVScroll round(__WorkingScrollVEndValue() * pPercent)
end _SetVScrollPercent


getprop dgHScroll
   if __HasMobileScroller() then
      return mobileControlGet(sScrollerId, "hScroll")
   else
      return round(the thumbPosition of scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me)
   end if
end dgHScroll
 
 
setprop dgHScroll pValue
    _SetHScroll pValue
end dgHScroll


private command _SetHScroll pValue
   lock screen
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   lock messages
   set the thumbPosition of scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me to pValue
   put the thumbPosition of scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me into pValue
   if __HasMobileScroller() then
      mobileControlSet sScrollerId, "hScroll", pValue
   end if
   
   set the lockMessages to msgsAreLocked
   
   if not msgsAreLocked and the visible of group "dgHorizontalComponents" of me then
      send "scrollbarDrag  pValue" to scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me
      ## dispatch slows things down terribly here
      --  dispatch "scrollbarDrag" to scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me with pValue
   else
      _ScrollListH pValue
   end if
   
   unlock screen
end _SetHScroll


private command _ScrollListH pScrollValue
    lock screen
    set the hScroll of group "dgHeaderMask" of group "dgHeaderComponents" of me to pScrollValue
    set the hScroll of group "dgListMask" of me to pScrollValue
    unlock screen
end _ScrollListH


getprop dgHScrollPercent
    return _GetHScrollPercent()
end dgHScrollPercent


private function __WorkingScrollHEndValue
   local theWorkingEndValue
   if the environment is not "mobile" then
      put the endValue of scrollbar "dgHScrollbar" of me - the thumbSize of scrollbar "dgHScrollbar" of me into theWorkingEndValue
   else if __HasMobileScroller() then
      local tContentRect
      put mobileControlGet(sScrollerId, "contentrect") into tContentRect
      put item 3 of tContentRect - the width of group "dgList" of me into theWorkingEndValue
   else
      put 0 into theWorkingEndValue
   end if
   return theWorkingEndValue
end __WorkingScrollHEndValue

private function _GetHScrollPercent
   local theWorkingEndValue
   put __WorkingScrollHEndValue() into theWorkingEndValue
   if theWorkingEndValue > 0 then
      if __HasMobileScroller() then
         return mobileControlGet(sScrollerId, "hScroll") / theWorkingEndValue
      end if
      return round(the thumbPosition of scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me) / theWorkingEndValue
   else
      return 0
   end if
end _GetHScrollPercent


setprop dgHScrollPercent pPercent
    _SetHScrollPercent pPercent
end dgHScrollPercent


private command _ResetScrollsToZero
    _ResetVScrollToZero
    _ResetHScrollToZero
end _ResetScrollsToZero


private command _ResetVScrollToZero
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   set the lockMessages to true
   
   if __HasMobileScroller() then
      mobileControlSet sScrollerId, "vScroll", 0
   end if
   set the thumbPosition of scrollbar "dgScrollbar" of me to 0
   set the vScroll of group "dgList" of group "dgListMask" of me to 0
   
   set the lockMessages to msgsAreLocked
end _ResetVScrollToZero


private command _ResetHScrollToZero
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   set the lockMessages to true
   
   if __HasMobileScroller() then
      mobileControlSet sScrollerId, "hScroll", 0
   end if
   set the thumbPosition of scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me to 0
   set the hScroll of group "dgHeaderMask" of group "dgHeaderComponents" of me to 0
   set the hScroll of group "dgListMask" of me to 0
   
   set the lockMessages to msgsAreLocked
end _ResetHScrollToZero


private command _SetHScrollPercent pPercent
   _SetHScroll round(__WorkingScrollHEndValue() * pPercent)
end _SetHScrollPercent
 
 
getprop dgDataControls
   local theControls, theList
   if _ControlType() is "form" then
      if the dgProps["cache controls"] of me then
         ## sTableObjectsA["visible row controls"] only contains visible controls but all controls are valid.
         put sTableObjectsA["all row controls"] into theControls       
      else
         put sTableObjectsA["visible row controls"] into theControls
      end if
      
      repeat for each line theControl in theControls
         put the long ID of theControl & cr after theList
      end repeat
      delete the last char of theList
      return theList
   else
      return empty
   end if
end dgDataControls
 
 
getprop dgHilitedIndex
    return sHilitedIndexes ## indexes will be in order of selection
end dgHilitedIndex
 
 
getprop dgHilitedIndexes
    return sHilitedIndexes ## indexes will be in order of selection
end dgHilitedIndexes


setprop dgHilitedIndex pIndexes
    _SetHilitedIndexes pIndexes
    return the result
end dgHilitedIndex
 
 
## Hmmm, this handler needs to ensure that the one of the hilited indexes
## will be visible on screen. For that we may need to query the range of 
## indexes currently visible and then scroll the index into view if need be.
setprop dgHilitedIndexes pIndexes
    _SetHilitedIndexes pIndexes
    return the result
end dgHilitedIndexes


private command _SetHilitedIndexes pIndexes
   put _SortIndexesSequentially(pIndexes) into pIndexes
   
   lock screen
   local theReturnValue
   if pIndexes is not sHilitedIndexes then
      put pIndexes into sHilitedIndexes
      if the dgProps["scroll selections into view"] of me is not false then
         ScrollIndexIntoView item 1 of sHilitedIndexes
      end if
      
      _HiliteIndexesInVisibleControls
      put true into theReturnValue
      
   else
      put false into theReturnValue
   end if
   
   unlock screen     
   
   return theReturnValue
end _SetHilitedIndexes


## Lines/Sequences are synonymous
getprop dgHilitedLines
    return _GetHilitedSequences()
end dgHilitedLines


getprop dgHilitedLine
    return _GetHilitedSequences()
end dgHilitedLine


private function _GetHilitedSequences
    local theHilitedSequences,theIndex,theItemNo
    
    set the wholeMatches to true
    repeat for each item theIndex in sHilitedIndexes   
        put itemOffset(theIndex, sIndexSequencing ) into theItemNo
        if theItemNo > 0 then
            put theItemNo & comma after theHilitedSequences
        end if
    end repeat
    delete the last char of theHilitedSequences
    return theHilitedSequences
end _GetHilitedSequences


## Lines/Sequences are synonymous
setprop dgHilitedLine pSequences
    _SetHilitedSequences pSequences
    return the result
end dgHilitedLine


setprop dgHilitedLines pSequences
    _SetHilitedSequences pSequences
    return the result
end dgHilitedLines


private command _SetHilitedSequences pSequences
   local theIndex,theSequence
   local theHilitedIndexes
   local theMaxSequence
   
   ## We want indexes to be in order of selection
   sort items of pSequences numeric
   put the number of items of sIndexSequencing into theMaxSequence
   
   repeat for each item theSequence in pSequences
      put item min(theSequence, theMaxSequence) of sIndexSequencing into theIndex
      if theIndex is not empty then
         put theIndex & comma after theHilitedIndexes
      end if
   end repeat
   delete the last char of theHilitedIndexes
   
   set the dgHilitedIndexes of me to theHilitedIndexes
   return the result
end _SetHilitedSequences
 
 
--> Private


private function _CardOf
    local theCharNo,theControl
     
    put the long ID of me into theControl
     
    put offset(" of card ", theControl) into theCharNo
    delete char 1 to (theCharNo - 1) of theControl
     
    put offset(" of stack ", theControl) into theCharNo
    delete char theCharNo to -1 of theControl
     
    return theControl
end _CardOf


private command _RefreshIndexes pIndexes
   local redrawTheList, theVScroll, theVisibleIndexes
   put false into redrawTheList
   
   lock screen
   put _GetVScrollPercent() into theVScroll
   put _VisibleIndexes() into theVisibleIndexes
   
   repeat for each item theIndex in pIndexes
      _UpdateIndexWithNewData theIndex
      
      set the wholeMatches to true
      
      if theIndex is among the items of theVisibleIndexes then
         _ResetControlsOfIndex theIndex
         put true into redrawTheList
      end if
      
   end repeat
   
   if redrawTheList then
      _RedrawList theVScroll
   end if
   
   unlock screen
end _RefreshIndexes


private function _ColorToRGB pColor
   if pColor is a color then
      if the number of items of pColor is not 3 then
         lock screen
         local theGraphic, theOrigColor
         put the long ID of graphic "dgBackground" of me into theGraphic
         put the backColor of theGraphic into theOrigColor
         set the backColor of theGraphic to pColor
         set the backpixel of theGraphic to the effective backpixel of theGraphic
         put the backColor of theGraphic into pColor
         set the backColor of theGraphic to theOrigColor
         unlock screen
      end if
   end if
   
   return pColor
end _ColorToRGB


private command _SetGraphicGradient pGraphic, pStartColor, pEndColor
   local theRect, theX, theY
   put the rect of pGraphic into theRect
   set the backgroundColor of pGraphic to empty
   set the fillgradient["quality"] of pGraphic to "normal"
   set the fillgradient["repeat"] of pGraphic to  1
   set the fillgradient["mirror"] of pGraphic to false
   set the fillgradient["wrap"] of pGraphic to true
   set the fillgradient["type"] of pGraphic to "linear"
   set the fillGradient["ramp"] of pGraphic to "0.00000," & pStartColor & cr & "1.00000," & pEndColor
   put item 1 of theRect into theX
   put item 2 of theRect into theY
   ## take gradient from the top to the bottom. 
   ## Spread it out via the X
   set the fillgradient["from"] of pGraphic to theX, theY
   set the fillgradient["to"] of pGraphic to theX, theY + (item 4 of theRect - item 2 of theRect)
   set the fillGradient["via"] of pGraphic to theX + 40, theY
   
   return empty
end _SetGraphicGradient

on scrollerBeginDrag
   _UserStartedVScrolling
   pass scrollerBeginDrag
end scrollerBeginDrag

on scrollerEndDrag
   _UserStoppedVScrolling
   pass scrollerEndDrag
end scrollerEndDrag

on scrollerDidScroll pHScroll, pVScroll
   dgScrollbarDragV max(0,pVScroll)
   dgScrollbarDragH max(0,pHScroll)
   pass scrollerDidScroll
end scrollerDidScroll

## This handler is called from the vscroll bar when user releases mouse.
## It draws any columns not currently visible within the mask area.
## Note that we do not currently take into account whether or not the vscroll changed
## so if the user clicked an released without scrolling we would still redraw. If this becomes
## a problem then add a flag in mouseDown.
command _UserStoppedVScrolling
   put false into sRunningActionsA["user is vscrolling"]
   local theColumnsA
   if _ControlType() is "table" then
      put _table.AreColumnsVisibleWithinMask() into theColumnsA
      _table.DrawColumns theColumnsA["hidden"]
   end if
end _UserStoppedVScrolling


command _UserStartedVScrolling
    put true into sRunningActionsA["user is vscrolling"]
end _UserStartedVScrolling


command PrintKeys pArray
    if pArray is not an array then put sDataArray into pArray
    put _PrintKeys(pArray)
end PrintKeys


private function _ResourceStack
   local theStack, theCharNo
   put the behavior of me into theStack
   if theStack is not empty then
      put offset(" of stack", theStack) into theCharNo
      delete char 1 to (theCharNo + 3) of theStack
   end if
   
   return theStack
end _ResourceStack

private function _TemplateControl
   -- Attempt to find the card of the datagrid template stack.
   -- Used to house template controls.
   -- Base this off the row template. If the row template is not in the template stack then keep our template controls in the DataGrid itself.
   if the dgProps["row template"] of me contains ("stack" && quote & "Data Grid Templates") then
      return the long id of the owner of the dgProps["row template"] of me
   else
      return the long id of me
   end if
end _TemplateControl

private function _PrintKeys @pArray, pDimension
   if pDimension is empty then put 0 into pDimension
   
   local theKeys, theText, theTempArray
   put the keys of pArray into theKeys
   sort theKeys numeric
   
   repeat for each line theKey in theKeys
      if pArray[theKey] is an array then
         put _printCharXTimes(space, pDimension * 5) & theKey & cr after theText
         put pArray[theKey] into theTempArray
         put _PrintKeys(theTempArray, pDimension + 1) after theText
      else
         put _printCharXTimes(space, pDimension * 5) &  theKey & ":" && "`" & pArray[theKey] & "`" & cr after theText
      end if
   end repeat
   
   return theText
end _PrintKeys


private function _printCharXTimes pChar, pTimes
    local theStr
     
    repeat with i = 1 to pTimes
        put pChar after theStr
    end repeat
    return theStr
end _printCharXTimes


function _CustomControlReference pControl
   -----
   local theFirstCharToDelete
   local theLastCharToDelete
   local theOffset
   local theStack
   -----
   put the long ID of pControl into pControl
   ## Get id without hierarchy
   if word 1 of pControl is not among the items of "card,stack" then
      ## Strip any nested refs
      if pControl contains "of group id" then
         put length(word 1 to 4 of pControl) + 1 into theFirstCharToDelete
         put offset(" card id", pControl) - 1 into theLastCharToDelete
         delete char theFirstCharToDelete to theLastCharToDelete of pControl
      end if
      
      local theStackOffset, theSecondStackOffset
      put offset(" of stack ", pControl) into theStackOffset
      put offset(" of stack ", pControl, theStackOffset) into theSecondStackOffset
      if theSecondStackOffset > 0 then
         ## Strip mainstack ref if substack.
         ## We want user to move stacks around.
         add theSecondStackOffset to theStackOffset
         delete char theStackOffset to -1 of pControl
      else
         ## Shorten stack name
         put char (theStackOffset + 4) to -1 of pControl into theStack
         put the short name of theStack into theStack	# get stack short name
         put quote & theStack & quote into char (theStackOffset + 10) to -1 of pControl
      end if
      
      ## Strip card ref
      ## Taken out so that one can locate the card of a stack that a reference is on
      ## without looping through every card on the stack.
      -- put offset(" of card ", pControl) into theFirstCharToDelete
      -- put offset(" of stack ", pControl) into theLastCharToDelete
      -- delete char theFirstCharToDelete + 1 to theLastCharToDelete of pControl
   end if
   
   return pControl
end _CustomControlReference


private function _TopIsVisible pRect, pMaskRect
    return item 2 of pRect < item 4 of pMaskRect and item 2 of pRect > item 2 of pMaskRect 
end _TopIsVisible


private function _BottomIsVisible pRect, pMaskRect
    return item 4 of pRect > item 2 of pMaskRect and item 4 of pRect < item 4 of pMaskRect
end _BottomIsVisible


private function _RectIsAtLeastAsTallAsMask pRect, pMaskRect
    return item 4 of pRect - item 2 of pRect >= item 4 of pMaskRect - item 2 of pMaskRect
end _RectIsAtLeastAsTallAsMask


private function _RectCoversMask pRect, pMaskRect
    return _RectIsAtLeastAsTallAsMask(pRect, pMaskRect) and \
            item 2 of pRect <= item 2 of pMaskRect and \
            item 4 of pRect >= item 4 of pMaskRect
end _RectCoversMask


private function _TopIsClipped pRect, pMaskRect
    return item 4 of pRect > item 2 of pMaskRect and item 2 of pRect < item 2 of pMaskRect
end _TopIsClipped


private function _BottomIsClipped pRect, pMaskRect
    return item 2 of pRect < item 4 of pMaskRect and item 4 of pRect > item 4 of pMaskRect
end _BottomIsClipped

private function _TopAndBottomAreClipped pRect, pMaskRect
    return item 2 of pRect >= item 4 of pMaskRect or item 4 of pRect <= item 2 of pMaskRect
end _TopAndBottomAreClipped


private command _SelectTargetControl pControl
    -----
    local theControl
    local theIndex
    local thePreviouslyHilitedIndexes
    -----
    if pControl is empty then put the dgDataControl of the target into pControl
    if pControl is not empty then
        put the dgIndex of pControl into theIndex
        put sHilitedIndexes into thePreviouslyHilitedIndexes
        
        ## single click always inserts index into first index var
        put theIndex into sFirstIndexClickedWithShiftKeyDown
        set the dgHilitedIndexes of me to the dgIndex of pControl
        
        ## Clicked on a control
        if the long ID of me is not in the long ID of the focusedObject then
            focus on graphic "dgBackground" of me
        end if 
        
        _SelectionChanged thePreviouslyHilitedIndexes
    end if
end _SelectTargetControl


private function _KeyedParametersToArray pString
    split pString by comma and ":"
    return pString
end _KeyedParametersToArray


private function _SortIndexesSequentially pIndexes
   local theIndex
   local theItemNo
   local theIndexes
   -----
   set the wholeMatches to true
   
   ## Algorithm: Inserts indexes into same line as sequence then strips
   ## empty lines. Seems like it would be faster then creating table of sequences/indexes,
   ## performing a sort and then extracting the index column. Haven't timed though.
   repeat for each item theIndex in pIndexes
      put itemOffset(theIndex, sIndexSequencing) into theItemNo
      if theItemNo > 0 then
         put theIndex into line theItemNo of theIndexes         
      end if
   end repeat
   
   filter theIndexes without empty ## Get rid of empty lines
   replace cr with comma in theIndexes
   
   return theIndexes
end _SortIndexesSequentially


private command _ProcessNewIndexData pIndex
   -----
   local theControl
   local theTemplateGroup
   local msgsAreLocked
   -----
   
   put the lockMessages into msgsAreLocked
   
   ## Create cached control as needed
   if the dgProps["cache controls"] of me and _ControlType() is "form" then
      put the dgProps["row template"] of me into theTemplateGroup
      lock messages
      copy theTemplateGroup to group "dgList" of me
      put it into theControl
      put "control id" && word 3 of theControl && "of me" into sControlOfIndexA[pIndex]
      set the visible of theControl to false
      set the dgIndex of theControl to pIndex
      set the layerMode of theControl to "dynamic"
      unlock messages
      
      put sControlOfIndexA[pIndex] into line (the number of lines of sTableObjectsA["all row controls"] + 1) of sTableObjectsA["all row controls"]
   end if
   
   ## Since number of records has changed we need to redraw alternating rows
   _DrawAlternatingRows
   
   _UpdateIndexWithNewData pIndex
   
   ## We only need to update formattedheight when working with fixed control heights.
   ## Otherwise the formatted height is adjusted when new data is updated.
   if sFormattedHeight is not empty then
      if the dgProps["fixed row height"] of me then
         add sControlHeights to sFormattedHeight
         _ConfigureScrollbar
      else
         _ConfigureScrollbar
         _AutoHideVScrollbar ## this only works for fixed height
      end if
   end if
   
   set the lockMessages to msgsAreLocked
   
   return theControl
end _ProcessNewIndexData


private command _UpdateIndexWithNewData pIndex
   -----
   local deleteTheControl, theControl, theLine, theRect
   local theListGroupRect
   local theTemplateGroup
   local theFocusedControl
   local msgsAreLocked
   local heightIsFixed
   -----
   put the long ID of the focusedObject into theFocusedControl
   
   put the dgDataControlOfIndex[pIndex] of me into theControl
   
   put the lockMessages into msgsAreLocked
   put the dgProps["fixed row height"] of me into heightIsFixed
   
   ## If not fixed height and no control exists then create one 
   ## and mark it for deletion
   if theControl is empty and not heightIsFixed then
      put true into deleteTheControl
      put the dgProps["row template"] of me into theTemplateGroup
      lock messages
      copy theTemplateGroup to group "dgList" of me
      put it into theControl
      set the layerMode of theControl to "dynamic"
   end if
   
   ## Insert data into control
   if theControl is not empty then
      unlock messages
      
      put _WorkingGroupRect(the long ID of group "dgList" of me) into theListGroupRect
      put the dgLine of theControl into theLine ## passing this param is deprecated
      put the rect of theControl into theRect
      put item 1 of theRect + (item 3 of theListGroupRect - item 1 of theListGroupRect) into item 3 of theRect
      
      dispatch "FillInData" to theControl with sDataArray[pIndex]
      lock messages
      set the rect of theControl to theRect ## FillInData could possibly extend elements outside of the original rect
      unlock messages
      dispatch "LayoutControl" to theControl with theRect, DG2_GetWorkingRectOfControlFromControlRect(theControl, theRect)
      
      lock messages
      if not heightIsFixed then
         put item 2 of theRect + the formattedHeight of theControl into item 4 of theRect
         set the rect of theControl to theRect
      end if
   end if
   
   ## Now update formatted height if we are not dealing with fixed control heights
   if not the dgProps["fixed row height"] of me and sFormattedHeight is not empty then
      ## First we need to subtract existing height from cached
      if sControlHeights[pIndex] is an integer and sFormattedHeight is not empty then
         subtract sControlHeights[pIndex] from sFormattedHeight
      end if
      
      ## Now cache control height
      put the height of theControl into sControlHeights[pIndex]
      add sControlHeights[pIndex] to sFormattedHeight
      
      _ConfigureScrollbar
   end if
   
   ## Note: fixed control height does NOT need formattedheight updated.
   
   ## Cleanup if not caching and not fixed control height
   if deleteTheControl then 
      lock messages
      delete theControl
   end if
   
   ## Make sure focus stays with us
   if the long ID of me is in theFocusedControl then
      
      lock messages
      if there is not a theFocusedControl then
         focus on graphic "dgBackground" of me
      else
         focus on theFocusedControl
      end if
      unlock messages
   end if
   
   set the lockMessages to msgsAreLocked
   
   return empty
end _UpdateIndexWithNewData


private function _VisibleIndexes
    -----
    local theControl
    local theIndexes
    -----
    switch _ControlType()
        case "table"
            put item sTableObjectsA["base sequence for visible controls"] to \
                    (sTableObjectsA["base sequence for visible controls"] + sTableObjectsA["row control count"]) of sIndexSequencing into theIndexes
            break
        default
            repeat for each line theControl in sTableObjectsA["visible row controls"]
                put the dgIndex of theControl & comma after theIndexes
            end repeat
            delete the last char of theIndexes
    end switch
     
    return theIndexes
end _VisibleIndexes


private command _ConfigureScrollbar
   local theEndValue
   if sFormattedHeight > 0 then
      put sFormattedHeight into theEndValue
   else
      put the height of group "dgList" of me into theEndValue
   end if
   
   lock screen
   
   ## If messages are not locked then scrollbarDrag is sent when group height is increased.
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   lock messages
   
   local thePercent
   put _GetVScrollPercent() into thePercent
   
   ## Setting thumbsize 2nd is important because engine limits thumbsize based on endValue
   set the endValue of scrollbar "dgScrollbar" of me to max(the height of group "dgList" of me, theEndValue)
   set the thumbSize of scrollbar "dgScrollbar" of me to the height of group "dgList" of me
   
   local thePageIncrement
   put the thumbSize of scrollbar "dgScrollbar" of me into thePageIncrement
   if sControlHeights is an integer then subtract sControlHeights from thePageIncrement
   else subtract 16 from thePageIncrement ## Why 16? Why not.
   set the pageIncrement of scrollbar "dgScrollbar" of me to thePageIncrement
   
   if the dgProps["fixed row height"] of me and sControlHeights is an integer then
      set the lineIncrement of scrollbar "dgScrollbar" of me to sControlHeights  
   else
      set the lineIncrement of scrollbar "dgScrollbar" of me to round(the pageIncrement of scrollbar "dgScrollbar" of me / 16)
   end if
   
   if __HasMobileScroller() then
      local tContentRect
      put mobileControlGet(sScrollerId, "contentrect") into tContentRect
      put max(the height of group "dgList" of me, theEndValue) into item 4 of tContentRect
      mobileControlSet sScrollerId, "contentrect", tContentRect
   end if
   
   ## in lock messages so no redrawing occurs
   _SetVScrollPercent thePercent
   
   set the lockMessages to msgsAreLocked    
   unlock screen
end _ConfigureScrollbar


private command _ConfigureHScrollbar
   if _ControlType() is "table" then
      local theScrollBar
      put the long ID of scrollbar "dgHScrollbar" of group "dgHorizontalComponents" of me into theScrollBar
      local theRect
      put _WorkingGroupRect(the long ID of group "dgListMask" of me) into theRect
      local theViewWidth
      if the visible of scrollbar "dgScrollbar" of me then
         put the left of scrollbar "dgScrollbar" of me - item 1 of theRect into theViewWidth
      else
         put the right of group "dgListMask" of me - item 1 of theRect into theViewWidth
      end if
      
      set the endValue of theScrollBar to max(sFormattedWidth, theViewWidth)
      set the thumbSize of theScrollBar to theViewWidth
      set the pageIncrement of theScrollBar to the thumbSize of theScrollBar
      
      if __HasMobileScroller() then
         local tContentRect
         put mobileControlGet(sScrollerId, "contentrect") into tContentRect
         put max(sFormattedWidth, theViewWidth) into item 3 of tContentRect
         mobileControlSet sScrollerId, "contentrect", tContentRect
      end if
      
      ## Show/hide last column divider shadow
      _SetVisibilityOfColumnDividers
   end if
end _ConfigureHScrollbar


private command _SetVisibilityOfColumnDividers
   local theRect, theViewWidth, theColumns, theColCount, i, theControl
   put _WorkingGroupRect(the long ID of group "dgListMask" of me) into theRect
   put the left of scrollbar "dgScrollbar" of me - item 1 of theRect into theViewWidth
   
   ## Show/hide last column divider shadow
   put _table.VisibleColumns() into theColumns
   put the number of lines of theColumns into theColCount
   repeat for each line theColumn in theColumns
      add 1 to i
      put sTableObjectsA["columns"][theColumn]["divider control"] into theControl
      if there is not a theControl then next repeat
      
      if i < theColCount then
         set the visible of theControl to true
      else
         ## Special rules for last one
         if the width of group "dgHeader" of group "dgHeaderMask" of me < theViewWidth - 1 then 
            ## Show
            set the visible of theControl to true
         else
            ## Hide
            set the visible of theControl to false
         end if
      end if
   end repeat
end _SetVisibilityOfColumnDividers


private command _AutoHideVScrollbar
   if the environment is "mobile" then
      return empty
   end if
   
   ## Determine scrollbars
   ## Doesn't work without fixed control height. We trap for this when setting prop but developer
   ## could lock messages and set dgProps["autohide scrollbar"].
   if the dgProps["show vscrollbar"] of me is "auto" and the dgProps["fixed row height"] of me then
      set the visible of scrollbar "dgScrollbar" of me to sFormattedHeight > the height of group "dgList" of me
      local theRect
      put the rect of group "dgList" of me into theRect
      if the visible of scrollbar "dgScrollbar" of me then
         put the left of scrollbar "dgScrollbar" of me into item 3 of theRect
      else
         put the right of scrollbar "dgScrollbar" of me into item 3 of theRect
      end if
      
      set the rect of group "dgListMask" of me to theRect
      
      if _ControlType() is "table" then
         _table.ResizeList
      else
         set the rect of group "dgList" of me to theRect
      end if
   end if
end _AutoHideVScrollbar


## Call whenever width of all columns changes
private command _AutoHideHScrollbar
   if the environment is "mobile" then
      return empty
   end if
   
   if _ControlType() is "table" then
      local msgsAreLocked
      put the lockMessages into msgsAreLocked
      lock messages
      if the dgProps["show hscrollbar"] of me is "auto" then
         local theWidth
         put sFormattedWidth into theWidth
         ## list mask extends behind scrollbar so negate that space in calculation
         if the visible of scrollbar "dgScrollbar" of me then
            add the width of scrollbar "dgScrollbar" of me to theWidth
         end if
         set the visible of group "dgHorizontalComponents" of me to theWidth > the width of group "dgListMask" of me
      end if
      set the lockMessages to msgsAreLocked
   end if
end _AutoHideHScrollbar


-- returns the rect where you can draw content in a group without making scrollbars appear
private function _WorkingGroupRect pGroup
   local theRect, theWidth
   put the rect of pGroup into theRect
   add the leftMargin of pGroup to item 1 of theRect
   add the topMargin of pGroup to item 2 of theRect
   subtract the rightMargin of pGroup from item 3 of theRect
   subtract the bottomMargin of pGroup from item 4 of theRect
   if the hScrollbar of pGroup then subtract the scrollbarWidth of pGroup from item 4 of theRect
   if the vScrollbar of pGroup then subtract the scrollbarWidth of pGroup from item 3 of theRect
   if the showBorder of pGroup then
      put the borderWidth of pGroup into theWidth
      add theWidth to item 1 of theRect
      add theWidth to item 2 of theRect
      subtract theWidth from item 3 of theRect
      subtract theWidth from item 4 of theRect
   end if
   return theRect
end _WorkingGroupRect


private function _MaxStartingSequence
   local theListGroupRect, theListGroupHeight, theMaxStartingSequence, theRequiredControlCount, theIndex
   if the dgProps["fixed row height"] of me then
      put _WorkingGroupRect(the long ID of group "dgListMask" of me) into theListGroupRect
      put item 4 of theListGroupRect - item 2 of theListGroupRect into theListGroupHeight
      put max(1, ((theListGroupHeight / sControlHeights) div 1)) into theMaxStartingSequence ## floor
      ## This was returning one number too low in tests with tables. (0.9.8.5)
      put _ControlsRequiredToFillSpace() into theRequiredControlCount
   else
      ## Start from the back and work our way down
      put _WorkingGroupRect(the long ID of group "dgListMask" of me) into theListGroupRect
      put item 4 of theListGroupRect - item 2 of theListGroupRect into theListGroupHeight
      
      ## Add controls until we exceed the list group height
      repeat with theItemNo = the number of items of sIndexSequencing down to 1
         put item theItemNo of sIndexSequencing into theIndex
         add 1 to theRequiredControlCount
         local theNecessaryHeight
         add sControlHeights[theIndex] to theNecessaryHeight
         if theNecessaryHeight >= theListGroupHeight then
            exit repeat
         end if
      end repeat
      local theFirstControlHeight, theHeight
      ## Get height of first control in list
      put sControlHeights[theIndex] into theFirstControlHeight
      
      ## The list group should be able to scroll the first control in the list out of view
      ## Add additional controls until we get to that number
      repeat with theItemNo = theItemNo - 1 down to 1
         -- answer theItemNo
         -- repeat for each item theIndex in (item theRequiredControlCount + 1 to -1 of theIndexList)
         add 1 to theRequiredControlCount
         add sControlHeights[theIndex] to theHeight
         if theHeight >= theFirstControlHeight then
            exit repeat
         end if
      end repeat
   end if
   
   local theNumberOfRecords
   put max(0, the number of elements of sDataArray) into theNumberOfRecords
   put theNumberOfRecords - theRequiredControlCount + 1 into theMaxStartingSequence
   return max(1, theMaxStartingSequence)
end _MaxStartingSequence


-- sTableObjectsA["base sequence for visible controls"] is only necessary if controls are not a fixed height
private function _ControlsRequiredToFillSpace
   local theFirstControlHeight,theIndex,theIndexList,theListGroupRect
   local theNecessaryHeight,theRequiredControlCount
   
   ## Cached for performance
   ## Reset when resized
   put empty into sControlsRequiredToFillSpace
   if sControlsRequiredToFillSpace is empty then
      put _WorkingGroupRect(the long ID of group "dgListMask" of me) into theListGroupRect
      
      if the dgProps["fixed row height"] of me then
         if _ControlType() is "table" then
            ## Since tables scroll by row we only need number of controls to fill visible area.
            ## Note: this could be updated if we add property for scrolling by row vs. pixel.
            put item 4 of theListGroupRect - item 2 of theListGroupRect + sControlHeights into theNecessaryHeight
            put ((theNecessaryHeight / sControlHeights) div 1) into sControlsRequiredToFillSpace ## floor + 1
         else
            ## We want to fill with number of controls to fill visible space + 1 control
            put item 4 of theListGroupRect - item 2 of theListGroupRect + sControlHeights into theNecessaryHeight
            put ((theNecessaryHeight / sControlHeights) div 1) + 1 into sControlsRequiredToFillSpace ## floor + 1
         end if
      else
         ## Beginning from the starting index add up control heights until we reach height of list group
         put item sTableObjectsA["base sequence for visible controls"] to -1 of sIndexSequencing into theIndexList
         put sControlHeights[item 1 of theIndexList] into theFirstControlHeight
         local theListGroupHeight
         put item 4 of theListGroupRect - item 2 of theListGroupRect into theListGroupHeight
         
         repeat for each item theIndex in theIndexList
            add 1 to sControlsRequiredToFillSpace
            add sControlHeights[theIndex] to theNecessaryHeight
            if theNecessaryHeight >= theListGroupHeight then
               exit repeat
            end if
         end repeat
         
         ## The list group should be able to scroll the first control in the list out of view
         ## Add additional controls until we get to that number
         repeat for each item theIndex in (item sControlsRequiredToFillSpace + 1 to -1 of theIndexList)
            add 1 to sControlsRequiredToFillSpace
            
            local theHeight
            add sControlHeights[theIndex] to theHeight
            if theHeight >= theFirstControlHeight then
               exit repeat
            end if
         end repeat
      end if
   end if
   
   return sControlsRequiredToFillSpace
end _ControlsRequiredToFillSpace


private command _ResizeCachedControls
   local msgsAreLocked, theListGroupRect, theTopLeft
   put the lockMessages into msgsAreLocked
   
   _AutoHideVScrollbar ## only works for fixed height
   
   put _WorkingGroupRect(the long ID of group "dgList" of me) into theListGroupRect
   put item 1 to 2 of theListGroupRect into theTopLeft
   
   lock screen
   if the dgProps["fixed row height"] of me then
      ## Control heights and total height remain unchanged
      repeat for each line theControl in sTableObjectsA["all row controls"]
         local theIndex, theRect
         put the dgIndex of theControl into theIndex
         set the topLeft of theControl to theTopLeft ## This allows developer to always rely on top and left of controls in template code
         put theTopLeft & comma & item 3 of theListGroupRect & comma & item 2 of theTopLeft + the height of theControl into theRect
         lock messages
         set the rect of theControl to theRect
         unlock messages
         dispatch "LayoutControl" to theControl with theRect, DG2_GetWorkingRectOfControlFromControlRect(theControl, theRect)
      end repeat
   else
      put empty into sControlHeights
      put 0 into sFormattedHeight
      
      repeat for each line theControl in sTableObjectsA["all row controls"]
         put the dgIndex of theControl into theIndex
         set the topLeft of theControl to theTopLeft ## This allows developer to always rely on top and left of controls in template code
         put theTopLeft & comma & item 3 of theListGroupRect & comma & item 2 of theTopLeft + the height of theControl into theRect
         lock messages
         set the rect of theControl to theRect
         unlock messages
         dispatch "LayoutControl" to theControl with theRect, DG2_GetWorkingRectOfControlFromControlRect(theControl, theRect)
         
         lock messages
         put item 2 of theRect + the formattedHeight of theControl into item 4 of theRect
         set the rect of theControl to theRect
         
         put item 4 of theRect - item 2 of theRect into sControlHeights[theIndex]
         add sControlHeights[theIndex] to sFormattedHeight
      end repeat
   end if
   unlock screen
   
   set the lockMessages to msgsAreLocked
end _ResizeCachedControls


private command _SetSequenceOfIndex pIndex, pSequence
    local theCurrentSequence,theError
    put min(max(1, pSequence), the number of items of sIndexSequencing) into pSequence
    
    set the wholeMatches to true
    put itemOffset(pIndex, sIndexSequencing) into theCurrentSequence
    if theCurrentSequence > 0 then
        delete item theCurrentSequence of sIndexSequencing
    end if
    
    put pIndex & comma before item pSequence of sIndexSequencing
    if the last char of sIndexSequencing is comma then
        delete the last char of sIndexSequencing
    end if
     
    return theError
end _SetSequenceOfIndex


private command _SelectionChanged pPreviouslyHilitedIndexes
    dispatch "selectionChanged" with sHilitedIndexes, pPreviouslyHilitedIndexes
end _SelectionChanged


command _ScrollListV pVScroll, pForceRefresh
   local theFraction,theGroupVScroll,theSequence, theError
   -- put the milliseconds & cr & the executioncontexts
   
   -- put false into sRunningActionsA["v scroll"]
   if sRunningActionsA["v scroll"] then
      put true into sRunningActionsA["resend _scrolllistv"]
      return empty
   end if
   
   put true into sRunningActionsA["v scroll"]
   
   try
      if sFormattedHeight > 0 then
         if pVScroll is not an integer then 
            put the dgVScroll of me into pVScroll
         end if
         
         ## Sequence can't be too high
         local theMaxStartingSequence
         put _MaxStartingSequence() into theMaxStartingSequence
         
         if the dgProps["fixed row height"] of me then
            put (pVScroll / sControlHeights) + 1 into theSequence
            put theSequence mod 1 into theFraction
            put theSequence div 1 into theSequence
            put round(sControlHeights * theFraction) into theGroupVScroll
            
            ## If sequence is too high then adjust group vscroll accordingly
            repeat with i = 1 to theSequence - theMaxStartingSequence
               add sControlHeights to theGroupVScroll
            end repeat
            
            -- put "max sequence:" && theMaxStartingSequence && \
                  -- "sequence:" && theSequence && "total records:" && the dgNumberOfRecords of me && \
                  -- "fraction:" && theFraction && "group vscroll:" && theGroupVScroll & cr after msg
            put min(theMaxStartingSequence, theSequence) into theSequence
         else
            ## Random sized records
            local theFormattedHeight
            put 0 into theFormattedHeight
            put 0 into theSequence
            repeat for each item theIndex in sIndexSequencing
               add 1 to theSequence
               add sControlHeights[theIndex] to theFormattedHeight
               
               if theFormattedHeight >= pVScroll then
                  put pVScroll - (theFormattedHeight - sControlHeights[theIndex]) into theGroupVScroll
                  exit repeat
               end if
            end repeat
         end if          
         
         _DrawListWithProperties theSequence, theGroupVScroll, pForceRefresh
      end if
      
   catch e
      put e into theError
   end try
   
   put false into sRunningActionsA["v scroll"]
   
   if theError is not empty then
      put false into sRunningActionsA["resend _scrolllistv"]
      _ReportBehaviorError theError
   end if
   
   if sRunningActionsA["resend _scrolllistv"] then
      -- put empty into pVScroll ## ?? Do we want the next round to determine where to go based on position of sb at time?
      ## I don't think so as little tests show that scrolling when dragging scrollbar is smoother if we keep value
      if the keys of the dragData is empty then ## messages don't go during drag opeations. Don't send.
         send "_ScrollListV pVScroll, pForceRefresh" to me in 0 milliseconds
      end if
      put false into sRunningActionsA["resend _scrolllistv"]
   end if
end _ScrollListV


private command _ReportBehaviorError pError
   local theBehaviorType, theLastLineNo
   -- put the executioncontexts & cr & cr & pError
   if the environment is "development" and revAppVersion() is not 0 then
      if _ControlType() is "table" then put "column" into theBehaviorType
      else put "row" into theBehaviorType
      answer "An error has occurred in behavior for the " & theBehaviorType & " template:" & cr & \
            revIDELookupError("execution", pError) with "OK" or "Edit Script" 
      if it is "Edit Script" then
         repeat for each line theLine in pError
            if there is a (item 4 of theLine) then
               if theLastLineNo is not an integer then put item 2 of theLine into theLastLineNo
               showLineOfScript item 4 of theLine, theLastLineNo
               exit repeat
            else
               put item 2 of theLine into theLastLineNo
            end if
         end repeat
      end if
      
      throw empty
   else
      throw pError
   end if
end _ReportBehaviorError


# Parameters
#   pObject : reference to the object owning the executing code
#   pLine : the number of line about to be executed
# Description
#   Called when the script editor may need to be updated because a new line
#   of code is about to be executed in the debugger. If there is no script
#   editor open for pObject then does nothing.
#   Otherwise tells the script editor to display the appropriate line etc.
private command showLineOfScript pObject, pLine
    local tScriptEditor
    put revScriptEditor(the long ID of pObject) into tScriptEditor
    if tScriptEditor is empty then
        edit the script of pObject
    end if
     
    put revScriptEditor(the long ID of pObject) into tScriptEditor
    
    if tScriptEditor is not empty then
        local tState
        put "edit" into tState
         
        local tMode
        send "revSEGetMode" to stack tScriptEditor
        put the result into tMode
        if tState is not tMode then
            # This must be sent in time to allow the script editor a chance to set its current object,
            # otherwise an infinite loop could occur.
            send "revSESetMode tState" to stack tScriptEditor in 0 milliseconds
        end if
         
        local tFalseString
        put "false" into tFalseString
         
        # These must be sent in time to allow the script editor a chance to set its current object,
        # otherwise an infinite loop could occur.
        send "revSEGoExecutionPoint pObject, pLine, true" to stack tScriptEditor in 0 milliseconds
        send "revSEUpdate tFalseString" to stack tScriptEditor in 0 milliseconds
         
        # OK-2008-08-18 : Bug 6935 - Toplevel / uniconify the script editor here.
        revGoScriptEditor the name of stack tScriptEditor
    end if
end showLineOfScript


private command _CancelMessage pMsg
    local theMessage,theMessages
     
    repeat until (comma & pMsg & comma) is not in the pendingMessages
        put the pendingMessages into theMessages
        filter theMessages with "*," & pMsg & ",*"
        repeat for each line theMessage in theMessages
            cancel item 1 of theMessage
        end repeat
    end repeat
end _CancelMessage


private command _CacheControls
   -----
   local i
   local msgsAreLocked
   local theControl
   local theIndex
   local theExtraControls
   local theListGroupRect
   local theRecordCount
   local theRect
   local theSequence
   local theTemplateGroup
   local theTopLeft
   local theControlHeight
   -----
   lock screen
   put the lockMessages into msgsAreLocked
   
   ## If auto hiding scrollbar then calculate height and hide scrollbar before 
   ## caching controls.
   ## Double check in case developer locked messages and set
   ## the dgProps["autohide scrollbar"]
   if the dgProps["show vscrollbar"] of me is "auto" and the dgProps["fixed row height"] of me then
      _CalculateFormattedHeight
      _AutoHideVScrollbar
   end if
   
   put empty into sControlHeights
   put 0 into sFormattedHeight
   
   local controlHeightIsFixed
   put the dgProps["fixed row height"] of me into controlHeightIsFixed
   
   ## Setup
   put the dgProps["row template"] of me into theTemplateGroup
   put max(0, the number of elements of sDataArray) into theRecordCount
   put _WorkingGroupRect(the long ID of group "dgList" of me) into theListGroupRect
   put item 1 to 2 of theListGroupRect into theTopLeft
   
   ## Delete any extra controls
   put line (theRecordCount + 1) to -1 of sTableObjectsA["all row controls"] into theExtraControls
   
   lock messages
   repeat for each line theControl in theExtraControls
      delete theControl
   end repeat
   delete line (theRecordCount + 1) to -1 of sTableObjectsA["all row controls"]
   
   ## Create controls as needed
   repeat with i = the number of lines of sTableObjectsA["all row controls"]  + 1 to theRecordCount
      copy theTemplateGroup to group "dgList" of me
      put "control id" && word 3 of it && "of me" & cr after sTableObjectsA["all row controls"] 
      set the name of it to the short name of it && format("%04d", i)
      set the layerMode of it to "dynamic"
      
      ## Take over geometry
      set the lockloc of it to true
   end repeat
   if the last char of sTableObjectsA["all row controls"] is cr then delete the last char of sTableObjectsA["all row controls"]
   unlock messages
   
   ## Link each index with a control
   put 0 into theSequence
   repeat for each line theControl in sTableObjectsA["all row controls"]
      add 1 to theSequence
      put theControl into sControlOfIndexA[item theSequence of sIndexSequencing]
   end repeat
   
   ## Fill in control data and resize
   put 0 into theSequence
   repeat for each item theIndex in sIndexSequencing
      add 1 to theSequence
      put sControlOfIndexA[theIndex] into theControl
      
      ## Set geometry
      if controlHeightIsFixed then
         if theControlHeight is empty then
            ## Cache to speed things up
            put the height of theControl into theControlHeight
         end if
         put theTopLeft & comma & item 3 of theListGroupRect & comma & item 2 of theTopLeft + theControlHeight into theRect
      else
         put theTopLeft & comma & item 3 of theListGroupRect & comma & item 2 of theTopLeft + the height of theControl into theRect
      end if
      
      lock messages
      set the dgIndex of theControl to theIndex
      unlock messages
      
      ## Get height
      if sDataArray[theIndex] is NULL then
         local theDataA
         GetDataForLine theSequence, theDataA
         dispatch "CalculateFormattedHeight" to theControl with theDataA
         if it is "unhandled" then
            dispatch "FillInData" to theControl with theDataA
            
            set the topLeft of theControl to theTopLeft  ## After in case FillInData moves stuff around
            lock messages
            set the rect of theControl to theRect
            unlock messages
            dispatch "LayoutControl" to theControl with theRect, DG2_GetWorkingRectOfControlFromControlRect(theControl, theRect)
            
            if not controlHeightIsFixed then
               ## LockLoc = true so resize to fit height
               put item 2 of theRect + the formattedHeight of theControl into item 4 of theRect
               lock messages
               set the rect of theControl to theRect
               unlock messages
            end if
            
            put the height of theControl into sControlHeights[theIndex]
         else
            put the result into sControlHeights[theIndex]
         end if
      else
         dispatch "CalculateFormattedHeight" to theControl with sDataArray[theIndex]
         if it is "unhandled" then
            dispatch "FillInData" to theControl with sDataArray[theIndex]
            
            set the topLeft of theControl to theTopLeft ## After in case FillInData moves stuff around
            lock messages
            set the rect of theControl to theRect
            unlock messages
            dispatch "LayoutControl" to theControl with theRect, DG2_GetWorkingRectOfControlFromControlRect(theControl, theRect)
            
            if not controlHeightIsFixed then
               ## LockLoc = true so resize to fit height
               put item 2 of theRect + the formattedHeight of theControl into item 4 of theRect
               lock messages
               set the rect of theControl to theRect
               unlock messages
            end if
            
            put the height of theControl into sControlHeights[theIndex]
         else
            put the result into sControlHeights[theIndex]
         end if
      end if
      
      ## Add to formattedheight
      add sControlHeights[theIndex] to sFormattedHeight
      
      ## All controls start off hidden
      set the visible of theControl to false
   end repeat
   
   if the dgProps["fixed row height"] of me then
      put sControlHeights[theIndex] into sControlHeights
   end if
   
   _ConfigureScrollbar
   
   set the lockMessages to msgsAreLocked
   
   unlock screen
end _CacheControls


## Used when refreshing the list: call LayoutControl but nothing else.
## Code is modified version of _CacheControls
private command _LayoutCachedControls
   lock screen
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   
   put empty into sControlHeights
   put 0 into sFormattedHeight
   
   local controlHeightIsFixed, theListGroupRect, theTopLeft
   put the dgProps["fixed row height"] of me into controlHeightIsFixed
   put _WorkingGroupRect(the long ID of group "dgList" of me) into theListGroupRect
   put item 1 to 2 of theListGroupRect into theTopLeft
   
   repeat for each item theIndex in sIndexSequencing
      local theControl, theControlHeight, theRect
      put sControlOfIndexA[theIndex] into theControl
      
      ## Set geometry
      if controlHeightIsFixed then
         if theControlHeight is empty then
            ## Cache to speed things up
            put the height of theControl into theControlHeight
         end if
         put theTopLeft & comma & item 3 of theListGroupRect & comma & item 2 of theTopLeft + theControlHeight into theRect
      else
         put theTopLeft & comma & item 3 of theListGroupRect & comma & item 2 of theTopLeft + the height of theControl into theRect
      end if
      
      set the topLeft of theControl to theTopLeft ## After in case FillInData moves stuff around
      lock messages
      set the rect of theControl to theRect
      unlock messages
      dispatch "LayoutControl" to theControl with theRect, DG2_GetWorkingRectOfControlFromControlRect(theControl, theRect)
      
      if not controlHeightIsFixed then
         ## LockLoc = true so resize to fit height
         put item 2 of theRect + the formattedHeight of theControl into item 4 of theRect
         lock messages
         set the rect of theControl to theRect
         unlock messages
      end if
      
      put item 4 of theRect - item 2 of theRect into sControlHeights[theIndex]
      
      ## Add to formattedheight
      add sControlHeights[theIndex] to sFormattedHeight
   end repeat
   
   if controlHeightIsFixed then
      put sControlHeights[theIndex] into sControlHeights
   end if
   
   _ConfigureScrollbar
   
   set the lockMessages to msgsAreLocked
   
   unlock screen
end _LayoutCachedControls

private command _HiliteControl pControl, pBoolean
   if there is a graphic "Background" of pControl then
      ## Compute the new background color based on whether it is hilited and
      ## if not hilited, whether alternating colors should be used.
      local tNewBackgroundColor
      if pBoolean then
         put _GetHiliteColor() into tNewBackgroundColor
      else
         set the wholeMatches to true
         local theLine
         put itemOffset(the dgIndex of pControl, sIndexSequencing) into theLine
         if theLine mod 2 is kAlternatingRowModValue then
            put _GetEffectiveColor("alternate row color") into tNewBackgroundColor
         else
            put _GetEffectiveColor("row color") into tNewBackgroundColor
         end if            
      end if

      ## [[ ColorRedraw ]] Only update the background color if it has actually
      ## changed.
      if the backgroundColor of graphic "Background" of pControl is not tNewBackgroundColor then
        set the backgroundColor of graphic "Background" of pControl to tNewBackgroundColor
      end if
   end if
   
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   unlock messages
   set the dgHilite of pControl to pBoolean
   set the lockMessages to msgsAreLocked
end _HiliteControl


private function _GetEffectiveColor pProperty
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   lock messages
   
   local theColor
   put the dgProps[pProperty] of me into theColor
   set the lockMessages to msgsAreLocked
   
   if theColor is not a color then
      switch pProperty
         case "column divider color"
            return the effective borderColor of me 
            break
         case "row color"
            return kRowColor
            break
         case "alternate row color"
            if the dgProps["alternate row colors"] of me then
               return kAlternateRowColor
            else
               return _GetEffectiveColor("row color")
            end if
            break
         case "dimmed hilite color"
            return kDefaultDimmedHiliteColor
            break
         case "hilite color"
            return the hiliteColor
            break
         case "hilited text color"
            if sSystemA["hilited text color"] is a color and not (the long ID of me is not in the long ID of the focusedObject and the dgProps["dim on focusOut"] of me is not false) then
               return sSystemA["hilited text color"]
            else
               -- Check the RGB values of the hiliteColor; add them
               -- up and average them - if the result >128 then show black text, and if it's
               -- <=128 then show white text. (Thanks Ken)
               local theHiliteColor
               put _GetHiliteColor("hilite color") into theHiliteColor
               if the number of items of theHiliteColor is not 3 then put _ColorToRGB(theHiliteColor) into theHiliteColor
               local theAvg
               put item 1 of theHiliteColor + item 2 of theHiliteColor + item 3 of theHiliteColor into theAvg
               put round(theAvg / 3) into theAvg
               if theAvg > 128 then return "0,0,0"
               else return "255,255,255"
            end if
            break
      end switch
   else
      return theColor
   end if
end _GetEffectiveColor


private function _GetHiliteColor
   ## changed in 1.0.0 b4
   if the long ID of me is not in the long ID of the focusedObject and the dgProps["dim on focusOut"] of me is not false then
      local theColor
      put _GetEffectiveColor("dimmed hilite color") into theColor
      put the dgProps["dimmed hilite color"] of me into theColor
      if theColor is empty then
         put kDefaultDimmedHiliteColor into theColor
      end if
   else
      put the dgProps["hilite color"] of me into theColor
      if theColor is empty then
         put the hiliteColor into theColor
      end if
   end if
   return theColor
end _GetHiliteColor

 
private function _IsThisModifierSetActive pModifiers
   replace "alt" with "option" in pModifiers
   
   set the wholeMatches to true
   
   local theState
   put the optionKey into theState
   if "option" is among the items of pModifiers then
      if theState is "up" then
         return false
      end if
   else if theState is "down" then
      return false
   end if
   
   put the shiftKey into theState
   if "shift" is among the items of pModifiers then
      if theState is "up" then
         return false
      end if
   else if theState is "down" then
      return false
   end if
   
   if the platform is "MacOS" then
      put the commandKey into theState
      if "command" is among the items of pModifiers then
         if theState is "up" then
            return false
         end if
      else if theState is "down" then
         return false
      end if
      
      put the controlKey into theState
      if "control" is among the items of pModifiers then
         if theState is "up" then
            return false
         end if
      else if theState is "down" then
         return false
      end if
   else
      put the commandKey into theState
      if "command" is among the items of pModifiers or "control" is among the items of pModifiers then
         if theState is "up" then
            return false
         end if
      else if theState is "down" then
         return false
      end if
   end if
   
   return true
end _IsThisModifierSetActive


--> Animation


constant kFrameLength = 10
constant kAnimationLength = 300

command StartScrollAnimation pScrollTo
   if sPendingMsgsA["UpdateScrollAnimation"] is not empty then
      cancel sPendingMsgsA["UpdateScrollAnimation"]
      put empty into sPendingMsgsA["UpdateScrollAnimation"]
   end if
   
   put true into sIsAnimating
   local rightNow, scrollFrom
   put the milliseconds into rightNow
   put the dgVScroll of me into scrollFrom
   
   ScheduleScrollAnimation scrollFrom, pScrollTo, rightNow, "ease in out", rightNow, rightNow + kAnimationLength
end StartScrollAnimation


command CancelAnimation
    put false into sIsAnimating
    cancel sPendingMsgsA["UpdateScrollAnimation"]
    put empty into sPendingMsgsA["UpdateScrollAnimation"]
end CancelAnimation


command ScheduleScrollAnimation pScrollFrom, pScrollTo, pLastTime, pPhase, pPhaseStart, pPhaseEnd
   if not sIsAnimating then return empty
   
   local rightNow, theNextTime
   put the milliseconds into rightNow
   ## Synchronize to the system clock.
   put (rightNow - (rightNow mod kFrameLength)) + kFrameLength into theNextTime
   
   send "UpdateScrollAnimation pScrollFrom, pScrollTo, pLastTime, pPhase, pPhaseStart, pPhaseEnd" to me in theNextTime - rightNow milliseconds
   put the result into sPendingMsgsA["UpdateScrollAnimation"]
end ScheduleScrollAnimation


command UpdateScrollAnimation pScrollFrom, pScrollTo, pLastTime, pPhase, pPhaseStart, pPhaseEnd
   put empty into sPendingMsgsA["UpdateScrollAnimation"]
   if not sIsAnimating then return empty
   
   local rightNow, theExponent
   put the milliseconds into rightNow
   
   put 2 into theExponent
   
   local theValue
   switch pPhase
      case "ease in"
         put round(aeEaseIn(pScrollFrom, pScrollTo, kAnimationLength, pLastTime - pPhaseStart, theExponent)) into theValue
         break
      case "ease in out"
      case "ease in and out"
         put round(aeEaseInOUt(pScrollFrom, pScrollTo, kAnimationLength, pLastTime - pPhaseStart, theExponent)) into theValue
         break
      case "ease out"
      default
         put round(aeEaseOut(pScrollFrom, pScrollTo, kAnimationLength, pLastTime - pPhaseStart, theExponent)) into theValue
   end switch
   
   lock screen
   
   local theControl
   put the long ID of the focusedObject into theControl
   
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   
   if not msgsAreLocked then lock messages
   if __HasMobileScroller() then
      mobileControlSet sScrollerId, "vScroll", theValue
   end if
   set the thumbPosition of scrollbar "dgScrollbar" of me to theValue
   if not msgsAreLocked then unlock messages
   
   _ScrollListV theValue
   
   ## Make sure focus stays with us
   if the long ID of me is in theControl and (there is not a theControl or the long ID of me is not in the long ID of the focusedobject) then
      focus on graphic "dgBackground" of me
   end if
   
   unlock screen
   
   ## Schedule next animation
   if pScrollFrom > pScrollTo then
      if theValue > pScrollTo then
         ScheduleScrollAnimation pScrollFrom, pScrollTo, rightNow, pPhase, pPhaseStart, pPhaseEnd
      else
         put false into sIsAnimating
      end if
   else
      if theValue < pScrollTo then
         ScheduleScrollAnimation pScrollFrom, pScrollTo, rightNow, pPhase, pPhaseStart, pPhaseEnd
      else
         put false into sIsAnimating
      end if
   end if
end UpdateScrollAnimation


--> Errors (Private)


private command _ThrowError pErrNum, pMsg
   ## error number, line number, col number, message
   if pErrNum is empty then put 567 into pErrNum ## external error
   
   ## Build error to throw using executionContexts 
   local theContexts
   put the executionContexts into theContexts
   
   ## don't want reference to self
   delete the last line of theContexts
   
   local theContextsA, theCount, theError
   put _ParseExecutionContexts(theContexts) into theContextsA
   
   put item 2 of line 1 of the extents of theContextsA into theCount
   put format("%u,%u,%u,%s\n", pErrNum, theContextsA[theCount]["line number"], 0, pMsg) after theError 
   repeat with i = theCount down to 1
      put format("%u,%u,%u,%s\n", pErrNum, theContextsA[i]["line number"], 0, theContextsA[i]["handler"]) after theError 
      put format("%u,%u,%u,%s\n", pErrNum, theContextsA[i]["line number"], 0, theContextsA[i]["object"]) after theError 
   end repeat
   delete the last char of theError
   throw theError
end _ThrowError


private function _ParseExecutionContexts pContexts
   -----
   local theContext
   local theContextsA
   local theItem
   -----
   ## Each line has object-long-id,handler-name,line-number,[parent script object][,]
   ## Beware of quotes and commas in stack path name. They will get you.
   ## How to properly parse?
   
   ## How many entries?
   repeat for each line theContext in pContexts
      local theIndex, theItemNo
      add 1 to theIndex
      put 0 into theItemNo
      repeat for each item theItem in theContext
         add 1 to theItemNo
         if theItem is an integer then
            ## found the line number
            put theItem into theContextsA[theIndex]["line number"]
            put item (theItemNo - 1) of theContext into theContextsA[theIndex]["handler"]
            put item 1 to (theItemNo - 2) of theContext into theContextsA[theIndex]["object"]
            
            put item (theItemNo + 1) to -1 of theContext into theContextsA[theIndex]["parents"]
         end if
      end repeat
   end repeat
   
   return theContextsA
end _ParseExecutionContexts


--> Line Breaks


command TruncateTail pFieldId, pTrailer
   if pTrailer is empty then
      put "..." into pTrailer
   end if
   
   lock screen
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   lock messages
   
   local tMaxWidth
   put the width of field ID pFieldId - the leftMargin of field ID pFieldId into tMaxWidth
   
   if the formattedWidth of char 1 to -1 of field ID pFieldId <= tMaxWidth then
      set the lockMessages to msgsAreLocked
      unlock screen
      return false
   end if
   
   local tCharCount
   put the number of chars of the text of field ID pFieldId into tCharCount
   
   local tFieldText
   put the HTMLText of field ID pFieldId into tFieldText
   set the text of field ID pFieldId to pTrailer
   
   local tTrailerWidth
   put the formattedWidth of char 1 to -1 of field ID pFieldId into tTrailerWidth
   
   set the HTMLText of field ID pFieldId to tFieldText
   
   -- The 'linear' version requires n steps, where n is the average number of characters 
   -- that will fit into the field up to tMaxWidth. That version will behave well for small
   -- widths, but will degrade significantly as the width increases.
   
   -- This version requires log_2(n) steps, where n is the number of characters in the field
   -- this will be much faster for larger widths, but slower for very small widths when the
   -- line is very long.
   
   -- The maximum length of the string we want is tMaxWidth minus the trailer width
   subtract tTrailerWidth from tMaxWidth
   
   -- These two vars store the number of characters before the string that is too small (tLow)
   -- and the number of chars that makes the string too long (tHigh)
   local tLow, tHigh
   put 0 into tLow
   put tCharCount into tHigh
   
   -- tMid contains the current number of characters we are 'guessing' will fit in tWidth.
   -- We make a initial estimate based on the width of the trailer. This initial estimate should
   -- virtually eliminate any advantage the linear algorithm has over the binary search in the
   -- case of a long line fitting into a small width.
   local tMid
   put tMaxWidth div (tTrailerWidth div 2) into tMid
   
   -- We loop until they are one apart - in which case the char between positions tLow and tHigh
   -- contains the break width.
   repeat while tHigh - tLow > 1
      
      -- Compute the width of tMid characters.
      local tWidth
      put (the formattedWidth of char 1 to tMid + 1 of field ID pFieldId) into tWidth
      
      if tWidth > tMaxWidth then
         -- If the new width is too much, bring down the high point
         put tMid into tHigh
      else if tWidth < tMaxWidth then
         -- If the new width is too little, bring up the low point
         put tMid into tLow
      else
         -- If we have reached the target width then exit, adjusting by one (we want
         -- the number of chars that goes from too small, to too much)
         put tMid into tLow
         put tMid + 1 into tHigh
         exit repeat
      end if
      
      if tHigh - tLow <= 1 then
         exit repeat
      end if
      
      put tLow + (tHigh - tLow) div 2 into tMid
   end repeat
   
   -- At this point tMid will contain the number of chars that causes a transition from too
   -- short to too long.
   
   put pTrailer into char tMid to -1 of field ID pFieldId
   set the textFont of char tMid to -1 of field ID pFieldId to the effective textFont of field ID pFieldId
   
   set the lockMessages to msgsAreLocked
   unlock screen
   
   return true
end TruncateTail


--> Field Editing

local sTemplateFieldEditorA


private command _ResetTemplateFieldEditor
    put "text" into sTemplateFieldEditorA["text type"]
    put NULL into sTemplateFieldEditorA["text"]
    put false into sTemplateFieldEditorA["select text"]
end _ResetTemplateFieldEditor


command DeleteFieldEditorAndOpenNext
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   unlock messages
   
   local shiftKeyIsDown, theField, theColumn, theCurrentLineNo, theIndex
   put _IsThisModifierSetActive("shift") into shiftKeyIsDown
   
   put the dgTargetField of sFieldEditor into theField
   put the dgColumn of the dgDataControl of theField into theColumn
   put the dgTargetIndex of sFieldEditor into theIndex
   put the dgLine of the dgDataControl of theField into theCurrentLineNo
   DeleteFieldEditor true
   
   ## theField might not be a correct reference at this point as DeleteFieldEditor saves and redraws
   if the dgIndex of the dgDataControl of theField is not theIndex then
      put ColumnControlOfIndex(theColumn, theIndex) into theField ## This might not actually be a field. But what to do...
   end if
   
   local theDirection, theColumns, theLineNo
   if shiftKeyIsDown then put "back" into theDirection
   else put "forward" into theDirection
   
   dispatch "OpenNextFieldEditor" to theField with theDirection
   
   local theColNumList
   if it is not "handled" then
      ## For tables we cycle through columns in current row
      if _ControlType() is "table" then
         set the wholeMatches to true
         put _table.VisibleColumns() into theColumns
         put lineOffset(theColumn, theColumns) into theLineNo
         
         if the number of lines of theColumns > 1 and theLineNo > 0 then
            ## Generate list of column numbers to try and open
            if theDirection is "forward" then
               if theLineNo is the number of lines of theColumns then
                  repeat with i = 1 to the number of lines of theColumns
                     put i & comma after theColNumList
                  end repeat
                  delete the last char of theColNumList
               else
                  repeat with i = theLineNo + 1 to the number of lines of theColumns
                     put i & comma after theColNumList
                  end repeat
                  repeat with i = 1 to theLineNo
                     put i & comma after theColNumList
                  end repeat
                  delete the last char of theColNumList
               end if
            else
               if theLineNo is 1 then
                  put the number of lines of theColumns & comma into theColNumList
                  repeat with i = the number of lines of theColumns - 1 down to 1
                     put i & comma after theColNumList
                  end repeat
                  delete the last char of theColNumList
               else
                  put theLineNo - 1 & comma into theColNumList
                  repeat with i = theLineNo - 2 down to 1
                     put i & comma after theColNumList
                  end repeat
                  repeat with i = the number of lines of theColumns down to theLineNo
                     put i & comma after theColNumList
                  end repeat
                  delete the last char of theColNumList
               end if
            end if
            
            ## Look for next column that supports editing  
            local jumpOutOfRepeat          
            put false into jumpOutOfRepeat
            repeat for each item theNextColNum in theColNumList 
               local theNextColumn
               put line theNextColNum of theColumns into theNextColumn
               
               if the dgColumnIsEditable[theNextColumn] of me then
                  repeat for each line theControl in sTableObjectsA["columns"][theNextColumn]["row controls"]
                     if the dgLine of the dgDataControl of theControl is theCurrentLineNo then
                        
                        dispatch "EditValue" to theControl
                        
                        if it is "unhandled" then
                           ## Try next column
                           next repeat
                        else
                           put true into jumpOutOfRepeat
                           _table.ScrollColumnIntoView theNextColumn
                           exit repeat                            
                        end if
                     end if
                  end repeat
               end if
               
               if jumpOutOfRepeat then exit repeat
            end repeat
            
         end if
      end if
   end if
   
   unlock screen
   
   set the lockMessages to msgsAreLocked
end DeleteFieldEditorAndOpenNext


command DeleteFieldEditor pSaveContents
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   
   if there is not a sFieldEditor then
      ## If error occurred when messages were broadcast below then you could end up with
      ## empty sFieldEditor. We get rid of it here.
      ## We clear out sFieldEditor so that if an error does occur we don't come back later
      ## and save changes.
      if there is a field kFieldEditorName of group "dgListMask" of me then
         lock messages
         delete field kFieldEditorName of group "dgListMask" of me
         set the lockMessages to msgsAreLocked
      end if
      
      return empty
   end if
   
   put pSaveContents is not false into pSaveContents
   
   unlock messages
   
   local theEditor, theResult, theField, theError
   put sFieldEditor into theEditor
   put empty into sFieldEditor
   put empty into theResult
   
   put the dgTargetField of theEditor into theField
   
   ## Keeps focus from getting messed up when dgDataOfIndex redraws
   if theEditor is the long ID of the focusedObject then
      lock messages
      focus on graphic "dgBackground" of me ## Engine doesn't like deleting focused control in groups
      unlock messages
   end if
   
   if pSaveContents and there is a theField then
      local theIndex, theKey, contentHasChanged
      put the dgTargetIndex of theEditor into theIndex
      put the dgTargetKey of theEditor into theKey ## might be an array index
      
      set the caseSensitive to true
      put the HTMLText of theEditor is not the dgOriginalHTMLText of theEditor into contentHasChanged
      set the caseSensitive to false
      
      ## Did user want us to automatically save?
      if theIndex is an integer and (theKey is not empty and theKey is not an array) then
         if contentHasChanged then
            
            ## Give the developer a chance to stop value from being set
            try
               dispatch "CloseFieldEditor" to theField with theEditor
               if it is "handled" then
                  put the result into theResult
               end if
               
               if theResult is not "cancel" then
                  local theDataA
                  put sDataArray[theIndex] into theDataA
                  
                  switch the dgTextType of theEditor
                     case "html"
                        put the HTMLText of theEditor into theDataA[theKey]
                        break
                     case "rtf"
                        put the RTFText of theEditor into theDataA[theKey]
                        break
                     case "unicode"
                        put the unicodeText of theEditor into theDataA[theKey]
                        break
                     case "utf8"
                        put the unicodeText of theEditor into theDataA[theKey]
                        put uniDecode(theDataA[theKey], "utf8") into theDataA[theKey]
                        break
                     default
                        put the text of theEditor into theDataA[theKey]
                  end switch
                  set the dgDataOfIndex [theIndex] of me to theDataA
               end if
            catch e
               put e into theError
            end try
         else
            try
               dispatch "ExitFieldEditor" to theField with theEditor
               if it is "handled" then
                  put the result into theResult
               end if
            catch e
               put e into theError
            end try
         end if
      else
         ## Announce our closing to the world
         try
            if contentHasChanged then
               dispatch "CloseFieldEditor" to theField with theEditor
            else
               dispatch "ExitFieldEditor" to theField with theEditor
            end if
            if it is "handled" then
               put the result into theResult
            end if
         catch e
            put e into theError
         end try
      end if
   end if ## pSaveContents check
   
   lock screen
   if there is a theEditor then delete theEditor
   set the lockMessages to msgsAreLocked
   
   ## If user displayed an answer dialog in any callbacks we end
   ## up with unbalanced focusOut/In messages. This causes hilites
   ## to stay grey. Force update
   put true into sFocusLeftMe
   _UpdateHiliteColor
   unlock screen
   
   if theError is not empty then throw theError
   
   return theResult
end DeleteFieldEditor


setprop dgTemplateFieldEditor [pProp] pValue
    switch pProp
        case "htmltext"
            put "html" into sTemplateFieldEditorA["text type"]
            put pValue into sTemplateFieldEditorA["text"]
            break
        case "rtftext"
            put "rtf" into sTemplateFieldEditorA["text type"]
            put pValue into sTemplateFieldEditorA["text"]
            break
        case "text"
            put "text" into sTemplateFieldEditorA["text type"]
            put pValue into sTemplateFieldEditorA["text"]
            break
        case "unicodetext"
            put "unicode" into sTemplateFieldEditorA["text type"]
            put pValue into sTemplateFieldEditorA["text"]
            break
        case "utf8text"
            put "utf8" into sTemplateFieldEditorA["text type"]
            put pValue into sTemplateFieldEditorA["text"]
            break
        case "select text"
            if pValue is not a boolean then _ThrowError kErrInvalidBoolean, pValue && "is not a boolean"
            put pValue into sTemplateFieldEditorA["select text"]
            break
        default
            _ThrowError kErrInvalidProperty, pProp && "is an invalid property"
    end switch
    
    return empty
end dgTemplateFieldEditor 


## Pass in pIndex and pKey to automatically update a record
## in the data grid. Otherwise update by hand in closeFieldEditor message.
command EditFieldText pField, pIndex, pKey
   -----
   local i
   local theBorderWidth
   local theClickChunk, theClickField, theClickLine
   local theError
   local theMargins
   local theText
   -----
   if there is not a pField then _ThrowError kErrCantFindObject, "could not find field to create field editor for"
   lock screen
   local msgsAreLocked
   put the lockMessages into msgsAreLocked
   lock messages
   
   ## Cache where the person clicked as this data will change if 
   ## OpenInlineEditor changes position of the target
   if the clickField is not empty then put the long ID of the clickField into theClickField
   else put empty into theClickField
   put the clickCharChunk into theClickChunk
   put the clickLine into theClickLine
   
   focus on nothing
   
   ## Delete existing
   DeleteFieldEditor
   
   reset the templatefield
   
   put the margins of pField into theMargins    
   if the number of items of theMargins is 1 then
      repeat with i = 1 to 3
         put "," & item 1 of theMargins after theMargins
      end repeat
   end if
   put the borderWidth of pField into theBorderWidth
   if sTemplateFieldEditorA["text"] is NULL then
      put the text of pField into sTemplateFieldEditorA["text"] ## default
   end if
   
   set the autoTab of the templatefield to the autoTab of pField
   set the dontWrap of the templatefield to the dontWrap of pField
   set the tabStops of the templatefield to the tabStops of pField
   set the margins of the templatefield to theMargins
   set the borderWidth of the templatefield to theBorderWidth
   set the textAlign of the templatefield to the effective textAlign of pField
   set the textFont of the templatefield to the effective textFont of pField
   set the textSize of the templatefield to the effective textSize of pField
   set the textStyle of the templatefield to the effective textStyle of pField
   set the fixedLineHeight of the templatefield to the fixedLineHeight of pField
   set the opaque of the templatefield to true
   set the threeD of the templatefield to true
   
   create field kFieldEditorName in group "dgListMask" of me
   put the long ID of it into sFieldEditor
   
   set the behavior of sFieldEditor to the long ID of button "Field Editor" of _ResourceStack()
   
   set the rect of sFieldEditor  to the rect of pField ## so formattedHeight will be correct in _resizeFieldToFitContent
   
   switch sTemplateFieldEditorA["text type"]
      case "rtf"
         set the RTFText of sFieldEditor to sTemplateFieldEditorA["text"]
         put the HTMLText of sFieldEditor into theText
         break
      case "unicode"
         set the unicodeText of sFieldEditor to sTemplateFieldEditorA["text"]
         put the HTMLText of sFieldEditor into theText
         break
      case "utf8"
         set the unicodeText of sFieldEditor to uniEncode(sTemplateFieldEditorA["text"], "utf8")
         put the HTMLText of sFieldEditor into theText
         break       
      case "html"
         put sTemplateFieldEditorA["text"] into theText
         break
      case "text"
         set the text of sFieldEditor to sTemplateFieldEditorA["text"]
         put the HTMLText of sFieldEditor into theText
         break
   end switch
   
   set the HTMLText of sFieldEditor to theText
   set the dgIsFieldEditor of sFieldEditor to true
   set the dgOriginalHTMLText of sFieldEditor to theText
   set the dgTextType of sFieldEditor to sTemplateFieldEditorA["text type"]
   set the dgTargetField of sFieldEditor to pField
   set the dgTargetIndex of sFieldEditor to pIndex	# hilited line can change on selectionchanged occasions
   set the dgTargetKey of sFieldEditor to pKey
   unlock messages
   
   ## Bug when editing right|center-aligned text that is wider than field.
   if the textAlign of sFieldEditor is not "left" and the formattedWidth of sFieldEditor >= the width of sFieldEditor then
      set the textAlign of sFieldEditor to "left"
   end if
   
   ## Shout our existence out to the world
   try
      dispatch "preOpenFieldEditor" to pField with sFieldEditor
   catch e
      put e into theError
      
      lock messages
      delete sFieldEditor
      unlock messages
   end try
   
   if theError is not empty then throw theError
   
   lock messages
   focus on sFieldEditor
   focus on sFieldEditor ## When tabbing through table cells engine would not focus on sFieldEditor without 2nd call
   -- put sFieldEditor & cr  &&  the long id of the focusedobject
   unlock messages
   
   if sTemplateFieldEditorA["select text"] is not false then
      select char 1 to -1 of sFieldEditor
   else
      if theClickField is not empty and theClickField is the long ID of pField then
         if theClickChunk is not empty then
            select after char (word 2 of theClickChunk) of sFieldEditor
         else if theClickLine is not empty then
            select after line (word 2 of theClickLine) of sFieldEditor
         else
            select after char -1 of sFieldEditor
         end if
      else
         select after char -1 of sFieldEditor
      end if
   end if
   
   reset the templatefield
   _ResetTemplateFieldEditor
   
   set the lockMessages to msgsAreLocked
   
   unlock screen
   
   return empty
end EditFieldText


--> Private (Persistent Data)


## updates data and sequence
private command _StorePersistentData
   if the dgProps["persistent data"] of me then
      local msgsAreLocked
      put the lockMessages into msgsAreLocked
      lock messages
      set the dgCache["data"] of me to sDataArray
      set the dgCache["sequencing"] of me to sIndexSequencing
      set the lockMessages to msgsAreLocked
   end if
end _StorePersistentData


## Just updates the sequence
private command _StorePersistentSequence
   if the dgProps["persistent data"] of me then
      local msgsAreLocked
      put the lockMessages into msgsAreLocked
      lock messages
      set the dgCache["sequencing"] of me to sIndexSequencing
      set the lockMessages to msgsAreLocked
   end if
end _StorePersistentSequence


private command _RestorePersistentData
   if the dgProps["persistent data"] of me then
      local msgsAreLocked
      put the lockMessages into msgsAreLocked
      lock messages
      put the dgCache["data"] of me into sDataArray
      put the dgCache["sequencing"] of me into sIndexSequencing
      set the lockMessages to msgsAreLocked
   end if
end _RestorePersistentData


--> Private (Alternating Row Colors)


private command _ShowAlternatingRows
   lock screen
   
   local theRect, theStartSequence
   switch _ControlType()
      case "table"
         put the rect of group "dgListMask" of me into theRect
         add sControlHeights to item 4 of theRect
         set the rect of graphic "dgAlternatingRows" of me to theRect
         put sTableObjectsA["base sequence for visible controls"] into theStartSequence
         if theStartSequence is not an integer then put 1 into theStartSequence
         
         if theStartSequence mod 2 is kAlternatingRowModValue then
            set the top of graphic "dgAlternatingRows" of me to the top of group "dgAlternatingRowsMask" of me - sControlHeights  
         else
            set the top of graphic "dgAlternatingRows" of me to the top of group "dgAlternatingRowsMask" of me
         end if
         set the visible of graphic "dgAlternatingRows" of me to the dgProps["alternate row colors"] of me
         break
         
      case "form"
      default
         if the dgProps["alternate row colors"] of me and sFormattedHeight < the height of group "dgList" of me then
            put the rect of group "dgListMask" of me into theRect
            put item 2 of theRect + sFormattedHeight into item 2 of theRect
            set the rect of graphic "dgAlternatingRows" of me to theRect
            show graphic "dgAlternatingRows" of me
         else
            hide graphic "dgAlternatingRows" of me
         end if
   end switch
   
   unlock screen
   
   return empty
end _ShowAlternatingRows


private command _FillInEmptyRowHeight
    ## Fill in default row height if empty
    if the dgProps["alternate row colors"] of me and the dgProps["row height"] of me is empty then
        if sControlHeights is an integer then
            set the dgProps["row height"] of me to sControlHeights
        else if the keys of sControlHeights is not empty then
            set the dgProps["row height"] of me to sControlHeights[1]
        end if
    end if
    return empty
end _FillInEmptyRowHeight


private command _DrawAlternatingRows
   -----
   local theOffset
   local theOtherColor
   local theRowColor, theRowHeight
   local theTemplateGroup
   local theStartSequence
   -----
   put sTableObjectsA["base sequence for visible controls"] into theStartSequence
   if _ControlType() is "form" then
      ## For forms the alternating lines draw from the bottom of displayed rows down.
      ## That means we need to determine alternating row color from last record down.
      ## Since the rows only show up if there aren't enough controls to fill the space
      ## we can just use the extents of the data array. If it is too high then no big deal.
      put max(1, the number of elements of sDataArray + 1) into theStartSequence
   else
      if theStartSequence is not an integer then
         put 1 into theStartSequence
      end if
   end if
   
   _FillInEmptyRowHeight
   local alternateTheColors
   put the dgProps["alternate row colors"] of me into alternateTheColors
   
   set the visible of graphic "dgAlternatingRows" of me to alternateTheColors
   if alternateTheColors then
      local theAlternateRowColor, theWidth, theFirstColor, theSecondColor
      put _GetEffectiveColor("alternate row color") into theAlternateRowColor
      put _GetEffectiveColor("row color") into theRowColor
      put the dgProps["row height"] of me into theRowHeight
      if theRowHeight is not an integer then put kDefaultRowHeight into theRowHeight
      put 0 into theOffset
      put 1 into theWidth
      
      if theStartSequence mod 2 is kAlternatingRowModValue then
         put theAlternateRowColor into theFirstColor
         put theRowColor into theSecondColor
      else
         put theRowColor into theFirstColor
         put theAlternateRowColor into theSecondColor
      end if
      
      _CreateAlternatingColorImage the long ID of image "dgAlternatingRows" of me, theFirstColor, theSecondColor, \
            theRowHeight, theWidth, theOffset
      set the backgroundPattern of graphic "dgAlternatingRows" of me to empty
      set the backgroundPattern of graphic "dgAlternatingRows" of me to the ID of image "dgAlternatingRows" of me
   else
      set the backgroundPattern of graphic "dgAlternatingRows" of me to empty
      set the text of image "dgAlternatingRows" of me to empty
   end if
   
   return empty
end _DrawAlternatingRows


private command _CreateAlternatingColorImage pDestImg, pColor1, pColor2, pRowHeight, pWidth, pOffset
   -----
   local theColor1Pixel, theColor2Pixel
   local theColor1Row, theColor1RowImgData, theColor2Row, theColor2RowImgData, theRow
   local theOffsetRow
   local thePixel
   local theRect
   -----
   if pRowHeight is empty then put 18 into pRowHeight 
   if pWidth is empty then put 500 into pWidth 
   put max(0, pOffset) into pOffset 
   
   ## turn strings into arrays 
   split pColor1 by comma 
   split pColor2 by comma 
   
   ## Create a pixel for color 1 and 2 
   put numToChar(0) into theColor1Pixel 
   put numToChar(pColor1[1]) after theColor1Pixel 
   put numToChar(pColor1[2]) after theColor1Pixel 
   put numToChar(pColor1[3]) after theColor1Pixel 
   
   put numToChar(0) into theColor2Pixel 
   put numToChar(pColor2[1]) after theColor2Pixel 
   put numToChar(pColor2[2]) after theColor2Pixel 
   put numToChar(pColor2[3]) after theColor2Pixel 
   
   ## build 1 complete row of using pixel 
   repeat with thePixel = 1 to pWidth 
      put theColor1Pixel after theColor1RowImgData 
      put theColor2Pixel after theColor2RowImgData 
   end REPEAT 
   
   ## if pOffset is set then build sliver of row 2 color 
   repeat with theRow = 1 to pOffset 
      put theColor2RowImgData after theOffsetRow 
   end repeat 
   
   ## build color 1 row 
   repeat with theRow = 1 to pRowHeight 
      put theColor1RowImgData after theColor1Row 
   end REPEAT 
   
   ## finish building row 2 color 
   repeat with theRow = 1 to pRowHeight - pOffset 
      put theColor2RowImgData after theColor2Row 
   end repeat 
   
   put the rect of pDestImg into theRect 
   put item 1 of theRect + pWidth into item 3 of theRect 
   put item 2 of theRect + pRowHeight * 2 into item 4 of theRect 
   
   ## Worka round crash bug when "jpeg"
   local theOrigCompr
   put the paintCompression into theOrigCompr
   set the paintCompression to "rle"
   
   lock screen 
   set the rect of pDestImg to theRect 
   set the imageData of pDestImg to theOffsetRow & theColor1Row & theColor2Row 
   unlock screen 
   
   set the paintCompression to theOrigCompr
   
   return empty
end _CreateAlternatingColorImage

private function __HasMobileScroller
   return the environment is "mobile" and \
         sScrollerId is not empty and \
         sScrollerId is among the lines of mobileControls()
end __HasMobileScroller

command __EnableMobileScroller
   if __HasMobileScroller() then
      mobileControlSet sScrollerId, "scrollingEnabled", "true"
   end if
end __EnableMobileScroller

command __DisableMobileScroller
   if __HasMobileScroller() then
      mobileControlSet sScrollerId, "scrollingEnabled", "false"
   end if
end __DisableMobileScroller

--------------------------------------------------------------------------------
-- DataGrid 2
--------------------------------------------------------------------------------

private command DG2_ClearVars
   put false into sEditMode

   put false into sReorderInProgress
   put empty into sReorderControl
   put empty into sReorderStartIndex
   put empty into sReorderStartLine
   put empty into sReorderLastHoverLine
   put false into sReorderMouseMoveInProgress

   cancel sReorderMoveMsgId
   put empty into sReorderMoveMsgId

   cancel sAnimationsPulseMsgID
   put empty into sAnimationsPulseMsgID
   put empty into sAnimationsA
   put empty into sAnimationsLastID

   cancel sReorderScrollPollMsgID
   put empty into sReorderScrollPollMsgID

   DG2_CustomisableControlsClear
   return the result
end DG2_ClearVars

private command DG2_EnsureRowChainedBehavior
   -- DataGrid 2 uses a behavior for each row to detect swipes and such.
   -- Make sure this behavior is applied to the end of the template row's behavior
   -- chain.
   if the dgProps["row template"] of me is not empty and there is a the dgProps["row template"] of me then
      local tChainedBehavior
      put the long ID of button "Row Chained Behavior" of group "Behaviors" of _ResourceStack() into tChainedBehavior

      local tControl
      put the behavior of the dgProps["row template"] of me into tControl

      -- Repeat through to the end of the behavior chain, exiting the loop if the
      -- template behavior already set.
      repeat while tControl is not empty and the behavior of tControl is not empty and the long id of the behavior of tControl is not tChainedBehavior
         put the behavior of tControl into tControl
      end repeat

      if tControl is not empty and the behavior of tControl is empty then
         set the behavior of tControl to tChainedBehavior
      end if
   end if

   return empty
end DG2_EnsureRowChainedBehavior

function DG2_GetMessageNameForTag pTag
   switch pTag
      case "EditModeReorderStarted"
         return kEditModeEditModeReorderStarted
      case "EditModeReorderCompleted"
         return kEditModeEditModeReorderCompleted
      case "EditModeActionSelectControlClicked"
         return kMessageEditModeActionSelectControlClicked
      case "EditModeActionControlClicked"
         return kMessageEditModeActionControlClicked
      case "EditModeActionControlHidden"
         return kMessageEditModeActionControlHidden
      case "RowSwipedRight"
         return kMessageRowSwipedRight
      case "RowSwipedLeft"
         return kMessageRowSwipedLeft
      case "RowLeftSwipeControlClicked"
         return kMessageRowLeftSwipeControlClicked
      case "RowRightSwipeControlClicked"
         return kMessageRowRightSwipeControlClicked
      case "RowLeftSwipeControlHidden"
         return kMessageRowLeftSwipeControlHidden
      case "RowRightSwipeControlHidden"
         return kMessageRowRightSwipeControlHidden
   end switch
end DG2_GetMessageNameForTag

--------------------------------------------------------------------------------
-- DataGrid2 Public Commands

-- RowSwipeShowControlForIndexAndSide
--
-- Fully slide in the swipe control from the specified side for the row  with
-- the specified index.
-- This command is typically used after a swipe gesture to fully reveal the swipe
-- control for the row.
--
-- pIndex - The index of the row we want the swipe control to appear on.
-- pSide  - The side want the control to appear. "left" or "right"
--
command RowSwipeShowControlForIndexAndSide pIndex, pSide
   if not the dgProps["enable swipe"] of me then
      return "Enable swipe is not set"
   end if
   
   if pSide is not among the words of "left right" then
      return "Unknown side" && pSide
   end if

   set the wholeMatches to true
   if pIndex is not among the items of the dgIndexes of me then
      return "Unknown index" && pIndex
   end if

   -- The swipe control is housed in a holder group that is overlaid on top
   -- of the list. This is used to block/catch all mouse events when the control
   -- is visible.
   local tSwipeControlHolder
   put DG2_SwipeControlHolderGet() into tSwipeControlHolder
   if tSwipeControlHolder is empty then
      return "Could not find swipre control holder"
   end if

   set the dgSwipeControlSide of tSwipeControlHolder to pSide
   set the dgSwipeControlRowIndex of tSwipeControlHolder to pIndex
   return the result
end RowSwipeShowControlForIndexAndSide

-- RowSwipeHideControl
--
-- Hide any visible swipe control.
-- Don't animate is typically set if we are about to perform a subsequent
-- animation. For example, when deleting a row.
--
-- pDontAnimate - Set to true to not animate the hide.
--
command RowSwipeHideControl pDontAnimate
   if not the dgProps["enable swipe"] of me then
      return "Enable swipe is not set"
   end if
   
   local tSwipeControlHolder
   put DG2_SwipeControlHolderGet() into tSwipeControlHolder
   if tSwipeControlHolder is empty then
      return "Could not find swipre control holder"
   end if

   if not the visible of tSwipeControlHolder then
      return empty
   end if

   -- If we don't want to animate, hide the holder.
   -- This will instantly hide the swipe control.
   -- The holder will then take care of any tidying up.
   lock screen
   if pDontAnimate then
      set the visible of tSwipeControlHolder to false
   end if
   set the dgSwipeControlRowIndex of tSwipeControlHolder to empty
   get the result
   unlock screen

   return it
end RowSwipeHideControl

-- EditModeShowActionControlForIndex
--
-- Slide in the action control from the left hand side of the row with
-- the specified index.
--
-- pIndex - The index of the row we want the action control to appear for.
--
command EditModeShowActionControlForIndex pIndex
   if not sEditMode then
      return "Action control can only be shown in edit mode"
   end if

   set the wholeMatches to true
   if pIndex is not among the items of the dgIndexes of me then
      return "Unknown index" && pIndex
   end if

   -- The action control is housed in a holder group that is overlaid on top
   -- of the list. This is used to block/catch all mouse events when the control
   -- is visible.
   local tActionControlHolder
   put DG2_EditModeActionControlHolderGet() into tActionControlHolder
   if tActionControlHolder is empty then
      return "Could not find action control holder"
   end if

   set the dgActionControlRowIndex of tActionControlHolder to pIndex
   return the result
end EditModeShowActionControlForIndex

-- EditModeHideActionControl
--
-- Hide any visible action control.
-- Don't animate is typically set if we are about to perform a subsequent
-- animation. For example, when deleting a row.
--
-- pDontAnimate - Set to true to not animate the hide.
--
command EditModeHideActionControl pDontAnimate
   if not sEditMode then
      return empty
   end if

   local tActionControlHolder
   put DG2_EditModeActionControlHolderGet() into tActionControlHolder
   if tActionControlHolder is empty then
      return "Could not find action control holder"
   end if
   if not the visible of tActionControlHolder then
      return empty
   end if

   -- If we don't want to animate, hide the holder.
   -- This will instantly hide the swipe control.
   -- The holder will then take care of any tidying up.
   lock screen
   if pDontAnimate then
      set the visible of tActionControlHolder to false
   end if
   set the dgActionControlRowIndex of tActionControlHolder to empty
   get the result
   unlock screen

   return it
end EditModeHideActionControl

----------------------------------------------------------------------
-- DataGrid 2 default implementations of swipe and edit mode actions.
--
-- By default we don't handle RowSwipedLeft and RowSwipedRight. This results in
-- the swipe control being fully revealed allowing the user to click it. If the
-- swipe control is clicked, delete this row.
--
-- By default, when the action select control is clicked, reveal the action
-- control.
--
-- By default, when the action control is clicked, delete the row.
--
-- These behaviors can be overriden by handling these messages in the user
-- scripts.
--
-- These messages are handled at this point of the message path to allow
-- users to potentially handle them at group level.

on RowLeftSwipeControlClicked
   DeleteIndex the dgIndex of the target
end RowLeftSwipeControlClicked

on RowRightSwipeControlClicked
   DeleteIndex the dgIndex of the target
end RowRightSwipeControlClicked

on EditModeActionSelectControlClicked pTarget
   EditModeShowActionControlForIndex the dgIndex of the target
end EditModeActionSelectControlClicked

on EditModeActionControlClicked pTarget
   DeleteIndex the dgIndex of the target
end EditModeActionControlClicked

--------------------------------------------------------------------------------
-- DataGrid 2 Edit Mode Handlers

setProp dgEditMode pMode
   if pMode then
      if the dgProps["style"] of me is not "form" then
         throw "Edit mode can only be applied to form controls"
      end if
      if not the dgProps["fixed row height"] of me then
         return "Edit mode can only be to controls with fixed row heights"
      end if
   end if

   local tResult
   if pMode and not sEditMode then
      DG2_EditModeEnter
      put the result into tResult
   else if not pMode and sEditMode then
      DG2_EditModeLeave
      put the result into tResult
   end if

   if tResult is empty then
      put pMode into sEditMode
   end if

   return tResult
end dgEditMode

getProp dgEditMode
   return sEditMode
end dgEditMode

private command DG2_EditModeEnter
   -- We set sEditMode here to ensure all subsequent redraws include the edit
   -- mode controls.
   put true into sEditMode

   -- If any swipes are in progress, tidy them up.
   RowSwipeHideControl true

   -- We use callbacks within the standard draw procedure to handle the
   -- animating in.
   _DrawListWithProperties sTableObjectsA["base sequence for visible controls"], the vScroll of group "dgList" of me, true, "DG2_EditModeEnterDrawCallback"
   return empty
end DG2_EditModeEnter

private command DG2_EditModeLeave
   -- If an edit mode action control is visible, tidy it up.
   EditModeHideActionControl true
   _DrawListWithProperties sTableObjectsA["base sequence for visible controls"], the vScroll of group "dgList" of me, true, "DG2_EditModeLeaveDrawCallback"
   return empty
end DG2_EditModeLeave

on DG2_EditModeEnterDrawCallbackStart @pContextA, pTopLeft
   put empty into pContextA["animations"]
   put 0 into pContextA["animation count"]
end DG2_EditModeEnterDrawCallbackStart

on DG2_EditModeEnterDrawCallback @pContextA, pControl, pLineNo, @pControlRect, @pControlTopLeft
   -- We are about to animate in. If there is an action control, it will appear
   -- on the left hand side of the row control.
   -- Therefore we need to extend the row control's left the accomodate the action control.
   -- The rect is passed by reference, meaning all future layouts in standard drawing loop
   -- will be effected also.
   local tActionSelectControl
   put DG2_CustomisableControlsGetEditModeActionSelectControlForControl(the long id of pControl) into tActionSelectControl
   if tActionSelectControl is not empty then
      subtract the width of tActionSelectControl from item 1 of pControlRect
      add 1 to pContextA["animation count"]
      put DG2_AnimationsAnimationCreate(pControl, "left", item 1 of pControlRect, item 1 of pControlRect + the width of tActionSelectControl, the dgAnimationProp["EditModeEnterExitDuration"] of me, the dgAnimationProp["EditModeEnterExitActionSelectControlControlEasing"] of me) into pContextA["animations"][pContextA["animation count"]]
   end if

   -- Fade in the reorder control.
   --
   local tReorderControl
   put DG2_CustomisableControlsGetEditModeReorderControlForControl(the long id of pControl) into tReorderControl
   if tReorderControl is not empty then
      set the right of tReorderControl to item 3 of pControlRect
      set the visible of tReorderControl to true
      set the blendLevel of tReorderControl to 100

      -- Continually setting the left of the reorder control during the animation ensures
      -- that it is always in the same position (at the right hand side of the list) and
      -- thus not effected by the control sliding in from the right (which would naturally
      -- move the roerder control right).
      add 1 to pContextA["animation count"]
      put DG2_AnimationsAnimationCreate(tReorderControl, "left", the left of tReorderControl, the left of tReorderControl, the dgAnimationProp["EditModeEnterExitDuration"] of me, "linear") into pContextA["animations"][pContextA["animation count"]]

      add 1 to pContextA["animation count"]
      put DG2_AnimationsAnimationCreate(tReorderControl, "blendLevel", 100, 0, the dgAnimationProp["EditModeEnterExitDuration"] of me, the dgAnimationProp["EditModeEnterExitReorderControlEasing"] of me) into pContextA["animations"][pContextA["animation count"]]
   end if

   -- If the controls are cached, "LayoutControl" won't be called by the standard draw loop.
   -- But we need it to be called to reposition everying inside the row to take account of
   -- any edit mode controls, so do dispatch "LayoutControl" here.
   if the dgProps["cache controls"] of me then
      set the rect of pControl to pControlRect
      dispatch "LayoutControl" to pControl with pControlRect, DG2_GetWorkingRectOfControlFromControlRect(pControl, pControlRect)
   end if
end DG2_EditModeEnterDrawCallback

on DG2_EditModeEnterDrawCallbackEnd @pContextA
   -- Queue all the animations and add an end callback to the final animation.
   -- The end callback will tidy everything up.
   if pContextA["animation count"] is not 0 then
      DG2_AnimationsAnimationSetCompletionMessage pContextA["animations"][pContextA["animation count"]], "DG2_EditModeAnimateComplete"
      DG2_AnimationsAnimationSetMessageTarget pContextA["animations"][pContextA["animation count"]], the long id of me
      DG2_AnimationsBatchAddWithArray pContextA["animations"]
   else
      send "DG2_EditModeAnimateComplete" to me in 0 seconds
   end if
end DG2_EditModeEnterDrawCallbackEnd

on DG2_EditModeLeaveDrawCallbackStart @pContextA, pTopLeft
   put empty into pContextA["animations"]
   put 0 into pContextA["animation count"]
end DG2_EditModeLeaveDrawCallbackStart

on DG2_EditModeLeaveDrawCallback @pContextA, pControl, pLineNo, @pControlRect, @pControlTopLeft
   local tRight
   put item 3 of pControlRect into tRight

   -- We will be sliding the row to the right to hide the action select control.
   -- Extend the right of the row's rect to ensure that now blank space is present
   -- on the right hand side as a result of the animation.
   -- Therefore we need to extend the row control's left the accomodate the action control.
   -- standard drawing loop will be effected also.
   local tActionSelectControl
   put DG2_CustomisableControlsGetEditModeActionSelectControlForControl(the long id of pControl) into tActionSelectControl
   if tActionSelectControl is not empty then
      add the width of tActionSelectControl to item 3 of pControlRect
      add 1 to pContextA["animation count"]
      put DG2_AnimationsAnimationCreate(pControl, "left", item 1 of pControlRect, item 1 of pControlRect - the width of tActionSelectControl, the dgAnimationProp["EditModeEnterExitDuration"] of me, the dgAnimationProp["EditModeEnterExitActionSelectControlControlEasing"] of me) into pContextA["animations"][pContextA["animation count"]]
   end if

   -- Fade out the reorder control.
   local tReorderControl
   put DG2_CustomisableControlsGetEditModeReorderControlForControl(the long id of pControl) into tReorderControl
   if tReorderControl is not empty then
      set the right of tReorderControl to tRight
      set the visible of tReorderControl to true
      set the blendLevel of tReorderControl to 0

      -- Continually setting the left of the reorder control during the animation ensures
      -- that it is always in the same position (at the right hand side of the list) and
      -- thus not effected by the control sliding out to the right (which would naturally
      -- move the roerder control left).
      add 1 to pContextA["animation count"]
      put DG2_AnimationsAnimationCreate(tReorderControl, "left", the left of tReorderControl, the left of tReorderControl, the dgAnimationProp["EditModeEnterExitDuration"] of me, "linear") into pContextA["animations"][pContextA["animation count"]]
      add 1 to pContextA["animation count"]

      put DG2_AnimationsAnimationCreate(tReorderControl, "blendLevel", 0, 100, the dgAnimationProp["EditModeEnterExitDuration"] of me, the dgAnimationProp["EditModeEnterExitReorderControlEasing"] of me) into pContextA["animations"][pContextA["animation count"]]
   end if

   -- If the controls are cached, "LayoutControl" won't be called by the standard draw loop.
   -- But we need it to be called to reposition everying inside the row to take account of
   -- any edit mode controls, so do dispatch "LayoutControl" here.
   if the dgProps["cache controls"] of me then
      set the rect of pControl to pControlRect
      dispatch "LayoutControl" to pControl with pControlRect, DG2_GetWorkingRectOfControlFromControlRect(pControl, pControlRect)
   end if
end DG2_EditModeLeaveDrawCallback

on DG2_EditModeLeaveDrawCallbackEnd @pContextA
   -- Queue all the animations and add an end callback to the final animation.
   -- The end callback will tidy everything up.
   if pContextA["animation count"] is not 0 then
      DG2_AnimationsAnimationSetCompletionMessage pContextA["animations"][pContextA["animation count"]], "DG2_EditModeAnimateComplete"
      DG2_AnimationsAnimationSetMessageTarget pContextA["animations"][pContextA["animation count"]], the long id of me
      DG2_AnimationsBatchAddWithArray pContextA["animations"]
   else
      send "DG2_EditModeAnimateComplete" to me in 0 seconds
   end if
end DG2_EditModeLeaveDrawCallbackEnd

on DG2_EditModeAnimateComplete
   -- Force a redraw after edit mode enter/exit. This will resize the rows correctly
   -- reseting any bounds extending that has occured as a result of the slide in animation.
   -- If the controls aren't cached, we can use _RedrawList, which is slightly quicker than
   -- RefreshList.
   if the dgProps["cache controls"] of me then
      RefreshList
   else
      _RedrawList
   end if
end DG2_EditModeAnimateComplete

--------------------------------------------------------------------------------
-- DataGrid 2 Reorder Handlers

command DG2_ReorderStart
   if not sEditMode then
      return "Can only reorder in edit mode"
   end if
   if sReorderInProgress then
      return "Reorder already in progress"
   end if

   local tControl
   put the the dgDataControl of the target into tControl
   if tControl is empty or not (there is a tControl) then
      return "Could not find control to reorder"
   end if

   local tIndex
   put the dgIndex of tControl into tIndex
   if tIndex is empty then
      return "Could not find index of control"
   end if

   local tLine
   put the dgLineOfIndex[tIndex] of me into tLine
   if tLine is empty then
      return "Could not find line of control"
   end if

   -- Make sure any scroller doesn't interfere with drag reorders.
   __DisableMobileScroller
   
   put tControl into sReorderControl
   put tIndex into sReorderStartIndex
   put tLine into sReorderStartLine
   put tLine into sReorderLastHoverLine
   put true into sReorderInProgress

   -- Bring the control we want to reorder to the front and apply an effect to it.
   lock screen
   relayer tControl to front of owner
   set the blendLevel of tControl to 30
   set the outerGlow["color"] of tControl to kReorderDragControlGlowColor
   set the outerGlow["size"] of tControl to kReorderDragControlGlowSize
   set the outerGlow["spread"] of tControl to kReorderDragControlGlowSpread
   unlock screen

   -- ScrollPoll checks to see if the mouse is at the top or bottom of the list
   -- and adjusts the scroll accodingly.
   send "DG2_ReorderScrollPoll" to me in 0 seconds

   -- Check for mouse moves. We do this manually rather than using mouse move
   -- as mouse move for a couple of reasons:
   -- Mouse move is sent to regularly, which can cometimes mean handling it
   -- interferes with animations. Polling like this acts as the equivelant of
   -- throttling mouse move.
   -- Also, widgets don't pass mouse move, so need to post it directly. This
   -- message can sometimes not get posted until the vent loop is cleared,
   -- meaning it can be held up behind any pending animations.
   send "DG2_ReorderMove" to me in 0 seconds

   -- Tell the user a reorder has started.
   dispatch DG2_GetMessageNameForTag("EditModeReorderStarted") to me with sReorderStartIndex, sReorderStartLine

   return empty
end DG2_ReorderStart

command DG2_ReorderMove pNewMouseH, pNewMouseV
   cancel sReorderMoveMsgId

   if not sReorderInProgress then
      return "No reorder currently in progress"
   end if

   if sReorderMouseMoveInProgress then
      return empty
   end if

   if the mouse is not "down" then
      return empty
   end if

   put true into sReorderMouseMoveInProgress

   if pNewMouseV is empty then
      put item 2 of the mouseLoc into pNewMouseV
   end if

   -- Don't extend the reorder beyond the rect of the DataGrid!
   if pNewMouseV < the top of group "dgListMask" of me then
      put the top of group "dgListMask" of me into pNewMouseV
   else if pNewMouseV > bottom of group "dgListMask" of me then
      put the bottom of group "dgListMask" of me into pNewMouseV
   end if

   local tHoverLine
   put DG2_VerticalLocToLineNo(pNewMouseV) into tHoverLine
   put max(tHoverLine, 1) into tHoverLine
   put min(tHoverLine, the dgNumberOfLines of me) into tHoverLine

   -- If the mouse is over a new line.
   -- This means we need to reorder.
   if sReorderLastHoverLine is not tHoverLine then
      local tMouseMoveDirection
      if sReorderLastHoverLine > tHoverLine then
         put 1 into tMouseMoveDirection
      else if sReorderLastHoverLine < tHoverLine then
         put -1 into tMouseMoveDirection
      end if

      local tLineToMove
      put tHoverLine into tLineToMove

      local tAnimationsA, tAnimationID
      put 1 into tAnimationID

      -- It's possible the mouse has moved over several controls since the last reorder.
      -- Make sure we animate each of those controls to their new position resulting from the reorder.
      repeat while tLineToMove is not sReorderLastHoverLine
         local tControlToMove
         put the dgDataControlOfLine[tLineToMove] of me into tControlToMove
         if tControlToMove is empty or there is not a tControlToMove then
            next repeat
         end if

         put DG2_AnimationsAnimationCreate(tControlToMove, "top", the top of tControlToMove, DG2_TopOfControlWithLineNo(tLineToMove + tMouseMoveDirection), the dgAnimationProp["ReorderAnimationDuration"] of me, the dgAnimationProp["ReorderAnimationEasing"] of me) into tAnimationsA[tAnimationID]
         add 1 to tAnimationID

         add tMouseMoveDirection to tLineToMove
      end repeat

      DG2_AnimationsBatchAddWithArray tAnimationsA

      -- Update the DataGrid's internal sequence to take account of the reorder.
      SetLineOfIndex the dgIndexOfLine[sReorderLastHoverLine] of me, tHoverLine

      put tHoverLine into sReorderLastHoverLine
   end if

   -- Make sure the control we're reordering is always tracking the mouse.
   set the loc of sReorderControl to item 1 of the loc sReorderControl, pNewMouseV

   send "DG2_ReorderMove" to me in sReorderMovePollRate milliseconds
   put the result into sReorderMoveMsgId

   put false into sReorderMouseMoveInProgress

   return empty
end DG2_ReorderMove

command DG2_ReorderEnd
   if not sReorderInProgress then
      return "No reorder currently in progress"
   end if

   __EnableMobileScroller
   
   -- Animate the control we are reordering into its new slot.
   DG2_AnimationsAdd sReorderControl, "top", the top of sReorderControl, DG2_TopOfControlWithLineNo(sReorderLastHoverLine) + 1, the dgAnimationProp["ReorderHomingDuration"] of me, the dgAnimationProp["ReorderHomingEasing"] of me, "DG2_ReorderControlHomed", empty, the long id of me
   put false into sReorderInProgress

   -- Tell the user the reorder has completed.
   dispatch DG2_GetMessageNameForTag("EditModeReorderCompleted") to me with sReorderStartIndex, sReorderStartLine, sReorderLastHoverLine

   return empty
end DG2_ReorderEnd

on DG2_ReorderControlHomed
   -- Once the control is in its new slot, remove any effects and redraw the
   -- list to tidy everything up.
   set the blendLevel of sReorderControl to 0
   set the outerGlow of sReorderControl to empty
   put empty into sReorderControl
   _RedrawList
end DG2_ReorderControlHomed

on DG2_ReorderScrollPoll
   cancel sReorderScrollPollMsgID

   if not sReorderInProgress then
      put empty into sReorderScrollPollMsgID
      exit DG2_ReorderScrollPoll
   end if

   local tMaxVScroll
   put the dgFormattedHeight of me - the height of group "dgList" of me into tMaxVScroll

      -- If the mouse is sitting at the top of the list, scroll the list up.
      -- If the mouse is sitting at teh bottom of the list, scroll the list down.
      -- This allows users to scroll the list while reordering.
      if item 2 of the mouseLoc - the top of me <= kReorderScrollPollMargin and the dgVScroll of me >= 0 then
         set the dgVScroll of me to max(the dgVScroll of me - kReorderScollPollIncrement, 0)
      else if the bottom of me - item 2 of the mouseLoc <= kReorderScrollPollMargin and the dgVScroll of me <= tMaxVScroll then
         set the dgVScroll of me to min(the dgVScroll of me + kReorderScollPollIncrement, tMaxVScroll)
   end if

   send "DG2_ReorderScrollPoll" to me in kReorderScrollPollRate milliseconds
   put the result into sReorderScrollPollMsgID
end DG2_ReorderScrollPoll

--------------------------------------------------------------------------------
-- DataGrid 2 Delete Animation Handlers

command DG2_DeleteIndex pIndex
   set the wholeMatches to true
   if pIndex is not among the items of the dgIndexes of me then
      return "Unknown index" && pIndex
   end if

   -- Store the vscroll before the delete. We want to preserve this.
   local tVScroll
   put the dgVScroll of me into tVScroll

   local tOffset
   put itemOffset(pIndex, sHilitedIndexes) into tOffset
   if tOffset > 0 then
      delete item tOffset of sHilitedIndexes
   end if

   if the dgProps["cache controls"] of me then
      if there is a sControlOfIndexA[pIndex] then
         put lineOffset(sControlOfIndexA[pIndex], sTableObjectsA["all row controls"]) into tOffset
         if tOffset > 0 then
            delete line tOffset of sTableObjectsA["all row controls"]
            subtract 1 from sTableObjectsA["row control count"]
         end if

         put lineOffset(sControlOfIndexA[pIndex], sTableObjectsA["visible row controls"]) into tOffset
         if tOffset > 0 then
            delete line tOffset of sTableObjectsA["visible row controls"]
         end if

         delete sControlOfIndexA[pIndex]
      end if
   end if

   local tControlHeight
   if the dgProps["fixed row height"] of me then
      put sControlHeights into tControlHeight
   else
      put sControlHeights[pIndex] into tControlHeight
   end if

   if sFormattedHeight is not empty then
      subtract tControlHeight from sFormattedHeight
   end if

   put itemOffset(pIndex, sIndexSequencing) into tOffset
   if tOffset > 0 then
      delete item tOffset of sIndexSequencing
   end if

   local tLineNo
   put tOffSet into tLineNo

   delete local sDataArray[pIndex]
   _StorePersistentData

   lock screen

   -- Hide any swipe and action controls that are present for the current row.
   local tActionControlHolder
   put DG2_EditModeActionControlHolderGet() into tActionControlHolder
   if tActionControlHolder is not empty and the visible of tActionControlHolder and the dgActionControlRowIndex of tActionControlHolder is pIndex then
      set the visible of tActionControlHolder to false
      set the dgActionControlRowIndex of tActionControlHolder to empty
   end if

   local tSwipeControlHolder
   put DG2_SwipeControlHolderGet() into tSwipeControlHolder
   if tSwipeControlHolder is not empty and the visible of tSwipeControlHolder and the dgSwipeControlRowIndex of tSwipeControlHolder is pIndex then
      set the visible of tSwipeControlHolder to false
      set the dgSwipeControlRowIndex of tSwipeControlHolder to empty
   end if

   if sFormattedHeight is not empty then
      _ConfigureScrollbar
      _AutoHideVScrollbar
   end if

   -- Redraw the list.
   if the keys of sDataArray is not empty then
      -- If there is a line number then this indicated we've found a control so
      -- we need to animate the delete.
      if tLineNo > 0 then
         -- Decide the direction of the animation.
         -- If there is enough scroll space above the deleted line, then pull in
         -- the controls from above. i.e. animate all controls before the
         -- deleted row downward.
         -- Otherwise animate the controls up from below.
         --
         -- Setting the vScroll here lays the controls out as they should be
         -- after the delete, ensuring all layout claculations are correct. This
         -- also sets the vScroll of the list group which we need to use to
         -- offset the y values of our animations.
         local tCallbackContextA
         if tVScroll >= tControlHeight then
            set the dgVScroll of me to tVScroll - tControlHeight
            put "above" into tCallbackContextA["animate from direction"]
         else
            set the dgVScroll of me to tVScroll
            put "below" into tCallbackContextA["animate from direction"]
         end if

         put tControlHeight into tCallbackContextA["deleted line height"]
         put tLineNo into tCallbackContextA["deleted line no"]
         put pIndex into tCallbackContextA["deleted line index"]
         put -1 * the vScroll of group "dgList" of me into tCallbackContextA["v scroll offset"]

         -- Use the draw loop callbacks to animate the delete.
         _DrawListWithProperties sTableObjectsA["base sequence for visible controls"], the vScroll of group "dgList" of me, true, "DG2_DeleteIndexDrawCallback", tCallbackContextA
      else
         _DrawAlternatingRows
         _RedrawList
      end if
   else
      _ResetData
   end if

   unlock screen

   return empty
end DG2_DeleteIndex

on DG2_DeleteIndexDrawCallbackStart @pContextA, @pTopLeft
   put empty into pContextA["animations"]
   put 0 into pContextA["animation count"]

   -- If we're pulling in the controls from above, then we want to start animating immediately.
   -- Flag this to the draw callback by setting the animate flag of the context.
   -- We also need to offset the initial top value the draw loop uses to take into account that
   -- all the controls above the deleted line will be animated downward.
   if pContextA["animate from direction"] is "above" then
      put true into pContextA["animate"]
      subtract pContextA["deleted line height"] from item 2 of pTopLeft
      put pContextA["deleted line height"] into pContextA["animation increment"]
   else
      put false into pContextA["animate"]
      put -1 * pContextA["deleted line height"] into pContextA["animation increment"]
   end if
end DG2_DeleteIndexDrawCallbackStart

on DG2_DeleteIndexDrawCallback @pContextA, pControl, pLineNo, @pControlRect, @pControlTopLeft
   -- We've reached the line number of the deleted control.
   -- If we were already animating, then stop (i.e. stop pulling controls down from above).
   -- If we are not animating, then start (i.e. start pulling up controls from below).
   -- All controls following this point need to be shifted down, so set the rect and top accordingly.
   -- i.e. if we've been pulling controls from above, the top will have been initially offset to take
   -- the animation into account. Undo this offset. If we're pulling up from below, the controls will
   -- need to be moved down to take into account the animate up.
   if pLineNo is pContextA["deleted line no"] then
      put not pContextA["animate"] into pContextA["animate"]
      add pContextA["deleted line height"] to item 2 of pControlTopLeft
      put item 1 of pControlRect, item 2 of pControlRect + pContextA["deleted line height"], item 3 of pControlRect, item 4 of pControlRect + pContextA["deleted line height"] into pControlRect
   end if

   -- Animate the control either up or down, based on pContextA["animation increment"].
   -- We need to take into account the scroll offset of the list. This is how the DataGrid partially
   -- shows/hides rows at the top and bottom.
   if pContextA["animate"] then
      add 1 to pContextA["animation count"]
      put DG2_AnimationsAnimationCreate(pControl, "top", item 2 of pControlTopLeft + pContextA["v scroll offset"], item 2 of pControlTopLeft + pContextA["animation increment"] + pContextA["v scroll offset"], the dgAnimationProp["DeleteIndexAnimationDuration"] of me, the dgAnimationProp["DeleteIndexAnimationEasing"] of me) into pContextA["animations"][pContextA["animation count"]]
   end if
end DG2_DeleteIndexDrawCallback

on DG2_DeleteIndexDrawCallbackEnd @pContextA
   -- Tidy up at the end of the delete animation.
   if pContextA["animation count"] is not 0 then
      DG2_AnimationsAnimationSetCompletionMessage pContextA["animations"][pContextA["animation count"]], "DG2_DeleteIndexAnimateComplete"
      DG2_AnimationsAnimationSetMessageTarget pContextA["animations"][pContextA["animation count"]], the long id of me
      DG2_AnimationsBatchAddWithArray pContextA["animations"]
   else
      send "DG2_DeleteIndexAnimateComplete" to me in 0 seconds
   end if
end DG2_DeleteIndexDrawCallbackEnd

on DG2_DeleteIndexAnimateComplete
   lock screen
   _DrawAlternatingRows
   _RedrawList
   unlock screen
end DG2_DeleteIndexAnimateComplete

--------------------------------------------------------------------------------
-- DataGrid 2 Control Holder Handlers

private function DG2_SwipeControlHolderGet
   -- Create a group to house the swipe control and catch any messages.
   -- When swipe buttons are visible, they take over the whole DataGrid.
   if there is a group "dgList" of me then
      if there is no group "DG2 Swipe Control Holder" of group "dgList" of me then
         lock screen

         local tRect
         put the rect of group "dgListMask" of me into tRect

         local tMsgsAreLocked
         put the lockMessages into tMsgsAreLocked
         lock messages

         reset the templateGroup
         create invisible group "DG2 Swipe Control Holder" in group "dgList" of me
         set the margins of it to 0
         set the dgControl of it to the dgControl of me
         set the behavior of it to the long ID of button "Swipe Control Holder" of group "Behaviors" of stack _ResourceStack()

         reset the templateGraphic
         create graphic "Message Catcher" in it
         set the rect of it to tRect
         set the style of it to "rectangle"
         set the linesize of it to 0
         set the opaque of it to true
         set the blendLevel of it to 100

         set the lockMessages to tMsgsAreLocked
         unlock screen
      end if

      return the long id of group "DG2 Swipe Control Holder" of group "dgList" of me
   end if

   return empty
end DG2_SwipeControlHolderGet

-- Called after scrolling the list.
private command DG2_SwipeControlHolderReposition
   local tControlHolder
   put DG2_SwipeControlHolderGet() into tControlHolder
   if tControlHolder is empty  or there is not a tControlHolder then
      return empty
   end if

   if the visible of tControlHolder then
      set the rect of tControlHolder to the rect of group "dgList" of me
      dispatch "DG2_SwipeControlHolderReposition" to tControlHolder
      return the result
   end if

   return empty
end DG2_SwipeControlHolderReposition

private function DG2_EditModeActionControlHolderGet
   -- Create a group to house the action control and catch any messages.
   -- When the action control is visible, it takes over the whole DataGrid.
   if there is a group "dgList" of me then
      if there is no group "DG2 Edit Mode Action Control Holder" of group "dgList" of me then
         lock screen

         local tRect
         put the rect of group "dgListMask" of me into tRect

         local tMsgsAreLocked
         put the lockMessages into tMsgsAreLocked
         lock messages

         reset the templateGroup
         create invisible group "DG2 Edit Mode Action Control Holder" in group "dgList" of me
         set the margins of it to 0
         set the dgControl of it to the dgControl of me
         set the behavior of it to the long ID of button "Action Control Holder" of group "Behaviors" of stack _ResourceStack()

         reset the templateGraphic
         create graphic "message catcher" in it
         set the rect of it to tRect
         set the style of it to "rectangle"
         set the linesize of it to 0
         set the opaque of it to true
         set the blendLevel of it to 100

         set the lockMessages to tMsgsAreLocked
         unlock screen
      end if

      return the long id of group "DG2 Edit Mode Action Control Holder" of group "dgList" of me
   end if

   return empty
end DG2_EditModeActionControlHolderGet

-- Called after scrolling the list.
private command DG2_EditModeActionControlHolderReposition
   if not sEditMode then
      return empty
   end if

   local tControlHolder
   put DG2_EditModeActionControlHolderGet() into tControlHolder
   if tControlHolder is empty  or there is not a tControlHolder then
      return empty
   end if

   if the visible of tControlHolder then
      set the rect of tControlHolder to the rect of group "dgList" of me
      dispatch "DG2_EditModeActionControlHolderReposition" to tControlHolder
      return the result
   end if

   return empty
end DG2_EditModeActionControlHolderReposition

--------------------------------------------------------------------------------
-- DataGrid 2 Customisable Controls Handlers
--
-- Customisable controls refer to the swipe, action, action select and reorder
-- controls: The set of controls that can be specified by the user.
-- We have default implementations of the controls which can be overidden by
-- setting the dgProps or handling the appropriate messages.
-- The following handlers take care of cloning and managing the controls appropriately.

private command DG2_CustomisableControlsInit
   local tPropertyNames
   get the customProperties["dgProps"] of me
   put the keys of it into tPropertyNames

   lock screen
   repeat for each item tControlName in kCustomisableControlNames
      -- Get the default implemetation of the control by calling the appropriate funciton.
      -- e.g. DG2_CustomisableControlsGetDefaultEditModeActionSelectControl()
      local tFunctionName
      put tControlName into tFunctionName
      replace space with empty in tFunctionName
      put "DG2_CustomisableControlsGetDefault" before tFunctionName

      local tControl
      dispatch function tFunctionName to me
      put the result into tControl
      if it is not "handled" then
         return "Unable to create default for control" && tControlName
      end if

      if tControl is not empty and there is a tControl then
         -- Use the default control if: A property hasn't already been set for this control type,
         -- or one has been set but the control no longer exists.
         if tControlName is not among lines of tPropertyNames or (the dgProps[tControlName] of me is not empty and there is not a (the dgProps[tControlName] of me)) then
            set the dgProps[tControlName] of me to the long id tControl
         end if
      end if
   end repeat
   unlock screen

   put true into sCustomisableControlsInitialised

   return empty
end DG2_CustomisableControlsInit

-- Returns the id of the customisable control of the given name for the given row.
private function DG2_CustomisableControlsGetForControlByName pRowControl, pControlName
   if not sCustomisableControlsInitialised then
      DG2_CustomisableControlsInit
   end if

   set the wholeMatches to true
   if pControlName is not among the items of kCustomisableControlNames then
      return empty
   end if

   -- If we haven't already fetched the given control for the row.
   if sCustomisableControlsA[pRowControl][pControlName] is not an array then
      -- Singleton controls are controls of which we only requre one per DataGrid - not one per row.
      local tIsSingleton
      put pControlName is among the items of kCustomisableControlSingletons into tIsSingleton

      -- Attempt to find the control to use. First of all send a message to the row. (e.g.
      -- GetEditModeReorderControl)
      -- If this message is handled, then use the control returend. If not, use the control specified
      -- in the dgProps.
      local tMessage
      put pControlName into tMessage
      replace space with empty in tMessage
      put "Get" before tMessage

      local tControl
      dispatch tMessage to pRowControl
      if it is "handled" then
         put the result into tControl
      else
         put the dgProps[pControlName] of me into tControl
      end if

      -- Set up the data array for the control
      if tControl is not empty and there is a tControl then
         local tControlA
         put the long id of tControl into tControlA["original"]
         put tIsSingleton into tControlA["singleton"]

         -- Check to see if the control we've found is the default implementation.
         -- This is needed for tidying up later.
         local tFunctionName
         put pControlName into tFunctionName
         replace space with empty in tFunctionName
         put "DG2_CustomisableControlsGetDefault" before tFunctionName
         dispatch function tFunctionName to me
         put the long id of the result is the long id of tControl into tControlA["default"]

         -- If this is a singleton control and we've already got a version of it present, then use that version.
         if tIsSingleton and sCustomisableControlsSingletonCopyMapA[tControlA["original"]] is not empty and there is sCustomisableControlsSingletonCopyMapA[tControlA["original"]] then
            put sCustomisableControlsSingletonCopyMapA[tControlA["original"]] into tControl
         else
            -- Otherwise we need to potentially copy the control to the datagrid.
            -- Singleton controls need to be copied to the DataGrid itself.
            -- Per row controls need tobe copied into the row.
            local tParent
            if tIsSingleton then
               put the long id of me into tParent
            else
               put the long id of pRowControl into tParent
            end if

            -- Only copy if the control is not already present in the target.
            -- i.e. the control is part of the row template.
            if not (the long id of tControl contains tParent) then
               lock screen
               copy tControl to tParent
               set the visible of it to false
               unlock screen
               put it into tControl
            end if

            -- Store the control in the list of singletons so that it can be reused.
            if tIsSingleton then
               put the long id of tControl into sCustomisableControlsSingletonCopyMapA[tControlA["original"]]
               if not tControlA["default"] then
                  put the long id of tControl into sCustomisableControlsSingletonsA[the long id of tControl]
               end if
            end if
         end if

         put the long id of tControl into tControlA["id"]
         put tControlA into sCustomisableControlsA[pRowControl][pControlName]
      else
         put empty into sCustomisableControlsA[pRowControl][pControlName]["id"]
      end if
   end if

   return sCustomisableControlsA[pRowControl][pControlName]["id"]
end DG2_CustomisableControlsGetForControlByName

function DG2_CustomisableControlsGetEditModeReorderControlForControl pControl
   return DG2_CustomisableControlsGetForControlByName(pControl, "edit mode reorder control")
end DG2_CustomisableControlsGetEditModeReorderControlForControl

function DG2_CustomisableControlsGetEditModeActionSelectControlForControl pControl
   return DG2_CustomisableControlsGetForControlByName(pControl, "edit mode action select control")
end DG2_CustomisableControlsGetEditModeActionSelectControlForControl

function DG2_CustomisableControlsGetEditModeActionControlForControl pControl
   return DG2_CustomisableControlsGetForControlByName(pControl, "edit mode action control")
end DG2_CustomisableControlsGetEditModeActionControlForControl

function DG2_CustomisableControlsGetLeftSwipeControlForControl pControl
   return DG2_CustomisableControlsGetForControlByName(pControl, "left swipe control")
end DG2_CustomisableControlsGetLeftSwipeControlForControl

function DG2_CustomisableControlsGetRightSwipeControlForControl pControl
   return DG2_CustomisableControlsGetForControlByName(pControl, "right swipe control")
end DG2_CustomisableControlsGetRightSwipeControlForControl

private command DG2_CustomisableControlsClear
   repeat for each element tControlA in sCustomisableControlsA
      repeat for each element tCustomisableControlA in tControlA
         if tCustomisableControlA["id"] is not empty and there is a tCustomisableControlA["id"] then
            -- Force remove every control we have made a copy of.
            if not tCustomisableControlA["original"] is not tCustomisableControlA["id"] then
               delete tCustomisableControlA["id"]
            end if
         end if
      end repeat
   end repeat

   put empty into sCustomisableControlsA
   DG2_CustomisableControlsClearSingletons
   return the result
end DG2_CustomisableControlsClear

private command DG2_CustomisableControlsClearForControlByName pRowControl, pControlName
   -- Control doesn't exist - just tidy up the cache.
   if sCustomisableControlsA[pRowControl][pControlName]["id"] is empty or there is no sCustomisableControlsA[pRowControl][pControlName]["id"] then
      delete variable sCustomisableControlsA[pRowControl][pControlName]
      return empty
   end if

   -- If it is a default control, the we want keep the control around for future reuse.
   if sCustomisableControlsA[pRowControl][pControlName]["default"] then
      set the visible of sCustomisableControlsA[pRowControl][pControlName]["id"] to false
      delete variable sCustomisableControlsA[pRowControl][pControlName]
      return empty
   end if

   -- Keep singletons around - other rows might be using them.
   -- Delete all other controls.
   if not sCustomisableControlsA[pRowControl][pControlName]["singleton"] and sCustomisableControlsA[pRowControl][pControlName]["original"] is not sCustomisableControlsA[pRowControl][pControlName]["id"] then
      delete sCustomisableControlsA[pRowControl][pControlName]["id"]
   else
      set the visible of sCustomisableControlsA[pRowControl][pControlName]["id"] to false
   end if
   delete variable sCustomisableControlsA[pRowControl][pControlName]

   return empty
end DG2_CustomisableControlsClearForControlByName

command DG2_CustomisableControlsClearForControl pRowControl
   repeat for each key tControlName in sCustomisableControlsA[pRowControl]
      DG2_CustomisableControlsClearForControlByName pRowControl, tControlName
   end repeat

   return empty
end DG2_CustomisableControlsClearForControl

private command DG2_CustomisableControlsClearByName pControlName
   repeat for each key tRowControl in sCustomisableControlsA
      DG2_CustomisableControlsClearForControlByName tRowControl, pControlName
   end repeat

   return empty
end DG2_CustomisableControlsClearByName

private command DG2_CustomisableControlsClearSingletons
   repeat for each element tControl in sCustomisableControlsSingletonsA
      if there is a tControl then
         delete tControl
      end if
   end repeat

   put empty into sCustomisableControlsSingletonCopyMapA
   put empty into sCustomisableControlsSingletonsA

   return empty
end DG2_CustomisableControlsClearSingletons

--------------------------------------------------------------------------------
-- DataGrid 2 Default Customisable Control Implentations
--
-- The default implementations will be created in the template stack (if they
-- don't already exist).

function DG2_CustomisableControlsGetDefaultEditModeReorderControl
   if there is not a group "DG2 Default Edit Mode Reorder Control"of _TemplateControl() then
      local tMsgsAreLocked
      put the lockMessages into tMsgsAreLocked
      unlock messages

      reset the templateGroup
      create invisible group "DG2 Default Edit Mode Reorder Control" in _TemplateControl()
      set the margins of it to kEditModeReorderControlMargins
      set the layerMode of it to "dynamic"

      create widget as "com.livecode.widget.svgpath" in it
      set the iconPresetName of it to kEditModeReorderControlIcon
      set the width of it to kEditModeReorderControlWidth
      set the foregroundColor of it to kEditModeReorderControlColor

      set the lockMessages to tMsgsAreLocked
   end if

   return the long id of group "DG2 Default Edit Mode Reorder Control" of _TemplateControl()
end DG2_CustomisableControlsGetDefaultEditModeReorderControl

function DG2_CustomisableControlsGetDefaultEditModeActionSelectControl
   if there is not a group "DG2 Default Edit Mode Action Select Control" of _TemplateControl() then
      local tMsgsAreLocked
      put the lockMessages into tMsgsAreLocked
      unlock messages

      reset the templateGroup
      create invisible group "DG2 Default Edit Mode Action Select Control" in _TemplateControl()
      set the margins of it to kEditModeActionSelectControlMargins
      set the layerMode of it to "dynamic"

      create widget as "com.livecode.widget.svgpath" in it
      set the iconPresetName of it to kEditModeActionSelectControlIcon
      set the width of it to kEditModeActionSelectControlWidth
      set the foregroundColor of it to kEditModeActionSelectControlIconColor

      set the lockMessages to tMsgsAreLocked
   end if

   return the long id of group "DG2 Default Edit Mode Action Select Control" of _TemplateControl()
end DG2_CustomisableControlsGetDefaultEditModeActionSelectControl

function DG2_CustomisableControlsGetDefaultEditModeActionControl
   if there is not a group "DG2 Default Action Control" of _TemplateControl()  then
      local tHeight
      put the dgProps["row height"] of me into tHeight

      local tMsgsAreLocked
      put the lockMessages into tMsgsAreLocked
      unlock messages

      reset the templateGroup
      create invisible group "DG2 Default Action Control" in _TemplateControl()
      set the margins of it to 0
      set the layerMode of it to "dynamic"

      reset the templateButton
      create button "DG2 Default Action Control" in it
      set the style of it to "opaque"
      set the label of it to kEditModeActionControlText
      set the autoHilite of it to false
      set the foregroundColor of it to kEditModeActionControlTextColor
      set the backgroundColor of it to kEditModeActionControlBGColor
      set the width of it to kEditModeActionControlWidth
      set the height of it to tHeight
      set the margins of it to 0

      set the lockMessages to tMsgsAreLocked
   end if

   return the long id of group "DG2 Default Action Control" of _TemplateControl()
end DG2_CustomisableControlsGetDefaultEditModeActionControl

private function DG2_CustomisableControlsGetDefaultSwipeControl pName
   if there is not a group pName of _TemplateControl() then
      local tHeight
      put the dgProps["row height"] of me into tHeight

      local tMsgsAreLocked
      put the lockMessages into tMsgsAreLocked
      unlock messages

      local tGroup
      reset the templateGroup
      create invisible group pName in _TemplateControl()
      set the margins of it to 0
      set the layerMode of it to "dynamic"
      put it into tGroup

      reset the templateGraphic
      create graphic in tGroup
      set the style of it to "rectangle"
      set the width of it to kSwipeControlWidth
      set the height of it to tHeight
      set the linesize of it to 0
      set the opaque of it to true
      set the backgroundColor of it to kSwipeControlBGColor

      create widget as "com.livecode.widget.svgpath" in tGroup
      set the iconPresetName of it to kSwipeControlIcon
      set the width of it to kSwipeControlIconWidth
      set the foregroundColor of it to kSwipeControlIconColor

      set the lockMessages to tMsgsAreLocked
   end if

   return the long id of group pName of _TemplateControl()
end DG2_CustomisableControlsGetDefaultSwipeControl

function DG2_CustomisableControlsGetDefaultLeftSwipeControl
   return DG2_CustomisableControlsGetDefaultSwipeControl("DG2 Default Left Swipe Control")
end DG2_CustomisableControlsGetDefaultLeftSwipeControl

function DG2_CustomisableControlsGetDefaultRightSwipeControl
   return DG2_CustomisableControlsGetDefaultSwipeControl("DG2 Default Right Swipe Control")
end DG2_CustomisableControlsGetDefaultRightSwipeControl

private command DG2_CustomisableControlsResizeDefaults
   if not sCustomisableControlsInitialised then
      DG2_CustomisableControlsInit
   end if

   -- The singleton controls need to be resized to take into account the line height.
   lock screen
   repeat for each item tControlName in kCustomisableControlSingletons
      local tFunctionName
      put tControlName into tFunctionName
      replace space with empty in tFunctionName
      put "DG2_CustomisableControlsGetDefault" before tFunctionName

      local tControl
      dispatch function tFunctionName to me
      put the result into tControl

      if tControl is not empty and there is a tControl then
         -- Assume the first control in the group is the background.
         -- All other controls should be centered.
         repeat with tControlNo = 1 to the number of controls in tControl
            if tControlNo is 1 then
               set the height of control tControlNo of tControl to the dgProps["row height"] of me
            else
               set the loc of control tControlNo of tControl to the loc of tControl
            end if
         end repeat
      end if
   end repeat
   unlock screen

   return empty
end DG2_CustomisableControlsResizeDefaults

--------------------------------------------------------------------------------
-- DataGrid 2 Animation Handlers
--
-- All animations have the following properties
--
-- pControl - The control to animate.
-- pProperty - The property to effect (e.g. top, width etc).
-- pStartValue - The start value of the poperty.
-- pEndValue - The end value of the property.
-- pDuration - The duration of the animation
-- pEasing - The easing function to use for the animation. Default to "linear".
-- pCompleteMsg - The message to send on completion of the animation.
-- pStepMsg - The message to send after each redraw.
-- pMsgTarget - The control to send the messages to. Defaults to the control we are animating.
--
-- The redrawing occurs in handler "DG2_AnimationsPulse", which executes every
-- kAnimationsPulseRate milliseconds, while there are amnimations to handle.

setProp dgAnimationProp[pTag] pValue
   if pTag is not among the lines of the keys  of sAnimationProps then
      return "Unknown animation property" && pTag
   end if

   put pValue into sAnimationProps[pTag]
   return empty
end dgAnimationProp

getProp dgAnimationProp[pTag]
   return sAnimationProps[pTag]
end dgAnimationProp

private command DG2_AnimationsInitProps
   put kEditModeEnterExitDuration into sAnimationProps["EditModeEnterExitDuration"]
   put kEditModeEnterExitActionSelectControlControlEasing into sAnimationProps["EditModeEnterExitActionSelectControlControlEasing"]
   put kEditModeEnterExitReorderControlEasing into sAnimationProps["EditModeEnterExitReorderControlEasing"]
   put kEditModeActionControlAnimationDuration into sAnimationProps["EditModeActionControlAnimationDuration"]
   put kEditModeActionControlAnimationEasing  into sAnimationProps["EditModeActionControlAnimationEasing"]
   put kReorderAnimationDuration into sAnimationProps[ "ReorderAnimationDuration"]
   put kReorderAnimationEasing into sAnimationProps["ReorderAnimationEasing"]
   put kReorderHomingDuration into sAnimationProps["ReorderHomingDuration"]
   put kReorderHomingEasing into sAnimationProps["kReorderHomingEasing"]
   put kDeleteIndexAnimationDuration into sAnimationProps["DeleteIndexAnimationDuration"]
   put kDeleteIndexAnimationEasing into sAnimationProps["DeleteIndexAnimationEasing"]
   put kSwipeCompleteDuration into sAnimationProps["SwipeCompleteDuration"]
   put kSwipeCompleteEasing into sAnimationProps["SwipeCompleteEasing"]
   put kSwipeReturnDuration into sAnimationProps["SwipeReturnDuration"]
   put kSwipeReturnEasing into sAnimationProps["SwipeReturnEasing"]

   return empty
end DG2_AnimationsInitProps

function DG2_AnimationsAnimationCreate pControl, pProperty, pStartValue, pEndValue, pDuration, pEasing, pCompleteMsg, pStepMsg, pMsgTarget
   local tAnimationA
   put pControl into tAnimationA["control"]
   put pProperty into tAnimationA["property"]
   put pStartValue into tAnimationA["start"]
   put pEndValue into tAnimationA["end"]
   put pDuration into tAnimationA["duration"]
   put pEasing into tAnimationA["easing"]
   put pCompleteMsg into tAnimationA["completion message"]
   put pStepMsg into tAnimationA["step message"]
   if pMsgTarget is not empty then
      put pMsgTarget into tAnimationA["message target"]
   else
      put pControl into tAnimationA["message target"]
   end if
   return tAnimationA
end DG2_AnimationsAnimationCreate

command DG2_AnimationsAnimationSetControl @self, pControl
   put pControl into self["control"]
end DG2_AnimationsAnimationSetControl

command DG2_AnimationsAnimationSetProperty @self, pProperty
   put pProperty into self["property"]
end DG2_AnimationsAnimationSetProperty

command DG2_AnimationsAnimationSetStart @self, pStart
   put pStart into self["start"]
end DG2_AnimationsAnimationSetStart

command DG2_AnimationsAnimationSetEnd @self, pEnd
   put pEnd into self["end"]
end DG2_AnimationsAnimationSetEnd

command DG2_AnimationsAnimationSetDuration @self, pDuration
   put pDuration into self["duration"]
end DG2_AnimationsAnimationSetDuration

command DG2_AnimationsAnimationSetEasing @self, pEasing
   put pEasing into self["easing"]
end DG2_AnimationsAnimationSetEasing

command DG2_AnimationsAnimationSetCompletionMessage @self, pMsg
   put pMsg into self["completion message"]
end DG2_AnimationsAnimationSetCompletionMessage

command DG2_AnimationsAnimationSetStepMessage @self, pMsg
   put pMsg into self["step message"]
end DG2_AnimationsAnimationSetStepMessage

command DG2_AnimationsAnimationSetMessageTarget @self, pMsgTarget
   put pMsgTarget into self["message target"]
end DG2_AnimationsAnimationSetMessageTarget

command DG2_AnimationsAdd pControl, pProperty, pStartValue, pEndValue, pDuration, pEasing, pCompleteMsg, pStepMsg, pMsgTarget
   local tAnimationA
   put DG2_AnimationsAnimationCreate(pControl, pProperty, pStartValue, pEndValue, pDuration, pEasing, pCompleteMsg, pStepMsg, pMsgTarget) into tAnimationA
   DG2_AnimationsAddWithArray tAnimationA
   return the result
end DG2_AnimationsAdd

command DG2_AnimationsAddWithArray pAnimationA
   -- If animations are off, just set the property to the end value.
   if not the dgProps["animate actions"] of me then
      DG2_AnimationsFinaliseAnimation pAnimationA
      return empty
   end if

   put pAnimationA["end"] - pAnimationA["start"] into pAnimationA["change"]
   put the milliseconds into pAnimationA["time"]

   put (sAnimationsLastID + 1) mod 1000 into sAnimationsLastID
   put sAnimationsLastID into pAnimationA["id"]
   put pAnimationA into sAnimationsA[sAnimationsLastID]

   if sAnimationsPulseMsgID is empty then
      send "DG2_AnimationsPulse" to me in 0 seconds
      put the result into sAnimationsPulseMsgID
   end if

   return pAnimationA["id"]
end DG2_AnimationsAddWithArray

command DG2_AnimationsBatchAddWithArray pAnimationsA
   local tTime
   put the milliseconds into tTime

   local tIDs

   repeat for each element tAnimationA in pAnimationsA
      -- If animations are off, just set the property to the end value.
      if not the dgProps["animate actions"] of me then
         DG2_AnimationsFinaliseAnimation tAnimationA
         next repeat
      end if

      put tAnimationA["end"] - tAnimationA["start"] into tAnimationA["change"]
      put tTime into tAnimationA["time"]

      put (sAnimationsLastID + 1) mod 1000 into sAnimationsLastID
      put sAnimationsLastID into tAnimationA["id"]
      put tAnimationA into sAnimationsA[sAnimationsLastID]

      if tIDs is not empty then
         put comma after tIDs
      end if
      put sAnimationsLastID after tIDs
   end repeat

   if not the dgProps["animate actions"] of me then
      return empty
   end if

   if sAnimationsPulseMsgID is empty then
      send "DG2_AnimationsPulse" to me in 0 seconds
      put the result into sAnimationsPulseMsgID
   end if

   return tIDs
end DG2_AnimationsBatchAddWithArray

function DG2_AnimationsGetPendingCount
   if sAnimationsA is empty or sAnimationsA is not an array then
      return 0
   else
      return the number of lines in the keys of sAnimationsA
   end if
end DG2_AnimationsGetPendingCount

-- Set all current animations to their end value.
command DG2_AnimationsFinaliseAll
   cancel sAnimationsPulseMsgID
   repeat for each element tAnimationA in sAnimationsA
      DG2_AnimationsFinaliseAnimation tAnimationA
   end repeat
   put empty into sAnimationsA

   return empty
end DG2_AnimationsFinaliseAll

-- Stop all current animaitions, leaving the controls as they are.
command DG2_AnimationsStopAll
   cancel sAnimationsPulseMsgID
   put empty into sAnimationsA
   return empty
end DG2_AnimationsStopAll

command DG2_AnimationsFinaliseAnimationByID pAnimationID
   local tAnimationA
   put sAnimationsA[pAnimationID] into tAnimationA
   if tAnimationA is an array then
      DG2_AnimationsFinaliseAnimation tAnimationA
   end if
   return empty
end DG2_AnimationsFinaliseAnimationByID

command DG2_AnimationsFinaliseStopByID pAnimationID
   delete variable sAnimationsA[pAnimationID]
   return empty
end DG2_AnimationsFinaliseStopByID

private command DG2_AnimationsFinaliseAnimation pAnimationA
   DG2_AnimationsSetPropertyOfControl pAnimationA["control"], pAnimationA["property"], pAnimationA["end"]
   if pAnimationA["completion message"] is not empty then
      send pAnimationA["completion message"] && pAnimationA["property"] & comma & pAnimationA["end"] to pAnimationA["message target"] in 0 seconds
   end if

   if pAnimationA["id"] is not empty then
      delete variable sAnimationsA[pAnimationA["id"]]
   end if

   return empty
end DG2_AnimationsFinaliseAnimation

private command DG2_AnimationsSetPropertyOfControl pControl, pProperty, pValue
   switch pProperty
      case "top"
         set the top of pControl to pValue
         break
      case "left"
         set the left of pControl to pValue
         break
      case "bottom"
         set the bottom of pControl to pValue
         break
      case "right"
         set the right of pControl to pValue
         break
      case "width"
         set the width of pControl to pValue
         break
      case "heaight"
         set the height of pControl to pValue
         break
      case "blendLevel"
         set the blendLevel of pControl to pValue
         break
   end switch
end DG2_AnimationsSetPropertyOfControl

on DG2_AnimationsPulse
   cancel sAnimationsPulseMsgID

   local tCurrentTime
   put the milliseconds into tCurrentTime

   lock screen
   repeat for each element tAnimationA in sAnimationsA
      if (the milliseconds - tAnimationA["time"]) >= tAnimationA["duration"] then
         DG2_AnimationsFinaliseAnimation tAnimationA
      else
         switch tAnimationA["easing"]
            case "in"
               get _easeIn(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
            case "out"
               get _easeOut(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
            case "in out"
               get _easeInOut(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
            case "in elastic"
               get _easeInElastic(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
            case "out elastic"
               get _easeOutElastic(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
            case "in out elastic"
               get _easeInOutElastic(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
            case "in bounce"
               get _easeInBounce(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
            case "out bounce"
               get _easeOutBounce(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
            case "in out bounce"
               get _easeInOutBounce(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
            case "in back"
               get _easeInBack(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
            case "out back"
               get _easeOutBack(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
            case "in out back"
               get _easeInOutBack(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
            case "in back cubic"
               get _easeInBackCubic(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
            case "out back cubic"
               get _easeOutBackCubic(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
            case "linear"
            default
               get _easeLinear(tCurrentTime - tAnimationA["time"], tAnimationA["start"], tAnimationA["change"], tAnimationA["duration"])
               break
         end switch

         DG2_AnimationsSetPropertyOfControl tAnimationA["control"], tAnimationA["property"], it

         if tAnimationA["step message"] is not empty then
            send tAnimationA["step message"] && tAnimationA["property]"] & comma & it to tAnimationA["message target"] in 0 seconds
         end if
      end if
   end repeat
   unlock screen

   if sAnimationsA is not empty then
      -- Redraw every kAnimationsPulseRate milliseconds.
      -- Make sure we take into account how long this handler took when determing when next to redraw.
      send "DG2_AnimationsPulse" to me in (kAnimationsPulseRate - (the milliseconds -  tCurrentTime)) milliseconds
      put the result into sAnimationsPulseMsgID
   else
      put empty into sAnimationsPulseMsgID
   end if
end DG2_AnimationsPulse

--------------------------------------------------------------------------------
-- Easing functions - based on Robert Penner's easing functions.
-- http://robertpenner.com/easing/

private function _easeLinear t, b, c, d
   return c * t / d + b
end _easeLinear

private function _easeIn t, b, c, d
   put t / d into t
   return c * t * t + b
end _easeIn

private function _easeOut t, b, c, d
   put t / d into t
   return -c * t * (t - 2) + b
end _easeOut

private function _easeInOut t, b, c, d
   put t / (d / 2) into t
   if t < 1 then
      return c / 2 * t * t + b
   end if
   subtract 1 from t
   return -c / 2 * (t * (t - 2) - 1) + b
end _easeInOut

private function _easeInElastic t, b, c, d
   put t / d into t
   if t is 1 then
      return b + c
   end if

   local p, s
   put d * 0.3 into p
   put p / 4 into s

   put t - 1 into t
   return -(c * 2 ^ (10 * t) * sin((t * d - s) * (2 * PI) / p)) + b
end _easeInElastic

private function _easeOutElastic t, b, c, d
   put t / d into t
   if t is 1 then
      return b + c
   end if

   local p, s
   put d * 0.3 into p
   put p / 4 into s

   return (c * (2 ^ (-10 * t)) * sin((t * d - s) * (2 * PI) / p) + c + b);
end _easeOutElastic

private function _easeInOutElastic t, b, c, d
   if t < (d / 2) then
      return _easeOutElastic(t * 2, b, c / 2, d)
   else
      return _easeInElastic((t * 2) - d, b + c / 2, c / 2, d);
   end if
end _easeInOutElastic

private function _easeInBounce t, b, c, d
   return c - _easeOutBounce(d - t, 0, c, d) + b
end _easeInBounce

private function _easeOutBounce t, b, c, d
   put t /d into t
   if t < (1 / 2.75) then
      return c * (7.5625 * t * t) + b
   else if t < (2 / 2.75) then
      put t - (1.5 / 2.75) into t
      return c * (7.5625 * t * t + 0.75) + b
   else if t < (2.5 / 2.75) then
      put t - (2.25 / 2.75) into t
      return c * (7.5625 * t * t + 0.9375) + b
   else
      put t - (2.625 / 2.75) into t
      return c * (7.5625 * t * t + 0.984375) + b
   end if
end _easeOutBounce

private function _easeInOutBounce t, b, c, d
   if t < (d / 2) then
      return _easeInBounce(t * 2, 0, c, d) * 0.5 + b
   else
      return _easeOutBounce(t * 2 - d, 0, c, d) * 0.5 + c * 0.5 + b
   end if
end _easeInOutBounce

private function _easeInBack t, b, c, d
   put t / d into t
   return c * t * t * ((1.70158 + 1) * t - 1.70158) + b
end _easeInBack

private function _easeOutBack t, b, c, d
   put t / d into t
   return c * ((t  - 1) * t * ((1.70158 + 1) * t + 1.70158) + 1) + b
end _easeOutBack

private function _easeInOutBack t, b, c, d
   local s
   put 1.70158 * 1.525 into s
   put t / d into t
   if (t / 2) < 1 then
      return c / 2 * (t * t * ((s + 1) * t - s)) + b
   else
      put t - 2 into t
      return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
   end if
end _easeInOutBack

private function _easeInBackCubic t, b, c, d
   put t / d into t
   return b  + c * (4 * t * t* t + -3 * t * t)
end _easeInBackCubic

private function _easeOutBackCubic t, b, c, d
   put t / d into t
   return b + c * ( 4 * t * t * t + -9 * t * t + 6 * t)
end _easeOutBackCubic

--------------------------------------------------------------------------------
-- These handler convert vertical locations to and from line numbers.
-- This assumes the DataGrid is using rows of fixed height.

private function DG2_MiddleOfControlWithLineNo pLineNo
   return __topOfControlWithLineNo(pLineNo) + the dgProps["row height"] of me / 2
end DG2_MiddleOfControlWithLineNo

private function DG2_TopOfControlWithLineNo pLineNo
   return (the top of group "dgListMask" of me + (pLineNo - 1) * the dgProps["row height"] of me) - the dgVScroll of me
end DG2_TopOfControlWithLineNo

private function DG2_BottomOfControlWithLineNo pLineNo
   return (the top of group "dgListMask" of me + (pLineNo) * the dgProps["row height"] of me) - the dgVScroll of me
end DG2_BottomOfControlWithLineNo

private function DG2_LocOfControlWithLineNo pLineNo
   return (item 1 of the loc of me, __middleOfControlWithLineNo(pLineNo))
end DG2_LocOfControlWithLineNo

private function DG2_VerticalLocToLineNo pPosV
   return ceil((pPosV + the dgVScroll of me - the top of group "dgListMask" of me) / the dgProps["row height"] of me)
end DG2_verticalLocToLineNo

--------------------------------------------------------------------------------

-- A row controls working rect takes into account any controls visible as part of
-- edit mode. i.e. it is reduced on the left hand side by the action select
-- control and on the right hand side by the reorder control.
private function DG2_GetWorkingRectOfControlFromControlRect pControl, pControlRect
   if sEditMode then
      local tActionSelectControl
      put DG2_CustomisableControlsGetEditModeActionSelectControlForControl(the long id of pControl) into tActionSelectControl
      if tActionSelectControl is not empty then
         add the width of tActionSelectControl to item 1 of pControlRect
      end if

      local tReorderControl
      put DG2_CustomisableControlsGetEditModeReorderControlForControl(the long id of pControl) into tReorderControl
      if tReorderControl is not empty then
         subtract the width of tReorderControl from item 3 of pControlRect
      end if
   end if

   return pControlRect
end DG2_GetWorkingRectOfControlFromControlRect
