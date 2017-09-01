script "revOnlineStackBehavior"

# Need to initialise stack
on preOpenStack   
   --global gRevUseTestServer
   --put true into gRevUseTestServer
   revOnlinePrefLoad
   # Do this to prevent a resizeStack message being generated. We don't need this as we 
   # are already resizing. Remebers default size position of stack
   lock messages
   set the width of me to revOnlinePrefGet("width")
   set the height of me to revOnlinePrefGet("height")
   set the location of me to revOnlinePrefGet("location")
   unlock messages
   # Set the callback that will be sent if an internet connection is not available
   # in this case will just display a message in the tooltip
   revOnlineSetConnectionErrorCallback "rvoConnectionErrorDisplay", the long id of me
   # Temporary measure
   revOnlineSetAccountFailureCallback "rvoAccountFailureDisplay", the long id of me
   # Load the saved cache data
   revOnlineCacheLoad
   login  
   send "initialize" to group "search filter" of me
   send "initialize" to group "search order" of me
   send "initialize" to group "paging" of me
   send "initialize" to group "progressbar" of me
   send "initialize" to group "search list" of me
   send "initialize" to group "viewing pane" of me
   updateBannerImage
   updateView
   rvoResize
   --put "finished" after msg
end preOpenStack

on closeStack
   revOnlineCacheSave
end closeStack


# Wrapper needed to perform login attempt upon startup
private command login
   if revOnlineSession() is not empty then
      send "loggedInDisplay" to group "menubar" of me
   else
      if revOnlinePrefGet("rememberEmail") is true then
         local tEmail, tPassword
         put revOnlinePrefGet("Email") into tEmail
         if revOnlinePrefGet("rememberPassword") is true then
            put revOnlinePrefGet("passwordhash") into tPassword         
            revOnlineLogin tEmail, tPassword, "loginCallback", (the long id of me)
         else
            send "loggedOutDisplay" to group "menubar" of me
         end if
      else
         send "loggedOutDisplay" to group "menubar" of me
      end if
   end if   
end login

command loginCallback pSuccess
   if pSuccess then
      send "loggedInDisplay" to group "menubar" of me
   else
      send "loggedOutDisplay" to group "menubar" of me
   end if
end loginCallback

# If no connection then need to reflect this in the gui
command rvoConnectionErrorDisplay
   --revOnlineQueueClear
   set the cTooltip of group "progressbar" of me to "Connection failure"
   
   rvoDrawProgressBar 0
   rvoHideProgressBar
   --hide group "viewing pane" of me
end rvoConnectionErrorDisplay

# The parameter is to distinguish an actual resize stack message from a scripted one
# If pUpdate is true the resize will potentially cause a new search request
command rvoResize pUpdate
   # menubar
   set the rect of group "menubar" of me to \
          (the left of this card of me, the top of this card of me, the right of this card of me,52)
   send "resize" to group "Menubar" of me
   
   # progressbar
   set the rect of group "progressbar" of me to \
          (the left of this card of me, the bottom of this card of me - 25, the right of this card of me, the bottom of this card of me)   
   local tDivider1, tDivider2
   put the left of button "resize bar" of me - 1 into tDivider1
   put the left of button "resize bar" of me + 300 into tDivider2
   send "resize tDivider1, tDivider2" to group "progressbar" of me
   
   # search filter
   set the rect of group "search filter" of me to \
          (the left of this card of me, the bottom of group "menubar" of me, the left of button "resize bar" of me, the bottom of this card of me - 25)
   send "resize" to group "Search Filter" of me
   
   # search order
   set the rect of group "search order" of me to \
          (the right of group "search filter" of me, the bottom of group "menubar" of me, the right of group "search filter" of me + 284,the bottom of group "menubar" of me + 30)
   send "resize" to group "search order" of me
   
   # pages
   set the rect of group "paging" of me to \
          (the right of group "search filter" of me + 3, the bottom of group "search order" of me, the right of group "search filter" of me + 284, the bottom of group "search order" of me + 21)
   send "resize" to group "paging" of me    
   
   # resize bar
   --set the rect of button "resize bar" of me to \
          --(the left of button "resize bar" of me, the bottom of group "paging" of me, the left of button "resize bar" of me + 2, the top of group "progressbar" of me)
   
   # editing controls
   set the rect of group "edit controls" of me to \
          (the right of group "paging" of me, the bottom of group "search order" of me, the right of this card, the bottom of group "search order" of me + 21)
   send "resize" to group "edit controls" of me
   
   # search list
   if the cMode of group "search list" of me is "grid" then      
      set the rect of group "search list" of me to \
             (the right of button "resize bar" of me - 1, the bottom of group "paging" of me, the right of this card, the top of group "progressbar" of me)
   else      
      set the rect of group "search list" of me to \
             (the right of button "resize bar" of me - 1, the bottom of group "paging" of me, the right of group "search filter" of me + 302, the top of group "progressbar" of me)
   end if
   send "resize pUpdate" to group "Search List" of me
   
   # Viewing Pane
   set the rect of group "viewing pane" of me to \
          (the right of group "search list" of me, the bottom of group "paging" of me, the right of this card of me, the bottom of this card of me - 25)   
   send "resize" to group "Viewing pane" of me
   
   # resize bar
   --set the height of button "resize bar" of me to (the top of group "progressbar" of me - the bottom of group "paging" of me)
   --set the top of button "resize bar" of me to the bottom of group "paging" of me
   
   # Border
   set the rect of graphic "border" of me to \
          (the right of button "resize bar" of me - 1, the top of group "paging" of me - 1, the right of this card + 40, the bottom of this card)  
end rvoResize

command rvoUpdateSearchFilter
   send "intialize" to group "search filter" of me
end rvoUpdateSearchFilter

command rvoDeleteStack pStackId pCallback
   local tArray
   put "deleteStack" into tArray["action"]
   put pStackId into tArray["parameters"]["id"]
   put revOnlineSession() into tArray["parameters"]["sessionId"]
   revOnlineQueryServer tArray, false, "get", pCallback
   return the result
end rvoDeleteStack

#   Returns an array containing all appropriate properties for the specified user.
command rvoFetchStackData pStackId, pCallback, pPrioritize
   # Generate array request
   local tArray
   put "fetchStackData" into tArray["action"]
   put pStackId  into tArray["parameters"]["id"]
   # Send the array to the CGI script, and call pCallback when done.
   revOnlineQueryServer tArray, false, "get", pCallback, true, pPrioritize
   
   return the result
end rvoFetchStackData

# Parameters
#   pObjectType : one of the supported revOnline object types, e.g "stack", "external" etc
#   pTag : the tag name to search for, could be empty if not searching by tag
#   pQuery : the search query as specified by the search filter group
#   pUserId : the user id to filter with. If empty, all users stacks are searched, otherwise only stacks where the user id matches are returned.
#   pSearchType : one of the following:
#      - "all" means all results are returned and if pQuery is empty, in a-z order, otherwise order of relevance to the search query
#      - "top rated" means that a server specified number of results is returned, ordered by rating.
#      - "latest" means that a server specified number of results is returned, ordered by date modified
#      - "popular" means that a server specified number of results is returned, ordered by number of downloads
#   pOffset : tells the server to start returning results at this offset in the search
#   pMaxLength : the maximum number of results to return.
#   pCallback : the callback to send when done.
# Description
#   Returns an ordered array containing all the text data from the search results. pUserId will always be empty for now
#   as the GUI is not going to initially support user filtering.
command rvoSearchStacks pParameters, pCallback, pPrioritize
   local tRequest, tParameters
   revOnlinePrefSet "lastSearch", pParameters
   put pParameters into tParameters
   put "searchStacks" into tRequest["action"]
   put tParameters into tRequest["parameters"]
   revOnlineQueryServer tRequest, "false", "get", pCallback, false, pPrioritize
   return the result
end rvoSearchStacks

# Parameters
#   pObjectType : one of the supported revOnline object types, e.g "stack", "external" etc.
#   pOrdering : server defined ordering, e.g "alphabetical", "popular".
#   pOffset : tells the server to start returning tags at this offset in whatever the current ordering is.
#   pLength : the number of tags we want returned.
#   pCallback : the callback to send when done.
# Description
#  When done, calls pCallback with an ordered return-delimited list of tags.
command rvoListTags pObjectType, pOrdering, pOffset, pLength, pCallback, pStackId, pUserId, pPrioritize
   local tParameters
   put pObjectType into tParameters["objectType"]
   put pOrdering into tParameters["ordering"]
   put pOffset into tParameters["offset"]
   put pLength into tParameters["length"]
   put pStackId into tParameters["stackid"]
   put pUserId into tParameters["userid"]
   
   local tRequest
   put "listTags" into tRequest["action"]
   put tParameters into tRequest["parameters"]
   
   revOnlineQueryServer tRequest, "false", "get", pCallback, true, pPrioritize
   return the result
end rvoListTags

command rvoListTypes pCallback
   local tRequest
   put "listTypes" into tRequest["action"]
   revOnlineQueryServer tRequest, "false", "get", pCallback
   return the result
end rvoListTypes

command rvoFetchStackProperty pStackId, pProperty, pCallback, pPrioritize
   local tArray
   put "fetchStackProperty" into tArray["action"]
   put pStackId into tArray["parameters"]["id"]
   put pProperty into tArray["parameters"]["propertyName"]
   revOnlineQueryServer tArray, false, "get", pCallback, true, pPrioritize
   return the result
end rvoFetchStackProperty

command rvoLaunchStack pStackId
   local tCallback
   put revCallbackCreate(the long id of me, "rvoLaunchStackCallback") into tCallback
   rvoUpdateTooltip "Downloading stack"  
   lock cursor
   set the cursor to watch
   revOnlineSetStatusCallback "rvoUpdateProgress", the long id of me
   rvoFetchStackProperty pStackId, "data", tCallback
end rvoLaunchStack

# Updates progressbar in response to uploading and downloading
command rvoUpdateProgress pUrl, pStatus
   local tPercentage
   put 0 into tPercentage
   
   if pStatus is among the words of "contacted requested" then
      put 0 into tPercentage
   end if
   
   if item 1 of pStatus is "loading" or item 1 of pStatus is "uploading" then
      local tReceived
      put item 2 of pStatus into tReceived
      local tTotal
      put item 3 of pStatus into tTotal
      put round((tReceived / tTotal) * 100) into tPercentage
   end if
   
   if pStatus is "uploaded" or pStatus is "downloaded" then
      put 100 into tPercentage
   end if
   if pStatus is "error" or pStatus is "timeout" then
      put 0 into tPercentage
   end if
   rvoDrawProgressBar tPercentage
end rvoUpdateProgress

# Draws the progressbar and puts text into the tooltip field
command rvoDrawProgressBar pPercent, pMessage
   
   if pPercent < 100 then
      send "update pPercent, rvoHiliteColor(), false" to group "loading progress" of group "progressBar" of me
      if pMessage is not empty then
         rvoUpdateTooltip pMessage
      end if
      --show group "loading progress" of group "progressBar" of stack "revonline"
   else
      send "update 100, rvoHiliteColor(), false" to group "loading progress" of group "progressBar" of me
      if pMessage is not empty then
         send "rvoClearTooltip pMessage" to me in 500 milliseconds
      end if
      --send "rvoDrawProgressBar 0" to me in 500 milliseconds
      send "rvoHideProgressBar" to me in 500 milliseconds
   end if
   show group "loading progress" of group "progressBar" of me
end rvoDrawProgressBar

command rvoHideProgressBar   
   hide group "loading progress" of group "progressBar" of me
end rvoHideProgressBar


# Hide progressbar
command hideProgress
   hide group "loading progress" of group "progressBar" of me
end hideProgress

# Returns the standard hilite color for revonline
function rvoHiliteColor
   return revEnvironmentEditionProperty("revonline_hilite_color")
end rvoHiliteColor

command rvoLaunchStackCallback pResult
   unlock cursor
   if pResult["result"]["data"] is not empty then
      rvoUpdateTooltip "Stack downloaded", true
      # Need to remove all searches that could potentially contain this stack
      # as popular will now have changed
      revOnlineCacheRemoveAction "searchStacks"
      # stack has been updated so must clear cache of its details
      local tArray, tKey
      put "fetchStackData" into tArray["action"]
      put pResult["stack_id"] into tArray["parameters"]["id"]
      put revOnlineEncodeArray(tArray) into tKey      
      revOnlineCacheRemove tKey
   else
      rvoUpdateTooltip "error"
   end if
   # Prevents problem with users stacks throwing errors on startup
   try
      go stack pResult["result"]["data"]
   catch tError
      
   end try
end rvoLaunchStackCallback
   
   


#   Returns an array containing all appropriate properties for the specified user.
--command rvoFetchUserData pUserEmail, pCallback, pPrioritize
command rvoFetchUserData pUserId, pCallback, pPrioritize
   # Generate array request
   local tArray
   put "fetchUserData" into tArray["action"]
   put pUserId  into tArray["parameters"]["id"]
   # Send the array to the CGI script, and call pCallback when done.
   revOnlineQueryServer tArray, false, "get", pCallback, true, pPrioritize
   return the result
end rvoFetchUserData

--command rvoFetchUserProperty pUserEmail, pProperty, pCallback, pPrioritize
command rvoFetchUserProperty pUserId, pProperty, pCallback, pPrioritize
   local tArray
   put "fetchUserProperty" into tArray["action"]
   put pUserId into tArray["parameters"]["id"]
   put pProperty into tArray["parameters"]["propertyName"]
   # Send the array to the CGI script, and call pCallback when done.
   revOnlineQueryServer tArray, false, "get", pCallback, true, pPrioritize
   return the result
end rvoFetchUserProperty

# Needs to be changed to a post instead of get
command rvoSetUserData pUserData, pCallBack
   local tArray
   put "setUserData" into tArray["action"]
   ###put pUserEmail into tArray["parameters"]["email"]
   --put revOnlineEmail() into tArray["parameters"]["email"]
   put pUserData into tArray["parameters"]["userData"]
   ##put the text of field "sessionId" into tArray["parameters"]["sessionId"]
   put revOnlineSession() into tArray["parameters"]["sessionId"]
   revOnlineQueryServer tArray, false, "post", pCallback
   return the result
end rvoSetUserData

# Needs to be changed to a post instead of get
command rvoSetStackData pStackData, pStackId, pCallBack
   local tArray
   put "setStackData" into tArray["action"]
   put pStackData into tArray["parameters"]["stackData"]
   put pStackId into tArray["parameters"]["stackid"]
   put revOnlineSession() into tArray["parameters"]["sessionId"]
   
   # Progressbar
   revOnlineSetStatusCallback "rvoUpdateProgress", the long id of me
   
   revOnlineQueryServer tArray, false, "post", pCallback
   return the result
end rvoSetStackData

command rvoIsStackRateable pStackId, pRevision, pCallBack
   local tArray
   put "isStackRateable" into tArray["action"]
   put pStackId into tArray["parameters"]["id"]
   put pRevision into tArray["parameters"]["revision"]
   put revOnlineSession() into tArray["parameters"]["sessionId"]
   revOnlineQueryServer tArray, false, "get", pCallback
   return the result
end rvoIsStackRateable

command rvoRateStack pStackId, pRating, pRevision, pCallBack
   rvoUpdateTooltip "Submitting rating ..."
   local tArray
   put "rateStack" into tArray["action"]
   put pStackId into tArray["parameters"]["id"]
   put pRevision into tArray["parameters"]["revision"]
   put pRating into tArray["parameters"]["rating"]
   put revOnlineSession() into tArray["parameters"]["sessionId"]
   revOnlineQueryServer tArray, false, "get", pCallback
   return the result
end rvoRateStack

command rvoTagStack pStackId, pTag, pCallBack
   local tArray
   put "tagStack" into tArray["action"]
   put pStackId into tArray["parameters"]["stackid"]
   put pTag into tArray["parameters"]["name"]
   put revOnlineSession() into tArray["parameters"]["sessionId"]
   revOnlineQueryServer tArray, false, "get", pCallback
end rvoTagStack

command rvoEditTags pStackId, pTags, pCallback
   local tArray
   put "editTags" into tArray["action"]
   put pStackId into tArray["parameters"]["stackid"]
   --put pTag into tArray["parameters"]["name"]
   put pTags into tArray["parameters"]["tagList"]
   put revOnlineSession() into tArray["parameters"]["sessionId"]
   revOnlineQueryServer tArray, false, "get", pCallback
end rvoEditTags

#####################################################################
# Utility Functions
######################################################################

local sCallbackLastHandle, sCallBacks, sLastCallback

command log pMessage
   put pMessage & return after msg
end log

command logArray pArray
   local tOutput
   logArrayRecurse pArray, 0, tOutput
   log tOutput
end logArray

command logArrayRecurse pArray pIndent, @rOutput
   local tOutput
   local tIndent
   put pIndent into tIndent
   repeat for each key tKey in pArray
      if the keys of pArray[tKey] is empty then
         repeat with x = 1 to pIndent
            put tab after rOutput
         end repeat
         put tKey && ":" && pArray[tKey] & return after rOutput
      else
         add 1 to tIndent
         repeat with x = 1 to pIndent
            put tab after rOutput
         end repeat
         put tKey && "-" && return after rOutput
         logArrayRecurse pArray[tKey], tIndent, rOutput
      end if
   end repeat  
end logArrayRecurse

local sRequestQueue
local sPendingRequests
local sLastOffset

command updateSearchList pOffset, pPrioritize
   local tOffset
   # Need to preserve the offset if the search is updated due to a resize
   if pOffset is empty then
      # need to make sure item 1 is somewhere on the newly created page
      local tNewPage
      put trunc(sLastOffset / (the cPageLimit of group "search list" of me)) into tNewPage
      put (the cPageLimit of group "search list" of me) * tNewPage into tOffset
      set the cPage of group "paging" of me to tNewPage + 1
   else
      put pOffset into tOffset
   end if
   
   if tOffset is 0 then
      set the cPages of group "paging" of me to empty
      set the cPage of group "paging" of me to 1      
   end if
   
   local tParameters
   put the cSelectedUser of group "search filter" of me into tParameters["userid"]
   put the cSelectedType of group "search filter" of me into tParameters["objectType"]
   if the cSelectedTag of group "search filter" of me is "all" then
      put empty into tParameters["tag"]
   else
      put the cSelectedTag of group "search filter" of me into tParameters["tag"]
   end if
   put the cSearchString of group "search filter" of me into tParameters["query"]  
   put the cSelectedOrder of group "search order" of me into tParameters["searchType"]
   put the cSelectedDirection of group "search order" of me into tParameters["direction"]
   
   put tOffset into tParameters["offset"]
   put the cPageLimit of group "search list" of me into tParameters["maxlength"]
   put tOffset into sLastOffset
   
   local tCallback
   put revCallbackCreate(the long id of me, "updateSearchListCallback") into tCallback
   
   rvoCancelSearch
   rvoRegisterSearchStart
   rvoSearchStacks tParameters, tCallback, pPrioritize
   rvoRegisterSearchRequest the result
end updateSearchLIst


# Now populate the list etc.
command updateSearchlistCallback pResult
   local tResultCount
   put pResult["resultCount"] into tResultCount
   local tPages, tTruncPages, tPageLimit, tStacksOnCurrentPage, tTotalStacksOnline
   put the cPageLimit of group "search list" of me into tPageLimit
   put tResultCount / tPageLimit into tPages
   put trunc(tPages) into tTruncPages
   # prevent an extra blank page
   if tPages - tTruncPages <> 0 then
      put tTruncPages + 1 into tPages
   end if
   
   ## New stuff
   put the number of elements of pResult["results"] into tStacksOnCurrentPage
   put pResult["totalStackCount"] into tTotalStacksOnline
   send "updateNumberOfStacks tStacksOnCurrentPage, tResultCount, tTotalStacksOnline" to group "ProgressBar" of me
   
   set the cPages of group "paging" of me to tPages    
   set the cList of group "search list" of me to pResult["results"]
end updateSearchlistCallback

command updateViewingPane pViewType, pObjectId
   --put "stuff" after msg
   # Check viewing pane pref
   if pViewType is empty then
      set the cViewType of group "viewing pane" of me to revOnlinePrefGet("view type")
   else
      revOnlinePrefSet "view type", pViewType
      set the cViewType of group "viewing pane" of me to pViewType
   end if
   
   # Set content of viewing pane
   if the cViewType of group "viewing pane" of me is "stack" then
      if pObjectId is not empty then
         set the cStack of group "stack" of me to pObjectId
         if pObjectId is not "new" then
            --rvoUpdateTooltip "Retrieving stack details"
            revOnlinePrefSet "stack Id", pObjectId
         end if
      else
         set the cStack of group "stack" of me to revOnlinePrefGet("stack id")
      end if
   else if the cViewType of group "viewing pane" of me is "user" then
      --rvoUpdateTooltip "Retrieving user details ..."
      if pObjectId is not empty then
         set the cUser of group "user" of me to pObjectId
         revOnlinePrefSet "user Id", pObjectId
      else
         set the cUser of group "user" of me to revOnlinePrefGet("user id")
      end if
   end if
end updateViewingPane

# Will adjust list and viewing pane groups appropriately
command updateView pMode, pView, pId
   --put "id:" && pId && return after msg
   lock screen
   local tPreviousMode
   put the cMode of group "search list" of me into tPreviousMode
   
   # Check mode prefs list/grid
   if pMode is not empty then
      set the cMode of group "search list" of me to pMode
      revOnlinePrefSet "mode", pMode
   else
      set the cMode of group "search list" of me to revOnlinePrefGet("mode")
   end if   
   
   # Clear editing controls
   send "hideAll" to group "edit controls" of me
   
   if the cMode of group "search list" of me is "list" then
      set the cSelectedView of group "search order" of me to "list"
      # Need to check what type of content will be displayed in viewing pane
      local tViewType
      if pView is empty then
         put revOnlinePrefGet("view type") into tViewType
      else
         put pView into tViewType         
      end if
      # Now update viewing pane accordingly
      # If the content type is stack, no stacks have previously been viewed and pId is empty
      # then need to choose a random stack
      if tViewType is "stack" and pId is empty and revOnlinePrefGet("stack id") is empty then
         local tCallback
         put revCallbackCreate(the long id of me, "updateViewingPane") into tCallback
         revCallbackAddParameter tCallback, pView
         revOnlinePickRandomStack tCallback
      else
         updateViewingPane pView, pId
      end if
   else if the cMode of group "search list" of me is "grid" then
      set the cSelectedView of group "search order" of me to "grid"
   end if   
   
   rvoResize   
   # Need to make sure the searchlist is updated when switching between grid/list
   if (pMode is "list" and tPreviousMode is "grid") or (pMode is "grid" and tPreviousMode is "list") then
      updateSearchList empty, true
   end if
   unlock screen
end updateView

# Updates the tooltip field with a message, if pWithClear is true then the tooltip
# will be cleared after a set period of time.  With wait ensures the message will
# display for a minimum time period
command rvoUpdateTooltip pMessage, pWithClear, pWithWait
   if pMessage is "bad_login" or pMessage is "cgierror,not_logged_in" then
      set the cTooltip of group "progressbar" of me to "You are not logged in"
      send "loggedOutDisplay" to group "menubar" of me
   else
      set the cTooltip of group "progressbar" of me to pMessage
   end if
   if pWithWait then
      set the cWait of group "progressbar" of me to "true"
   end if
   if pWithClear then
      send "rvoClearTooltip pMessage" to me in 3 seconds
   end if
end rvoUpdateTooltip

command rvoClearTooltip pMessage
   --put the cTooltip of group "progressbar" of me
   if the cTooltip of group "progressbar" of me is pMessage then
      set the cTooltip of group "progressbar" of me to empty
   end if
end rvoClearTooltip

on resizestack
   revOnlinePrefSet "width", the width of me
   revOnlinePrefSet "height", the height of me
   revOnlinePrefSet "location", the location of me   
   if the short name of this card is "main" then
      rvoresize "true"
   end if
end resizestack

# Handlers to remember default location/size
on moveStack
   send "revOnlineUpdateOnStackMoved" to me in 0 milliseconds
end moveStack

command revOnlineUpdateOnStackMoved
   if the iconic of me then
      exit revOnlineUpdateOnStackMoved
   end if
   revOnlinePrefSet "location", the location of me
end revOnlineUpdateOnStackMoved


function capitaliseChar1 pString
   return ((toUpper(char 1 of pString)) & char 2 to - 1 of pString)
end capitaliseChar1


local sSearchRequests

# Description
#   Registers the beginning of a new stack search. Clearing out any previous ones. This should be called
#   In updateSearchList before the searchStacks query is sent out.
command rvoRegisterSearchStart
   put empty into sSearchRequests
end rvoRegisterSearchStart

# Parameters
#   pId : a queue request id as returned by revOnlineQueryServer
# Description
#   Registers the specified id as part of the current search. This means that this request will be cancelled
#   when rvoCancelSearch is called.
command rvoRegisterSearchRequest pId
   if sSearchRequests is empty then
      put pId into sSearchRequests
   else
      put return & pId after sSearchRequests
   end if
end rvoRegisterSearchRequest
   
# Description
#   Cancels the current search by cancelling all requests that have been registered as part of it.
command rvoCancelSearch
   repeat for each line tRequest in sSearchRequests
      --put tRequest & return after msg
      revOnlineQueueCancel tRequest
   end repeat
   put empty into sSearchRequests
end rvoCancelSearch

### Temporary
command rvoAccountFailureDisplay
   set the cTooltip of group "progressbar" of me to "A valid license is required to create a RevOnline account"
end rvoAccountFailureDisplay

# Used by "share this stack" item in file menu of revmenubar
command rvoShareThisStack pStackPath
   --put "!!!" & return after msg
   lock screen  
   updateView "list", "stack", "new"   
   send "newStackFile pStackPath" to group "stack" of group "viewing pane" of me
   unlock screen
   --put "finished Shre" & return after msg
end rvoShareThisStack

on updateBannerImage
   local tPath
   
   if char 1 of the version < 7 then
      put ideCoreFolderPath("skin","revOnline-top_legacy.png") into tPath
   else
      put ideCoreFolderPath("skin","revOnline-top.png") into tPath
   end if
   set the filename of image "topBanner" of group "menubar" to tPath
   set the width of image "topBanner" of group "menubar" to the formattedWidth of image "topBanner"
   set the topLeft of image "topBanner" of group "menubar" to 0,0
end updateBannerImage





