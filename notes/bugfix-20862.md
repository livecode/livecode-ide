# Fix multi-module assembly support
The extension builder now supports multi-module assemblies properly.
An extension folder can contain a main module, eg main.lcb, and any
number of support modules, named <main name>-<suffix>.lcb, which are
then compiled together into one bytecode file. 

For example, it is useful when building cross-platform extensions to
put the platform-specific code in a support module, so the extension
folder would contain for example

	button.lcb
	button-android.lcb
	button-ios.lcb
	...
etc

