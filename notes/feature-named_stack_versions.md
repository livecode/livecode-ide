---
version: 8.0.0-dp-6
---
# Per-version IDE stack filenames

When a binary stackfile is rewritten in the IDE for a new version, it
now has a (major) version in the filename to prevent unwanted IDE
merging between versions. This can also be used to ensure incompatible
stacks are not loaded if present - the IDE will only load stacks with
a version less than or equal to its version.

For example, from 8.0 onwards, the "revIdeLibrary" stack has filename
`/Toolset/libraries/revidelibrary.8.livecodescript`.
