# Restructure the Go buildpack ecosystem

## Proposal

In the new structure there will be 5 buildpacks as opposed to 3 they will be as follows.

* `go-dist`: functions the same as the current go-compiler
* `go-mod-vendor`: executes `go mod vendor` to put dependencies into a common vendored location
* `dep`: responsible for installing the dep dependency
* `dep-ensure`: executes `dep ensure` to put dependencies into a common vendored location
* `go-build`: builds the go binary and writes a start command for the app

The order groupings would look as follows.
```toml
[[order]]
  [[order.group]]
    id = "go-dist"
  [[order.group]]
    id = "go-mod-vendor"
  [[order.group]]
    id = "go-build"

[[order]]
  [[order.group]]
    id = "go-dist"
  [[order.group]]
    id = "dep"
  [[order.group]]
    id = "dep-ensure"
  [[order.group]]
    id = "go-build"

[[order]]
  [[order.group]]
    id = "go-dist"
  [[order.group]]
    id = "go-build"
```
## Motivation

The above plan has several benefits over the existing structure.

- The structure is much more modular allowing for much more customization and insertion of custom buildpacks.
- It separates the concerns of the buildpacks allowing them to be simpler and easier to maintain, while also helping separate different points of failure.
- It condenses common binary building logic into one buildpack in the form of go-build.

{{REMOVE THIS SECTION BEFORE RATIFICATION!}}
