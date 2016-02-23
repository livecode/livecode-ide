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
   
   send "ideMessageSend" &&  "ideSelectedObjectChanged" to stack "revIDELibrary" in 0 milliseconds
   pass selectedObjectChanged
end selectedObjectChanged

on objectSelectionStarted
   if revIDEObjectIsOnIDEStack(the long id of the target) then pass objectSelectionStarted
   
   put true into sSelectingObjects
   send "ideMessageSend" &&  "ideObjectSelectionStarted" to stack "revIDELibrary" in 0 milliseconds
   pass objectSelectionStarted
end objectSelectionStarted

on objectSelectionEnded
   if revIDEObjectIsOnIDEStack(the long id of the target) then pass objectSelectionEnded
   
   put false into sSelectingObjects
   send "ideMessageSend" &&  "ideSelectedObjectChanged" to stack "revIDELibrary" in 0 milliseconds
   pass objectSelectionEnded
end objectSelectionEnded

on resizeControl
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass resizeControl
   
   send "ideMessageSend" &&  "ideResizeControl,tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass resizeControl
end resizeControl

on resumeStack
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass resumeStack
   
   send "ideMessageSend" &&  "ideResumeStack","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass resumeStack
end resumeStack

on newCard
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newCard
   
   send "ideMessageSend" &&  "ideNewCard","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass newCard
end newCard

on newStack
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newStack

   send "ideMessageSend" &&  "ideNewStack","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass newStack
end newStack

on newField
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newField

   send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass newField
end newField

on newGraphic
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newGraphic
   
   send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
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
   
   send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
end newImage

on newPlayer
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newPlayer

   send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
end newPlayer

on newScrollbar
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newScrollbar

   send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass newScrollbar
end newScrollbar

on newButton
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newButton
   
   send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass newButton
end newButton

on newWidget
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newWidget

   send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass newWidget
end newWidget

on newBackground
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass newBackground

   send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass newBackground
end newBackground

on deleteBackground
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteBackground

   send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
end deleteBackground

on deleteButton
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteButton

   send "ideMessageSend" && "ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteButton
end deleteButton

on deleteCard
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteCard
   
   send "ideMessageSend" &&  "ideCardDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteCard
end deleteCard
   
on deleteEPS
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteEPS

   send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteEPS
end deleteEPS

on deleteField
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteField
   
   send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds 
   pass deleteField
end deleteField

on deleteGraphic
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteGraphic

   send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteGraphic
end deleteGraphic

on deleteGroup
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteGroup

   send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteGroup
end deleteGroup

on deleteImage
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteImage

   send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteImage
end deleteImage

on deletePlayer
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deletePlayer
   
   send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deletePlayer
end deletePlayer

on deleteScrollbar
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteScrollbar

   send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteScrollbar
end deleteScrollbar

on deleteWidget 
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteWidget
   
   send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteWidget
end deleteWidget

on deleteStack
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass deleteStack

   send "ideMessageSend ideStackDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass deleteStack
end deleteStack

on libraryStack
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass libraryStack

   send "ideMessageSend ideLibraryStack","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass libraryStack
end libraryStack

on releaseStack
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass releaseStack

   send "ideMessageSend ideReleaseStack","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass releaseStack
end releaseStack

on nameChanged pOldName, pNewName
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass nameChanged
   
   local tParams
   put pOldName into tParams[1]
   put pNewName into tParams[2]
   put tTarget into tParams[3]
   send "ideMessageSendWithParameters ideNameChanged,tTarget,tParams" to stack "revIDELibrary" in 0 milliseconds
   pass nameChanged
end nameChanged

on openCard
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass openCard
   
   send "ideMessageSend" &&  "ideOpenCard","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass openCard
end openCard

on openStack
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then pass openStack
   
   send "ideMessageSend" &&  "ideOpenStack","tTarget" to stack "revIDELibrary" in 0 milliseconds
   pass openStack
end openStack

--PM-2015-10-05: [[ Bug 16099 ]] choose pointer/browse tool does not update Tools palette
on newTool pTool
   send "ideMessageSend" &&  "ideToolChanged" to stack "revIDELibrary" in 0 milliseconds
   pass newTool
end newTool

on mainstackChanged pOldMainstack, pNewMainStack
   local tTarget
   put the long id of the target into tTarget
   if revIDEStackIsIDEStack(tTarget) then pass mainstackChanged
   
   local tParams
   put pOldMainstack into tParams[1]
   put pNewMainStack into tParams[2]
   put tTarget into tParams[3]
   send "ideMessageSendWithParameters" &&  "ideMainstackChanged,tTarget, tParams" to stack "revIDELibrary" in 0 milliseconds
   pass mainstackChanged
end mainstackChanged

on moveStack pLeft, pTop
   if the platform is "MacOS" then -- prevent stack getting stuck under menu bar
      if pTop < the bottom of stack revIDEPaletteToStackName("menubar") and the right of stack revTargetStack() < the right of stack revIDEPaletteToStackName("menubar") + 5 then
         set the top of stack revTargetStack() to the bottom of stack revIDEPaletteToStackName("menubar") + 20
      end if
   end if
   
   # IDE to notify any objects subscribed to the ideStackMoved Message
   local tLongID
   put the long id of the owner of the target into tLongID
   send "ideMessageSendWithTrigger" &&  "ideStackMoved, tLongID, tLongID" to stack "revIDELibrary" in 0 milliseconds
   pass moveStack
end moveStack

on mouseDown pButton
   local tTarget
   put the long id of the target into tTarget
   if revIDEStackIsIDEStack(tTarget) then pass mouseDown
   
   local tParams
   put pButton into tParams[1]
   put tTarget into tParams[2]
   
   send "ideMessageSendWithParameters" &&  "ideMouseDown, tTarget, tParams" to stack "revIDELibrary" in 0 milliseconds
   pass mouseDown
end mouseDown

on mouseUp pButton
   local tTarget
   put the long id of the target into tTarget
   if revIDEStackIsIDEStack(tTarget) then pass mouseUp
   
   local tParams
   put pButton into tParams[1]
   put tTarget into tParams[2]
   
   send "ideMessageSendWithParameters" &&  "ideMouseUp, tTarget, tParams" to stack "revIDELibrary" in 0 milliseconds
   pass mouseUp
end mouseUp

on mouseDoubleUp pButton
   local tTarget
   put the long id of the target into tTarget
   if revIDEStackIsIDEStack(tTarget) then pass mouseDoubleUp
   
   local tParams
   put pButton into tParams[1]
   put tTarget into tParams[2]
   
   send "ideMessageSendWithParameters" &&  "ideMouseDoubleUp, tTarget, tParams" to stack "revIDELibrary" in 0 milliseconds
   pass mouseDoubleUp
end mouseDoubleUp

on closeStackRequest
   # IDE to notify any objects subscribed to the ideCloseStackRequest Message
   local tLongID
   put the long id of the owner of the target into tLongID
   if revIDEStackIsIDEStack(tLongID) then pass closeStackRequest
   
   send "ideMessageSendWithTrigger" &&  "ideCloseStackRequest, tLongID, tLongID" to stack "revIDELibrary" in 0 milliseconds
   pass closeStackRequest
end closeStackRequest
