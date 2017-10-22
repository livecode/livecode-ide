# Script Extensions
Support has been added for installing script libraries contained
in livecode extension packages (.lce files).

## extensionInitialize and extensionFinalize messages

`extensionInitialize` and `extensionFinalize` handlers should be implemented
to govern how the script library extension is loaded in the IDE and in
a standalone.

### Example

	on extensionInitialize
	   if the target is not me then
		  pass extensionInitialize
	   end if
   
	   insert the script of me into back
   
	   if the environment contains "development" then
		  -- Do IDE-specific initialisation
	   end if
	end extensionInitialize

	on extensionFinalize
	   if the target is not me then
		  pass extensionFinalize
	   end if
   
	   remove the script of me from back
	end extensionFinalize

## extensionStartupScript message

A `extensionStartupScript` handler can be implemented to provide code 
which will be executed after the library is loaded in a standalone
application.

### Example

	on extensionStartupScript
	   if the target is not me then
		  pass extensionStartupScript
	   end if
   
	   -- Initialise library for use in standalone
	end extensionStartupScript

## Metadata 
Metadata for script libraries should be contained in the library
level docs. The following docs elements are used for library 
metadata:
- Title: the display name of the library
- Version: the version number (using the semantic versioning system)
- Author: the library author
- Requires: a comma-delimited list of other extension IDs (eg 
  widget kinds, lcb or lcs library extension ids)
- Uses: a comma-delimited list of the library's requirements when
  building a standalone. Currently only android permissions and 
  hardware features are supported.

Other docs elements are used for display in the docs. Any tags and 
associations applied to the library in this section are applied to all 
elements of the library's API.

### Example

	script "com.livecode.library.networking"
	/**
	Title: My Networking Library
	
	Version: 1.0.0
	
	Author: LiveCode
	
	Description:
	This library provides a networking API.
	
	Requires: com.livecode.library.messageauthentication
	
	Uses: INTERNET (android permission)
	
	Tags: networking
	*/
	
	on extensionInitialize
	...
	