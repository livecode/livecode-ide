script "RevDataGridLibraryBehaviorsDefaultHeaderButtonBehavior"
--> all handlers


on LayoutControl pControlRect
    -- Position all of the controls within the header
    put the loc of me into theLoc
    set the margins of field 1 of me to the dgProps["header margins"] of the dgControl of me
    set the rect of graphic "Background" of me to pControlRect
    set the rect of field 1 of me to pControlRect
    set the left of graphic "LeftHilite" of me to item 1 of pControlRect
    set the right of graphic "RightHilite" of me to item 3 of pControlRect
    
    -- Position field and sort arrow
    put the width of button "SortArrow" of me into theArrowWidth
    set the loc of button "SortArrow" of me to item 3 of pControlRect - (round(theArrowWidth / 2) + 5), item 2 of the loc of me 
    add 5 to theArrowWidth
    if the textAlign of field 1 of me is "center" then
        set the rect of field 1 of me to item 1 of pControlRect, item 2 of pControlRect, \
                item 1 of pControlRect + ( (item 3 of pControlRect - item 1 of pControlRect) - (theArrowWidth * 2) ), \
                item 4 of pControlRect
        set the loc of field 1 of me to theLoc 
    else
        if the visible of button "SortArrow" of me then
            set the rect of field 1 of me to item 1 of pControlRect, item 2 of pControlRect, \
                    item 1 of pControlRect + ( (item 3 of pControlRect - item 1 of pControlRect) - theArrowWidth ), \
                    item 4 of pControlRect
        else
            set the rect of field 1 of me to item 1 of pControlRect, item 2 of pControlRect, \
                    item 1 of pControlRect + ( (item 3 of pControlRect - item 1 of pControlRect) ), \
                    item 4 of pControlRect
        end if
    end if
end LayoutControl


setprop dgHilite pBoolean
    set the visible of button "SortArrow" of me to pBoolean
    set the visible of graphic "Background" of me to pBoolean
    if pBoolean then
        if the dgColumnSortDirection[the short name of me] of the dgControl of me is "ascending" then
            ## Ascending
            set the icon of button "SortArrow" of me to the dgProps["ascending sort icon"] of the dgControl of me
        else
            ## Descending
            set the icon of button "SortArrow" of me to the dgProps["descending sort icon"] of the dgControl of me
        end if
    end if
end dgHilite


getprop dgColumn
    return the short name of me
end dgColumn


getprop dgHeaderControl
    return the long ID of me
end dgHeaderControl


setprop dgLabel [pEncoding] pValue
   switch pEncoding ## Added in 1.0.2 build 11
      case "mac"
         if the platform is not "macos" then
            put mactoiso(pValue) into pValue
         end if
         break
      case "iso"
         if the platform is "macos" then
            put isotomac(pValue) into pValue
         end if
         break
      default
   end switch
   
   set the text of field 1 of me to pValue
end dgLabel


setprop dgTooltip pValue
    set the toolTip of field 1 of me to pValue
end dgTooltip


setprop dgAlignment pValue
    set the textAlign of field 1 of me to pValue
end dgAlignment


-- on mouseDown pMouseBtnNum
    -- ## _HeaderMouseDown resides in parent group script. It will return true if click triggers a column resize.
    -- ## Otherwise it returns false.
    -- _HeaderMouseDown pMouseBtnNum
    
    -- pass mouseDown
-- end mouseDown


on mouseUp pMouseBtnNum
    if pMouseBtnNum is 1 and not the dgHeaderColumnIsBeingResized of the dgHeader of me then
        ## Change the sort of the column
        ## _HeaderToggleSortOfColumn is a helper that resizes in the parent group script.
        ## It toggles the sort of the column based on current state of column.
        _HeaderToggleSortOfColumn the dgColumn of me
    end if
    
    pass mouseUp
end mouseUp
