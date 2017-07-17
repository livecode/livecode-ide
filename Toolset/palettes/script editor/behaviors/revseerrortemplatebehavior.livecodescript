script "revSEErrorTemplateBehavior"
# Parameters
#   pInfo : error information, format described below
# Description
#   Initializes this error group with the specified information.
#   pInfo is in the following format.
#   <object> tab <type> tab <line> tab <char> tab <description> tab <token>
on itemInit pInfo
   set the itemDelimiter to tab
   
   local tObjectId, tObject
   put item 1 of pInfo into tObjectId
   
   local tType
   put item 2 of pInfo into tType
   
   # If the type is "noerror" then we don't need to display the object
   # this is important because sometimes the errors pane can be refreshed before
   # any objects have been added to the script editor. In this case there will be 
   # no errors yet, so we check for "noerror" and only attempt to access tObjectId
   # if there was an error.
   if tType is not "noerror" then
      put revDebuggerObjectName(tObjectId) into tObject
   end if
   
   # Standard errors and warnings
   if tType is "execution" or tType is "compilation" or tType is "warning" then
      
      local tLine
      put item 3 of pInfo into tLine
      
      local tDescription
      put item 5 of pInfo into tDescription
      
      local tToken
      put item 6 of pInfo into tToken
      
      local tPosition
      put item 4 of pInfo into tPosition
      
      local tLabel
      if tType is "warning" then
         put empty into tLabel
      else
         put " error" into tLabel
      end if
      
      if tLine is 0 then
         put "n/a" into tline
      end if
      
      # Generate error messages that look something like this:
      # Object: compilation error at line 10 (Expression: bad factor) near "blah", char 10
      local tErrorString
      put tObject & ": " & tType & tLabel & " at line " & tLine & " (" & tDescription & ")" into tErrorString
      if tToken is not empty then
         put " near " & quote & tToken & quote after tErrorString
      end if
      if tPosition is not empty and tPosition is not 0 then
         put ", char " & tPosition after tErrorString
      end if
      
      
      put tErrorString into field 1 of me
   else
      # tType may also be "noerror", in which case we just display this.
      put  "No errors occurred" into field 1 of me
   end if
   
   local tIconId
   put getIconId(tType) into tIconId
   set the icon of button 1 of me to tIconId
   
   # Set some custom properties so that when the user selects this group, we know
   # which error they want to display.
   set the cObject of me to item 1 of pInfo
   set the cLine of me to item 3 of pInfo
   set the cPosition of me to item 4 of pInfo
   set the cType of me to item 2 of pInfo
   
   resize
end itemInit

command itemHilite
   --   set the backgroundColor of field 1 of me to "210,210,210"
   
   # OK-2009-03-11 : Bug 7499
   local tHiliteColor
   put sePrefGet("editor,hiliteColor") into tHiliteColor
   if tHiliteColor is empty then
      put the hiliteColor into tHiliteColor
   end if
   
   if tHiliteColor is empty then
      put "210,210,210" into tHiliteColor
   end if
   
   if seGetPlatform() is not "MacOS" then
      set the textColor of field 1 of me to "255,255,255"
   end if
   set the backgroundColor of field 1 of me to tHiliteColor
end itemHilite

command itemUnhilite
   if seGetPlatform() is not "MacOS" then
      set the textColor of field 1 of me to "0,0,0"
   end if
   set the backgroundColor of field 1 of me to "255,255,255"
end itemUnhilite


# Description
#   Sent by the parent when this object might be been resized.
#   Updates the controls to reflect the current rect of the object.
command resize
  set the topLeft of button 1 of me to the topLeft of me
  set the width of field 1 of me to the width of me - the width of button 1 of me
  set the topLeft of field 1 of me to the topRight of button 1 of me
end resize

private function getIconId pType
  if pType is "execution" then
    return seGetIcon("errorsExecution")
  end if
  
  if pType is "compilation" then
    return seGetIcon("errorsCompilation")
  end if
  
  if pType is "noerror" then
    return seGetIcon("errorsNoError")
  end if
  
  if pType is "warning" then
    return 0
  end if
end getIconId

