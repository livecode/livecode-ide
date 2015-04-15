script "revAnalyticsLibrary"
on revLoadLibrary
   insert the script of me into back
   initialiseAnalytics
end revLoadLibrary

on revUnloadLibrary
   remove the script of me from back
end revUnloadLibrary

--------Analytics Library--------
# This library is used to send anonymous usage data of LiveCode to our analytics account
# It is used help us work out whether changes we are making to the IDE are helping improve
# developer experience. 

# pType: Must be one of 'pageview', 'screenview', 'event', 'transaction', 'item', 'social', 'exception', 'timing'.
on revAnalyticsIDEHit pType, pPath, pScreenName
   if pType is not among the items of "pageview,screenview,event,transaction,item,social,exception,timing" then exit revAnalyticsIDEHit
   if pPath is empty then exit revAnalyticsIDEHit
   if pScreenName is empty then exit revAnalyticsIDEHit
   
   local tLicence, tVersion, tScreenResolution
   put revAnalyticsScreenResolution() into tScreenResolution
   put revAnalyticsLiveCodeLicenseType() into tLicence
   put revAnalyticsLiveCodeVersion() into tVersion
   
   local tData
   put pType & "," & pPath & "," & pScreenName & "," & tLicence & "," & tVersion & "," & tScreenResolution & CR into tData
   write tData to process analyticsSlave()
end revAnalyticsIDEHit

private function revAnalyticsScreenResolution
   return item 3 of line 1 of the screenrects & "x" &  item 4 of line 1 of the screenrects
end revAnalyticsScreenResolution

private function revAnalyticsLiveCodeLicenseType
   return line 3 of the revlicenseinfo
end revAnalyticsLiveCodeLicenseType

private function revAnalyticsLiveCodeVersion
   return char 1 - 5 of the version
end revAnalyticsLiveCodeVersion

on revAnalyticsScreenChanged pLongID
   local tTargetStackID
   put revIDEStackOfObject(pLongID) into tTargetStackID
   
   if revIDEStackIsRevStack(tTargetStackID) is true then
      local tTargetCardID
      put revIDECardOfObject(pLongID) into tTargetCardID
      
      local tStackName, tScreenName
      put the short name of tTargetStackID into tStackName
      put the short name of tTargetCardID into tScreenName
      revAnalyticsIDEHit "screenview",tStackName,tScreenName
   end if
end revAnalyticsScreenChanged

function analyticsSlave
   return specialfolderpath("desktop") & slash & "slave"
end analyticsSlave

on initialiseAnalytics
   local tDeployInfo
   put empty into tDeployInfo
   
   put the filename of stack "revAnalytics" into tDeployInfo["stackfile"]
   put analyticsSlave() into tDeployInfo["output"]
   
   local tAuxStacks
   put the effective filename of stack "revLibUrl" after tAuxStacks
   
   repeat for each line tStackFile in tAuxStacks
      local tTempStackFile
      put the tempname into tTempStackFile
      dispatch "revSBResaveScriptOnlyStackAsProperStackFile" to stack "revSBLibrary" with the short name of stack tStackFile, tStackFile, tTempStackFile
      if tDeployInfo["auxiliary_stackfiles"] is empty then
         put tTempStackFile into tDeployInfo["auxiliary_stackfiles"]
      else
         put return & tTempStackFile after tDeployInfo["auxiliary_stackfiles"]
      end if
   end repeat

   put "send" && quote & "revLoadLibrary" & quote && "to stack" && quote & "revLibUrl" & quote into tDeployInfo["startup_script"] 
   
   get revEnvironmentRuntimePath()
   switch the platform
      case "MacOS"
         if revEnvironmentIsInstalled() then
            put it & "/Mac OS X/x86-32/Standalone.app/Contents/MacOS/Standalone" into tDeployInfo["engine"]
         else
            if revLicenseType() is "community" then
               put revEnvironmentBinariesPath() & slash & "Standalone-Community.app/Contents/MacOS/Standalone-Community" into tDeployInfo["engine"]
            else
               put revEnvironmentBinariesPath() & slash & "Standalone-Commercial.app/Contents/MacOS/Standalone-Commercial" into tDeployInfo["engine"]
            end if
         end if
         _internal deploy macosx tDeployInfo
         break
      case "Windows"
         if revEnvironmentIsInstalled() then
            put it & "/Windows/x86-32/Standalone" into tDeployInfo["engine"]
         else
            if revLicenseType() is "community" then
               put revEnvironmentBinariesPath() & slash & "standalone-community.exe" into tDeployInfo["engine"]
            else
               put revEnvironmentBinariesPath() & slash & "standalone-commercial.exe" into tDeployInfo["engine"]
            end if
         end if
         _internal deploy windows tDeployInfo
         break
      case "Linux"
         if revEnvironmentIsInstalled() then
            put it & "/Linux/x86-64/Standalone" into tDeployInfo["engine"]
         else
            if revLicenseType() is "community" then
               put revEnvironmentBinariesPath() & slash & "standalone-community" into tDeployInfo["engine"]
            else
               put revEnvironmentBinariesPath() & slash & "standalone-commercial" into tDeployInfo["engine"]
            end if
         end if
         _internal deploy linux tDeployInfo
         break
   end switch
end initialiseAnalytics
