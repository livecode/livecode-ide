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
      return tConnection
   end if
   
   put tConnection into sConnection
end ideDocsInitialize

private function __fetchDocsData pLibraryName, pEntryName, pType
   # Ensure we have a connection
   ideDocsInitialize
   
   local tSql, tRecordSet, tData, tDataSet
   
   put "SELECT data from" && pLibraryName into tSql
   put " WHERE name = '" & tolower(pEntryName) & "'" after tSql
   if pType is not empty then
      put " AND type = '" & pType & "'" after tSql
   end if
   
   # Execute the query, keeping the record set ID.
   put revQueryDatabase(sConnection, tSql) into tRecordSet
   if the result is not a number then
      -- error - connection may have been closed, so try to reopen
      put empty into sConnection
      ideDocsInitialize
      put revQueryDatabase(sConnection, tSql) into tRecordSet
      if the result is not a number then
         return the result
      end if
   end if
   
   # Get the docs data from the record set
   local tCount, tMoreRecords
   put true into tMoreRecords
   repeat while tMoreRecords
      add 1 to tCount
      get revDatabaseColumnNamed(tRecordSet, "data", "tData")
      put tData into tDataSet[tCount]
      revMoveToNextRecord tRecordSet
      put the result into tMoreRecords
   end repeat
   
   # Close the record set
   revCloseCursor tRecordSet
   
   return tDataSet
end __fetchDocsData

private function __ideDocsFetchData pLibraryName, pEntryName, pType
   # Fetch the data
   local tData
   put __fetchDocsData(pLibraryName, pEntryName, pType) into tData
   
   if tData[1] is empty then
      return empty
   end if
   
   repeat for each key tCount in tData
      put arrayDecode(tData[tCount]) into tData[tCount]
   end repeat
   
   # Return the decoded array
   return tData
end __ideDocsFetchData

private function ideDocsFetchElementOfType pLibraryName, pEntryName, pType, pElement
   local tDataA
   put __ideDocsFetchData(pLibraryName, pEntryName, pType) into tDataA
   
   return tDataA[1][pElement]
end ideDocsFetchElementOfType

private function ideDocsFetchDataOfType pLibraryName, pEntryName, pType
   local tDataA
   put  __ideDocsFetchData(pLibraryName, pEntryName, pType) into tDataA
   return tDataA[1]
end ideDocsFetchDataOfType

private function ideDocsFetchData pLibraryName, pEntryName
   return __ideDocsFetchData(pLibraryName, pEntryName)
end ideDocsFetchData

function ideDocsFetchLCSData pEntryName
   return ideDocsFetchData("livecode_script", pEntryName)
end ideDocsFetchLCSData

function ideDocsFetchLCSDataOfType pEntryName, pType
   return ideDocsFetchDataOfType("livecode_script", pEntryName, pType)
end ideDocsFetchLCSDataOfType

function ideDocsFetchLCSElementOfType pEntryName, pType, pElement
   return ideDocsFetchElementOfType("livecode_script", pEntryName, pType, pElement)
end ideDocsFetchLCSElementOfType

on ideDocsUpdateDatabase pLibraryA
   ideDocsInitialize
   dispatch "revDocsUpdateDatabase" to stack "revDocsParser" with sConnection, pLibraryA
end ideDocsUpdateDatabase
