script "RevDataGridLibraryBehaviorsActionControlHolderBehavior"
----------------------------------------------------------------------
-- This behavior is applied to a group used to house the action control for a
-- given row. It takes care of animating the action control in and out as well
-- as handling any actions when visible: When visible, the action control takes
-- over the full DataGrid, with all clicks either resulting in the action
-- control being hidden or the action control action being applied. The
-- behaviors's group acts as a message catcher, spanning the whole DataGrid.

local sRowIndex
local sActionControl
local sActionControlOwner

-- Animate in the action control for the row with the given index.
-- Setting to empty will animate out any visible action control.
setProp dgActionControlRowIndex pIndex
   if pIndex is not empty then
      local tRowControl
      put the dgDataControlOfIndex[pIndex] of the dgControl of me into tRowControl
      if tRowControl is empty then
         return "Could not find row control"
      end if

      get DG2_CustomisableControlsGetEditModeActionControlForControl(the long id of tRowControl)
      if it is empty then
         return "Could not find action control"
      end if

      put it into sActionControl
      put pIndex into sRowIndex
      put the owner of sActionControl into sActionControlOwner

      lock screen
      set the rect of me to the rect of group "dgList" of the dgControl of me
      set the rect of graphic "Message Catcher" of me to the rect of me
      set the visible of me to true
      unlock screen

      DG2_EditModeActionControlShow
      return the result
   else
      local tResult
      DG2_EditModeActionControlHide
      put the result into tResult
      put empty into sRowIndex
      return the result
   end if
end dgActionControlRowIndex

getProp dgActionControlRowIndex
   return sRowIndex
end dgActionControlRowIndex

-- A scroll or resize has occurred. Reposition the group inside the the list,
-- the action control next to the appropriate row and the row to the left of
-- the action control.
command DG2_EditModeActionControlHolderReposition
   if not the visible of me then
      return empty
   end if
   if sRowIndex is empty then
      return empty
   end if
   if sActionControl is empty then
      return empty
   end if

   local tRowControl
   put the dgDataControlOfIndex[sRowIndex] of the dgControl of me into tRowControl
   if tRowControl is empty then
      set the visible of sActionControl to false
      return empty
   end if

   lock screen
   set the visible of sActionControl to true
   set the rect of me to the rect of group "dgList" of the dgControl of me
   set the rect of graphic "Message Catcher" of me to the rect of me
   set the top of sActionControl to the top of tRowControl
   set the right of tRowControl to the left of sActionControl
   unlock screen

   return empty
end DG2_EditModeActionControlHolderReposition

private command DG2_EditModeActionControlShow
   local tRowControl
   put the dgDataControlOfIndex[sRowIndex] of the dgControl of me into tRowControl
   if tRowControl is empty then
      return "Could not find row control"
   end if

   -- We relayer the action control behind the row so that it is revealed as the
   -- row animates left.
   lock screen
   relayer sActionControl before tRowControl
   set the rect of sActionControl to the right of tRowControl - the width of sActionControl, the top of tRowControl, the right of tRowControl, the bottom of tRowControl
   set the visible of sActionControl to true
   unlock screen

   DG2_AnimationsAdd the long id of tRowControl, "left", the left of tRowControl, the left of tRowControl - the width of sActionControl, the dgAnimationProp["EditModeActionControlAnimationDuration"] of the dgControl of me, the dgAnimationProp["EditModeActionControlAnimationEasing"] of the dgControl of me, "DG2_EditModeActionControlShowComplete", empty, the long id of me

   return empty
end DG2_EditModeActionControlShow

on DG2_EditModeActionControlShowComplete
   -- When the animation is complete, the action control should be fully visible.
   -- This means we can now bring it to the front of the DataGrid allowing it or
   -- the holder group to catch all messages.
   lock screen
   relayer me to front of owner
   relayer sActionControl to front of me
   unlock screen

   return empty
end DG2_EditModeActionControlShowComplete

private command DG2_EditModeActionControlHide
   local tRowControl
   put the dgDataControlOfIndex[sRowIndex] of the dgControl of me into tRowControl
   if tRowControl is empty then
      return "Could not find row control"
   end if

   if the visible of me then
      -- Put the action control back behind the row control so that it is hidden
      -- as the row animates right.
      lock screen
      relayer sActionControl before tRowControl
      set the visible of me to false
      unlock screen

      DG2_AnimationsAdd the long id of tRowControl, "left", the left of tRowControl, the left of tRowControl + the width of sActionControl, the dgAnimationProp["EditModeActionControlAnimationDuration"] of the dgControl of me, the dgAnimationProp["EditModeActionControlAnimationEasing"] of the dgControl of me, "DG2_EditModeActionControlHideComplete", empty, the long id of me
   else
      -- If we're not visible, don't bother with any animating.
      set the left of tRowControl to the left of group "dgList" of the dgControl of me
      DG2_EditModeActionControlHideComplete
   end if

   return empty
end DG2_EditModeActionControlHide

on DG2_EditModeActionControlHideComplete
   -- Return the action control to where it was before being added to the group.
   if sActionControl is not empty then
      lock screen
      set the visible of sActionControl to false
      relayer sActionControl to back of sActionControlOwner
      unlock screen
   end if

   return empty
end DG2_EditModeActionControlHideComplete

on mouseUp
   local tRowControl
   put the dgDataControlOfIndex[sRowIndex] of the dgControl of me into tRowControl
   if tRowControl is empty then
      exit mouseUp
   end if

   if the long id of the target contains the long id of sActionControl then
      dispatch DG2_GetMessageNameForTag("EditModeActionControlClicked") to tRowControl with the target
   else
      DG2_EditModeActionControlHide
      dispatch DG2_GetMessageNameForTag("EditModeActionControlHidden") to tRowControl
   end if
end mouseUp
