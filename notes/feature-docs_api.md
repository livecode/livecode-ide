# Documentation API

There is now a limited documentation API used in the IDE. 

It consists of three functions:

-`ideDocsFetchLCSData pEntryName` : Fetch the data for entries with name `pEntryName`
-`ideDocsFetchLCSDataOfType pEntryName, pType`: Fetch the data for the entry with name `pEntryName` and type `pType`.
-`ideDocsFetchLCSElementOfType pEntryName, pType, pElement`: Fetch the data for the docs element `pElement` with entry name `pEntryName` and type `pType`.

`ideDocsFetchLCSData` returns a numerically keyed array, each element of which is the array
of data about a docs entry with the given name.

`ideDocsFetchLCSDataOfType` returns the array of data about the unique docs entry with given
name and type.

`ideDocsFetchLCSElementOfType` fetches a specific element of the array of data about the 
unique docs entry with given name and type.
