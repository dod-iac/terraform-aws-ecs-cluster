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
	"time"

	"github.com/stretchr/testify/require"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/aws/aws-sdk-go/service/cloudwatchlogs"
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

	tags := map[string]interface{}{
		"Automation": "Terraform",
		"Terratest":  "yes",
		"Test":       "TestTerraformSimpleExample",
	}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// TerraformDir is where the terraform state is found.
		TerraformDir: "../examples/simple",
		// Set the variables passed to terraform
		Vars: map[string]interface{}{
			"test_name": testName,
			"tags": tags,
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
	ecsClusterName := terraform.Output(t, terraformOptions, "ecs_cluster_name")

	s := session.Must(session.NewSession())

	c := ecs.New(s, aws.NewConfig().WithRegion(region))

	logs := cloudwatchlogs.New(s, aws.NewConfig().WithRegion(region))

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

  message := fmt.Sprintf("test message for %s", testName)

  cloudwatchLogGroupName := terraform.Output(t, terraformOptions, "cloudwatch_log_group_name")
	ecsTaskExecutionRoleArn := terraform.Output(t, terraformOptions, "ecs_task_execution_role_arn")
	ecsTaskRoleArn := terraform.Output(t, terraformOptions, "ecs_task_role_arn")

	registerTaskDefinitionOutput, registerTaskDefinitionError := c.RegisterTaskDefinition(&ecs.RegisterTaskDefinitionInput{
		ContainerDefinitions: []*ecs.ContainerDefinition{
			&ecs.ContainerDefinition{
				Command: []*string{},
				Cpu: aws.Int64(128),
				EntryPoint: []*string{aws.String("/bin/echo"), aws.String(message)},
				Essential: aws.Bool(true),
				Image: aws.String("debian:latest"),
				LogConfiguration: &ecs.LogConfiguration{
					LogDriver: aws.String("awslogs"),
					Options: map[string]*string{
						"awslogs-group": aws.String(cloudwatchLogGroupName),
						"awslogs-region": aws.String(region),
						"awslogs-stream-prefix": aws.String(testName),
					},
				},
				Memory: aws.Int64(128),
				Name: aws.String(testName),
				ReadonlyRootFilesystem: aws.Bool(true),
				StopTimeout: aws.Int64(5),
			},
		},
		ExecutionRoleArn: aws.String(ecsTaskExecutionRoleArn),
		TaskRoleArn: aws.String(ecsTaskRoleArn),
		Family: aws.String(testName),
		NetworkMode: aws.String("bridge"),
		RequiresCompatibilities: []*string{aws.String("EC2")},
		Tags: []*ecs.Tag{
			&ecs.Tag{
				Key: aws.String("Automation"),
				Value: aws.String("Terraform"),
			},
			&ecs.Tag{
				Key: aws.String("Terratest"),
				Value: aws.String("yes"),
			},
			&ecs.Tag{
				Key: aws.String("Test"),
				Value: aws.String("TestTerraformSimpleExample"),
			},
		},
	})
	require.NoError(t, registerTaskDefinitionError)
	taskDefinition := fmt.Sprintf(
		"%s:%d",
		aws.StringValue(registerTaskDefinitionOutput.TaskDefinition.Family),
		int(aws.Int64Value(registerTaskDefinitionOutput.TaskDefinition.Revision)),
	)

	// If TT_SKIP_DESTROY is set to "1" then do not deregister the task definition.
	if os.Getenv("TT_SKIP_DESTROY") != "1" {
		defer func() {
			_, _ = c.DeregisterTaskDefinition(&ecs.DeregisterTaskDefinitionInput{
			 TaskDefinition:  aws.String(taskDefinition),
		 })
		} ()
	}

	// Wait for EC2-backed container instance to spin up.
	for i := 0 ; true; i++ {
		listContainerInstancesOutput, listContainerInstancesError := c.ListContainerInstances(&ecs.ListContainerInstancesInput{
			Cluster: aws.String(ecsClusterName),
			Status: aws.String("ACTIVE"),
		})
		require.NoError(t, listContainerInstancesError)
		if len(listContainerInstancesOutput.ContainerInstanceArns) > 0 {
			break
		}
		time.Sleep(15*time.Second)
		if i == 12 {
			require.Fail(t, "ECS Cluster had no instances after 1 minute")
		}
	}

	runTaskOutput, runTaskError := c.RunTask(&ecs.RunTaskInput{
		Cluster: aws.String(ecsClusterName),
		Count: aws.Int64(1),
		LaunchType: aws.String("EC2"),
		PropagateTags: aws.String("TASK_DEFINITION"),
		TaskDefinition: aws.String(taskDefinition),
	})
	require.NoError(t, runTaskError)
	require.Len(t, runTaskOutput.Failures, 0)

  // Wait for log messages to be saved
	time.Sleep(15*time.Second)

	filterLogEventsOutput, filterLogEventsError := logs.FilterLogEvents(&cloudwatchlogs.FilterLogEventsInput{
		LogGroupName: aws.String(cloudwatchLogGroupName),
	})
	require.NoError(t, filterLogEventsError)
	require.Len(t, filterLogEventsOutput.Events, 1)
	require.Equal(t, message, aws.StringValue(filterLogEventsOutput.Events[0].Message))
}
