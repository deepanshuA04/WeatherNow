IAM helper — create minimal roles for ECS tasks

These files help create two roles used by ECS:

- `ecs-execution-trust-policy.json` — trust policy allowing `ecs-tasks.amazonaws.com` to assume the role.
- `weathernow-task-role-policy.json` — minimal inline policy for the application task role (Secrets Manager + CloudWatch Logs).

Quick CLI commands (run from a machine with AWS CLI configured and an account with IAM permissions). Replace names/ARNs if you changed them.

1) Create the execution role (this role should also have the AWS managed policy `AmazonECSTaskExecutionRolePolicy` attached):

```bash
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://iam/ecs-execution-trust-policy.json

# attach AWS managed policy (allows ECR pull, CloudWatch Logs write, etc.)
aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

2) Create the task role (role the container uses) and attach the inline policy we generated:

```bash
aws iam create-role \
  --role-name weathernowTaskRole \
  --assume-role-policy-document file://iam/ecs-execution-trust-policy.json

aws iam put-role-policy \
  --role-name weathernowTaskRole \
  --policy-name weathernow-task-policy \
  --policy-document file://iam/weathernow-task-role-policy.json
```

Notes & next steps
- The `ecsTaskExecutionRole` uses a managed policy — that's the recommended approach because it includes necessary permissions for pulling images from ECR and writing logs.
- The inline policy `weathernow-task-policy` grants read access to Secrets Manager entries matching `weathernow/*` and CloudWatch Logs access for `/ecs/*` log groups — update the ARNs if your secret name is different.
- After creating roles, copy the role ARNs into the `ecs/*.json` task definition `executionRoleArn` and `taskRoleArn` fields if needed (the repo already contains placeholders for account 484907495137 in `ecs/`).

If you want, I can also generate a CloudFormation snippet to create these roles automatically.
