# Widget default scripts
When opening the code editor for a widget, it will now be prepopulated 
by a default script, if it is provided by the widget developer. The 
default script is contained in a script-only stack file in the widget's
`support` folder. 

The stack file must be named `defaultscript.livecodescript`, and the 
stack itself must be named `<widget id>.__DefaultScript`, for example
`com.livecode.widget.navbar.__DefaultScript`.