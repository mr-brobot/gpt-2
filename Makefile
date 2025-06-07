# config
INSTANCE_NAME := gpt-2
INSTANCE_TYPE := ml.t3.medium
ROLE_NAME := service-role/AmazonSageMaker-ExecutionRole-20250607T132660
LIFECYCLE_NAME := $(INSTANCE_NAME)-lifecycle
SSH_PORT := 11022
JUPYTER_PORT := 8888
SSH_ALIAS := sagemaker-ssh

# derived
ACCOUNT_ID := $(shell aws sts get-caller-identity --query "Account" --output text)
ROLE_ARN := arn:aws:iam::$(ACCOUNT_ID):role/$(ROLE_NAME)
INSTANCE_ID := $(shell aws ec2 describe-instances --filters "Name=tag:Name,Values=$(INSTANCE_NAME)" --query "Reservations[0].Instances[0].InstanceId" --output text 2>/dev/null || echo "MISSING")
VPC_ID := $(shell aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query "Vpcs[0].VpcId" --output text)
SUBNET_ID := $(shell aws ec2 describe-subnets --filters Name=vpc-id,Values=$(VPC_ID) --query "Subnets[0].SubnetId" --output text)
SECURITY_GROUP_ID := $(shell aws ec2 describe-security-groups --filters Name=vpc-id,Values=$(VPC_ID) Name=group-name,Values=default --query 'SecurityGroups[0].GroupId' --output text)

.PHONY: init connect config status stop destroy

validate:
	@echo "🔍 Validating prerequisites..."
	@aws sts get-caller-identity >/dev/null || (echo "❌ AWS credentials not configured" && exit 1)

init: validate
	@echo "🚀 Creating lifecycle config $(LIFECYCLE_NAME)..."
	@aws sagemaker create-notebook-instance-lifecycle-config \
	  --notebook-instance-lifecycle-config-name "$(LIFECYCLE_NAME)" \
	  --on-create Content=$$(base64 scripts/sagemaker/lifecycle.sh | tr -d '\n')

	@echo "📦 Creating notebook instance $(INSTANCE_NAME)..."
	@aws sagemaker create-notebook-instance \
	  --notebook-instance-name "$(INSTANCE_NAME)" \
	  --instance-type "$(INSTANCE_TYPE)" \
	  --role-arn "$(ROLE_ARN)" \
	  --subnet-id "$(SUBNET_ID)" \
	  --security-group-ids "$(SECURITY_GROUP_ID)" \
	  --lifecycle-config-name "$(LIFECYCLE_NAME)"

	@echo "✅ Notebook created."

status:
	@echo "🔍 Status of $(INSTANCE_NAME):"
	@aws sagemaker describe-notebook-instance \
	  --notebook-instance-name "$(INSTANCE_NAME)" \
	  --query "{Status:NotebookInstanceStatus,URL:NotebookInstanceUrl}" --output table

start:
	@echo "▶️ Starting notebook $(INSTANCE_NAME)..."
	@aws sagemaker start-notebook-instance \
	  --notebook-instance-name "$(INSTANCE_NAME)"

stop:
	@echo "🛑 Stopping notebook $(INSTANCE_NAME)..."
	@aws sagemaker stop-notebook-instance \
	  --notebook-instance-name "$(INSTANCE_NAME)"

destroy:
	@echo "🧨 Deleting notebook instance and lifecycle config..."
	@aws sagemaker delete-notebook-instance \
	  --notebook-instance-name "$(INSTANCE_NAME)" || echo "⚠️  Notebook instance may not exist"
	@aws sagemaker delete-notebook-instance-lifecycle-config \
	  --notebook-instance-lifecycle-config-name "$(LIFECYCLE_NAME)" || echo "⚠️  Lifecycle config may not exist"
	@echo "✅ Cleanup complete"

config:
	sm-local-configure

connect: config
	@echo "🔗 Starting SSH tunnel on port $(SSH_PORT)..."
	sm-ssh connect $(INSTANCE_NAME).notebook.sagemaker -L $(SSH_PORT):localhost:8888
