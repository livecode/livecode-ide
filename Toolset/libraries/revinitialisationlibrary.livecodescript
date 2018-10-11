script "revinitialisationlibrary"
// A array that stores whether a library is loaded
// sLoadedLibraries["library name"] = true
local sLoadedLibraries

constant kLCLibraryPrefix = "com.livecode.library"

command revInternal__LoadLibrary pLibrary, pFullPath
   // Create the path to the library file. Assumption is made that the directory, file and stack name are all the same.
   //set the itemdel to "/"
   
   -- SN-2015-02-20: Linux uses case-sensitive filenames, so we
   --  follow the lower-case naming of the library names
   put toLower(pLibrary) into pLibrary
   
   if sLoadedLibraries[pLibrary] is not empty then
      return "Library" && pLibrary && "already loaded as" && sLoadedLibraries[pLibrary]
   end if
   
   local tStackName
   if there is a stack pLibrary then
      put pLibrary into tStackName
   else if there is a stack (kLCLibraryPrefix & "." & pLibrary) then
      put kLCLibraryPrefix & "." & pLibrary into tStackName
   else if the environment begins with "development" and \
         there is a stack pFullPath then
      put the short name of stack pFullPath into tStackName
   else
      return "no stack for library" && pLibrary
   end if
   
   local tError, tLegacyError
   try
      // TODO: Remove legacy message name	   
      dispatch "revLoadLibrary" to stack tStackName  
      if it is not "handled" then
      	throw "No revLoadLibrary handler found"
      end if
   catch tLegacyError 
   end try 
   
   if tLegacyError is not empty then
      try
         send "extensionInitialize" to stack tStackName   
      catch tError
      end try
   end if
   
   if tError is not empty then
      write ("Error" && tError && "while loading stack:" && pLibrary) \
            & return to stderr
      return "Error loading" && pLibrary & return & tError
   end if
   
   put tStackName into sLoadedLibraries[pLibrary]
   return empty
end revInternal__LoadLibrary

command revInternal__LoadIfLibrary pLibrary
   try
      local tAvailable, tMsg
      put the revAvailableHandlers of stack pLibrary into tAvailable
      if tAvailable contains "extensionInitialize" then
         put "extensionInitialize" into tMsg
         // TODO: Remove legacy message name	            
      else if tAvailable contains "revLoadLibrary" then 
         put "revLoadLibrary" into tMsg
      else
         throw "not a library"
      end if
      send tMsg to stack pLibrary
      local tStackName
      put the name of stack pLibrary into tStackName
      put tStackName into sLoadedLibraries[pLibrary]
      return true
   end try
   delete stack pLibrary
   return false
end revInternal__LoadIfLibrary

command revInternal__UnloadLibrary pLibraryName
   // Check if the library is loaded
   if sLoadedLibraries[pLibraryName] is empty then
      return "Library not loaded"
   end if
   
   local tStackName
   put sLoadedLibraries[pLibraryName] into tStackName
   if there is not a stack tStackName then return "library not loaded"
   
   local tError, tLegacyError
   try
      // TODO: Remove legacy message name	   
      dispatch "revUnloadLibrary" to stack tStackName  
      if it is not "handled" then
         throw "No revUnloadLibrary handler found"
      end if
   catch tLegacyError
   end try
   
   if tLegacyError is not empty then
      try
         // Request the library shuts down
         send "extensionFinalize" to stack tStackName
      catch tError
      end try
   end if
   
   if tError is not empty then
      return "Error while unloading library. Library" && pLibraryName \
            && "did not complete the extensionFinalize request"
   end if
   delete variable sLoadedLibraries[pLibraryName]
   return empty
end revInternal__UnloadLibrary

function revInternal__ListLoadedLibraries
   local tLibs
   put the keys of sLoadedLibraries into tLibs
   sort tLibs
   return tLibs
end revInternal__ListLoadedLibraries

function revInternal__LoadedLibraryStackName pLibName
   return sLoadedLibraries[pLibName]
end revInternal__LoadedLibraryStackName

command revInternal__SetAppIcon pAppIcon
   global gRevAppIcon
   set the paintCompression to "png" -- match the engine
   put pAppIcon into gRevAppIcon
end revInternal__SetAppIcon

command revInternal__SetSmallAppIcon pSmallAppIcon
   global gRevSmallAppIcon
   set the paintCompression to "png" -- match the engine
   put pSmallAppIcon into gRevSmallAppIcon
end revInternal__SetSmallAppIcon

command revInternal_SetJAVA_HOME
   if $JAVA_HOME is empty then
      local tPath
      switch the platform
         case "MacOS"
            put word 1 to -1 of shell("/usr/libexec/java_home") into tPath
            break
         case "Linux"
            local tJAVAC
            put "/bin/javac" into tJAVAC
            put word 1 to -1 of shell("/usr/bin/env readlink -f /usr" & tJAVAC) into tPath
            if there is a file tPath and tPath ends with tJAVAC then
               set the itemDelimiter to slash
               delete item -2 to -1 of tPath
            end if
            break
      end switch
      if there is a folder tPath then
         put tPath into $JAVA_HOME
      end if
   end if
end revInternal_SetJAVA_HOME

command revInternal_SetCLASSPATH
   local tJarFiles, tFolder, tClasspath
   put specialFolderPath("resources") & "/Externals/JVM" into tFolder
   
   put files(tFolder) into tJarFiles
   filter tJarFiles with "*.jar"
   
   repeat for each line tJar in tJarFiles
      put tFolder & slash before tJar
      if tClasspath is empty then
         put tJar into tClasspath
      else
         put ":" & tJar after tClasspath
      end if
   end repeat
   
   put tClasspath into $CLASSPATH
end revInternal_SetCLASSPATH
