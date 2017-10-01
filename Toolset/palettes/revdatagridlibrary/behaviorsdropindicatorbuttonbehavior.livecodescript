script "RevDataGridLibraryBehaviorsDropIndicatorButtonBehavior"
--> all handlers

on resizeControl
    if the target is not me then pass resizeControl
    
    put the rect of group "dgListMask" of the dgControl of me into theParentRect
    set the topLeft of me to item 1 to 2 of theParentRect
    
    put the rect of graphic 2 of me into theRect
    put item 3 of theParentRect + 1 into item 3 of theRect ## +1 is because lines don't really fill up entire rect
    set the rect of graphic 2 of me to theRect
end resizeControl
