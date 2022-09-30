package integration_test

import (
	"os/exec"
	"path/filepath"
	"strings"
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

	// Only perform the graceful stack upgrade test on stacks that aren't jammy
	builder, _ := pack.Builder.Inspect.Execute()
	if !strings.Contains(builder.LocalInfo.Stack.ID, "io.buildpacks.stacks.jammy") {
		suite("StackUpgrades", testGracefulStackUpgrades)
	}
	suite.Run(t)
}
