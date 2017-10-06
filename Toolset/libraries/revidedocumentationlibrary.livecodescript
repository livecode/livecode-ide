script "revIDEDocumentationLibrary"
on revLoadLibrary
   if the target is me then
      insert the script of me into back
   end if
end revLoadLibrary

on revUnloadLibrary
   if the target is me then
      remove script of me from back
   end if
end revUnloadLibrary

private on ideDocsEnsureDatabase pLocation
   if there is not a file (pLocation & slash & "api.sqlite") then
      put url ("binfile:" & revIDESpecialFolderPath("API") & slash & "api.sqlite") into \
            url ("binfile:" & pLocation & slash & "api.sqlite")
   end if
end ideDocsEnsureDatabase

local sConnectionsA
command ideDocsInitialize pDistributed
   If pDistributed is true and revEnvironmentIsInstalled() then
      ideThrow "can't write to installed IDE"
      return empty
   end if
   
   local tConnection, tLocation, tKey
   if pDistributed is true then
      put "ide" into tKey
      put revIDESpecialFolderPath("API") into tLocation
   else
      put "cache" into tKey
      put revIDESpecialFolderPath("documentation cache") into tLocation
      ideDocsEnsureDatabase tLocation
   end if
   put sConnectionsA[tKey] into tConnection
   
   if tConnection is among the items of revOpenDatabases() then
      return tConnection
   end if
   
   dispatch "revDocsOpenAPIDatabase" to stack "revDocsParser" with tLocation
   put the result into tConnection
   if tConnection is not a number then
      ideThrow "unable to open database", tConnection
   end if
   
   put tConnection into sConnectionsA[tKey]
   return tConnection
end ideDocsInitialize

private function __fetchDocsData pEntryName, pLibraryName, pType
   # Ensure we have a connection
   local tConnection
   try
      ideDocsInitialize
      put the result into tConnection
   catch tError
      return tError
   end try
   
   # Find the library id
   local tSQL, tLibraryID, tResult
   if pLibraryName is not empty then
      # Get the library's escaped name
      local tLibName
      dispatch function "revDocsModifyForUrl" to stack "revDocsParser" with pLibraryName
      put the result into tLibName
      
      put "SELECT library_id FROM libraries WHERE library_name = :1" into tSQL
      put revDataFromQuery(comma, return, sConnection, tSQL, "tLibName") into tLibraryID
      
      put the result into tResult
      if tResult is not a number then
         return "error finding library id for" && pLibraryName & return & tResult
      end if
   end if
   
   local tRecordSet, tData, tDataSet, tParamCount
   
   put "SELECT entry_data from dictionary_data" into tSQL
   
   local tWhere
   if pEntryName is not empty then
      put "entry_name" into tWhere[1]
   end if
   if pType is not empty then
      put "entry_type" into tWhere[2]
   end if
   if pLibraryName is not empty then
      put "library_id" into tWhere[3]
   end if
   
   local tWhereString
   repeat with x = 1 to 3
      if tWhere[x] is not empty then
         if tWhereString is empty then
            put " WHERE" && tWhere[x] & "=:" & x into tWhereString
         else
            put " AND" && tWhere[x] & "=:" & x after tWhereString
         end if
      end if
   end repeat
   
   put tWhereString after tSQL
   
   local tEntryName
   put tolower(pEntryName) into tEntryName
   
   # Execute the query, keeping the record set ID.
   put revQueryDatabase(sConnection, tSql, "tEntryName", "pType", "tLibraryID") into tRecordSet
   if the result is not a number then
      return "entry" && tEntryName && "not found" & return & the result
   end if
   
   # Get the docs data from the record set
   local tCount, tMoreRecords
   put true into tMoreRecords
   repeat while tMoreRecords
      add 1 to tCount
      get revDatabaseColumnNamed(tRecordSet, "entry_data", "tData")
      put tData into tDataSet[tCount]
      revMoveToNextRecord tRecordSet
      put the result into tMoreRecords
   end repeat
   
   # Close the record set
   revCloseCursor tRecordSet
   
   return tDataSet
end __fetchDocsData

private function __ideDocsFetchData pEntryName, pLibraryName, pType
   # Fetch the data
   local tData
   put __fetchDocsData(pEntryName, pLibraryName, pType) into tData
   
   if tData[1] is empty then
      return empty
   end if
   
   repeat for each key tCount in tData
      put arrayDecode(tData[tCount]) into tData[tCount]
   end repeat
   
   # Return the decoded array
   return tData
end __ideDocsFetchData

private function ideDocsFetchElementOfType pEntryName, pLibraryName, pType, pElement
   local tDataA
   put __ideDocsFetchData(pEntryName, pLibraryName, pType) into tDataA
   
   return tDataA[1][pElement]
end ideDocsFetchElementOfType

private function ideDocsFetchDataOfType pEntryName, pLibraryName, pType
   local tDataA
   put  __ideDocsFetchData(pEntryName, pLibraryName, pType) into tDataA
   return tDataA[1]
end ideDocsFetchDataOfType

private function ideDocsFetchData pEntryName, pLibraryName
   return __ideDocsFetchData(pEntryName, pLibraryName)
end ideDocsFetchData

/* 
Fetch the data for LiveCode script dictionary entries with name <pEntryName>

Returns:
A numerically keyed array, each element of which is the array
of data 
pertaining to a  LiveCode script dictionary entry with the given name.
*/
function ideDocsFetchLCSData pEntryName
   return ideDocsFetchData(pEntryName, "LiveCode Script")
end ideDocsFetchLCSData

/* 
Fetch the data for the LiveCode script dictionary entry with name <pEntryName>
and type <pType>

Returns:
An array
of data pertaining to the unique LiveCode script dictionary entry with the 
given name and type.
*/
function ideDocsFetchLCSDataOfType pEntryName, pType
   return ideDocsFetchDataOfType(pEntryName, "LiveCode Script", pType)
end ideDocsFetchLCSDataOfType

/* 
Fetch a specific element of the array of data for the LiveCode script dictionary entry 
with name <pEntryName> and type <pType>.

Returns:
Either a string or an array
of data describing the element of the array of data
pertaining to the LiveCode script dictionary entry with the given name and type.
*/
function ideDocsFetchLCSElementOfType pEntryName, pType, pElement
   return ideDocsFetchElementOfType(pEntryName, "LiveCode Script", pType, pElement)
end ideDocsFetchLCSElementOfType

/* 
Fetch all docs element of the given type in the LiveCode script dictionary.

Returns:
A numerically keyed array of data, each element of which is an array of data
pertaining to a LiveCode script dictionary entry with the given type.
*/
function ideDocsFetchLCSElementsOfType pType
   return __ideDocsFetchData("", "LiveCode Script", pType)
end ideDocsFetchLCSElementsOfType

/* 
Fetch the data for LiveCode builder dictionary entries with name <pEntryName>

Returns:
A numerically keyed array, each element of which is the array
of data 
pertaining to a LiveCode builder dictionary entry with the given name.
*/
function ideDocsFetchLCBData pEntryName
   return ideDocsFetchData(pEntryName, "LiveCode Builder")
end ideDocsFetchLCBData

/* 
Fetch the data for the LiveCode builder dictionary entry with name <pEntryName>
and type <pType>

Returns:
An array
of data pertaining to the unique LiveCode builder dictionary entry with the 
given name and type.
*/
function ideDocsFetchLCBDataOfType pEntryName, pType
   return ideDocsFetchDataOfType(pEntryName, "LiveCode Builder", pType)
end ideDocsFetchLCBDataOfType

/* 
Fetch a specific element of the array of data for the LiveCode builder dictionary entry 
with name <pEntryName> and type <pType>.

Returns:
Either a string or an array
of data describing the element of the array of data
pertaining to the LiveCode builder dictionary entry with the given name and type.
*/
function ideDocsFetchLCBElementOfType pEntryName, pType, pElement
   return ideDocsFetchElementOfType(pEntryName, "LiveCode Builder", pType, pElement)
end ideDocsFetchLCBElementOfType

/* 
Fetch all docs element of the given type in the LiveCode builder dictionary.

Returns:
A numerically keyed array of data, each element of which is an array of data
pertaining to a LiveCode builder dictionary entry with the given type.
*/
function ideDocsFetchLCBElementsOfType pType
   return __ideDocsFetchData("", "LiveCode Builder", pType)
end ideDocsFetchLCBElementsOfType

/* 
Fetch the data for entries in the API for extension <pID> with name <pEntryName>

Returns:
A numerically keyed array, each element of which is the array
of data 
pertaining to an entry in the API for the given extension with the given name.
*/
function ideDocsFetchExtensionData pID, pEntryName
   local tLibraryName
   put revIDEExtensionProperty(pID, "title") into tLibraryName
   return ideDocsFetchData(pEntryName, tLibraryName)
end ideDocsFetchExtensionData

/* 
Fetch the data for the entry in the API for extension <pID> with name <pEntryName>
and type <pType>

Returns:
An array
of data pertaining to the unique entry in the API for the given extension with the 
given name and type.
*/
function ideDocsFetchExtensionDataOfType pID, pEntryName, pType
   local tLibraryName
   put revIDEExtensionProperty(pID, "title") into tLibraryName
   return ideDocsFetchDataOfType(pEntryName, tLibraryName, pType)
end ideDocsFetchExtensionDataOfType

/* 
Fetch a specific element of the array of data for the entry in the API for extension <pID>  
with name <pEntryName> and type <pType>.

Returns:
Either a string or an array
of data describing the element of the array of data
pertaining to the entry in the API for the given extension with the given name and type.
*/
function ideDocsFetchExtensionElementOfType pID, pEntryName, pType, pElement
   local tLibraryName
   put revIDEExtensionProperty(pID, "title") into tLibraryName	
   return ideDocsFetchElementOfType(pEntryName, tLibraryName, pType, pElement)
end ideDocsFetchExtensionElementOfType

/* 
Fetch all docs element of the given type in the LiveCode script dictionary.

Returns:
A numerically keyed array of data, each element of which is an array of data
pertaining to a LiveCode script dictionary entry with the given type.
*/
function ideDocsFetchExtensionElementsOfType pID, pType
   local tLibraryName
   put revIDEExtensionProperty(pID, "title") into tLibraryName
   return __ideDocsFetchData("", tLibraryName, pType)
end ideDocsFetchExtensionElementsOfType

/*
Returns a list of library names, one per line, which have API entries in the dictionary.
*/
function ideDocsFetchLibraryNames
   # Ensure we have a connection
   local tConnection
   try
      ideDocsInitialize
      put the result into tConnection
   catch tError
      return tError
   end try
   
   local tRecordSet, tData, tDataSet, tSQL
   put "SELECT library_name FROM libraries" into tSQL
   put revQueryDatabase(sConnection, tSQL) into tRecordSet
   if the result is not a number then
      return "error fetching library names" & return & the result
   end if
   
   # Get the docs data from the record set
   local tCount, tMoreRecords
   put true into tMoreRecords
   repeat while tMoreRecords
      add 1 to tCount
      get revDatabaseColumnNamed(tRecordSet, "library_name", "tData")
      put tData into tDataSet[tCount]
      revMoveToNextRecord tRecordSet
      put the result into tMoreRecords
   end repeat
   
   # Close the record set
   revCloseCursor tRecordSet
   
   combine tDataSet with return
   return tDataSet
end ideDocsFetchLibraryNames

private function ideDocsFetchLibraryEntries pLibraryName
   return __ideDocsFetchData("", pLibraryName, "")
end ideDocsFetchLibraryEntries

/* 
Fetch the data for all entries in the LiveCode script dictionary

Returns:
A numerically keyed array, each element of which is the array
of data 
pertaining to an entry in the LiveCode script dictionary.
*/
function ideDocsFetchLCSEntries
   return ideDocsFetchLibraryEntries("LiveCode Script")
end ideDocsFetchLCSEntries

/* 
Fetch the data for all entries in the LiveCode builder dictionary

Returns:
A numerically keyed array, each element of which is the array
of data 
pertaining to an entry in the LiveCode builder dictionary.
*/
function ideDocsFetchLCBEntries
   return ideDocsFetchLibraryEntries("LiveCode Builder")
end ideDocsFetchLCBEntries

/* 
Fetch the data for all entries in the API for extension <pID>  

Returns:
A numerically keyed array, each element of which is the array
of data 
pertaining to an entry in the API for the given extension.
*/
function ideDocsFetchExtensionEntries pID
   local tLibraryName, tAPI
   put revIDEExtensionProperty(pID, "title") into tLibraryName
   put revIDEExtensionProperty(pID, "api") into tAPI
   return ideDocsFetchLibraryEntries(tAPI, tLibraryName)
end ideDocsFetchExtensionEntries

on ideDocsUpdateDatabase pAPI, pLibraryA, pDistributed
   if pDistributed is true and revEnvironmentIsInstalled() then
      exit ideDocsUpdateDatabase
   end if
   
   local tConnection
   ideDocsInitialize pDistributed
   put the result into tConnection
   
   local tResult
   revExecuteSQL tConnection,"BEGIN TRANSACTION"
   dispatch "revDocsUpdateDatabase" to stack "revDocsParser" with tConnection, pAPI, pLibraryA
   put the result into tResult
   
   if tResult is not empty then
      revExecuteSQL tConnection,"ROLLBACK"
      return tResult
   end if
   
   revExecuteSQL tConnection, "COMMIT"
   return empty
end ideDocsUpdateDatabase
