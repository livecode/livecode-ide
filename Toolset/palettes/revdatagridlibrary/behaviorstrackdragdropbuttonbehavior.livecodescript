script "RevDataGridLibraryBehaviorsTrackDragDropButtonBehavior"
--> all handlers

local sDataGridA

setprop dgTargetControl pValue
    put pValue into sDataGridA[the dgControl of the target]
    -- put pValue into sDataGrid
end dgTargetControl


on dragDrop
    send "dgDragDrop" to sDataGridA[the dgControl of the target]
    pass dragDrop
end dragDrop


on dragEnd
    send "dgDragEnd" to sDataGridA[the dgControl of the target]
    pass dragEnd
end dragEnd


on dragMove pMouseH,pMouseV
    send "dgDragMove pMouseH, pMouseV" to sDataGridA[the dgControl of the target]
    pass dragMove
end dragMove
