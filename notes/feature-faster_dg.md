# Accelerated DataGrid

The DataGrid has been updated to use the new container layer mode
feature when running in form view mode.

To take advantage of this, the datagrid must be at top-level or
contained withing groups all having container layer mode set. It
must have showBorder set to false, and the acceleratedRendering
property must be enabled on the stack with appropriate compositor
property settings.

To get the maximum benefit from accelerated rendering, the behavior
script for a row template should changing properties within the
template unnecessarily.

A new datagrid property `minimal layout` has been added. When this
property is true, a row template will only receive the `LayoutControl`
message if its data or its width or height has changed as opposed
to every time its rect changes (e.g. due to scrolling).

