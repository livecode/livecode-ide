script "revDictionary"
local sBrowserID, sTab

on preOpenStack
   set the minWidth of this stack to 1000
   dispatch "setAsBehavior" to stack revIDEFrameBehavior() with the long id of me
   set the showPreferenceAction of me to false
   set the title of me to "Dictionary"
   send "openBrowser" to me in 0 millisecs
end preOpenStack

on openBrowser
   local tURL
   put "file:" & revIDESpecialFolderPath("documentation") & slash & "html_viewer/viewer.html" into tURL
   
   put revBrowserOpenCEF(the windowId of this stack, tUrl) into sBrowserID
end openBrowser

on openStack
   addFrameItem "show_apis","header", "navigation", "API", "f1b3", "f1b3","showAPIs", the long id of me
   addFrameItem "show_guides","header", "navigation", "Guide", "f1b3", "f1b3","showGuides", the long id of me
   global gRevDevelopment
   if gRevDevelopment is true then
      addFrameItem "show_ide_library","header", "navigation", "IDE", "f1b3", "f1b3","showIDELibrary", the long id of me
   end if
   set the navigationDisplayStyle of me to "names"
   set the width of this stack to 1000
   resizeStack
   set the cantModify of me to true
end openStack

on resizeStack
   if sBrowserID is not empty then
      revBrowserSet sBrowserID, "rect", the contentRect of me
   end if
end resizeStack

on showAPIs
   setUrl "file:" & revIDESpecialFolderPath("documentation") & slash & "html_viewer" & slash & "viewer.html"
   put "api" into sTab
end showAPIs

on showGuides
   setUrl "file:" & revIDESpecialFolderPath("documentation") & slash & "html_viewer" & slash & "guide.html"
   put "guide" into sTab
end showGuides

on showIDELibrary
   setUrl "file:" & revIDESpecialFolderPath("documentation") & slash & "html_viewer" & slash & "ide_temp.html"
end showIDELibrary

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
