script "revIDEExtensionManagerStoreBehavior"
local sBrowserID, sFinishedLoading, sShowBrowser

on preOpenCard
   browserShow
   send "resizeStack" to me
   setStatus "Loading LiveCode extensions store"
   set the repeatcount of image "loading" to -1
end preOpenCard

on openCard
   hiliteFrameItem "search"
end openCard

on closeCard
   browserHide
end closeCard

on closeStack
   browserClose
end closeStack

on setStatus pStatus
   put pStatus into field "status" of me
end setStatus

on resizeStack
   lock screen
   local tContentRect, tPadding
   put the contentrect of me into tContentRect
   put the palettePadding of me into tPadding
   
   set the rect of graphic "browser_background" of me to tContentRect
   set the width of field "status" of me to the width of me
   set the loc of field "status" of me to the loc of me
   set the loc of image "loading" of me to the loc of me
   set the bottom of image "loading" of me to the top of field "status" of me - tPadding
   
   set the loc of image "loading_header" to 100,(item 2 of tContentRect / 2 )
   if there is a field "preferences" then
      set the right of image "loading_header" to the left of field "preferences" -10
   else
      set the right of image "loading_header" to the width of me - 30
   end if
   
   try
      if sFinishedLoading is true and sShowBrowser is true then
         revBrowserSet sBrowserID, "rect", the rect of graphic "browser_background" of me
      end if
   catch tError
   end try
   unlock screen
   pass resizeStack
end resizeStack

on browserStart
   lock screen
   if (sBrowserID is not empty) AND sBrowserID is among the lines of revBrowserInstances() then exit browserStart
   
   put false into sFinishedLoading
   put revBrowserOpenCEF(the windowId of this stack, revIDEWebPageURL("extensions")) into sBrowserID
   if sBrowserID is not an integer then
      answer "Failed to open browser"
      exit browserStart
   end if
   
   browserHide
   
   revBrowserSet sBrowserID, "useragent", "LiveCode"
   
   unlock screen
end browserStart

on browserBeforeNavigate
   set the repeatcount of image "loading_header" to -1
   show image "loading_header"
end browserBeforeNavigate

on browserNavigateComplete
   revBrowserAddJavaScriptHandler sBrowserID,"installExtension"
   set the repeatcount of image "loading_header" to 0
   hide image "loading_header"
end browserNavigateComplete

on browserClose
    if sBrowserID is empty then exit browserClose
   try
      revBrowserClose sBrowserID
   catch tError
   end try
end browserClose

on browserHide
   put false into sShowBrowser
   if sBrowserID is empty then exit browserHide
   try
      revBrowserSet sBrowserID, "rect", "-400,-400,0,0"
   catch tError
   end try
end browserHide

on browserDocumentComplete pURL
   put true into sFinishedLoading
   
   if the short name of this card is "search" then
      resizeStack
   end if
end browserDocumentComplete

on browserDocumentFailed pURL
   browserSetURL revIDEWebPageURL("extensions")
end browserDocumentFailed

on browserShow
   put true into sShowBrowser
   if sFinishedLoading is false then exit browserShow
   if sBrowserID is empty then exit browserShow
   try
      revBrowserSet sBrowserID, "rect", the contentrect of me
      dispatch "resizeStack"
   catch tError
   end try
end browserShow

on browserSetURL pURL
   lock screen
   put true into sShowBrowser
   put false into sFinishedLoading
   revBrowserSet sBrowserID, "url", pURL
   dispatch "resizeStack"
   unlock screen
end browserSetURL

on browserGoToExtensionPage pExtenstionTypeID
   lock screen
   browserSetURL revIDEWebPageURL("extensions") & pExtenstionTypeID & slash
   go card 2 of this stack
   unlock screen
end browserGoToExtensionPage


