script "revStandaloneSettingsBugReportsBehavior"
on preOpenCard
   local tStandaloneSettingsA
   put getSettings() into tStandaloneSettingsA
   set the hilite of btn "errorDialog" to tStandaloneSettingsA["errorDialog"] = true
   set the enabled of group "errorDialog" to tStandaloneSettingsA["errorDialog"] = true
   put tStandaloneSettingsA["errorDialog,htmlText"] into fld "htmlText"
   put tStandaloneSettingsA["errorDialog,icon"] into fld "icon"
   put tStandaloneSettingsA["errorDialog,email"] into fld "email"
   set the hilite of btn "comments" to tStandaloneSettingsA["errorDialog,comments"] = true
   set the hilite of btn "save" to tStandaloneSettingsA["errorDialog,save"] = true
   set the hilite of btn "email1" to tStandaloneSettingsA["errorDialog,email"] <> ""
   set the enabled of group "email" to tStandaloneSettingsA["errorDialog,email"] <> ""
   set the enabled of button "errorDialog" to not tStandaloneSettingsA["ios"]
   pass preOpenCard
end preOpenCard
