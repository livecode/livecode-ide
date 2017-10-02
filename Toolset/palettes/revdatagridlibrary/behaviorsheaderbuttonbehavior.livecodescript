script "RevDataGridLibraryBehaviorsHeaderButtonBehavior"
--> all handlers

local sTargetColumn
local sResizing
local sClickHOffset
local sClickHOrigin
local sLastMouseH
local sRunningActions
local sTargetHeaderGroup


getprop dgHeader
   return the long id of me
end dgHeader


getprop dgHeaderColumnIsBeingResized
    return sResizing is true
end dgHeaderColumnIsBeingResized


on mouseMove pMouseH,pMouseV
   if sResizing then
      _UpdateCursor
      
      put empty into theError
      if sRunningActions["resizing column"] then exit mouseMove
      try
         put the dgColumnWidth[sTargetColumn] of the dgControl of me into theWidth
         put the dgColumnMinWidth[sTargetColumn] of the dgControl of me into theMinWidth
         put the dgColumnMaxWidth[sTargetColumn] of the dgControl of me into theMaxWidth
         put the rect of sTargetHeaderGroup into theMaskRect
         
         if theWidth is theMinWidth and pMouseH > item 3 of theMaskRect or \
                theWidth is theMaxWidth and pMouseH < item 3 of theMaskRect or \
                (theWidth is not theMinWidth and theWidth is not theMaxWidth) then
            put true into sRunningActions["resizing column"]
            if pMouseH > sLastMouseH then
               put abs(pMouseH - sLastMouseH) into theChange
            else
               put abs(pMouseH - sLastMouseH) * -1 into theChange
            end if
            
            add theChange to theWidth
            set the dgColumnWidth[sTargetColumn] of the dgControl of me to theWidth
         end if
      catch e
         put e into theError
         put false into sResizing
      end try
      
      put pMouseH into sLastMouseH
      
      put false into sRunningActions["resizing column"]
      if theError is not empty then
         throw theError
      end if
      
   else if the dgProp["allow column resizing"] of the dgControl of me then
      _SeeIfPointerIsOverDraggableRegion pMouseH, pMouseV
   end if
end mouseMove


on mouseLeave
   get the mouseloc
   put item 1 of it into theMouseH
   put item 2 of it into theMouseV
   
   ## Look for mouseLeaving header group
   if the dgProp["allow column resizing"] of the dgControl of me then
      send "_SeeIfPointerIsOverDraggableRegion theMouseH, theMouseV" to me in 0 seconds
   end if
end mouseLeave


command _SeeIfPointerIsOverDraggableRegion pMouseH, pMouseV
    put empty into sTargetColumn
    put 0 into theLeftColNum
    if the mousecontrol is not empty and pMouseH,pMouseV is within the rect of me then
        put the dgHeaderControl of the mousecontrol into theTarget
         
        if theTarget is not empty then
            put the dgControl of me into theDataGroup
            put the dgColumnNumber of the mousecontrol into theColNum
            put the dgProps["visible columns"] of theDataGroup into theColumns
            put the number of lines of theColumns into theColCount
             
            put the rect of theTarget into theRect
            if theColNum > 1 and pMouseH <= item 1 of theRect + 2 then
                ## resize previous column
                put theColNum - 1 into theLeftColNum
            else if theColNum <= theColCount and pMouseH >= item 3 of theRect - 4 then
                ## resize this column
                put theColNum into theLeftColNum
            end if
             
            if theLeftColNum > 0 then
                put line theLeftColNum of theColumns into sTargetColumn
            end if
            
            ## Determine if column is resizable
            if not the dgColumnIsResizable[sTargetColumn] of theDataGroup then put empty into sTargetColumn
             
            ## Update cursor
            if sTargetColumn is not empty then
                _UpdateCursor
                put _ColumnHeaderGroup(sTargetColumn) into sTargetHeaderGroup
            else
                set the defaultcursor to arrow
            end if
        else
            set the defaultcursor to arrow
        end if
    else
        set the defaultcursor to arrow
    end if
end _SeeIfPointerIsOverDraggableRegion


private command _UpdateCursor
    local theDataGroup
    local theWidth
    
    put the dgControl of me into theDataGroup
    put the dgColumnWidth[sTargetColumn] of theDataGroup into theWidth
    if the dgColumnMinWidth[sTargetColumn] of theDataGroup is theWidth then
        set the defaultcursor to 103002
    else if the dgColumnMaxWidth[sTargetColumn] of theDataGroup is theWidth then
        set the defaultcursor to 103003
    else
        set the defaultcursor to 103001
    end if
    return empty
end _UpdateCursor


command _HeaderToggleSortOfColumn pColumn
    put the dgColumnSortDirection[pColumn] of the dgControl of me into theDirection
    if the dgProps["sort by column"] of the dgControl of me is pColumn then
        if theDirection is "ascending" then put "descending" into theDirection
        else put "ascending" into theDirection
         
        set the dgColumnSortDirection[pColumn] of the dgControl of me to theDirection
    else
        set the dgProps["sort by column"] of the dgControl of me to pColumn
    end if
    
    return empty
end _HeaderToggleSortOfColumn


on mouseDown pMouseBtnNum
    _HeaderMouseDown pMouseBtnNum
    if not the result then pass mouseDown
end mouseDown


command _HeaderMouseDown pMouseBtnNum
    if pMouseBtnNum is 1 then
        if sTargetColumn is not empty then
            put the dgHeaderControl of the mousecontrol into theTarget
            put the rect of theTarget into theRect
            put the clickh into sClickHOrigin
            put sClickHOrigin into sLastMouseH
            if sClickHOrigin <= item 1 of theRect + 2 then
                put sClickHOrigin - item 1 of theRect into sClickHOffset
            else if sClickHOrigin >= item 3 of theRect - 4 then
                put sClickHOrigin - item 3 of theRect into sClickHOffset
            end if
            
            put true into sResizing
            return true
        end if
    end if    
    return false
end _HeaderMouseDown


on mouseUp pMouseBtnNum
    put false into sResizing
    set the defaultcursor to arrow
end mouseUp


on mouseRelease pMouseBtnNum
    put false into sResizing
    set the defaultcursor to arrow
end mouseRelease
