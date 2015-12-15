---
version: 8.0.0-dp-3
---
# General IDE improvements

### Menu bar

The menubar has been made a script-only stack to facilitate bugfixes
and community contributions.  Users should not notice much difference
in terms of its appearance. Some of the menu items have been changed,
however.

The "New Mainstack" item now has a submenu with a range of size
choices, as well as the option to create a script-only
stack. Selecting script-only stack will prompt a choice of name, and
subsequently open the stack in the script editor.

We have centralised the building and handling of contextual menus in
the menubar script, thereby making per-object contextual menus display
and behave consistently throughout the IDE.

The "Object → New Control" submenu is now generated based on the
property information present for each object type, and the newly added
"Object → New Widget" submenu is generated based on the currently
loaded widget extensions.

### Widget metadata and the IDE

Widget metadata now controls a number of additional features with
respect to how the widget interacts with the IDE.

Firstly, the `preferredSize` attribute controls the initial size of
the widget when dragged out from the tools palette.  For example, the
navbar widget now has

```
metadata preferredSize is "320,49"
```

so that when dragged out, it is created at the correct size for an
original iPhone screen.

Secondly, the `userVisible` attribute controls whether the widget
appears at all in the tools palette of the IDE.

A number of widgets have been declared user invisible for this
release, either because they are not meant to be draggable objects at
all (eg the icon picker widget, which is designed to be popped up) or
are not quite refined to the point where they are suitable for user
stacks, but are included because they are being used in the IDE (for
example the tree view widget).

Finally, if present, the `SvgIcon` attribute will be used to display
an icon for the widget in the tools palette, taking precedence over
the included icon resources. All of the widgets included by default in
the tools palette now use svg icon paths.

### Standalone Settings

A field has been added to the "Copy Files" tab of the standalone
settings which is populated with the list of currently installed
extensions. All selected extensions from this list are included in
standalones and loaded when the standalone is launched. Dependencies
between extensions declared in the LiveCode Builder source code using
`use` are automatically calculated and included along with the
top-level widget.
