---
version: 8.0.0-dp-11
---
# Documentation API

There is now a limited documentation API used in the IDE. 

It consists of three functions for accessing LiveCode Script dictionary entries:

* `ideDocsFetchLCSData pEntryName`: Fetch the data for entries with
  name `pEntryName`. It returns a numerically-keyed array, each
  element of which is the array of data about a docs entry with the
  given name.

* `ideDocsFetchLCSDataOfType pEntryName, pType`: Fetch the data for
  the entry with name `pEntryName` and type `pType`.  It returns the
  array of data about the unique docs entry with the given name and
  type.

* `ideDocsFetchLCSElementOfType pEntryName, pType, pElement`: Fetch
  the data for the docs element `pElement` with entry name
  `pEntryName` and type `pType`.  It returns the specific element of
  dictionary data for the entry with the given name and type.
