script "revIDESnippetViewerBehavior"
command setAsBehavior pTarget
   set the behavior of pTarget to the long id of this me
end setAsBehavior

command revIDESnippetViewerColor
    dispatch "revSEColorizeField" to stack "revSEUtilities" \
          with the long id of field "Snippet" of me
end revIDESnippetViewerColor
 
private function _GetSnippetText
    return the text of field "Snippet" of me
end _GetSnippetText
 
command revIDESnippetViewerSetSnippet pText
    put pText into field "Snippet" of me
    revIDESnippetViewerColor
end revIDESnippetViewerSetSnippet

constant kMargin = 5
command revIDESnippetViewerResize
    local tCopyToClipboard, tCopyToSE, tSnippet
    put the long id of button "Copy to clipboard" of me \
          into tCopyToClipboard
    put the long id of button "Copy to Script Editor" of me \
          into tCopyToSE
    put the long id of field "Snippet" of me into tSnippet
    
    local tCardRect
    put the rect of card 1 of me into tCardRect
    
    local tFieldWidth
    put item 3 of tCardRect - item 1 of tCardRect - 2*kMargin into tFieldWidth
    
    local tButtonWidth
    put (tFieldWidth - kMargin) / 2 into tButtonWidth
    
    set the width of tCopyToClipboard to tButtonWidth
    set the width of tCopyToSE to tButtonWidth
    
    set the bottomleft of tCopyToClipboard to \
          item 1 of tCardRect + kMargin, \
          item 4 of tCardRect - kMargin
    
    set the bottomright of tCopyToSE to \
          item 3 of tCardRect - kMargin, \
          item 4 of tCardRect - kMargin
    
    set the rect of tSnippet to \
          item 1 of tCardRect + kMargin, \
          item 2 of tCardRect + kMargin, \
          item 3 of tCardRect - kMargin, \
          the top of tCopyToSE - kMargin
    unlock screen
end revIDESnippetViewerResize

command revIDESnippetViewerCopyToClipboard
    lock clipboard
    set the rawClipboardData["text"] to _GetSnippetText()
    unlock clipboard
end revIDESnippetViewerCopyToClipboard

command revIDESnippetViewerCopyToScriptEditor pEditor
    local tNewScript
    dispatch function "revSEGetScript" to stack pEditor
    put the result into tNewScript
    
    if tNewScript is not empty then
        if the last line of tNewScript is not empty then
            put return after tNewScript
        end if
        put return after tNewScript
    end if
    put _GetSnippetText() after tNewScript
    dispatch "revSESetScript" to stack pEditor with tNewScript
end revIDESnippetViewerCopyToScriptEditor

on mouseUp
    switch the short name of the target
        case "Copy to clipboard"
            revIDESnippetViewerCopyToClipboard
            break
        case "Copy to Script Editor"
            local tScriptEditors
            put revListScriptEditors() into tScriptEditors
            if tScriptEditors is empty then
                answer error "No script editor window to copy snippet to"
            else
                revIDESnippetViewerCopyToScriptEditor line 1 of tScriptEditors
            end if
            break
    end switch
end mouseUp
