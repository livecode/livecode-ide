script "revStandaloneSettingsCopyFilesBehavior"
on setProps
   setSetting "files", field "files"
   setSetting "CopyReferencedFiles", the hilite of button "Copy Referenced Files"
   setSetting "ReferencedFilesDestination", field "Destination"

   set the enable of button "Remove Entry" to (field "files" is empty)
   checkForWarning
end setProps

on preOpenCard
   put getSetting("files") into fld "files"
   if getSetting("copyreferencedfiles") is "true" then
      set the hilite of button "Copy Referenced Files" to true
      set the enabled of group "Destination Group" to true
   else
      -- it is either false, or not defined, and the default is false
      set the hilite of button "Copy Referenced Files" to false
      set the enabled of group "Destination Group" to false
   end if
   
   local tDestination
   put getSetting("referencedfilesdestination") into tDestination
   if tDestination is empty then 
      put "Referenced Files" into tDestination
   end if
   put tDestination into field "Destination"
   set the enabled of button "Copy Referenced Files" to not getSetting("ios")
   
   checkForWarning
   
   pass preOpenCard
end preOpenCard

on mouseUp
   if the short name of the target is "Copy Referenced Files" then
      set the enabled of group "Destination Group" to the hilite of the target
      setProps
   end if
end mouseUp

-- MW-2010-12-16: [[ Bug 9238 ]] Check for folders beginning with 'Resources' as this breaks
-- the simulator.
command checkForWarning
   if not the cRevStandaloneSettings["ios"] of stack the cRevTargetStack of this stack then
      hide field "Warning"
      exit checkForWarning
   end if
   
   local tMustWarn, tIndex
   put false into tMustWarn
   set the itemDelimiter to slash
   put 1 into tIndex
   repeat for each line tLine in field "files"
      if item 1 of tLine is "Resources" then
         put true into tMustWarn
         set the textColor of line tIndex of field "files" to "red"
         set the textStyle of line tIndex of field "files" to "bold"
      end if
      add 1 to tindex
   end repeat
   set the visible of field "Warning" to tMustWarn
end checkForWarning
