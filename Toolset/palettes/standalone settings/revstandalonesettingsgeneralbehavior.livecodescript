script "revStandaloneSettingsGeneralBehavior"
on preOpenCard
   local tStandaloneSettingsA,tList,tCount,tHilite
   put getSettings() into tStandaloneSettingsA
   put tStandaloneSettingsA["name"] into field "standalone name"
   
   if tStandaloneSettingsA["inclusions"] is "select" then
      set the hilitedButtonName of group "inclusions" of me to "select"
      enable button "inclusions" of group "cards" of this card of me
   else
      set the hilitedButtonName of group "inclusions" of me to "search"
      disable button "inclusions" of group "cards" of this card of me
   end if
   
   if tStandaloneSettingsA["includeProfiles"] <> "" then
      set the hilitedButtonName of group "profiles" to "include"
      enable group "include profiles"
      if tStandaloneSettingsA["includeProfiles"] = "*" then
         set the hilitedButtonName of group "include profiles" to "all"
      else
         set the hilitedButtonName of group "include profiles" to "selected"
         put 1 into tCount
         put "" into tHilite
         put field "include profiles" into tList
         repeat for each line tLine in tList
            if tLine is among the lines of tStandaloneSettingsA["includeProfiles"] then put tCount & "," after tHilite
            add 1 to tCount
         end repeat
         set the hilitedLines of field "include profiles" to char 1 to -2 of tHilite
      end if
   else
      disable group "include profiles"
      if tStandaloneSettingsA["setToProfile"] <> "" then
         enable button "set objects"
         set the hilitedButtonName of group "profiles" to "set"
         set the label of button "set objects" to tStandaloneSettingsA["setToProfile"]
      else
         disable button "set objects"
         set the hilitedButtonName of group "profiles" to "remove"
      end if
   end if
   
   # OK-2009-05-22 : Added ability to save default build folder
   set the text of field "Default Build Folder" of me to tStandaloneSettingsA["defaultBuildFolder"]
   set the hilite of button "Automatically Build here" of me to (tStandaloneSettingsA["automaticallyBuildInDefaultFolder"] is true)
   
   enable group "profiles"
   
   local tTipLastShown, tShowTip
   
   put the cIDE_SAGeneralTipShow of stack "revPreferences" into tShowTip
   put the cIDE_SAGeneralTipLastShown of stack "revPreferences" into tTipLastShown
   
   if revLicenseType() is "commercial" or revLicenseType() is "professional" then
      put false into tShowTip
      set the cIDE_SAGeneralTipShow of stack "revPreferences" to false
   end if
   
   if tShowTip is false then
      if  revLicenseType() is "community" then
         if the seconds > (tTipLastShown + 2419200) then
            put true into tShowTip
         end if
      end if
   end if   
   if tShowTip is empty then put true into tShowTip
   
   set the visible of group "generalCommercialTip" to tShowTip
   tipPreferenceSet tShowTip
   tipDisplayUpdate  
   
   pass preOpenCard
end preOpenCard

on tipDisplayUpdate
   if the visible of group "generalCommercialTip" then
      set the topLeft of group "generalContent" to 9,138
      set the cSize of this card to 568,520
   else 
      set the topLeft of group "generalContent" to 9,78
      set the cSize of this card to 568,460
   end if
   updateCardSize
end tipDisplayUpdate

on tipPreferenceSet pValue
   set the cIDE_SAGeneralTipShow of stack "revPreferences" to pValue
   set the cIDE_SAGeneralTipLastShown of stack "revPreferences" to the seconds
end tipPreferenceSet
