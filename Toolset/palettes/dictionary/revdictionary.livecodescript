script "revDictionary"
local sBrowserID, sTab

on preOpenStack
   put revBrowserOpenCEF(the windowId of this stack) into sBrowserID
   revBrowserAddJavaScriptHandler sBrowserID, "fetchData"
   dispatch "setAsBehavior" to stack revIDEFrameBehavior() with the long id of me
end preOpenStack

on openStack
   lock screen
   addFrameItem "show_apis","header", "navigation", "API", "f1b3", "f1b3","showAPIs", the long id of me
   addFrameItem "show_guides","header", "navigation", "Guide", "f1b3", "f1b3","showGuides", the long id of me
   
   set the navigationDisplayStyle of me to "names"
   resizeStack
   hiliteFrameItem "api"
   showAPIs
   unlock screen
end openStack

on resizeStack
   revBrowserSet sBrowserID, "rect", the contentRect of me
end resizeStack

on showAPIs
   put "api" into sTab
   setUrl "file:" & revIDESpecialFolderPath("documentation") & slash & "html_viewer" & slash & "viewer.html"
end showAPIs

on showGuides
   put "guide" into sTab
   setUrl "file:" & revIDESpecialFolderPath("documentation") & slash & "html_viewer" & slash & "guide.html"
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
   revBrowserAddJavaScriptHandler sBrowserID, "fetchData"
end browserNavigateComplete

on fetchData
   send "setData" to me in 0 millisecs
end fetchData

on setData
   local tJSONDataPath
   put revIDESpecialFolderPath("documentation cache") & slash & "built_" & sTab & ".js" into tJSONDataPath
   get revBrowserCallScript(sBrowserID, "setData", textDecode(url("binfile:" & tJSONDataPath), "utf-8"))
   revBrowserRemoveJavaScriptHandler sBrowserID, "fetchData"
end setData
