package integration_test

import (
	"bytes"
	"path/filepath"
	"testing"
	"time"

	"github.com/paketo-buildpacks/packit/pexec"
	"github.com/sclevine/spec"
	"github.com/sclevine/spec/report"

	. "github.com/onsi/gomega"
)

var goBuildpack string

func TestIntegration(t *testing.T) {
	Expect := NewWithT(t).Expect

	bash := pexec.NewExecutable("bash")
	buffer := bytes.NewBuffer(nil)
	err := bash.Execute(pexec.Execution{
		Args:   []string{"-c", "../scripts/package.sh --version 1.2.3"},
		Stdout: buffer,
		Stderr: buffer,
	})
	Expect(err).NotTo(HaveOccurred(), buffer.String)

	goBuildpack, err = filepath.Abs("../build/buildpackage.cnb")
	Expect(err).NotTo(HaveOccurred())

	SetDefaultEventuallyTimeout(10 * time.Second)

	suite := spec.New("Integration", spec.Parallel(), spec.Report(report.Terminal{}))
	suite("Build", testBuild)
	suite("Dep", testDep)
	suite("GoMod", testGoMod)
	suite.Run(t)
}
