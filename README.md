# Go Paketo Buildpack

## `docker.io/paketobuildpacks/go`

The Go Paketo Buildpack provides a set of collaborating buildpacks that
enable the building of a Go-based application. These buildpacks include:
- [Go Distribution CNB](https://github.com/paketo-buildpacks/go-dist)
- [Go Mod Vendor CNB](https://github.com/paketo-buildpacks/go-mod-vendor)
- [Go Build CNB](https://github.com/paketo-buildpacks/go-build)

The buildpack supports building applications that use either the built-in [Go
modules](https://golang.org/cmd/go/#hdr-Module_maintenance) feature for managing
their dependencies. Usage examples can be found in the
[`samples` repository under the `go` directory](https://github.com/paketo-buildpacks/samples/tree/main/go).

#### The Go buildpack is compatible with the following builder(s):
- [Paketo Jammy Full Builder](https://github.com/paketo-buildpacks/builder-jammy-full)
- [Paketo Jammy Base Builder](https://github.com/paketo-buildpacks/builder-jammy-base)
- [Paketo Jammy Tiny Builder](https://github.com/paketo-buildpacks/builder-jammy-tiny)
- [Paketo Jammy Static Buildpackless Builder](https://github.com/paketo-buildpacks/builder-jammy-buildpackless-static)†
- [Paketo Full Builder](https://github.com/paketo-buildpacks/full-builder)
- [Paketo Base Builder](https://github.com/paketo-buildpacks/base-builder)
- [Paketo Tiny Builder](https://github.com/paketo-buildpacks/tiny-builder)

This buildpack also includes the following utility buildpacks:
- [Git CNB](https://github.com/paketo-buildpacks/git)
- [Procfile CNB](https://github.com/paketo-buildpacks/procfile)
- [Environment Variables CNB](https://github.com/paketo-buildpacks/environment-variables)
- [Image Labels CNB](https://github.com/paketo-buildpacks/image-labels)
- [CA Certificates CNB](https://github.com/paketo-buildpacks/ca-certificates)

Check out the [Go Paketo Buildpack docs](https://paketo.io/docs/buildpacks/language-family-buildpacks/go/) for more information.

† To build with the static buildpackless builder, use the following command:

```
pack build \
  --builder paketobuildpacks/builder-jammy-buildpackless-static \
  --buildpack paketo-buildpacks/go \
  --env "CGO_ENABLED=0" \
  --env "BP_GO_BUILD_FLAGS=-buildmode=default"
  <app-name>
```
