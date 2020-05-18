# Source Removal Buildpack

## Proposal

We should extract all application source removal functionality into a stand alone buildpack that can be an optional buildpack that can be added to any order grouping.

## Motivation

By using a centralized source removal solution the Go buildpacks will be feature consistent with other buildpacks that remove content from the application source making for a more consistent experience within the buildpack ecosystem.

## Implementation

Add an optional buildpack to the end of every order grouping whose sole responsibility will be the removal of application source bits from the working directory. An initial iteration of this buildpack exists [here](https://github.com/ForestEckhardt/clear-source), but some modifications would need to be made in order to fulfill all of Go's use cases.

{{REMOVE THIS SECTION BEFORE RATIFICATION!}}
