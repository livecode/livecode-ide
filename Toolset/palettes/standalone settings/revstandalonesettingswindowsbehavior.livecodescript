script "revStandaloneSettingsWindowsBehavior"
on preOpenCard
   local tStandaloneSettingsA
   put getSettings() into tStandaloneSettingsA
   set the itemdelimiter to ","
   local tEnabled
   put false into tEnabled
   repeat for each item tItem in "Windows,Windows x86-64"
   		put tStandaloneSettingsA[tItem] = true or tEnabled into tEnabled
   		set the hilite of btn tItem of group "platforms" to tStandaloneSettingsA[tItem] = true
   end repeat

   set the enabled of group "Windows" to tEnabled
   put tStandaloneSettingsA["Windows,iconFile"] into fld "iconFile"
   put tStandaloneSettingsA["Windows,documenticonFile"] into fld "documenticonFile"
   put tStandaloneSettingsA["Windows,fileDescription"] into fld "fileDescription"
   put tStandaloneSettingsA["Windows,LegalCopyright"] into fld "LegalCopyright"
   put tStandaloneSettingsA["Windows,comments"] into fld "comments"
   put tStandaloneSettingsA["Windows,internalName"] into fld "internalName"
   put tStandaloneSettingsA["Windows,productName"] into fld "productName"
   put tStandaloneSettingsA["Windows,privateBuild"] into fld "privateBuild"
   put tStandaloneSettingsA["Windows,companyName"] into fld "companyName"
   put tStandaloneSettingsA["Windows,originalFilename"] into fld "originalFilename"
   put tStandaloneSettingsA["Windows,legalTrademarks"] into fld "legalTrademarks"
   put tStandaloneSettingsA["Windows,specialBuild"] into fld "specialBuild"
   repeat with X=1 to 4
      put tStandaloneSettingsA["Windows,productVersion"&X] into fld ("productVersion"&X)
      put tStandaloneSettingsA["Windows,fileVersion"&X] into fld ("fileVersion"&X)
   end repeat
   
   # OK-2009-09-25: UAC stuff, initialize the UI.
   enable button "UAC Execution Level"
   
   local tExecutionLevel
   put tStandaloneSettingsA["Windows,uacExecutionLevel"] into tExecutionLevel
   if tExecutionLevel is empty then
      put "default" into tExecutionLevel
   end if
   
   set the cValue of button "UAC Execution Level" of me to tExecutionLevel
   uacUpdateInfoField tExecutionLevel
   
   // IM-2014-08-15: [[ Bug 13118 ]] HiDPI settings initialisation
   enable button "usePixelScaling"
   local tUsePixelScaling
   put tStandaloneSettingsA["Windows,usePixelScaling"] into tUsePixelScaling
   if tUsePixelScaling is empty then put true into tUsePixelScaling
   
   
   # OK-2009-09-25: Attempting to make the fonts consistent for the label fields
   initializeFonts
   
   pass preOpenCard
end preOpenCard

private command initializeFonts
   repeat for each item tLabelFieldName in "Icon Label,Version Label,UAC Label"
      revFontApplySystemStyle the long id of field tLabelFieldName of me, empty, "bold"
   end repeat
end initializeFonts

# MJVH : As a user does not always go to the advanced card, we should make sure that we generate one here.
# Otherwise an application could be generated with a random UUID that does not get saved, so next time the
# Adavanced Settings would be run, a new UUID would be generated.
on checkUUId
   if getSetting("Windows,UUID") is empty then
      setSetting "Windows,UUID", revSBGenerateUUID()
   end if
end checkUUId

# OK-2009-09-25 : UAC Manifest inclusion for user desktop deployment. This command updates a field which explains the
# various UAC options.

command uacUpdateInfoField pManifestOption
   set the text of field "UAC Info" of me to uacManifestOptionToInfo(pManifestOption)
end uacUpdateInfoField

command uacUpdateUIStatus
   enable button "UAC Execution Level"
end uacUpdateUIStatus

function uacManifestOptionToInfo pManifestOption
   local tMessage
   switch pManifestOption
      case "asInvoker"
         put "Runs with the same access as the parent process (or user)" into tMessage
         break
      case "highestAvailable"
         put "Runs with the highest privileges the current user can obtain" into tMessage
         break
      case "requireAdministrator"
         put "Must be run as administrator, useful for installers or system utilities" into tMessage
         break
      default
         put "Runs with default UAC access. No manifest is included." into tMessage
   end switch
   
   return tMessage
end uacManifestOptionToInfo

