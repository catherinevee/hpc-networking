package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestHPCNetworkingBasic(t *testing.T) {
	t.Parallel()

	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",

		// Variables to pass to Terraform
		Vars: map[string]interface{}{
			"vpc_id": "vpc-test-12345", // Replace with test VPC ID
		},

		// Environment variables
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-east-1",
		},
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Test outputs
	instanceCount := terraform.Output(t, terraformOptions, "instance_count")
	assert.Equal(t, "8", instanceCount)

	// Test that instances are created
	instanceIds := terraform.OutputList(t, terraformOptions, "instance_ids")
	assert.Len(t, instanceIds, 8)

	// Test that FSx for Lustre is created
	fsxId := terraform.Output(t, terraformOptions, "fsx_file_system_id")
	assert.NotEmpty(t, fsxId)

	// Test that placement group is created
	placementGroupId := terraform.Output(t, terraformOptions, "placement_group_id")
	assert.NotEmpty(t, placementGroupId)

	// Test that security groups are created
	securityGroupId := terraform.Output(t, terraformOptions, "efa_security_group_id")
	assert.NotEmpty(t, securityGroupId)
}

func TestHPCNetworkingAdvanced(t *testing.T) {
	t.Parallel()

	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/advanced",

		// Variables to pass to Terraform
		Vars: map[string]interface{}{
			"vpc_id": "vpc-test-12345", // Replace with test VPC ID
		},

		// Environment variables
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-east-1",
		},
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Test auto scaling group
	asgName := terraform.Output(t, terraformOptions, "autoscaling_group_name")
	assert.NotEmpty(t, asgName)

	// Test that auto scaling group has correct configuration
	asg := aws.GetAsgByName(t, asgName, "us-east-1")
	assert.Equal(t, int64(8), asg.DesiredCapacity)
	assert.Equal(t, int64(2), asg.MinSize)
	assert.Equal(t, int64(16), asg.MaxSize)

	// Test CloudWatch dashboard
	dashboardName := terraform.Output(t, terraformOptions, "dashboard_name")
	assert.NotEmpty(t, dashboardName)

	// Test SNS topic
	snsTopicArn := terraform.Output(t, terraformOptions, "sns_topic_arn")
	assert.NotEmpty(t, snsTopicArn)
}

func TestHPCNetworkingMultiRegion(t *testing.T) {
	t.Parallel()

	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/multi-region",

		// Variables to pass to Terraform
		Vars: map[string]interface{}{
			"primary_vpc_id":   "vpc-primary-test",
			"secondary_vpc_id": "vpc-secondary-test",
		},

		// Environment variables
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-east-1",
		},
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Test primary cluster
	primaryInstances := terraform.OutputList(t, terraformOptions, "primary_instance_ids")
	assert.Len(t, primaryInstances, 8)

	// Test secondary cluster
	secondaryInstances := terraform.OutputList(t, terraformOptions, "secondary_instance_ids")
	assert.Len(t, secondaryInstances, 8)

	// Test shared data bucket
	primaryBucket := terraform.Output(t, terraformOptions, "primary_bucket_name")
	assert.NotEmpty(t, primaryBucket)

	secondaryBucket := terraform.Output(t, terraformOptions, "secondary_bucket_name")
	assert.NotEmpty(t, secondaryBucket)

	// Test S3 replication
	replicationRoleArn := terraform.Output(t, terraformOptions, "replication_role_arn")
	assert.NotEmpty(t, replicationRoleArn)
}

func TestHPCNetworkingPerformance(t *testing.T) {
	t.Parallel()

	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",

		// Variables to pass to Terraform
		Vars: map[string]interface{}{
			"vpc_id": "vpc-test-12345",
		},

		// Environment variables
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-east-1",
		},
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Test performance metrics
	expectedBandwidth := terraform.Output(t, terraformOptions, "expected_bandwidth_gbps")
	assert.Equal(t, "3200", expectedBandwidth)

	expectedLatency := terraform.Output(t, terraformOptions, "expected_latency_us")
	assert.Equal(t, "50", expectedLatency)

	gpuCount := terraform.Output(t, terraformOptions, "gpu_count")
	assert.Equal(t, "8", gpuCount)

	// Test EFA environment variables
	efaEnvVars := terraform.OutputMap(t, terraformOptions, "efa_environment_variables")
	assert.NotEmpty(t, efaEnvVars)
	assert.Equal(t, "1", efaEnvVars["FI_EFA_FORK_SAFE"])
	assert.Equal(t, "1", efaEnvVars["FI_EFA_USE_DEVICE_RDMA"])
}

func TestHPCNetworkingSecurity(t *testing.T) {
	t.Parallel()

	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",

		// Variables to pass to Terraform
		Vars: map[string]interface{}{
			"vpc_id": "vpc-test-12345",
		},

		// Environment variables
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-east-1",
		},
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Test security groups
	efaSecurityGroupId := terraform.Output(t, terraformOptions, "efa_security_group_id")
	assert.NotEmpty(t, efaSecurityGroupId)

	// Test IAM roles
	ec2RoleArn := terraform.Output(t, terraformOptions, "ec2_role_arn")
	assert.NotEmpty(t, ec2RoleArn)

	// Test KMS encryption
	kmsKeyId := terraform.Output(t, terraformOptions, "kms_key_id")
	assert.NotEmpty(t, kmsKeyId)

	// Test VPC endpoints
	vpcEndpoints := terraform.OutputList(t, terraformOptions, "vpc_endpoint_ids")
	assert.NotEmpty(t, vpcEndpoints)
}

func TestHPCNetworkingCostOptimization(t *testing.T) {
	t.Parallel()

	// Configure Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/advanced",

		// Variables to pass to Terraform
		Vars: map[string]interface{}{
			"vpc_id": "vpc-test-12345",
		},

		// Environment variables
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-east-1",
		},
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Test cost optimization features
	vpcEndpointsEnabled := terraform.Output(t, terraformOptions, "vpc_endpoints_enabled")
	assert.Equal(t, "true", vpcEndpointsEnabled)

	spotInstancesAllowed := terraform.Output(t, terraformOptions, "spot_instances_allowed")
	assert.Equal(t, "true", spotInstancesAllowed)

	encryptionEnabled := terraform.Output(t, terraformOptions, "encryption_enabled")
	assert.Equal(t, "true", encryptionEnabled)
}

// Helper function to wait for instances to be running
func waitForInstancesRunning(t *testing.T, instanceIds []string, region string) {
	for _, instanceId := range instanceIds {
		aws.WaitForSsmInstance(t, region, instanceId, 10*time.Minute, 30*time.Second)
	}
}

// Helper function to test network connectivity
func testNetworkConnectivity(t *testing.T, instanceIds []string, region string) {
	// This would typically involve SSH'ing into instances and running network tests
	// For now, we'll just verify the instances are running
	waitForInstancesRunning(t, instanceIds, region)
}
