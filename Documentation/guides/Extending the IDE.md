# Extending the LiveCode IDE

The LiveCode IDE (integrated development environment) has been written
using LiveCode. All the components – the Tools Palette, Property
Inspector, Script Editor, Debugger, etc., are implemented as LiveCode
stacks.

These stacks all use the central IDE library, stack *revIDELibrary*, to
control their interactions with user stacks and each other. This design
makes it easy to extend the IDE with plug-ins. If you are an advanced
LiveCode developer you can also edit the IDE itself to provide custom
functionality.

## Publish and Subscribe

The IDE has to perform a tricky balancing act: on one hand it must 
provide all the functionality needed by its stacks and by the user 
during development; on the other it should be as hands-off as possible
during execution so as not to disrupt anything. Ideally running a stack
in the IDE should be as similar as possible to running it in a 
standalone.

As a general solution to this problem, the IDE library act as a broker 
for messages associated with certain events. A single stack in the 
frontscripts, *revIDEMessageHandler*, intercepts all engine messages and
notifies the IDE library at the next available time, but passes those
messages so they propagate through the message path in the usual way.

IDE stacks and plugins should subscribe to messages via the IDE library 
using the **revIDESubscribe** command:

	revIDESubscribe pMessage, pOptionalSource

If *pOptionalSource* is not empty, then only messages coming from that 
source will be delivered to the subscriber. The subscriber is currently 
always `the long id of the target`, i.e. the object whose script 
execution directly resulted in the call to **revIDESubscribe**.

For example, a plugin that needs to update itself when a new control is 
created, instead of directly handling the **newControl** message, should
subscribe to the **ideNewControl** message at an appropriate time
(usually during its **preOpenStack** handler) and handle the 
**ideNewControl** message:

	on preOpenStack
		revIDESubscribe "ideNewControl"
	end preOpenStack
	
	on ideNewControl pControl
		-- pControl is the long id of the newly created control
	end ideNewControl

It is not currently possible to subscribe to messages on behalf of other
objects, but if this is a desirable feature then it is something we can 
consider adding in the future.

### Parameterised Messages

Some messages are parameterised, for example **idePreferenceChanged**, 
which can be subscribed to on a per-preference basis by subscribing to 
the message 

	idePreferenceChanged:<preference name>
	
For example, a script editor plugin should honour the *cRevScriptSize* 
preference, which will be sent by the IDE library whenever this 
preference is changed. Therefore it can subscribe in its 
**preOpenStack** handler and respond to the **idePreferenceChanged** 
message:

	on preOpenStack
		revIDESubscribe "idePreferenceChanged:cRevScriptSize"
	end preOpenStack
	
	on idePreferenceChanged pPreference
		switch pPreference
		case "cRevScriptSize"
			local tValue
			put revIDEGetPreference(pPreference) into tValue
			-- Update with new value of cRevScriptSize
		...
	end idePreferenceChanged
	
### Custom Messages

The IDE library does not have a fixed set of messages that it is the 
broker for. Therefore plugins can use the IDE library, if they wish, to 
send any messages they require. This would in theory enable further
independently authored plugins to interact with each other without 
having to be concerned with checks about whether they are in memory.

### Messages currently handled by the IDE

The following is a list of the most useful IDE messages.

	ideNewControl pControlID

Sent when any control is created. This is an aggregation of all the 
engine's `new<Control>` messages.

	ideControlDeleted pControlID

Sent when any control is deleted. This is an aggregation of all the 
engine's `<control>Delete` messages.

	ideNewCard pCardID

Sent when any control is created. This is the equivalent of the engine's
`newCard` message.

	ideCardDeleted pCardID

Sent when any control is deleted. This is the equivalent of the engine's
`deleteStack` message.

	ideNewStack pStackID

Sent when any control is created. This is the equivalent of the engine's
`newCard` message.

	ideStackDeleted pStackID

Sent when any control is deleted. This is the equivalent of the engine's
`deleteStack` message.

	ideOpenStack pStackID
	
Sent when a stack is opened. This is the equivalent of the engine's 
`openStack` message.

	idePreferenceChanged pPreference

Sent when a preference is changed.

	ideSelectedObjectChanged

Sent when the selected object changed. This is the equivalent of the
engine's `selectedObjectChanged` message.

	ideToolChanged
	
Sent when the user changes between *Run* and *Edit* mode. This is the 
equivalent of the engine's `newTool` message.

	idePropertyChanged pObjectID
	
Sent when a property of an object has changed. 

	ideEditScript pObjectID
	
Sent when the script editor is opened for an object.

	ideNameChanged pOldName, pNewName, pObjectID 

Sent when the user changes an object's name. This is the equivalent of
the engine's `nameChanged` message.

## Data Provision

There are a number of sets of data that are useful for IDE stacks and 
plugins that are designed for common IDE tasks. Each of the following
sections details some of the relevant IDE library handler for these sets
of data.

### Extension Data

### Documentation Data

## IDE Actions

- ultimately all public ide api handlers will be prefixed ide... rather than revIDE
- will be moved into revIdeApi.livecodescript when 'stable'
- please test!

## Creating Plug-ins

You can create a plug-in to help perform tasks that you need to do
regularly in the LiveCode IDE. Plug-ins are written as LiveCode stacks.
(If you need to extend LiveCode using a lower level language, see the
section on *Externals*, below.)

To create a plug-in, save your stack into the Plugins folder, located
within the My LiveCode [Edition] folder, inside your Documents folder.

You can now load your stack by choosing its name from the Development
-\> Plugins submenu. By default your plug-in will be loaded as a
palette. This allows you to operate the controls in the plug-in while
the LiveCode IDE is in pointer tool mode. This allows you to create
custom "Property Inspector" style behaviors or other object editing
tools.

### The Plugin Settings Screen

Open the Plugin settings screen from the Development -\> Plugins
submenu. Choose the plugin you have created from the Plugin menu at the
top of the screen to apply settings to it.

![](images/image118.png)

Figure 84 – The Plugin Settings Screen

#### Open plugin when:

By default your plugin will load when you chose it from the plugins
menu. If you want to have your plugin load whenever you start LiveCode
select the "LiveCode starts up". Use this if your plugin is used to set
up your environment, for example by loading stacks that you are working
on or adjusting window layout. To have your plugin load when LiveCode
quits choose "LiveCode quits". Use this if your plugin performs clean up
tasks that you want to have run whenever you exit.

#### Open as:

Choose the mode you want your plugin to open as. If you choose the
invisible option, your plugin stack will be loaded invisible. Use this
option to create a plugin that installs a faceless library (for example
by inserting a button within it into the front or backscripts) or to
perform some other automated task that does not require a visible user
interface.

> **Note:** Loading from your plugin will not allow you to edit the
> plugin itself. If you want to edit the plugin, first load it from the
> menu then use the Application Browser to make it toplevel by right
> clicking on it in the list of stacks and choosing Toplevel from the
> popup menu.

## Adding Property Inspector editors

The property inspector is dynamically generated depending on the 
attributes of each property in its current pane. It has been 
implemented with flexibility and extensibility in mind, since it must be 
able to control the values of widget properties in any way required by 
widget developers. Each property has a number of attributes which affect 
how it appears in the inspector.

#### Property Attributes

The fixed property attributes of all the 'classic' LiveCode controls
(that is all controls other than widgets) are defined in text files in 

	Toolset/resources/supporting_files/property_definitions

These are parsed by the IDE library on startup in order to implement the
handlers detailed in the *Property Data* section above.

Widgets define the attributes associated with their properties in their
source files, which are written to the widget manifest when the widget
is compiled and parsed by the IDE when the widget is loaded.

- default: the default value of the property
- group: editors with the same group name are placed side by side
- label: the label to use for this property
- options: defines the possible values for a given property, if 
applicable
- section: determines which tab of the property inspector contains the 
editor for the property in question
- user_visible: whether the property should be displayed to the user
- read_only: whether the property should be modifiable by the user
- editor: the editor that will be used to display the value of the 
property and allow it to be edited.

In the future the editor used for a given property may be 
user-configurable. In the mean time, it is still possible for widget 
developers to create their own editors for their widget properties.

#### Editors

Currently an editor must be a stack consisting of a group named 
"template" and a stack with a behavior script. The latter must have the 
same name as the stack with the template group with ".behavior" appended
to it. The property inspector looks up the specified editor for a given 
property, clones the template group, and sets its behavior to the script
of the stack.

The behavior script must at a minimum implement the following three 
handlers:

	on editorInitialize
		-- Called when the editor has been cloned and assigned a 
		-- property to manage
	end editorInitialize
	
	on editorUpdate
		-- Called when the property value changes 
	end editorUpdate
	
	on editorResize
		-- Called when the inspector resizes 
	end editorResize

There are a number of properties available to any editor:
* editorMinWidth
* editorMaxWidth
* editorEnabled
* editorEffective
* editorValue

These should be set or got appropriately. For example, if an editor 
consists of a text field, the **editorUpdate** handler should update the 
value of the field with 'the editorValue of me'. Similarly, if the 
content of the field changes, the field should call a function in the 
behavior which sets 'the editorValue of me' to the content of the field.

The **editorEnabled** and **editorEffective** properties are set by the 
generic behavior depending on the property info and the values of the 
properties. The **editorEffective** is true if the value of the property 
in question is empty but there is an effective value in play. The editor 
should alter the display of its value accordingly.

Editors can specify their min and max width if required.

It is our intention that ultimately a widget alone will be able to 
function as a property editor, however currently this feature is not 
available.

## Editing the IDE

> **Caution:** Editing the IDE can easily cause LiveCode to become
> unusable. We recommend that only advanced users attempt to edit the
> IDE. We recommend you back up the IDE prior to making any changes. We
> do not recommend attempting to edit the IDE while working on any
> mission critical project.

To edit the LiveCode IDE, turn on *Show IDE stacks in lists* in the
*View* menu. This causes LiveCode to display its own stacks within the
Project Browser and other editing screens. You can now load these
stacks to edit them. To allow you to edit LiveCode IDE objects with the
keyboard shortcuts, turn on the *In LiveCode UI Windows* and 
*Contextual menus work in LiveCode Windows*, options in the 
*Preferences*.

The IDE uses script-only stack libraries to provide much of its
functionality. The scripts are loaded into the **frontScripts** and 
**backScripts** when the IDE is started. To edit these scripts, go to 
the *Front Scripts* or *Back Scripts* tab within the Message Box and 
ensure *Show IDE Stacks In Lists* is checked in the *View* menu.

> **Caution:** If you make a mistake editing *revFrontScriptLibrary*,
> *revBackScriptLibrary*, or *revIDELibrary*, LiveCode may become 
> non-responsive and you will have to force-quit.

Some of the Script Editor and Property Inspector functionality is 
provided by two stacks, *revTemplateScriptEditor* and 
*revInspectorTemplate*. These stacks are cloned each time you open a 
new Script Editor or Inspector. To make permanent changes you need to 
apply the changes to these stacks and save them. However the bulk of 
their functionality is implemented in script-only stack behaviors, which
can be updated with immediate effect.