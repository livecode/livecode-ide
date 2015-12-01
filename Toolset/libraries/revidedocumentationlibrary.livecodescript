script "revIDEDocumentationLibrary"
on revLoadLibrary
   insert the script of me into back
end revLoadLibrary

local sConnection
on ideDocsInitialize
   if sConnection is not empty then
      exit ideDocsInitialize
   end if
   
   local tConnection
   dispatch "revDocsOpenAPIDatabase" to stack "revDocsParser" with revIDESpecialFolderPath("API")
   put the result into tConnection
   if tConnection is not a number then
      ideThrow "unable to open database", tConnection
   end if
   
   put tConnection into sConnection
   return empty
end ideDocsInitialize

private function __fetchDocsData pEntryName, pLibraryName, pType
   # Ensure we have a connection
   try
      ideDocsInitialize
   catch tError
      return tError
   end try
   
   # Find the library id
   local tSQL, tLibraryID, tResult
   if pLibraryName is not empty then
      put "SELECT library_id FROM libraries WHERE library_name = :1" into tSQL
      put revDataFromQuery(comma, return, sConnection, tSQL, "pLibraryName") into tLibraryID
      
      put the result into tResult
      if tResult is not a number then
         return "error finding library id for" && pLibraryName & return & tResult
      end if
   end if
   
   local tRecordSet, tData, tDataSet, tParamCount
   
   put "SELECT entry_data from dictionary_data" into tSQL
   put " WHERE entry_name = :1" after tSQL
   if pType is not empty then
      put " AND entry_type = :2" after tSQL
   end if
   if pLibraryName is not empty then
      put " AND library_id = :3" after tSQL
   end if
   
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

function ideDocsFetchLCSData pEntryName
   return ideDocsFetchData(pEntryName, "livecode_script")
end ideDocsFetchLCSData

function ideDocsFetchLCSDataOfType pEntryName, pType
   return ideDocsFetchDataOfType(pEntryName, "livecode_script", pType)
end ideDocsFetchLCSDataOfType

function ideDocsFetchLCSElementOfType pEntryName, pType, pElement
   return ideDocsFetchElementOfType(pEntryName, "livecode_script", pType, pElement)
end ideDocsFetchLCSElementOfType

on ideDocsUpdateDatabase pLibraryA
   ideDocsInitialize
   dispatch "revDocsUpdateDatabase" to stack "revDocsParser" with sConnection, pLibraryA
end ideDocsUpdateDatabase
