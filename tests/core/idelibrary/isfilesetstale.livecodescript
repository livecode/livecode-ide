script "TestIsFilesetStale"

local sWorkDir, sOldDir, sOldFile, sNewDir, sNewFile
local sEmptyDir, sMissingDir, sMissingFile

on TestSetup
   set the itemdelimiter to slash
   set the defaultfolder to item 1 to -2 of the filename of me

   put "_TestIsFilesetStale" into sWorkDir

   put sWorkDir & slash & "missing" into sMissingDir
   put sMissingDir & slash & "missing" into sMissingFile
   put sWorkDir & slash & "empty" into sEmptyDir
   put sWorkDir & slash & "old" into sOldDir
   put sOldDir & slash & "old" into sOldFile
   put sWorkDir & slash & "new" into sNewDir
   put sNewDir & slash & "new" into sNewFile
   
   if there is a folder sWorkDir then
      exit TestSetup
   end if
   
   create folder sWorkDir
   create folder sEmptyDir
   create folder sOldDir
   put empty into url("file:" & sOldFile)
   wait for 2 seconds with messages
   create folder sNewDir
   put empty into url("file:" & sNewFile)
   
end TestSetup

private command __TestBasicFileset pOld, pNew, pMissing, pEmpty
   TestAssert "empty filesets are up-to-date", revIDEIsFilesetStale(pEmpty, pEmpty, false) is false
   TestAssert "empty output fileset is up-to-date", revIdeIsFilesetStale(pNew, pEmpty, false) is false
   TestAssert "empty input fileset is up-to-date", revIDEIsFilesetStale(pEmpty, pOld, false) is false
   
   TestAssert "new file is up-to-date", revIDEIsFilesetStale(pOld, pNew, false) is false
   TestAssert "old file is stale", revIDEIsFilesetStale(pNew, pOld, false) is true
   TestAssert "missing file is stale", revIDEIsFilesetStale(pOld, pMissing, false) is true
end __TestBasicFileset

command __TestMissingInput
   return revIDEIsFilesetStale(sMissingFile, sNewFile, false)
end __TestMissingInput

command __TestEmptyFilename
   local tFileset
   put empty into tFileset[1]
   return revIDEIsFilesetStale(sOldFile, tFileset, false)
end __TestEmptyFilename

on TestBasicFileset
   local tOldFileset, tNewFileset, tMissingFileset, tEmptyFileset
   put sOldFile into tOldFileset[1]
   put sNewFile into tNewFileset[1]
   put sMissingFile into tMissingFileset[1]
   put empty into tEmptyFileset[1]
   delete variable tEmptyFileset[1]

   TestDiagnostic "Testing string-based single-file filesets"
   __TestBasicFileset sOldFile, sNewFile, sMissingFile, empty
   TestDiagnostic "Testing array-based single-file filesets"
   __TestBasicFileset tOldFileset, tNewFileset, tMissingFileset, tEmptyFileset

   put sNewFile into tNewFileset[2]
   put sNewFile into tOldFileset[2]
   put sNewFile into tMissingFileset[2]
   TestDiagnostic "Testing multi-file filesets"
   __TestBasicFileset tOldFileset, tNewFileset, tMissingFileset, tEmptyFileset

   TestDiagnostic "Testing basic errors"
   TestAssertThrow "missing inputs are an error", "__TestMissingInput", \
      the long id of me, "Failed to check modification time: missing file"
   TestAssertThrow "invalid filenames are an error", "__TestEmptyFilename", \
      the long id of me, "Failed to check modification time: invalid filename"
end TestBasicFileset

command __TestUnexpectedFolder
   return revIDEIsFilesetStale(sOldFile, sNewDir, false)
end __TestUnexpectedFolder

private command __TestRecursiveFileset pOld, pNew, pMissing, pEmpty
   TestAssert "new dir is up-to-date", revIDEIsFilesetStale(pOld, pNew, true) is false
   TestAssert "old dir is stale", revIDEIsFilesetStale(pNew, pOld, true) is true
   TestAssert "missing dir is stale", revIDEIsFilesetStale(pOld, pMissing, true) is true
end __TestRecursiveFileset

on TestRecursiveFileset
   TestAssertThrow "folders are erroneous unless recursive", \
      "__TestUnexpectedFolder", the long id of me, \
      "Failed to check modification time: unexpected folder"

   __TestRecursiveFileset sOldDir, sNewDir, sMissingDir, sEmptyDir
end TestRecursiveFileset
