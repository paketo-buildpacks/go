# Restructure the Go buildpack ecosystem

## Proposal

In the new structure there will be 5 buildpacks as opposed to 3 they will be as follows.

go-compiler this buildpack will function the same as the current go-compiler.
go-mod-install this buildpack is a division of the current go-mod buildpack and will only be responsible for installing the apps go modules.
dep this will be a division of the current dep buildpack and will be responsible for only downloading the dep dependency.
dep-install this will be be another division of the current dep buildpack and will be responsible for installing the apps go modules using dep.
go-build this buildpack will be responsible for building the go binary and writing a start command for the app.
The order groupings would look as follows.
```toml
[[order]]
  [[order.group]]
    id = "go-compiler"
  [[order.group]]
    id = "go-mod-install"
  [[order.group]]
    id = "go-build"

[[order]]
  [[order.group]]
    id = "go-compiler"
  [[order.group]]
    id = "dep"
  [[order.group]]
    id = "dep-install"
  [[order.group]]
    id = "go-build"
```
## Motivation

The above plan has several benefits over the existing structure.

- The structure is much more modular allowing for much more customization and insertion of custom buildpacks.
- It separates the concerns of the buildpacks allowing them to be simpler and easier to maintain, while also helping separate different points of failure.
- It condenses common binary building logic into one buildpack in the form of go-build.

{{REMOVE THIS SECTION BEFORE RATIFICATION!}}
