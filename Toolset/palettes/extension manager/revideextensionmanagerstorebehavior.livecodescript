script "revIDEExtensionManagerStoreBehavior"
on preOpenCard
   send "resizeStack" to me
   browserHide
   setStatus "Loading LiveCode extensions store"
   set the repeatcount of image "loading" of me to -1
end preOpenCard

constant kLoadTimeout = 2
on openCard
   hiliteFrameItem "store"
   if the url of widget "browser" of me is empty then
      set the userAgent of widget "browser" of me to "LiveCode"
      browserGoToExtensionStore
   else
      nudgeBrowser
   end if
end openCard

on nudgeBrowser
   -- Hack to get round bug 18946
   send "browserNavigateComplete" to me in kLoadTimeout seconds
end nudgeBrowser

on setStatus pStatus
   put pStatus into field "status" of me
end setStatus

on resizeStack
   lock screen
   local tContentRect, tPadding
   put the contentrect of me into tContentRect
   put the palettePadding of me into tPadding
   set the width of field "status" of me to the width of me
   set the loc of field "status" of me to the loc of me
   set the loc of image "loading" of me to the loc of me
   set the bottom of image "loading" of me to the top of field "status" of me - tPadding
   
   set the rect of graphic "browser_background" of me to tContentRect
   set the rect of widget "browser" of me to tContentRect
   
   unlock screen
   pass resizeStack
end resizeStack

on browserHide
   hide widget "browser" of me
end browserHide

on browserShow
   show widget "browser" of me
end browserShow

on browserSetURL pURL
   lock screen
   set the url of widget "browser" of me to pURL
   nudgeBrowser
   unlock screen
end browserSetURL

on browserGoToExtensionPage pExtensionTypeID
   lock screen
   browserSetURL revIDEWebPageURL("extensions") & pExtensionTypeID & slash
   go card 2 of this stack
   unlock screen
end browserGoToExtensionPage

on browserGoToExtensionStore
   lock screen
   browserSetURL revIDEWebPageURL("extensions")
   unlock screen
end browserGoToExtensionStore

on browserDocumentLoadComplete pURL
   browserShow
end browserDocumentLoadComplete

on browserDocumentLoadFailed pURL
   browserGoToExtensionStore
end browserDocumentLoadFailed

on browserNavigateComplete
   set the javaScriptHandlers of widget "browser" of me to "installExtension"
   browserShow
end browserNavigateComplete
