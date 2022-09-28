go-online
=========

This app is copied from the `go_mod` app, but has the addition of the package
`github.com/mattn/go-sqlite3 `. This package is used because it uses `CGO`, a
package that frequently causes errors due to dynamic linking in binaries
compiled for mismatched operating systems.

This app exists for the purpose of testing graceful stack upgrades between
builds, to ensure no such problem arises in the buildpacks.

Sample go web app using the GoLang example: http://golang.org/doc/articles/wiki/final.go

to run
======

$ go build site.go
$ PORT=3000 ./site
