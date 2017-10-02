script "RevDataGridLibraryBehaviorsVerticalScrollbarButtonBehavior"
--> all handlers

on dragStart
    ## Scrollbars don't need to send dragStart messages
end dragStart


on mouseDown pBtnNum
    if pBtnNum is 1 then
        _UserStartedVScrolling
    end if
    pass mouseDown
end mouseDown


command mouseUp pBtnNum
    if pBtnNum is 1 then
        _UserStoppedVScrolling
    end if
    pass mouseUp
end mouseUp


command mouseRelease pBtnNum
    if pBtnNum is 1 then
        _UserStoppedVScrolling
    end if
    pass mouseRelease
end mouseRelease
