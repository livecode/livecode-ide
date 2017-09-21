script "RevDataGridLibraryBehaviorsFieldEditorButtonBehavior"
--> all handlers


on escapeKey
    send "DeleteFieldEditor false" to the dgControl of me in 0 seconds
end escapeKey


on closeField
    ## Don't delete editor within same message
    send "DeleteFieldEditor" to the dgControl of me in 0 seconds
end closeField


on exitField
    send "DeleteFieldEditor" to the dgControl of me in 0 seconds
end exitField


on returnInField
    if the autotab of me then
        send "DeleteFieldEditor" to the dgControl of me in 0 seconds
    else
        pass returnInField
    end if
end returnInField


on enterInField
    if the autotab of me then
        send "DeleteFieldEditor" to the dgControl of me in 0 seconds
    else
        pass enterInField
    end if
end enterInField


on tabKey
    if the autotab of me then
        send "DeleteFieldEditorAndOpenNext" to the dgControl of me in 0 seconds
    else
        pass tabkey
    end if
end tabKey


on selectionChanged
    ## don't pass as selectionChanged is reserved for group
    ## developer can override behavior to process selectionChanged
end selectionChanged
