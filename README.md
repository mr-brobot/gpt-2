# GPT-2

https://www.youtube.com/watch?v=l8pRSuU81PU

## 🧪 VSCode + SageMaker Notebooks via SSH

This guide lets you run notebooks from your local **VSCode Jupyter extension** using a **remote SageMaker notebook instance**.

---

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **AWS Profile** (optional) - you can use `AWS_PROFILE=your-profile` prefix
3. **Permissions** to create SageMaker notebook instances, lifecycle configs, and access EC2/VPC resources

### Configuration

Before running any commands, update the configuration variables at the top of the `Makefile`:

```makefile
# config
INSTANCE_NAME := gpt-2                    # Change to your desired instance name
INSTANCE_TYPE := ml.t3.medium            # Adjust instance type as needed
ROLE_NAME := service-role/AmazonSageMaker-ExecutionRole-20250607T132660  # Update with your role
```

---

## 📋 Available Commands

### `make validate`

Validates that AWS credentials are properly configured.

```bash
make validate
# or with specific profile
AWS_PROFILE=your-profile make validate
```

### `make init`

Creates the entire SageMaker setup:

- Creates a lifecycle configuration that installs `sagemaker-ssh-helper`
- Creates a new SageMaker notebook instance with the lifecycle config
- Sets up the instance in your default VPC and subnet

```bash
make init
# or with specific profile
AWS_PROFILE=your-profile make init
```

**Note**: This command will fail if resources with the same names already exist.

### `make status`

Checks the current status of your notebook instance.

```bash
make status
```

### `make connect`

Establishes an SSH tunnel to the notebook instance and configures SSH alias.

```bash
make connect
```

This command:

- Adds an SSH configuration entry to `~/.ssh/config`
- Starts a port forwarding session from local port `11022` to the instance's SSH port `22`
- Keeps the session active (press Ctrl+C to disconnect)

### `make jupyter`

Forwards the Jupyter port from the remote instance to your local machine.

```bash
make jupyter
```

This forwards port `8888` from the SageMaker instance to your local port `8888`, allowing you to access Jupyter directly at `http://localhost:8888`.

### `make stop`

Stops the running notebook instance (but doesn't delete it).

```bash
make stop
```

### `make delete`

**⚠️ WARNING**: Permanently deletes the notebook instance and lifecycle configuration.

```bash
make delete
```

---

## ✅ Complete Workflow

### 1. Initial Setup

```bash
# Validate AWS credentials
AWS_PROFILE=your-profile make validate

# Create the SageMaker notebook instance
AWS_PROFILE=your-profile make init
```

### 2. Connect to Your Instance

```bash
# Check if instance is ready (status should be "InService")
AWS_PROFILE=your-profile make status

# Connect via SSH tunnel (run in one terminal)
AWS_PROFILE=your-profile make connect
```

### 3. Access Jupyter (Optional)

```bash
# In another terminal, forward Jupyter port
AWS_PROFILE=your-profile make jupyter
```

Now you can:

- Access Jupyter at `http://localhost:8888`
- Use VSCode's Jupyter extension to connect to the remote kernel
- SSH directly to the instance using `ssh sagemaker-ssh`

### 4. Cleanup

```bash
# Stop the instance to save costs
AWS_PROFILE=your-profile make stop

# Or completely delete everything
AWS_PROFILE=your-profile make delete
```

---

## 🔧 Advanced Configuration

### Custom Lifecycle Script

The lifecycle script is located at `scripts/sagemaker/lifecycle.sh`. You can modify it to install additional packages or configure the environment differently.

### Port Configuration

You can customize the ports used by modifying these variables in the Makefile:

```makefile
SSH_PORT := 11022      # Local SSH tunnel port
JUPYTER_PORT := 8888   # Local Jupyter port
```

### Instance Configuration

Adjust the instance type and other settings:

```makefile
INSTANCE_TYPE := ml.t3.medium    # Can be ml.t3.small, ml.m5.large, etc.
```

---

## 🐛 Troubleshooting

### "AWS credentials not configured"

- Ensure AWS CLI is installed and configured: `aws configure`
- Or use AWS profiles: `AWS_PROFILE=your-profile make command`

### "INSTANCE_ID := MISSING"

- The instance might not be running or doesn't exist
- Run `make status` to check the instance state
- Make sure the `INSTANCE_NAME` matches your actual instance

### SSH Connection Issues

- Ensure the instance is in "InService" state: `make status`
- Check that the SSH tunnel is active: `make connect`
- Verify the SSH config: `cat ~/.ssh/config | grep -A 5 sagemaker-ssh`

### Port Already in Use

- Kill existing port forwards: `pkill -f "aws ssm start-session"`
- Or change the port numbers in the Makefile

---

## 📁 Project Structure

```
├── Makefile                    # Main automation script
├── README.md                   # This file
├── scripts/
│   └── sagemaker/
│       └── lifecycle.sh        # SageMaker instance startup script
└── nbs/
    └── 1__hf.ipynb            # Example notebook
```
