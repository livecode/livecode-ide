script "RevDataGridLibraryBehaviorsSwipeControlHolderBehavior"
----------------------------------------------------------------------
-- This behavior is applied to a group used to house fully visible swipe
-- controls for a give row and side, dealing with animating the control in an
-- out as well as catching any clicks. (Partially visible - i.e. during a row
-- drag left/right action - are handled in the row's chained behavior). When
-- fully visible, a swipe control takes over the full DataGrid, using the holder
-- group as message catcher, with all clicks in th DataGrid either hiding the
-- swipe control or performing the swipe control click action.

local sRowIndex
local sSwipeControlSide
local sSwipeControl
local sSwipeControlOwner

setProp dgSwipeControlSide pSide
   put pSide into sSwipeControlSide
end dgSwipeControlSide

getProp dgSwipeControlSide
   return sSwipeControlSide
end dgSwipeControlSide

-- Animate in the swipe control for the given row index using from the
-- previously specified side.
-- Setting to empty will animate out any visible swipe control.
setProp dgSwipeControlRowIndex pIndex
   if pIndex is not empty then
      local tRowControl
      put the dgDataControlOfIndex[pIndex] of the dgControl of me into tRowControl
      if tRowControl is empty then
         return "Could not find row control"
      end if

      switch sSwipeControlSide
         case "left"
            get DG2_CustomisableControlsGetLeftSwipeControlForControl(the long id of tRowControl)
            break
         case "right"
            get DG2_CustomisableControlsGetRightSwipeControlForControl(the long id of tRowControl)
            break
         default
            return "Unknown swipe side" && sSwipeControlSide
      end switch
      if it is empty then
         return "Could not find swipe control"
      end if

      put it into sSwipeControl
      put pIndex into sRowIndex
      put the owner of sSwipeControl into sSwipeControlOwner

      lock screen
      set the rect of me to the rect of group "dgList" of the dgControl of me
      set the rect of graphic "Message Catcher" of me to the rect of me
      set the visible of me to true
      unlock screen

      DG2_SwipeControlShow
      return the result
   else
      local tResult
      DG2_SwipeControlHide
      put empty into sRowIndex
      return tResult
   end if
end dgSwipeControlRowIndex

getProp dgSwipeControlRowIndex
   return sRowIndex
end dgSwipeControlRowIndex

-- A scroll or resize has occurred. Reposition the group inside the the list,
-- the swipe control next to the appropriate row and the row to the left or
-- right of the swipe control.
command DG2_SwipeControlHolderReposition
   if not the visible of me then
      return empty
   end if
   if sRowIndex is empty then
      return empty
   end if
   if sSwipeControl is empty then
      return empty
   end if

   local tRowControl
   put the dgDataControlOfIndex[sRowIndex] of the dgControl of me into tRowControl
   if tRowControl is empty then
      set the visible of sSwipeControl to false
      return empty
   end if

   lock screen
   set the visible of sSwipeControl to true
   set the rect of me to the rect of group "dgList" of the dgControl of me
   set the rect of graphic "Message Catcher" of me to the rect of me
   set the top of sSwipeControl to the top of tRowControl
   switch sSwipeControlSide
      case "left"
         set the left of tRowControl to the right of sSwipeControl
         break
      case "right"
         set the right of tRowControl to the left of sSwipeControl
         break
   end switch
   unlock screen

   return empty
end DG2_SwipeControlHolderReposition

private command DG2_SwipeControlShow
   local tRowControl
   put the dgDataControlOfIndex[sRowIndex] of the dgControl of me into tRowControl
   if tRowControl is empty then
      return "Could not find row control"
   end if

   -- A swipe has been occured so tell the user by sending the
   -- appropriate message. If the user handles the message then we
   -- can assume they are dealing with the action and on't need to do
   -- anything more. If it's not handled, then fully animate in the
   -- swipe control.
   switch sSwipeControlSide
      case "left"
         dispatch DG2_GetMessageNameForTag("RowSwipedRight") to tRowControl
         if it is not "handled" then
         DG2_AnimationsAdd the long id of tRowControl, "left", the left of tRowControl, the right of sSwipeControl, the dgAnimationProp["SwipeCompleteDuration"] of the dgControl of me, the dgAnimationProp["SwipeCompleteEasing"] of the dgControl of me, "DG2_SwipeControlShowComplete", empty, the long id of me
         end if
         break
      case "right"
         dispatch DG2_GetMessageNameForTag("RowSwipedLeft") to tRowControl
         if it is not "handled" then
         DG2_AnimationsAdd the long id of tRowControl, "right", the right of tRowControl, the left of sSwipeControl, the dgAnimationProp["SwipeCompleteDuration"] of the dgControl of me, the dgAnimationProp["SwipeCompleteEasing"] of the dgControl of me, "DG2_SwipeControlShowComplete", empty, the long id of me
         end if
         break
   end switch

   return empty
end DG2_SwipeControlShow

on DG2_SwipeControlShowComplete
   -- When the animation is complete, the swipe control should be fully visible.
   -- This means we can now bring it to the front of the DataGrid allowing it or
   -- the holder group to catch all messages.
   lock screen
   relayer me to front of owner
   relayer sSwipeControl to front of me
   unlock screen

   return empty
end DG2_SwipeControlShowComplete

private command DG2_SwipeControlHide
   local tRowControl
   put the dgDataControlOfIndex[sRowIndex] of the dgControl of me into tRowControl
   if tRowControl is empty then
      return "Could not find row control"
   end if

   local tIsVisible
   put the visible of me into tIsVisible

   lock screen
   relayer sSwipeControl before tRowControl
   set the visible of me to false
   unlock screen

   -- The row script takes care of returning the swipe control.
   -- If we're not visible then tell the row control not to bother animating the
   -- return.
   dispatch "DG2_SwipeReturn" to tRowControl with not tIsVisible
   return the result
end DG2_SwipeControlHide

on DG2_SwipeControlHideComplete
   local tRowControl
   put the dgDataControlOfIndex[sRowIndex] of the dgControl of me into tRowControl
   if tRowControl is not empty then
      set the left of tRowControl to the left of group "dgList" of the dgControl of me
   end if

   if sSwipeControl is not empty then
      set the visible of sSwipeControl to false
      relayer sSwipeControl to back of sSwipeControlOwner
   end if

   return empty
end DG2_SwipeControlHideComplete

on mouseUp
   local tRowControl
   put the dgDataControlOfIndex[sRowIndex] of the dgControl of me into tRowControl
   if tRowControl is empty then
      exit mouseUp
   end if

   if the long id of the target contains the long id of sSwipeControl then
      switch sSwipeControlSide
         case "left"
            dispatch DG2_GetMessageNameForTag("RowLeftSwipeControlClicked") to tRowControl
            break
         case "right"
            dispatch DG2_GetMessageNameForTag("RowRightSwipeControlClicked") to tRowControl
            break
      end switch
   else
      DG2_SwipeControlHide
      switch sSwipeControlSide
         case "left"
            dispatch DG2_GetMessageNameForTag("RowLeftSwipeControlHidden") to tRowControl
            break
         case "right"
            dispatch DG2_GetMessageNameForTag("RowRightSwipeControlHidden") to tRowControl
            break
      end switch
   end if
end mouseUp
