script "revIdeMessageHandlerLibrary"
on extensionInitialize
   if the target is not me then
      pass "extensionInitialize"
   end if	
   insert the script of me into front
end extensionInitialize

on extensionFinalize
   if the target is not me then
      pass "extensionFinalize"
   end if
   remove the script of me from front
end extensionFinalize

#################################
# Messages handled and sent on to object
#################################
local sSelectingObjects
on selectedObjectChanged
   if not sSelectingObjects and \
         not revIDEObjectIsOnIDEStack(the long id of the target) then
      send "ideMessageSend" &&  "ideSelectedObjectChanged" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass selectedObjectChanged
end selectedObjectChanged

on objectSelectionStarted
   if not revIDEObjectIsOnIDEStack(the long id of the target) then
      put true into sSelectingObjects
      send "ideMessageSend" &&  "ideObjectSelectionStarted" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass objectSelectionStarted
end objectSelectionStarted

on objectSelectionEnded
   if not revIDEObjectIsOnIDEStack(the long id of the target) then
      put false into sSelectingObjects
      send "ideMessageSend" &&  "ideSelectedObjectChanged" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass objectSelectionEnded
end objectSelectionEnded

on resizeControl
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend" &&  "ideResizeControl,tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass resizeControl
end resizeControl

on resumeStack
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend" &&  "ideResumeStack","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass resumeStack
end resumeStack

on newCard
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend" &&  "ideNewCard","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass newCard
end newCard

on newStack
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend" &&  "ideNewStack","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass newStack
end newStack

on newField
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass newField
end newField

on newGraphic
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass newGraphic
end newGraphic

on newGroup
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend" && "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass newGroup
end newGroup

on newImage
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass newImage
end newImage

on newPlayer
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass newPlayer
end newPlayer

on newScrollbar
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass newScrollbar
end newScrollbar

on newButton
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass newButton
end newButton

on newWidget
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend" &&  "ideNewControl","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass newWidget
end newWidget

on deleteButton
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend" && "ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass deleteButton
end deleteButton

on deleteCard
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend" &&  "ideCardDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass deleteCard
end deleteCard
   
on deleteEPS
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass deleteEPS
end deleteEPS

on deleteField
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then   
      send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds 
   end if
   pass deleteField
end deleteField

on deleteGraphic
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass deleteGraphic
end deleteGraphic

on deleteGroup
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass deleteGroup
end deleteGroup

on deleteImage
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass deleteImage
end deleteImage

on deletePlayer
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then   
      send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass deletePlayer
end deletePlayer

on deleteScrollbar
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass deleteScrollbar
end deleteScrollbar

on deleteWidget 
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then   
      send "ideMessageSend ideControlDeleted","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass deleteWidget
end deleteWidget

on deleteStack
   local tLongID
   -- deleteStack is sent to the card, so the owner of the target is the stack
   put the long id of the owner of the target into tLongID
   if not revIDEStackIsIDEStack(tLongID) then
      send "ideMessageSend ideStackDeleted","tLongID" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass deleteStack
end deleteStack

on libraryStack
   local tTarget
   put the long id of the target into tTarget
   if revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend ideLibraryStack","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass libraryStack
end libraryStack

on releaseStack
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      send "ideMessageSend ideReleaseStack","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass releaseStack
end releaseStack

on nameChanged pOldName, pNewName
   local tTarget, tParams
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then   
      put pOldName into tParams[1]
      put pNewName into tParams[2]
      put tTarget into tParams[3]
      send "ideMessageSendWithParameters ideNameChanged,tTarget,tParams" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass nameChanged
end nameChanged

on openCard
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then   
      send "ideMessageSend" &&  "ideOpenCard","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass openCard
end openCard

on openStack
   local tTarget
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then   
      send "ideMessageSend" &&  "ideOpenStack","tTarget" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass openStack
end openStack

--PM-2015-10-05: [[ Bug 16099 ]] choose pointer/browse tool does not update Tools palette
on newTool pTool
   send "ideMessageSend" &&  "ideToolChanged" to stack "revIDELibrary" in 0 milliseconds
   pass newTool
end newTool

on mainstackChanged pOldMainstack, pNewMainStack
   local tTarget, tParams
   put the long id of the target into tTarget
   if not revIDEStackIsIDEStack(tTarget) then
      put pOldMainstack into tParams[1]
      put pNewMainStack into tParams[2]
      put tTarget into tParams[3]
      send "ideMessageSendWithParameters" &&  "ideMainstackChanged,tTarget, tParams" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass mainstackChanged
end mainstackChanged

on moveStack pLeft, pTop
   local tMenuBar
   if the platform is "MacOS" then -- prevent stack getting stuck under menu bar
      put revIDEPaletteToStackName("menubar") into tMenuBar
      if pTop < the bottom of stack tMenuBar and the right of stack revTargetStack() < the right of stack tMenuBar + 5 then
         set the top of stack revTargetStack() to the bottom of stack tMenuBar + 20
      end if
   end if
   
   # IDE to notify any objects subscribed to the ideStackMoved Message
   local tLongID
   -- moveStack is sent to the card, so the owner of the target is the stack
   put the long id of the owner of the target into tLongID
   send "ideMessageSendWithTrigger" &&  "ideStackMoved, tLongID, tLongID" to stack "revIDELibrary" in 0 milliseconds
   pass moveStack
end moveStack

on moveControl
   # IDE to notify any objects subscribed to the ideControlMoved Message
   local tLongID
   put the long id of the target into tLongID
   send "ideMessageSendWithTrigger" &&  "ideControlMoved, tLongID, tLongID" to stack "revIDELibrary" in 0 milliseconds
   pass moveControl
end moveControl

on mouseMove pX, pY
   local tTarget, tParams
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      put pX into tParams[1]
      put pY into tParams[2]
      put tTarget into tParams[3]
      send "ideMessageSendWithParameters" &&  "ideMouseMove, tTarget, tParams" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass mouseMove
end mouseMove

on mouseDown pButton
   local tTarget, tParams
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      put pButton into tParams[1]
      put tTarget into tParams[2]
      send "ideMessageSendWithParameters" &&  "ideMouseDown, tTarget, tParams" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass mouseDown
end mouseDown

on mouseUp pButton
   local tTarget, tParams
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      put pButton into tParams[1]
      put tTarget into tParams[2]
      send "ideMessageSendWithParameters" &&  "ideMouseUp, tTarget, tParams" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass mouseUp
end mouseUp

on mouseDoubleUp pButton
   local tTarget, tParams
   put the long id of the target into tTarget
   if not revIDEObjectIsOnIDEStack(tTarget) then
      put pButton into tParams[1]
      put tTarget into tParams[2]
      send "ideMessageSendWithParameters" &&  "ideMouseDoubleUp, tTarget, tParams" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass mouseDoubleUp
end mouseDoubleUp

on closeStackRequest
   # IDE to notify any objects subscribed to the ideCloseStackRequest Message
   local tLongID
   -- closeStackRequest is sent to the card, so the owner of the target is the stack
   put the long id of the owner of the target into tLongID
   if not revIDEStackIsIDEStack(tLongID) then   
      send "ideMessageSendWithParameters" &&  "ideCloseStackRequest, tLongID, tLongID" to stack "revIDELibrary" in 0 milliseconds
   end if
   pass closeStackRequest
end closeStackRequest

on msgChanged pHandler, pLine
   local tTarget
   put the long id of the target into tTarget
   
   local tParams
   put tTarget into tParams[1]
   put pHandler into tParams[2]
   put pLine into tParams[3]
   put msg into tParams[4]
   send "ideMessageSendWithParameters" &&  "ideMsgChanged, tTarget, tParams" to stack "revIDELibrary" in 0 milliseconds
   pass msgChanged
end msgChanged

on logChanged pLog
   send "ideMessageSend ideExtensionLog, pLog" to stack "revIDELibrary" in 0 milliseconds
end logChanged

on desktopChanged
   send "ideMessageSend ideDesktopChanged" to stack "revIDELibrary" in 0 milliseconds
   pass desktopChanged
end desktopChanged
