script "revStandaloneSettingsLinuxBehavior"
on preOpenCard
   local tStandaloneSettingsA
   put getSettings() into tStandaloneSettingsA
   
   -- MW-2013-11-06: [[ LinuxX64 ]] For now, only show the x64 button if we have
   --    and engine to build for (this is only until we integrate 64-bit linux builds
   --    into production builds).
   set the visible of button "Linux x64" to revEngineCheck("Linux x64")
   
   -- FG-2014-08-19: [[ RPi ]] Don't show the ARMv6 checkbox if the engine isn't present
   set the visible of button "Linux ARMv6-HF" to revEngineCheck("Linux armv6-hf")
   
   set the enabled of group "UNIX" to false
   
   repeat with X = 1 to the number of buttons of group "flavors"
      set the hilite of button X of group "flavors" to tStandaloneSettingsA[the short name of button X of group "flavors"] = true
      if tStandaloneSettingsA[the short name of button X of group "flavors"] then
         set the enabled of group "UNIX" to true
      end if
   end repeat
   set the hilite of button "FileSelector" to tStandaloneSettingsA["UNIX,fileSelector"] = true
   set the hilite of button "PageSetup" to tStandaloneSettingsA["UNIX,pageSetup"] = true
   set the hilite of button "PrinterChooser" to tStandaloneSettingsA["UNIX,printerChooser"] = true
   
   # OK-2007-08-14 : Temporary disable the Solaris buttons until we support it, also ensure that unix dialog
   # stacks are only included if the linux button is checked, this block of code should be removed when unix
   # support is completed.
   set the enabled of button "Solaris Intel" of group "Flavors" of me to false
   set the enabled of button "Solaris SPARC" of group "Flavors" of me to false
   
   // SN-2015-01-13: [[ Bug 14373 ]] Do not undo what the previous does: not only looking at the Linux checkbox
   --  set the enabled of group "UNIX" of me to the hilite of button "Linux" of group "Flavors" of me
   
   pass preOpenCard
end preOpenCard
