script "revanaliticslibrary"

on revLoadLibrary
   insert the script of me into back
end revLoadLibrary

on revUnloadLibrary
   remove the script of me from back
end revUnloadLibrary

--------Analytics Library--------
# This library is used to send anonymous usage data of LiveCode to our analytics account
# It is used help us work out whether changes we are making to the IDE are helping improve
# developer experience. 

on revAnalyticsScreenChanged pLongID
   local tTargetStackID
   put revIDEStackOfObject(pLongID) into tTargetStackID
   
   if revIDEStackIsRevStack(tTargetStackID) is true then
      local tTargetCardID
      put revIDECardOfObject(pLongID) into tTargetCardID
      
      local tStackName, tScreenName
      put the short name of tTargetStackID into tStackName
      put the short name of tTargetCardID into tScreenName
      revAnaliticsIDEHit "screenview",tStackName,tScreenName
   end if
end revAnalyticsScreenChanged

# pType: Must be one of 'pageview', 'screenview', 'event', 'transaction', 'item', 'social', 'exception', 'timing'.
on revAnaliticsIDEHit pType, pPath, pScreenName
   if pType is not among the items of "pageview,screenview,event,transaction,item,social,exception,timing" then exit revAnaliticsIDEHit
   if pPath is empty then exit revAnaliticsIDEHit
   if pScreenName is empty then exit revAnaliticsIDEHit
   
   local tData
   
   put pType into tData["t"] // Google analytics: hit type
   put "ide/" & pPath into tData["dp"] // Google analytics: document path
   put pScreenName into tData["cd"] // Google analytics: screen name
   
   revAnaliticsSendData tData
end revAnaliticsIDEHit

local sSessionStarted
private on revAnaliticsSendData pData
   put 1 into pData["v"] // Google analytics protocal version to call
   put "UA-41842002-2" into pData["tid"] // Google analytics tracking ID
   put "app" into pData["ds"] // Tell google the source of the hit is the LiveCode application
   put revAnalyticsClientID() into pData["cid"] // Links all hits from anonymous client ID
   put revAnalyticsScreenResolution() into pData["sr"] // Links all hits from anonymous client ID
   put "LiveCode" && revAnalyticsLiveCodeLicenseType() into pData["an"] // App name LiveCode Community or LiveCode Commercial
   put revAnalyticsLiveCodeVersion() into pData["sv"] // Application version
   
   if sSessionStarted is not true then
      put true into sSessionStarted
      put "start" into pData["sc"] // Starts a session
   end if
   
   local tURL, tPayload
   put "https://www.google-analytics.com/collect" into tURL
   repeat for each line tKey in the keys of pData
      put tKey & "=" & revAnalyticsURLEncode(pData[tKey]) & "&" after tPayload
   end repeat
   delete the last char of tPayload
   
   post tPayload to tURL
   //put tURL & return & tPayload & return & the result & return & it
end revAnaliticsSendData

// Returns the anonymous client ID from the local system
private function revAnalyticsClientID
   return "35009a79-1a05-49d7-b876-2b884d0f825b"
end revAnalyticsClientID

private function revAnalyticsScreenResolution
   return item 3 of line 1 of the screenrects & "x" &  item 4 of line 1 of the screenrects
end revAnalyticsScreenResolution

private function revAnalyticsLiveCodeLicenseType
   return line 3 of the revlicenseinfo
end revAnalyticsLiveCodeLicenseType

private function revAnalyticsLiveCodeVersion
   return char 1 - 5 of the version
end revAnalyticsLiveCodeVersion

private function revAnalyticsURLEncode pURL
   replace " " with "%20" in pURL
   replace "/" with "%2F" in pURL
   return pURL
end revAnalyticsURLEncode
   
