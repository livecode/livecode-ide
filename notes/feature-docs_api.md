---
version: 8.0.0-dp-12
---
# Documentation API

There is now a documentation API used in the IDE, and available for use by plugin authors
and toolmakers. 

It consists of the following functions:

* `ideDocsFetchLCSData pEntryName` : Fetch the data for entries with 
  name `pEntryName` in the LiveCode Script dictionary.
* `ideDocsFetchLCSDataOfType pEntryName, pType`: Fetch the data for the 
  entry with name `pEntryName` and type `pType` in the LiveCode Script 
  dictionary.
* `ideDocsFetchLCSElementOfType pEntryName, pType, pElement`: Fetch the 
  data for the docs element `pElement` with entry name `pEntryName` and 
  type `pType` in the LiveCode Script dictionary.
* `ideDocsFetchLCSEntries`: Fetch all the data for entries in the 
  LiveCode Script dictionary.

* `ideDocsFetchLCBData pEntryName` : Fetch the data for entries with 
  name `pEntryName` in the LiveCode Builder dictionary.
* `ideDocsFetchLCBDataOfType pEntryName, pType`: Fetch the data for the 
  entry with name `pEntryName` and type `pType` in the LiveCode Builder 
  dictionary.
* `ideDocsFetchLCBElementOfType pEntryName, pType, pElement`: Fetch the 
  data for the docs element `pElement` with entry name `pEntryName` and 
  type `pType` in the LiveCode Builder dictionary.
* `ideDocsFetchLCBEntries`: Fetch all the data for entries in the 
  LiveCode Builder dictionary.

To fetch the entries for a specific extension, use the following:

* `ideDocsFetchExtensionData pID, pEntryName` : Fetch the data for 
  entries with name `pEntryName` in the API for the extension with 
  id `pID`.
* `ideDocsFetchExtensionDataOfType pID, pEntryName, pType`: Fetch the 
  data for the entry with name `pEntryName` and type `pType` in the API 
  for the extension with id `pID`.
* `ideDocsFetchExtensionElementOfType pID, pEntryName, pType, pElement`: 
  Fetch the data for the docs element `pElement` with entry name 
  `pEntryName` and type `pType` in the API for the extension with id 
  `pID`.
* `ideDocsFetchExtensionEntries pID`: Fetch all the data for entries in 
  the API for the extension with id `pID`.

The `pID` is the full type id of the extension, for example to fetch the
documentation entries for the clock widget, use
	
	ideDocsFetchExtensionEnties "com.livecode.widget.clock"

`ideDocsFetch...Data` returns a numerically keyed array, each element of 
which is the array of data about a docs entry with the given name in the 
specified library.

`ideDocsFetch...DataOfType` returns the array of data about the unique 
docs entry with given name and type in the specified library.

`ideDocsFetch...ElementOfType` returns a specific element of the array 
of data about the unique docs entry with given name and type in the 
specified library.

`ideDocsFetch...Entries`: returns all the data for entries in the 
specified library.
