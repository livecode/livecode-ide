script "RevDataGridLibraryBehaviorsDefaultColumnButtonBehavior"
--> all handlers

on FillInData pData
    -- This message is sent when the Data Grid needs to populate
    -- this template with the column data. pData is the value to be displayed.
    set the text of the long ID of me to pData ## temp workaround for
end FillInData


on LayoutControl pControlRect
    -- A default column is just a field. Nothing to change here.
end LayoutControl


on ResetData
    -- Sent when column data is being emptied because the control is no longer being used to display data
    set the text me to empty
end ResetData


on PreFillInData
    -- Sent right before new data is going to replace existing data in the column
end PreFillInData


setprop dgHilite pBoolean
    -- This custom property is set when the highlight of your column template has
    -- changed. You only add script here if you want to customize the highlight.
    if pBoolean then
        set the foregroundColor of me to the dgProp["hilited text color"] of the dgControl of me
    else
        set the foregroundColor of me to empty
    end if
end dgHilite


getprop dgDataControl
    -- Required by library so that it can locate the control.
    return the long ID of me
end dgDataControl


-- Data grid will call this if a user action asks to edit cell content.
command EditValue
    EditFieldText the long ID of me, the dgIndex of me, the dgColumn of me
end EditValue


on mouseDoubleUp pMouseBtnNum
    if pMouseBtnNum is 1 then
        if the dgProps["allow editing"] of the dgControl of me \
                and the dgColumnIsEditable[the dgColumn of me] of the dgControl of me then
            -- Edit field contents if the user double-clicks
            EditCellOfIndex the dgColumn of me, the dgIndex of me
            exit mouseDoubleUp
        end if
    end if
    pass mouseDoubleUp
end mouseDoubleUp
