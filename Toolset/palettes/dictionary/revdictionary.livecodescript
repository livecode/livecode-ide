script "revDictionary"
local sBrowserID, sTab

on preOpenStack
   send "openBrowser" to me in 0 millisecs
   dispatch "setAsBehavior" to stack revIDEFrameBehavior() with the long id of me
   set the title of me to "Dictionary"
end preOpenStack

on openBrowser
   local tURL
   put "file:" & revIDESpecialFolderPath("documentation") & slash & "html_viewer/viewer.html" into tURL
   
   put revBrowserOpenCEF(the windowId of this stack, tUrl) into sBrowserID
end openBrowser

on openStack
   addFrameItem "show_apis","header", "navigation", "API", "f1b3", "f1b3","showAPIs", the long id of me
   addFrameItem "show_guides","header", "navigation", "Guide", "f1b3", "f1b3","showGuides", the long id of me
   
   set the navigationDisplayStyle of me to "names"
   set the cantModify of me to true
end openStack

on resizeStack
   revBrowserSet sBrowserID, "rect", the contentRect of me
end resizeStack

on showAPIs
   setUrl "file:" & revIDESpecialFolderPath("documentation") & slash & "html_viewer" & slash & "viewer.html"
   put "api" into sTab
end showAPIs

on showGuides
   setUrl "file:" & revIDESpecialFolderPath("documentation") & slash & "html_viewer" & slash & "guide.html"
   put "guide" into sTab
end showGuides

on showPreview
   setUrl "file:" & revIDESpecialFolderPath("documentation") & slash & "html_viewer" & slash & "viewer_temp.html"
end showPreview

on previewDocs
   lock screen
   addFrameItem "show_preview","header", "navigation", "Show Preview", "f1b3", "f1b3","showPreview", the long id of me
   
   local tTempViewer
   put revIDESpecialFolderPath("documentation") & slash & "html_viewer" & slash & "viewer_temp.html" into tTempViewer
   if there is not a file tTempViewer then
      local tHTML
      put url ("file:" & revIDESpecialFolderPath("documentation") & slash & "html_viewer" & slash & "viewer.html") into tHTML
      replace "built_api.js" with "temp_api.js" in tHTML
      put tHTML into url ("file:" & tTempViewer)
   end if
   
   layoutFrame
   resizeStack
   unlock screen
   showPreview
end previewDocs

on setUrl pUrl
   revBrowserSet sBrowserID, "url", pUrl
end setUrl

on closeStack
   lock screen
   revBrowserClose sBrowserID
   put empty into sBrowserID
   unlock screen
end closeStack

on browserNavigateComplete
   resizeStack
end browserNavigateComplete
