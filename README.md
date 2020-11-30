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
support for applications that do not use a package manager. Usage examples can
be found in the
[`samples` repository under the `go` directory](https://github.com/paketo-buildpacks/samples/tree/main/go).

#### The Go buildpack is compatible with the following builder(s):
- [Paketo Full Builder](https://github.com/paketo-buildpacks/full-builder)
- [Paketo Base Builder](https://github.com/paketo-buildpacks/base-builder)
- [Paketo Tiny Builder](https://github.com/paketo-buildpacks/tiny-builder)
