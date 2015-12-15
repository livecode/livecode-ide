---
version: 8.0.0-dp-9
---
# Extension folder locations within the IDE

If you write plugins, or have code that relies on the location of extensions 
then please ensure you use the following access functions to locate them:
* `revEnvironmentExtensionsPath`: returns the path to the folder where the 
IDE looks for packaged extensions to load (by default, this is 
`My Livecode/Extensions`)
* `revEnvironmentUserExtensionsPath`: returns the path to the folder where the
IDE looks for user-installed extensions to load.

When building from source, `revEnvironmentExtensionsPath` returns the location in
the binaries folder to which the packaged extensions have been extracted.
