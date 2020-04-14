# Go Cloud Native Buildpack

The Go Cloud Native Buildpack provides a set of collaborating buildpacks that
enable the building of a Go-based application. These buildpacks include:
- [Go Compiler CNB](https://github.com/paketo-buildpacks/go-compiler)
- [Go Mod CNB](https://github.com/paketo-buildpacks/go-mod)
- [Dep CNB](https://github.com/paketo-buildpacks/dep)

The buildpack supports building applications that use either the built-in [Go
modules](https://golang.org/cmd/go/#hdr-Module_maintenance) feature or
[Dep](https://golang.github.io/dep/) for managing their dependencies.  Support
for each of these package managers is mutually-exclusive. There is no support
for applications that do not use a package manager.
