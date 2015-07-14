script "revErrorDisplay"
# AL-2015-07-07: Ensure LCB error code matches that of the engine.
local sLCBErrorCode

on resizeStack
  revUpdateGeometry
  updateStoredRect
end resizeStack

# OK-2007-07-02: Bug 5203
private command updateStoredRect
  set the cErrorDisplayRect of stack "revPreferences" to the rect of me
  set the cErrorDisplayScreenRect of stack "revPreferences" to the screenRect
end updateStoredRect

# OK-2007-07-02: Bug 5203
on preOpenStack
   if sLCBErrorCode is empty then
      # AL-2015-07-07: Calculate LCB error code
      put lineOffset("extension: error occured with domain", the scriptExecutionErrors) into sLCBErrorCode
   end if
   
   local tStoredRect
   put the cErrorDisplayRect of stack "revPreferences" into tStoredRect
   
   local tStoredScreenRect
   put the cErrorDisplayScreenRect of stack "revPreferences" into tStoredScreenRect
   
   lock messages	
   if tStoredRect is not empty then
      
      if tStoredScreenRect is not empty then
         local tLeft, tTop
         put item 1 of tStoredRect into tLeft
         put item 2 of tStoredRect into tTop
         
         local tRight, tBottom 
         put round(item 3 of tStoredRect * (item 3 of the screenRect / item 3 of tStoredScreenRect)) into tRight
         put round(item 4 of tStoredRect * (item 4 of the screenRect / item 4 of tStoredScreenRect)) into tBottom 
         
         set the rect of me to tLeft, tTop, tRight, tBottom
      else
         set the rect of me to tStoredRect
      end if
      
   else
      set the width of me to 512
      set the height of me to 277
      
      set the loc of me to the screenLoc
   end if
   
   if there is a group "errordisplay" of me then
      delete group "errordisplay" of me
   end if
   
   set the width of the templatebutton to 82
   set the height of the templatebutton to 23
   set the style of the templatebutton to "standard"
   
   
   create group "errordisplay"
   create field "Error" in group "errordisplay"
   set the hscrollbar of it to true
   set the vscrollbar of it to true
   set the vgrid of it to true
   set the lockText of it to true
   set the dontwrap of it to true
   set the tabstops of it to "60,2000"
   set the rect of it to "0,0,800,434"
   set the margins of it to "8,14,8,8"
   set the bordercolor of it to "220,220,220"
   set the showfocusborder of it to false
   create button "Ignore" in group "errordisplay"
   set the loc of it to "-50,437"
   create button "Script" in group "errorDisplay"
   set the loc of it to "402,461"
   create button "Debug" in group "errordisplay"
   set the loc of it to "-50,403"
   
   reset the templatebutton
   
   unlock messages
end preOpenStack

on openStack
   show me
end openStack

on closeStack
  updateStoredRect
  pass closeStack
end closeStack

# OK-2007-11-26
command revCloseErrorDialog
  send "revCloseErrorDialogDo" to me in 0 milliseconds
end revCloseErrorDialog

command revCloseErrorDialogDo
  close me
end revCloseErrorDialogDo

local lExit

on closeStack
  if the enabled of btn "Ignore" of group "errorDisplay" of me then
    set the traceAbort to true
    set the traceReturn to true
  end if
  
  # OK-2007-07-02: Bug 5203
  pass closeStack
end closeStack

on returnInField
  returnKey
end returnInField

on enterInField
  returnKey
end enterInField

on returnKey
  if the default of btn "Ignore" of group "errorDisplay" of me then click at the loc of btn "Ignore" of group "errorDisplay" of me
  else click at the loc of btn "script"
end returnKey

on enterKey
  returnKey
end enterKey

on preOpenCard
   global gREVMovingPalette, gREVDevelopment, gRevExit
   
   if "resizeStack" is among the items of line 1 of the executionContexts then -- BZ 2867 resizeStack grabs focus, bringing up a dialog now = disaster
      send "modeless revErrorDisplay" to me in 500 milliseconds
      lock messages
      close stack "revErrorDisplay"
      unlock messages 
      exit to top
   end if
   
   
   if gREVExit then
      put false into gREVExit
      exit preOpenCard
   end if
   
   set the lockCursor to false
   if the platform is "MacOS" and there is a group "revMenuBar" of stack revIDEPaletteToStackName("menubar") then
      local tReturn
      put the defaultStack into tReturn
      set the defaultStack to revIDEPaletteToStackName("menubar")
      set the defaultMenuBar to the long id of group "revMenuBar" of stack revIDEPaletteToStackName("menubar")
      set the defaultStack to tReturn
   end if
   
   local tError
   put the executionError of this stack into tError
   
   local tScriptError
   put the scriptError of this stack into tScriptError
   
   local tObject
   put the errorObject of this stack into tObject
   set the executionError of this stack to empty
   set the scriptError of this stack to empty
   set the errorObject of this stack to empty

   lock screen
   set the textHeight of fld "Error" of group "errorDisplay" of me to 16
   --debug mode stuff
   
   local tFldContent
   put the htmlText of fld 1 into tFldContent
   
   local tProfile
   put "Master" into tProfile
   global gREVProfileReadOnly
   
   local tReturnReadOnly
   put gREVProfileReadOnly into tReturnReadOnly
   put true into gREVProfileReadOnly
   repeat with i = 1 to the number of controls
      set the cREVGeneral["profile"] of control i to tProfile
   end repeat
   put tReturnReadOnly into gREVProfileReadOnly
   set the default of btn "Ignore" of group "errorDisplay" of me to true
   set the default of btn "Ignore" of group "errorDisplay" of me to false
   set the left of btn "Ignore" of group "errorDisplay" of me to -100
   set the left of btn "Debug" of group "errorDisplay" of me to -100
   disable btn "Ignore" of group "errorDisplay" of me
   disable btn "Debug" of group "errorDisplay" of me
   --end if
   if tScriptError is not empty then
      enable btn "Ignore" of group "errorDisplay" of me
      disable btn "Ignore" of group "errorDisplay" of me
      set the default of btn "Ignore" of group "errorDisplay" of me to false
      disable btn "Debug" of group "errorDisplay" of me
   end if
   set the htmlText of fld 1 to tFldContent
   resizeStack
   --end debug mode stuff
   if tError is not empty then
      local tErrorString
      put "     " & tab & "executing at" && the long time & cr into tErrorString

      if item 2 of line 1 of tError is 0 then -- go down until error is found
         repeat with i = 1 to the number of lines in tError
            if item 2 of line i of tError is not 0 then exit repeat
         end repeat
         
         local tErrorLine
         put i into tErrorLine
      else
         put 1 into tErrorLine
      end if
      put "Type" & tab after tErrorString
      
      local tNumber
      put item 1 of line 1 of tError into tNumber -- look up number based on line 1 always
      if tNumber is not a number then
         close stack "revErrorDisplay"
         close stack "execution error"
         exit to top
      end if
      if tNumber is 634 then
         put item 4 to -1 of line 1 of tError & cr after tErrorString
      else
         put line tNumber of the scriptExecutionErrors & cr after tErrorString
      end if
   else if tScriptError is not empty then
      put tScriptError into tError
      put "     " & tab & "compiling at" && the long time & cr into tErrorString
      put "Type" & tab & line (item 1 of line 1 of tError) of the cScriptErrors of cd 1 of stack "REVErrorDisplay" & cr after tErrorString
   end if
   if tOBject is empty then exit to top -- bogus error
   put "Object" & tab & the short name of tObject & cr after tErrorString
   
   local tTargetStack
   put revTargetStack(tObject) into tTargetStack
   
   # OK-2010-02-12: No longer correct
   --if the passKey of stack tTargetStack is not the passWord of stack tTargetStack then -- its password protected
   if not the passkey of stack tTargetStack then
      answer error "There was an error executing a script in stack" && tTargetStack & ".  No more information is available because the stack is password protected."
      close stack "revErrorDisplay"
      close stack "execution error"
      exit to top
   end if
   
   if item 1 of line 1 of tError is sLCBErrorCode then
      put "LCB Error" & tab & item 4 to -1 of line 2 of tError into line 2 of tErrorString
      put "LCB File" & tab & item 4 to -1 of line 3 of tError & cr after tErrorString
      put "LCB Line" & tab & item 4 to -1 of line 4 of tError after tErrorString
   else
      local tLineNo
      if word 1 to -1 of line (item 2 of tError) of the script of tObject is empty or item 2 of tError is 0 then put tErrorLine into tLineNo else put 1 into tLineNo
      put "Line" & tab & word 1 to -1 of line (item 2 of line tLineNo of tError) of the script of tObject & cr after tErrorString
      set the cLastError of this cd to line -2 of tErrorString & cr & tObject
      
      local tExit
      put false into tExit
      repeat for each line l in tError
         if the number of items in l is 4 then
            put true into tExit
            exit repeat
         end if
      end repeat
      if not tExit then put line 1 of tError into l
      put "Hint" & tab & item 4 of l after tErrorString
   end if
   put revTargetStack(tObject) into tTargetStack
   if tTargetStack is not among the lines of revFilterStacksList(tTargetStack) then
      put "internal" into word 2 of tErrorString
      local tUIError
      put true into tUIError
   end if
   if "license limit" is in tScriptError or "license limit" is in tError then
      put false into tUIError
   end if
   if tUIError and gREVDevelopment is not true then
      put cr & cr & cr & "*** --Internal error" & cr & tErrorString after URL "file:components/save/sessionlog.txt"
      if tError is not empty then
         put cr & tError & cr & the long id of tObject & cr after URL "file:components/save/sessionlog.txt"
      else
         put tScriptError & cr & the long id of tObject after URL "file:components/save/sessionlog.txt"
      end if
      lock messages
      close stack "revErrorDisplay"
      set the traceAbort to true
      set the traceReturn to true
      exit preOpenCard
   else if lExit then
      put tErrorString into line 1 to 5 of fld "Error" of group "errorDisplay" of me
      set the textColor of line 1 to 5 of fld "Error" of group "errorDisplay" of me to 64,64,64
   else
      put tErrorString & cr & cr before fld "Error" of group "errorDisplay" of me
   end if
   set the imageSource of char 1 of fld "Error" of group "errorDisplay" of me to 202696
   set the textStyle of line 1 of fld "Error" of group "errorDisplay" of me to "bold"
   set the textStyle of line 2 to 5 of fld "Error" of group "errorDisplay" of me to "plain"
   set the textColor of line 1 to 5 of fld "Error" of group "errorDisplay" of me to "black"
   set the hScroll of fld "Error" of group "errorDisplay" of me to 0
   if tUIError then
      --
   end if
   
   if the formattedWidth of fld "Error" of group "errorDisplay" of me > the width of fld "Error" of group "errorDisplay" of me then set the hScrollBar of fld "Error" of group "errorDisplay" of me to true
   else set the hScrollBar of fld "Error" of group "errorDisplay" of me to false
   set the vScroll of fld "Error" of group "errorDisplay" of me to 0
   set the hScroll of fld "Error" of group "errorDisplay" of me to 0
   
   local tUniqueChunk
   put base64encode(line 1 to 5 of fld "Error" of group "errorDisplay" of me) into tUniqueChunk
   if tError is not empty then
      set the tUniqueChunk of this stack to tError & cr & the long id of tObject
      set the cCurrentObject of this cd to tError & cr & the long id of tObject
   else
      set the tUniqueChunk of this stack to tScriptError & cr & the long id of tObject
      set the cCurrentObject of this cd to tScriptError & cr & the long id of tObject
   end if
   enable btn "script"
   unlock screen
end preOpenCard

on openCard
   global gREVEditNow, gREVExit2
   --write "got error opencard" & cr to stdout
   if gREVExit2 then
      put false into gREVExit2
      exit openCard
   end if
   if lExit then
      put false into lExit
      lock screen
      select line 1 to 5 of fld "Error" of group "errorDisplay" of me
      set the hScroll of fld "Error" of group "errorDisplay" of me to 0
      send "revLineColors" to me in 20 seconds
      unlock screen
      exit openCard
   end if
   
   send "revLineColors" to me in 20 seconds
   lock messages
   modeless "REVErrorDisplay"
   unlock messages
   if the mode of stack "revErrorDisplay" is not 0 then
      lock screen
      select line 1 to 5 of fld "Error" of group "errorDisplay" of me
      set the hScroll of fld "Error" of group "errorDisplay" of me to 0
      unlock screen
   else 
      exit openCard
   end if
   --beep
   if gREVEditNow then
      put false into gREVEditNow
      send "mouseDoubleUp" to fld "Error" of group "errorDisplay" of me
   end if
end openCard

on revLineColors
   local tTotal
   put 0 into tTotal
   repeat for each line l in the pendingMessages
      if "revLineColors" is in l then add 1 to tTotal
   end repeat
   
   local tLineStart
   put 1 into tLineStart
   add tTotal * 6 to tLineStart
   
   # OK-2008-08-18 : Bug 5039 - I'm not sure why this block of code is needed, but its causing bug 5039, so for now, it goes...
   --  if the selectedField is not empty then -- select script editor field again
   --    put true into tRestore
   --    put the long id of the selectedField into tField
   --    put the selectedChunk into tChunk
   --  end if
   set the textColor of line tLineStart to tLineStart+5 of fld "Error" of group "errorDisplay" of me to "64,64,64"
   set the imageSource of char 1 of line tLineStart of fld "Error" of group "errorDisplay" of me to 202697
   
   # OK-2008-08-18 : Bug 5039
   --  if tRestore then
   --    put word 2 of tChunk into tCharFrom
   --    put word 4 of tChunk into tCharTo
   --    select char tCharFrom to tCharTo of tField
   --  end if
end revLineColors

setProp cCurrentObject pWhat
   local tScriptError
   if "Script Compile Error" is in (the selection) then put true into tScriptError
   else if (the selection) is empty and line 1 of fld "Error" of group "errorDisplay" of me contains "Script Compile Error" then put true into tScriptError
   else put false into tScriptError
   
   local tObject
   put last line of pWhat into tObject
   
   local tParsedData
   repeat for each line l in (line 1 to -2 of pWhat)
      if tScriptError then put "     " & tab & line (item 1 of l) of the cScriptErrors of cd 1 of stack "REVErrorDisplay" & cr after tParsedData
      else put "Type" & tab & line (item 1 of l) of the cErrorsList of cd 1 of stack "REVErrorDisplay" & cr after tParsedData
      put word 1 to -1 of line (item 2 of l) of the script of tObject & cr after tParsedData
      put "Line" & tab & item 2 of l && "Character:" && item 3 of l & cr after tParsedData
      put "Hint"  & tab & item 4 of l & cr & cr after tParsedData
   end repeat
end cCurrentObject

on mouseUp
   local tKey
   if the target begins with "button" then
      if the short name of the target is "Script" then
         send "mouseDoubleUp" to fld "Error" of group "errorDisplay" of me
      else if the short name of the target is "Ignore" then
         set the traceAbort to true
         set the traceReturn to true
         set the default of btn "Ignore" of group "errorDisplay" of me to false
         disable btn "Ignore" of group "errorDisplay" of me
         disable btn "Debug" of group "errorDisplay" of me
      else if the short name of the target is "Debug" then
         global gREVSelectScriptChunk
         local tObject, tLineNo
         lock screen
         if the selection is empty then select line 1 to 5 of fld 1
         put base64Encode(the selection) into tKey
         put last line of the tKey of this stack into tObject
         if word 1 of item 2 of the tKey of this stack is 0 then
            if item 2 of line -5 of the tKey of this stack is 0 then
               put -4 into tLineNo
            else
               put -5 into tLineNo
            end if
         else
            put 1 into tLineNo
         end if
         put "char" && word 1 of item 3 of line tLineNo of the tKey of this stack && "to -1 of line" && item 2 of line tLineNo of the tKey of this stack into gREVSelectScriptChunk
         revDebugScript (item 2 of line tLineNo of the tKey of this stack),tObject
         unlock screen
      end if	
   else if the target begins with "field" then
      if the clickText is not empty then
         local tLine
         put word 2 of the clickChunk into tLine
         put the num of lines in char 1 to tLine of fld "Error" of group "errorDisplay" of me into tLine
         put trunc(tLine/6)*6 into tLine
         lock screen
         select line (tLine + 1) to (tLine + 5) of field "Error" of group "errorDisplay" of me
         set the hScroll of field "Error" of group "errorDisplay" of me to 0
         unlock screen
         put base64Encode(the selection) into tKey
         set the cCurrentObject of this card to the tKey of this stack
         if the selection is not empty then
            --enable btn "Reset All"
            enable button "Script" of group "errorDisplay" of me
         end if
      end if
   end if
end mouseUp

on mouseDoubleUp
   if the target begins with "field" and the short name of the target is "Error" then
      --global gREVSelectScriptChunk
      lock screen
      lock error dialogs
      if the selection is empty then select line 1 to 5 of field "Error" of group "errorDisplay" of me
      
      local tKey
      put base64Encode(the selection) into tKey
      
      local tObject
      put last line of the tKey of this stack into tObject
      
      local tError
      put the tKey of this stack into tError
      
      -- If it is an LCB Error there is no double-click behavior
      if item 1 of line 1 of tError is sLCBErrorCode then
         exit mouseDoubleUp
      end if
      
      local tLineNo
      if item 2 of line 1 of tError is 0 then -- go down until error is found
         repeat with i = 1 to the number of lines in tError
            if item 2 of line i of tError is not 0 then exit repeat
         end repeat
         put i into tLineNo
      else
         put 1 into tLineNo
      end if
      
      disable btn "Ignore" of group "errorDisplay" of me
      set the default of btn "Ignore" of group "errorDisplay" of me to false
      disable btn "Debug" of group "errorDisplay" of me
      unlock screen
      
      # OK-2008-06-18 : New script editor modifications
      revDebuggerStop
      
      edit the script of tObject
      local tScriptEditor
      put revScriptEditor(tObject) into tScriptEditor
      
      local tLineNumber
      put item 2 of line tLineNo of the tKey of this stack into tLineNumber
      
      # Because the script editor does a number of things on a timer on startup in order to ensure
      # that the script editor stack doesn't appear, we have to wait until these are all finished before
      # attempting to highlight the appropriate line number. This is a total hack, but there doensn't seem
      # to be a better way to make it work quickly...
      send "checkScriptEditor tScriptEditor, tObject, tLineNumber" to me in 100 milliseconds
   end if
end mouseDoubleUp

command checkScriptEditor pScriptEditor, pObject, pLineNumber
   # Need to wait until the script editor has finished loading the object. This may take a while because
   # the loading is done on a timer. We only need to wait until an object has been loaded.
   local tCurrentObject
   send "revSEGetCurrentObject" to stack pScriptEditor
   put the result into tCurrentObject
   if there is a tCurrentObject then
      local tTrueString
      put "true" into tTrueString
      
      send "revSEGoExecutionPoint pObject, pLineNumber, tTrueString" to stack pScriptEditor in 0 milliseconds
   else
      send "checkScriptEditor pScriptEditor, pObject, pLineNumber" to me in 100 milliseconds
   end if
end checkScriptEditor
