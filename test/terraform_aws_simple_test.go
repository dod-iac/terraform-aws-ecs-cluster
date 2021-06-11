// =================================================================
//
// Work of the U.S. Department of Defense, Defense Digital Service.
// Released as open source under the MIT License.  See LICENSE file.
//
// =================================================================

package test

import (
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ecs"
)

func TestTerraformSimpleExample(t *testing.T) {

	// Allow test to run in parallel with other tests
	t.Parallel()

	region := os.Getenv("AWS_DEFAULT_REGION")

	// If AWS_DEFAULT_REGION environment variable is not set, then fail the test.
	require.NotEmpty(t, region, "missing environment variable AWS_DEFAULT_REGION")

	// Append a random suffix to the test name, so individual test runs are unique.
	// When the test runs again, it will use the existing terraform state,
	// so it should override the existing infrastructure.
	testName := fmt.Sprintf("terratest-ecs-cluster-simple-%s", strings.ToLower(random.UniqueId()))

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// TerraformDir is where the terraform state is found.
		TerraformDir: "../examples/simple",
		// Set the variables passed to terraform
		Vars: map[string]interface{}{
			"test_name": testName,
			"tags": map[string]interface{}{
				"Automation": "Terraform",
				"Terratest":  "yes",
				"Test":       "TestTerraformSimpleExample",
			},
		},
		// Set the environment variables passed to terraform.
		// AWS_DEFAULT_REGION is the only environment variable strictly required,
		// when using the AWS provider.
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	})

	// If TT_SKIP_DESTROY is set to "1" then do not destroy the intrastructure,
	// at the end of the test run
	if os.Getenv("TT_SKIP_DESTROY") != "1" {
		defer terraform.Destroy(t, terraformOptions)
	}

	// InitAndApply runs "terraform init" and then "terraform apply"
	terraform.InitAndApply(t, terraformOptions)

	ecsClusterARN := terraform.Output(t, terraformOptions, "ecs_cluster_arn")

	s := session.Must(session.NewSession())

	c := ecs.New(s, aws.NewConfig().WithRegion(region))

	describeClustersOutput, describeClustersError := c.DescribeClusters(&ecs.DescribeClustersInput{
		Clusters: []*string{
			aws.String(ecsClusterARN),
		},
	})

	require.NoError(t, describeClustersError)
	require.NotNil(t, describeClustersOutput)
	require.Len(t, describeClustersOutput.Clusters, 1)

	status := aws.StringValue(describeClustersOutput.Clusters[0].Status)
	require.Equal(t, "ACTIVE", status)
}
