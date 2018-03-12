script "RevDataGridLibraryBehaviorsRowChainedBehavior"
----------------------------------------------------------------------
-- This behavior sits at the back of a row's behavior chain and is used to
-- determine and handle edit mode and swipe actions.

local sPreDragging
local sDragging
local sDragStart
local sDragLocs
local sControlLeft
local sControlRight

-- A user is seen to be dragging a row if the mouse has moved kPreDragLocDiff
-- points within kPreDragTimeMargin milliseconds of the initial mouse click.
constant kPreDragLocDiff = 15
constant kPreDragTimeMargin = 100

-- A swipe has occured if the mouse has moved kSwipeLocDiff points within
-- kSwipeTimeDiff milliseconds, plus or minus kSwipeTimeDiffMargin.
constant kSwipeTimeDiff = 100
constant kSwipeTimeDiffMargin = 25
constant kSwipeLocDiff = 50

----------------------------------------------------------------------

private command DG2_ClearVars
   put false into sPreDragging
   put false into sDragging
   put empty into sDragStart
   put empty into sDragLocs
   put empty into sControlLeft
   put empty into sControlRight

   DG2_CustomisableControlsClearForControl the long id of me
end DG2_ClearVars

before PreFillInData
   DG2_ClearVars
end PreFillInData

before ResetData
   DG2_ClearVars
end ResetData

----------------------------------------------------------------------

before mouseDown
   -- This prevents execution when editing the template stack
   if the dgControl of me is empty then
      pass mouseDown
   end if

   if the dgEditMode of the dgControl of me then
      -- If the reorder control has been clicked start a reorder. Exiting to top
      -- at this point prevents the mouseDown message being sent to control.
      local tReorderControl
      put DG2_CustomisableControlsGetEditModeReorderControlForControl(the long id of me) into tReorderControl
      if tReorderControl is not empty and the long id of target contains the long id of tReorderControl then
         DG2_ReorderStart
         exit to top
      end if
   else
      -- Only track swipes if all previous swipe actions have completed - i.e.
      -- there are no animations pending. This prevents situations like where a
      -- user drags in one direction, but an animation is returning the row in
      -- the oposite direction.
      if the dgProps["enable swipe"] of the dgControl of me and DG2_AnimationsGetPendingCount() is 0 then
         local tStartDrag
         put false into tStartDrag

         -- Layer the swipe controls behind the current row so that they reveal
         -- on swiping. Don't postion at this point as the left and right
         -- controls might be the same object.
         local tSwipeControl
         put DG2_CustomisableControlsGetLeftSwipeControlForControl(the long id of me) into tSwipeControl
         if tSwipeControl is not empty then
            relayer tSwipeControl before me
            put true into tStartDrag
         end if
         put DG2_CustomisableControlsGetRightSwipeControlForControl(the long id of me) into tSwipeControl
         if tSwipeControl is not empty then
            relayer tSwipeControl before me
            put true into tStartDrag
         end if

         if tStartDrag then
            -- We store the start position in sSwipeStart to use as an offset
            -- when repositioning the row control under the pointer on drag.
            put item 1 of the mouseLoc into sDragStart
            put the milliseconds && item 1 of the mouseLoc into sDragLocs
            put true into sPreDragging
            put false into sDragging
         end if

      end if
   end if

   pass mouseDown
end mouseDown

before mouseMove pNewMouseH, pNewMouseV
   -- This prevents execution when editing the template stack
   if the dgControl of me is empty then
      pass mouseMove
   end if

   if not the dgEditMode of the dgControl of me then
      -- If the user has just clicked (i.e. pre-dragging), attempt to determine
      -- if the user is trying to drag the row. We do this by checking if the
      -- horizontal position of the drag has changed sufficiently within a given
      -- time frame. If so, we can turn the scroller off to prevent any
      -- interference and begin tracking the drag.
      if sPreDragging then
         if abs(word 2 of the last line of sDragLocs - pNewMouseH) > kPreDragLocDiff then
            put false into sPreDragging
            put true into sDragging
            __DisableMobileScroller
         else if the milliseconds - word 1 of the last line of sDragLocs > kPreDragTimeMargin then
            put false into sPreDragging
         else
            put the milliseconds && pNewMouseH & return before sDragLocs
         end if
      end if

      if sDragging then
         put the milliseconds && pNewMouseH & return before sDragLocs

         -- Calculate the virtual left and right of the control if it were to
         -- track the mouse's new horizontal position.
         local tLeft, tRight
         put sControlLeft - (sDragStart - pNewMouseH) into tLeft
         put tLeft + the width of me into tRight

         -- If as a result of the new mouse position the row will move to
         -- the right of its original location, check to see if there is a left
         -- swipe control which we can reveal. If so, move the row and reveal
         -- the left swipe contol.
         -- Do the same for drags to the left.
         local tSwipeControl
         if tRight > sControlRight then
            put DG2_CustomisableControlsGetLeftSwipeControlForControl(the long id of me) into tSwipeControl
            if tSwipeControl is not empty then
               lock screen
               set the visible of tSwipeControl to true
               set the rect of tSwipeControl to sControlLeft, the top of me, sControlLeft + the width of tSwipeControl, the bottom of me
               set the left of me to min(tLeft, the right of tSwipeControl)
               unlock screen
            end if
         else if tLeft < sControlLeft then
            put DG2_CustomisableControlsGetRightSwipeControlForControl(the long id of me) into tSwipeControl
            if tSwipeControl is not empty then
               lock screen
               set the visible of tSwipeControl to true
               set the rect of tSwipeControl to sControlRight - the width of tSwipeControl, the top of me, sControlRight, the bottom of me
               set the right of me to max(tRight, the left of tSwipeControl)
               unlock screen
            end if
         end if
      end if
   end if

   pass mouseMove
end mouseMove

before mouseUp
   -- This prevents execution when editing the template control
   if the dgControl of me is empty then
      pass mouseUp
   end if

   if the dgEditMode of the dgControl of me then
      DG2_ReorderEnd

      -- If the action select control has been clicked, tell the user (by
      -- sending the appropriate message) and exit to top to prevent any further
      -- interaction.
      local tActionSelectControl
      put DG2_CustomisableControlsGetEditModeActionSelectControlForControl(the long id of me) into tActionSelectControl
      if tActionSelectControl is not empty then
         if the long id of the target contains the long id of tActionSelectControl then
            dispatch DG2_GetMessageNameForTag("EditModeActionSelectControlClicked") to me with the target
            exit to top
         end if
      end if
   else
      put false into sPreDragging
      if sDragging then
         DG2_DragFinished
      end if
   end if

   pass mouseUp
end mouseUp

before mouseRelease
   -- This prevents execution when editing the template control
   if the dgControl of me is empty then
      pass mouseRelease
   end if

   if the dgEditMode of the dgControl of me then
      DG2_ReorderEnd
   else
      put false into sPreDragging
      if sDragging then
         DG2_DragFinished
      end if
   end if

   pass mouseRelease
end mouseRelease

----------------------------------------------------------------------

before LayoutControl pControlRect, pWorkingRect
   local tActionSelectControl, tReorderControl
   put DG2_CustomisableControlsGetEditModeActionSelectControlForControl(the long id of me) into tActionSelectControl
   put DG2_CustomisableControlsGetEditModeReorderControlForControl(the long id of me) into tReorderControl

   -- If we're in edit mode, position the edit mode controls appropriately.
   -- The action select control on the left, reorder on the right.
   if the dgEditMode of the dgControl of me then
      if tActionSelectControl is not empty then
         set the visible tActionSelectControl to true
         set the topLeft of tActionSelectControl to item 1 of pControlRect, item 2 of pControlRect + (item 4 of pControlRect - item 2 of pControlRect - the height of tActionSelectControl) / 2
      end if

      if tReorderControl is not empty then
         -- We can't rely on the right of the control rect to be the right of
         -- the list group: When animating out of edit mode, the control rect
         -- can be extended to the right to make room for the animation. So,
         -- use the right of the list group to postion the reorder control.
         set the visible of tReorderControl to true
         set the topRight of tReorderControl to min(item 3 of pControlRect, the right of group "dgList" of the dgControl of me), item 2 of pControlRect + (item 4 of pControlRect - item 2 of pControlRect - the height of tReorderControl) / 2
      end if
   else
      if tActionSelectControl is not empty then
         set the visible tActionSelectControl to false
      end if
      if tReorderControl is not empty then
         set the visible of tReorderControl to false
      end if
   end if
end LayoutControl

after LayoutControl pControlRect, pWorkingRect
   put the left of me into sControlLeft
   put the right of me into sControlRight
end LayoutControl

----------------------------------------------------------------------

private command DG2_DragFinished
   __EnableMobileScroller
   
   -- first check if we are already there
   get word 2 of the last line of sDragLocs
   local tLocDiff
   local tSwipeControl
   
   put item 1 of the mouseLoc - it into tLocDiff
   if tLocDiff > 0 then
      put DG2_CustomisableControlsGetLeftSwipeControlForControl(the long id of me) into tSwipeControl
      if tSwipeControl is not empty and \
            the left of me is the right of tSwipeControl then
         put false into sPreDragging
         put false into sDragging
         put empty into sDragLocs
         RowSwipeShowControlForIndexAndSide the dgIndex of me, "left"
         return the result
      end if
   else if tLocDiff < 0 then
      put DG2_CustomisableControlsGetRightSwipeControlForControl(the long id of me) into tSwipeControl
      if tSwipeControl is not empty and \
            the right of me is the left of tSwipeControl then
         put false into sPreDragging
         put false into sDragging
         put empty into sDragLocs
         RowSwipeShowControlForIndexAndSide the dgIndex of me, "right"
         return the result
      end if
   end if
   
   local tNow
   put the milliseconds into tNow

   -- Parse the list of swipe locations to find out where we were
   -- kSwipeTimeDiff milliseconds ago (or as close as we have to
   -- kSwipeTimeDiff milliseconds ago).
   local tPrevDragLoc, tMatchedLoc
   repeat for each line tDragLoc in sDragLocs
      local tTimeDiff
      put tNow - word 1 of tDragLoc into tTimeDiff

      if tTimeDiff >= kSwipeTimeDiff then
         -- We've found a location that occured after kSwipeTimeDiff.
         -- Chose the location which occured closet in time to kSwipeTimeDiff
         -- milliseconds ago; the current location or the last location in
         -- the list
         if tPrevDragLoc is empty or tTimeDiff < (tNow - word 1 of tPrevDragLoc) then
            get tDragLoc
         else
            get tPrevDragLoc
         end if

         -- Make sure the location we have chosen occurred within a
         -- reasonable margin of kSwipeTimeDiff.
         if abs(kSwipeTimeDiff - (tNow - word 1 of it)) <= kSwipeTimeDiffMargin then
            put word 2 of it into tMatchedLoc
         end if

         exit repeat
      end if

      put tDragLoc into tPrevDragLoc
   end repeat
   
   put item 1 of the mouseLoc - tMatchedLoc into tLocDiff
   if tMatchedLoc is not empty and abs(tLocDiff) > kSwipeLocDiff then
      -- The mouse has moved sufficiently to instantiate a swipe.
      -- Determine the direction of the swipe and make sure we are
      -- currently showing the appropriate control for that swipe direcion.
      if tLocDiff > 0 and the left of me > sControlLeft then
         put false into sPreDragging
         put false into sDragging
         put empty into sDragLocs
            RowSwipeShowControlForIndexAndSide the dgIndex of me, "left"
            return the result
      else if tLocDiff < 0 and the right of me < sControlRight then
         put false into sPreDragging
         put false into sDragging
         put empty into sDragLocs
            RowSwipeShowControlForIndexAndSide the dgIndex of me, "right"
            return the result
      end if
   end if

   -- If we've reached this point, no swipe has been detected, so return
   -- everything to as it were before dragging.
   DG2_SwipeReturn
   return the result
end DG2_DragFinished

command DG2_SwipeReturn pDontAnimate
   -- Return everything back to where it was before the dragging started.
   put false into sPreDragging
   put false into sDragging
   put empty into sDragLocs
   if  pDontAnimate then
      set the left of me to sControlLeft
      DG2_SwipeReturnComplete
      return the result
   else
      DG2_AnimationsAdd the long id of me, "left", the left of me, sControlLeft, the dgAnimationProp["SwipeReturnDuration"] of the dgControl of me, the dgAnimationProp["SwipeReturnEasing"] of the dgControl of me, "DG2_SwipeReturnComplete"
      return empty
   end if
end DG2_SwipeReturn

on DG2_SwipeReturnComplete
   local tSwipeControl
   put DG2_CustomisableControlsGetLeftSwipeControlForControl(the long id of me) into tSwipeControl
   if tSwipeControl is not empty then
      set the visible of tSwipeControl to false
   end if
   put DG2_CustomisableControlsGetRightSwipeControlForControl(the long id of me) into tSwipeControl
   if tSwipeControl is not empty then
      set the visible of tSwipeControl to false
   end if

   return empty
end DG2_SwipeReturnComplete
