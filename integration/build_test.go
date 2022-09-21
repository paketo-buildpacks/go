package integration_test

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"
	"testing"

	"github.com/paketo-buildpacks/occam"
	"github.com/sclevine/spec"

	. "github.com/onsi/gomega"
	. "github.com/paketo-buildpacks/occam/matchers"
)

func testBuild(t *testing.T, context spec.G, it spec.S) {
	var (
		Expect     = NewWithT(t).Expect
		Eventually = NewWithT(t).Eventually

		pack   occam.Pack
		docker occam.Docker
	)

	it.Before(func() {
		pack = occam.NewPack()
		docker = occam.NewDocker()
	})

	context("when building a go app with no package manager", func() {
		var (
			image     occam.Image
			container occam.Container

			name    string
			source  string
			sbomDir string
		)

		it.Before(func() {
			var err error
			name, err = occam.RandomName()
			Expect(err).NotTo(HaveOccurred())

			source, err = occam.Source(filepath.Join("testdata", "build"))
			Expect(err).NotTo(HaveOccurred())

			sbomDir, err = os.MkdirTemp("", "sbom")
			Expect(err).NotTo(HaveOccurred())
			Expect(os.Chmod(sbomDir, os.ModePerm)).To(Succeed())
		})

		it.After(func() {
			Expect(docker.Container.Remove.Execute(container.ID)).To(Succeed())
			Expect(docker.Image.Remove.Execute(image.ID)).To(Succeed())
			Expect(docker.Volume.Remove.Execute(occam.CacheVolumeNames(name))).To(Succeed())
			Expect(os.RemoveAll(source)).To(Succeed())
			Expect(os.RemoveAll(sbomDir)).To(Succeed())
		})

		it("creates a working OCI image", func() {
			var err error
			var logs fmt.Stringer
			image, logs, err = pack.WithNoColor().Build.
				WithBuildpacks(goBuildpack).
				WithSBOMOutputDir(sbomDir).
				WithPullPolicy("never").
				Execute(name, source)
			Expect(err).NotTo(HaveOccurred(), logs.String())

			container, err = docker.Container.Run.
				WithEnv(map[string]string{"PORT": "8080"}).
				WithPublish("8080").
				WithPublishAll().
				Execute(image.ID)
			Expect(err).NotTo(HaveOccurred())

			Eventually(container).Should(Serve(ContainSubstring("Hello, World!")).OnPort(8080))

			Expect(logs).To(ContainLines(ContainSubstring("Buildpack for Go Distribution")))
			Expect(logs).To(ContainLines(ContainSubstring("Buildpack for Go Build")))

			Expect(logs).NotTo(ContainLines(ContainSubstring("Buildpack for Go Mod Vendor")))
			Expect(logs).NotTo(ContainLines(ContainSubstring("Buildpack for Procfile")))
			Expect(logs).NotTo(ContainLines(ContainSubstring("Buildpack for Environment Variables")))
			Expect(logs).NotTo(ContainLines(ContainSubstring("Buildpack for Image Labels")))
			Expect(logs).NotTo(ContainLines(ContainSubstring("Buildpack for Git")))

			// check that all required SBOM files are present
			Expect(filepath.Join(sbomDir, "sbom", "build", "paketo-buildpacks_go-dist", "go", "sbom.cdx.json")).To(BeARegularFile())
			Expect(filepath.Join(sbomDir, "sbom", "build", "paketo-buildpacks_go-dist", "go", "sbom.spdx.json")).To(BeARegularFile())
			Expect(filepath.Join(sbomDir, "sbom", "build", "paketo-buildpacks_go-dist", "go", "sbom.syft.json")).To(BeARegularFile())

			Expect(filepath.Join(sbomDir, "sbom", "launch", "paketo-buildpacks_go-build", "targets", "sbom.cdx.json")).To(BeARegularFile())
			Expect(filepath.Join(sbomDir, "sbom", "launch", "paketo-buildpacks_go-build", "targets", "sbom.spdx.json")).To(BeARegularFile())
			Expect(filepath.Join(sbomDir, "sbom", "launch", "paketo-buildpacks_go-build", "targets", "sbom.syft.json")).To(BeARegularFile())
		})

		context("using optional utility buildpacks", func() {
			var procfileContainer occam.Container
			it.Before(func() {
				Expect(os.WriteFile(filepath.Join(source, "Procfile"),
					[]byte("procfile: /layers/paketo-buildpacks_go-build/targets/bin/workspace --moon"),
					0644)).To(Succeed())
			})

			it.After(func() {
				Expect(docker.Container.Remove.Execute(procfileContainer.ID)).To(Succeed())
			})

			it("builds a working OCI image with start command from the Procfile and incorporating the utility buildpacks' effects", func() {
				var err error
				var logs fmt.Stringer
				image, logs, err = pack.WithNoColor().Build.
					WithBuildpacks(goBuildpack).
					WithPullPolicy("never").
					WithEnv(map[string]string{
						"BPE_SOME_VARIABLE":      "some-value",
						"BP_IMAGE_LABELS":        "some-label=some-value",
						"BP_LIVE_RELOAD_ENABLED": "true",
					}).
					Execute(name, source)
				Expect(err).NotTo(HaveOccurred(), logs.String())

				Expect(image.Buildpacks[5].Key).To(Equal("paketo-buildpacks/environment-variables"))
				Expect(image.Buildpacks[5].Layers["environment-variables"].Metadata["variables"]).To(Equal(map[string]interface{}{"SOME_VARIABLE": "some-value"}))
				Expect(image.Labels["some-label"]).To(Equal("some-value"))

				Expect(logs).To(ContainLines(ContainSubstring("Buildpack for Go Distribution")))
				Expect(logs).To(ContainLines(ContainSubstring("Buildpack for Go Build")))
				Expect(logs).To(ContainLines(ContainSubstring("Buildpack for Procfile")))
				Expect(logs).To(ContainLines(ContainSubstring("Buildpack for Environment Variables")))
				Expect(logs).To(ContainLines(ContainSubstring("Buildpack for Image Labels")))
				Expect(logs).To(ContainLines(ContainSubstring("Buildpack for Watchexec")))

				container, err = docker.Container.Run.
					WithEnv(map[string]string{"PORT": "8080"}).
					WithPublish("8080").
					WithPublishAll().
					Execute(image.ID)
				Expect(err).NotTo(HaveOccurred())

				Eventually(container).Should(Serve(ContainSubstring("Hello, World!")).OnPort(8080))

				procfileContainer, err = docker.Container.Run.
					WithEntrypoint("procfile").
					WithEnv(map[string]string{"PORT": "8080"}).
					WithPublish("8080").
					WithPublishAll().
					Execute(image.ID)
				Expect(err).NotTo(HaveOccurred())

				Eventually(procfileContainer).Should(Serve(ContainSubstring("Hello, Moon!")).OnPort(8080))
			})
		})

		context("when building a dep app that is vendored", func() {
			it("creates a working OCI image", func() {
				var err error
				var logs fmt.Stringer
				image, logs, err = pack.WithNoColor().Build.
					WithBuildpacks(goBuildpack).
					WithPullPolicy("never").
					Execute(name, source)
				Expect(err).NotTo(HaveOccurred(), logs.String())

				container, err = docker.Container.Run.
					WithEnv(map[string]string{"PORT": "8080"}).
					WithPublish("8080").
					WithPublishAll().
					Execute(image.ID)
				Expect(err).NotTo(HaveOccurred())

				Eventually(container).Should(Serve(ContainSubstring("Hello, World!")).OnPort(8080))

				Expect(logs).To(ContainLines(ContainSubstring("Buildpack for Go Distribution")))
				Expect(logs).To(ContainLines(ContainSubstring("Buildpack for Go Build")))

				Expect(logs).NotTo(ContainLines(ContainSubstring("Buildpack for Go Mod Vendor")))
				Expect(logs).NotTo(ContainLines(ContainSubstring("Buildpack for Procfile")))
				Expect(logs).NotTo(ContainLines(ContainSubstring("Buildpack for Environment Variables")))
				Expect(logs).NotTo(ContainLines(ContainSubstring("Buildpack for Image Labels")))
				Expect(logs).NotTo(ContainLines(ContainSubstring("Buildpack for Git")))
			})
		})

		context("when using CA certificates", func() {
			var (
				client *http.Client
			)

			it.Before(func() {
				var err error
				source, err = occam.Source(filepath.Join("testdata", "ca_certificate_apps"))
				Expect(err).NotTo(HaveOccurred())

				caCert, err := ioutil.ReadFile(filepath.Join(source, "client_certs", "ca.pem"))
				Expect(err).ToNot(HaveOccurred())

				caCertPool := x509.NewCertPool()
				caCertPool.AppendCertsFromPEM(caCert)

				cert, err := tls.LoadX509KeyPair(filepath.Join(source, "client_certs", "cert.pem"), filepath.Join(source, "client_certs", "key.pem"))
				Expect(err).ToNot(HaveOccurred())

				client = &http.Client{
					Transport: &http.Transport{
						TLSClientConfig: &tls.Config{
							RootCAs:      caCertPool,
							Certificates: []tls.Certificate{cert},
							MinVersion:   tls.VersionTLS12,
						},
					},
				}
			})

			it("builds a working OCI image and uses a client-side CA cert for requests", func() {
				var err error
				var logs fmt.Stringer
				image, logs, err = pack.WithNoColor().Build.
					WithBuildpacks(goBuildpack).
					WithPullPolicy("never").
					WithEnv(map[string]string{
						"BP_KEEP_FILES": "key.pem:cert.pem",
					}).
					Execute(name, filepath.Join(source, "build"))
				Expect(err).NotTo(HaveOccurred())

				Expect(logs).To(ContainLines(ContainSubstring("Buildpack for CA Certificates")))
				Expect(logs).To(ContainLines(ContainSubstring("Buildpack for Go Distribution")))
				Expect(logs).To(ContainLines(ContainSubstring("Buildpack for Go Build")))

				container, err = docker.Container.Run.
					WithPublish("8080").
					WithEnv(map[string]string{
						"PORT":                 "8080",
						"SERVICE_BINDING_ROOT": "/bindings",
					}).
					WithVolumes(fmt.Sprintf("%s:/bindings/ca-certificates", filepath.Join(source, "binding"))).
					Execute(image.ID)
				Expect(err).NotTo(HaveOccurred())

				Eventually(func() string {
					cLogs, err := docker.Container.Logs.Execute(container.ID)
					Expect(err).NotTo(HaveOccurred())
					return cLogs.String()
				}).Should(
					ContainSubstring("Added 1 additional CA certificate(s) to system truststore"),
				)

				request, err := http.NewRequest("GET", fmt.Sprintf("https://localhost:%s", container.HostPort("8080")), nil)
				Expect(err).NotTo(HaveOccurred())

				Eventually(func() string {
					response, err := client.Do(request)
					if err != nil {
						return ""
					}
					defer response.Body.Close()

					content, err := ioutil.ReadAll(response.Body)
					if err != nil {
						return ""
					}

					return string(content)
				}).Should(ContainSubstring("Hello, World!"))
			})
		})
	})
}
