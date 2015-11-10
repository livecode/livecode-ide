script "revIdeMessageHandlerLibrary"
on revLoadLibrary
   if the target is not me then
      pass "revLoadLibrary"
   end if	
   insert the script of me into front
end revLoadLibrary

on revUnloadLibrary
   if the target is not me then
      pass "revUnloadLibrary"
   end if
   remove the script of me from front
end revUnloadLibrary

#################################
# Messages handled and sent on to object
#################################
local sSelectingObjects
on selectedObjectChanged
   if sSelectingObjects is true then exit selectedObjectChanged
   if revIDEObjectIsOnIDEStack(the long id of the target) then pass selectedObjectChanged
   
   revIDEMessageSend "ideSelectedObjectChanged"
   pass selectedObjectChanged
end selectedObjectChanged

on objectSelectionStarted
   if revIDEObjectIsOnIDEStack(the long id of the target) then pass objectSelectionStarted
   
   put true into sSelectingObjects
   revIDEMessageSend "ideObjectSelectionStarted"
   pass objectSelectionStarted
end objectSelectionStarted

on objectSelectionEnded
   if revIDEObjectIsOnIDEStack(the long id of the target) then pass objectSelectionEnded
   
   put false into sSelectingObjects
   revIDEMessageSend "ideSelectedObjectChanged"
   pass objectSelectionEnded
end objectSelectionEnded

on resizeControl
   if revIDEObjectIsOnIDEStack(the long id of the target) then pass resizeControl
   
   revIDEMessageSend "ideResizeControl"
   pass resizeControl
end resizeControl

on resumeStack
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass resumeStack
   
   send "revIDEMessageSend" &&  "ideResumeStack","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass resumeStack
end resumeStack

on newCard
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newCard
   
   revIDEMessageSend "ideNewCard",tTarget
   pass newCard
end newCard

on newStack
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newStack

   revIDEMessageSend "ideNewStack",tTarget
   pass newStack
end newStack

on newField
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newField

   revIDEMessageSend "ideNewControl",tTarget
   pass newField
end newField

on newGraphic
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newGraphic
   
   revIDEMessageSend "ideNewControl",tTarget
end newGraphic

on newGroup
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newGroup
   
   --revIDEMessageSend "ideNewControl",tTarget
end newGroup

on newImage
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newImage
   
   revIDEMessageSend "ideNewControl",tTarget
end newImage

on newPlayer
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newPlayer

   revIDEMessageSend "ideNewControl",tTarget
end newPlayer

on newScrollbar
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newScrollbar

   revIDEMessageSend "ideNewControl",tTarget
   pass newScrollbar
end newScrollbar

on newButton
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newButton
   
   revIDEMessageSend "ideNewControl",tTarget
   pass newButton
end newButton

on newWidget
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newWidget

   revIDEMessageSend "ideNewControl",tTarget
   pass newWidget
end newWidget

on newBackground
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newBackground

   revIDEMessageSend "ideNewControl",tTarget
   pass newBackground
end newBackground

on deleteBackground
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteBackground

   send "revIDEMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
end deleteBackground

on deleteButton
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteButton

   send "revIDEMessageSend" && "ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteButton
end deleteButton

on deleteCard
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteCard
   
   send "revIDEMessageSend" &&  "ideCardDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteCard
end deleteCard
   
on deleteEPS
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteEPS

   send "revIDEMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteEPS
end deleteEPS

on deleteField
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteField
   
   send "revIDEMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds 
   pass deleteField
end deleteField

on deleteGraphic
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteGraphic

   send "revIDEMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteGraphic
end deleteGraphic

on deleteGroup
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteGroup

   send "revIDEMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteGroup
end deleteGroup

on deleteImage
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteImage

   send "revIDEMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteImage
end deleteImage

on deletePlayer
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deletePlayer
   
   send "revIDEMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deletePlayer
end deletePlayer

on deleteScrollbar
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteScrollbar

   send "revIDEMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteScrollbar
end deleteScrollbar

on deleteWidget 
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteWidget
   
   send "revIDEMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteWidget
end deleteWidget

on deleteStack
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteStack

   send "revIDEMessageSend ideStackDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteStack
end deleteStack

on libraryStack
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass libraryStack

   send "revIDEMessageSend ideLibraryStack","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass libraryStack
end libraryStack

on releaseStack
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass releaseStack

   send "revIDEMessageSend ideReleaseStack","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass releaseStack
end releaseStack

on nameChanged
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass nameChanged

   send "revIDEMessageSend ideNameChanged","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass nameChanged
end nameChanged

on openStack
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass openStack
   
   revIDEMessageSend "ideOpenStack",tTarget
   pass openStack
end openStack

--PM-2015-10-05: [[ Bug 16099 ]] choose pointer/browse tool does not update Tools palette
on newTool pTool
   revIDEMessageSend "ideToolChanged"
   pass newTool
end newTool
