package integration_test

import (
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	"github.com/paketo-buildpacks/occam"
	"github.com/sclevine/spec"
	"github.com/sclevine/spec/report"

	. "github.com/onsi/gomega"
)

var goBuildpack string

func TestIntegration(t *testing.T) {
	pack := occam.NewPack()
	Expect := NewWithT(t).Expect

	output, err := exec.Command("bash", "-c", "../scripts/package.sh --version 1.2.3").CombinedOutput()
	Expect(err).NotTo(HaveOccurred(), string(output))

	goBuildpack, err = filepath.Abs("../build/buildpackage.cnb")
	Expect(err).NotTo(HaveOccurred())

	SetDefaultEventuallyTimeout(10 * time.Second)

	suite := spec.New("Integration", spec.Parallel(), spec.Report(report.Terminal{}))
	suite("Build", testBuild)
	suite("GoMod", testGoMod)
	suite("ReproducibleBuilds", testReproducibleBuilds)
	suite.Run(t)

	// Only perform the graceful stack upgrade test on the Bionic base stack
	builder, _ := pack.Builder.Inspect.Execute()
	if builder.BuilderName == "paketobuildpacks/builder:buildpackless-base" {
		spec.Run(t, "StackUpgrades", testGracefulStackUpgrades, spec.Report(report.Terminal{}))
	}
}
