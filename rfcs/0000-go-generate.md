# Go Generate Buildpack

## Proposal
The language family should have a `go generate` buildpack.

<!---
{{What changes are you purposing to the overall language family?}}
-->

## Motivation
### Use Cases
#### `go:generate` with a go tool

##### How does this usually work in Dockerfile?

#### `go:generate` with a tool installed on the system
##### How does this work in a Dockerfile?

#### `go:generate` with a binary generated during project build
##### How does this work in a Dockerfile?

<!---
{{Why are we doing this? What pain points does this resolve? What use cases
does it support? What is the expected outcome? Use real, concrete examples to
make your case!}}
-->

## Implementation (Optional)
### API
If some file in the app source contains the directive
```
//go:generate some-tool
```
then the buildpack should require:
```
[[requires]]
name = "some-tool"

[[or]]

[[or.requires]]
mixin = "some-tool"
```
This takes advantage of the possibility of future
[stackpacks](https://github.com/buildpacks/rfcs/blob/main/text/0069-stack-buildpacks.md)
providing the necessary tool.

This buildpack should not provide anything.

### Detection criteria
The buildpack should pass detection if the files on which the generate command
is run contain any  `//go:generate` directives AND a `BP_GO_GENERATE`
environment variable is set to `true`. Its default value should be `true`.

Since go is not installed in the image during detection, we may need to re-implement
the logic of `go generate -n <flags> ./...` (dry run) to search for directives.

### Configuration options
Users can skip `go generate` by setting `BP_GO_GENERATE=false` at build time.
This will cause the buildpack to fail detection. It will therefore **not**
require the tools specified in the `//go:generate` directives.

Users can specify flags to use with the `go generate` command with the
`BP_GO_GENERATE_FLAGS` environment variable.  The most interesting flag here is
`-run="<regex>"` which allows users to select a subset of generate directives
to run. (See `go help generate` for a full description of this flag.)

Users can specify files/packages that should be generated with the
`BP_GO_GENERATE_ARGS` environment variable.  This way, users can run generation
on only certain files at build time. (See `go help generate` for a description of
how `go generate` accepts arguments.)

<br/><br/>
For example, for a given `main.go`
```
package main

import "fmt"

//go:generate go get honnef.co/go/tools/cmd/staticcheck
//go:generate staticcheck main.go
//go:generate staticcheck internal/helper.go

func main() {
	if "hello" == "hello" {
		fmt.Println("hello world!")
	}
}
```

A user can set `BP_GO_GENERATE_FLAGS='-run="^//go:generate go get"'`. The buildpack should then run:
```
go generate -run="^//go:generate go get" ./...
```
which will only run the command: `go get honnef.co/go/tools/cmd/staticcheck`.

<br/><br/>
If, instead, a user set `BP_GO_GENERATE_FLAGS='-run="^//go:generate staticcheck"'`, the buildpack should run:
```
go generate -run="^//go:generate staticcheck" ./...
```
which will attempt to run
```
staticcheck main.go
staticcheck internal/helper.go
```
but should fail unless `staticcheck` has been pre-installed on the system because the `go get` command is skipped.

<br/><br/>
A user can set `BP_GO_GENERATE_ARGS=main.go` and the buildpack should then run:
```
go generate main.go
```
which will only run directives within that file.

<br/><br/>
Using both in conjunction, a user can set `BP_GO_GENERATE_FLAGS='-run="^//go:generate staticcheck"` and `BP_GO_GENERATE_ARGS=main.go` and the buildpack will run:
```
go generate -run="^//go:generate staticcheck" main.go
```

<br/><br/>
In this way, users can specify which packages and directives to run during build. Capture groups make it simple to include directives from a few different tools (e.g. `BP_GO_GENERATE_FLAGS='-run "^//go:generate (staticcheck)|(faux)"'`).

### Build behaviour
The buildpack should do the equivalent of running
```
go generate <user-provided flags> <user-provided args>
```
from the app working directory.

If the user does not provide flags, it should run
```
go generate ./...
```
from the app working directory.

`go generate` fails with an informative error if a tool needed for a directive
is not found on the `PATH`. Though the buildpack API should prevent this error
from arising.


### Language Family Ordering
Proposed updated order:
```
[[order]]

  [[order.group]]
    id = "paketo-buildpacks/go-dist"

  [[order.group]]
    id = "paketo-buildpacks/go-generate"
    optional = true

  [[order.group]]
    id = "paketo-buildpacks/go-mod-vendor"

  [[order.group]]
    id = "paketo-buildpacks/go-build"

[[order]]

  [[order.group]]
    id = "paketo-buildpacks/go-dist"

  [[order.group]]
    id = "paketo-buildpacks/go-generate"
    optional = true

  [[order.group]]
    id = "paketo-buildpacks/dep"

  [[order.group]]
    id = "paketo-buildpacks/dep-ensure"

  [[order.group]]
    id = "paketo-buildpacks/go-build"

[[order]]

  [[order.group]]
    id = "paketo-buildpacks/go-dist"
    version = "0.2.6"

  [[order.group]]
    id = "paketo-buildpacks/go-generate"
    optional = true

  [[order.group]]
    id = "paketo-buildpacks/go-build"
    version = "0.1.2"
```

Note that in some cases, `go mod vendor` can fail if run before `go generate`
because some non-generated files depend on packages with generated files. A
common example would be generated fakes for tests.

<!---
{{Give a high-level overview of implementation requirements and concerns. Be
specific about areas of code that need to change, and what their potential
effects are. Discuss which repositories and sub-components will be affected,
and what its overall code effect might be.}}
-->

## Source Material (Optional)

- An [existing go-generate buildpack](https://github.com/stefanlesperance/go-generate)
- [Implementation of `go generate`](https://github.com/golang/gofrontend/blob/master/libgo/go/cmd/go/internal/generate/generate.go)
<!---
{{Any source material used in the creation of the RFC should be put here.}}
-->

## Unresolved Questions and Bikeshedding (Optional)

- How common are the different use-cases? Which ones should we focus on addressing?
- Does this buildpack imply the existence of a "go get" buildpack that provides
  arbitrary go projects on the path?
- Should `BP_GO_GENERATE` be `true` or `false` by default?
- How can we search for `go generate` directives without go tools during the
detect phase? Can we avoid re-implementing `go generate`'s search method?

<!---
{{Write about any arbitrary decisions that need to be made (syntax, colors,
formatting, minor UX decisions), and any questions for the proposal that have
not been answered.}}
-->

{{REMOVE THIS SECTION BEFORE RATIFICATION!}}
