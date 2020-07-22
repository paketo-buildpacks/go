# Go Paketo Buildpack

## `gcr.io/paketo-buildpacks/go`

The Go Paketo Buildpack provides a set of collaborating buildpacks that
enable the building of a Go-based application. These buildpacks include:
- [Go Distribution CNB](https://github.com/paketo-buildpacks/go-dist)
- [Go Mod Vendor CNB](https://github.com/paketo-buildpacks/go-mod-vendor)
- [Dep CNB](https://github.com/paketo-buildpacks/dep)
- [Dep Ensure CNB](https://github.com/paketo-buildpacks/dep-ensure)
- [Go Build CNB](https://github.com/paketo-buildpacks/go-build)

The buildpack supports building applications that use either the built-in [Go
modules](https://golang.org/cmd/go/#hdr-Module_maintenance) feature or
[Dep](https://golang.github.io/dep/) for managing their dependencies.  Support
for each of these package managers is mutually-exclusive. There is also
support for applications that do not use a package manager.
