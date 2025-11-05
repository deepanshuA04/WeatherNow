# WeatherNow ECS Setup Script
# Run this with admin AWS credentials configured
# The script will:
# 1. Create and attach trust policies
# 2. Attach execution role policy
# 3. Create CloudWatch log groups
# 4. Attach PassRole policy to Jenkins user
# 5. Force new ECS deployments
# 6. Show service events and logs

$ErrorActionPreference = "Stop"
$region = "us-east-1"
$account = "164334671507"
$jenkinsUser = "weathernow"  # Change if your Jenkins uses a different user

# Create temporary policy files
$trustPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@

$jenkinsPassRolePolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": [
        "arn:aws:iam::${account}:role/ecsTaskExecutionRole",
        "arn:aws:iam::${account}:role/weathernowTaskRole"
      ]
    }
  ]
}
"@

# Function to wait for user confirmation
function Confirm-Action {
    param($message)
    Write-Host "${message} (y/n)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -ne "y") {
        Write-Host "Skipping..." -ForegroundColor Yellow
        return $false
    }
    return $true
}

Write-Host "=== WeatherNow ECS Setup Script ===" -ForegroundColor Cyan

# 1. Update trust policies
if (Confirm-Action "Update trust policies for ecsTaskExecutionRole and weathernowTaskRole?") {
    Write-Host "Updating trust policies..." -ForegroundColor Green
    $trustPolicy | Set-Content trust-policy.json
    
    try {
        aws iam update-assume-role-policy --role-name ecsTaskExecutionRole --policy-document file://trust-policy.json --region $region
        Write-Host "Updated ecsTaskExecutionRole trust policy" -ForegroundColor Green
        
        aws iam update-assume-role-policy --role-name weathernowTaskRole --policy-document file://trust-policy.json --region $region
        Write-Host "Updated weathernowTaskRole trust policy" -ForegroundColor Green
    }
    catch {
        Write-Host "Error updating trust policies: $_" -ForegroundColor Red
    }
}

# 2. Attach execution role policy
if (Confirm-Action "Attach AmazonECSTaskExecutionRolePolicy to ecsTaskExecutionRole?") {
    Write-Host "Attaching AmazonECSTaskExecutionRolePolicy..." -ForegroundColor Green
    try {
        aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy --region $region
        Write-Host "Attached AmazonECSTaskExecutionRolePolicy" -ForegroundColor Green
    }
    catch {
        Write-Host "Error attaching execution role policy: $_" -ForegroundColor Red
    }
}

# 3. Create CloudWatch log groups with retention
if (Confirm-Action "Create CloudWatch log groups with 14-day retention?") {
    Write-Host "Creating CloudWatch log groups..." -ForegroundColor Green
    try {
        # Backend log group
        aws logs create-log-group --log-group-name /ecs/weathernow-backend --region $region
        aws logs put-retention-policy --log-group-name /ecs/weathernow-backend --retention-in-days 14 --region $region
        Write-Host "Created /ecs/weathernow-backend log group" -ForegroundColor Green
        
        # Frontend log group
        aws logs create-log-group --log-group-name /ecs/weathernow-frontend --region $region
        aws logs put-retention-policy --log-group-name /ecs/weathernow-frontend --retention-in-days 14 --region $region
        Write-Host "Created /ecs/weathernow-frontend log group" -ForegroundColor Green
    }
    catch {
        Write-Host "Error creating log groups (they may already exist): $_" -ForegroundColor Yellow
    }
}

# 4. Attach PassRole policy to Jenkins user
if (Confirm-Action "Attach PassRole policy to Jenkins user ($jenkinsUser)?") {
    Write-Host "Attaching PassRole policy..." -ForegroundColor Green
    $jenkinsPassRolePolicy | Set-Content jenkins-pass-role-policy.json
    
    try {
        aws iam put-user-policy --user-name $jenkinsUser --policy-name JenkinsPassRolePolicy --policy-document file://jenkins-pass-role-policy.json --region $region
        Write-Host "Attached PassRole policy to $jenkinsUser" -ForegroundColor Green
    }
    catch {
        Write-Host "Error attaching PassRole policy: $_" -ForegroundColor Red
    }
}

# 5. Force new ECS deployments
if (Confirm-Action "Force new ECS service deployments?") {
    Write-Host "Forcing new deployments..." -ForegroundColor Green
    try {
        aws ecs update-service --cluster weathernow-cluster --service weathernow-backend-service --force-new-deployment --region $region
        Write-Host "Triggered backend service deployment" -ForegroundColor Green
        
        aws ecs update-service --cluster weathernow-cluster --service weathernow-frontend-service --force-new-deployment --region $region
        Write-Host "Triggered frontend service deployment" -ForegroundColor Green
    }
    catch {
        Write-Host "Error forcing deployments: $_" -ForegroundColor Red
    }
}

# 6. Show service events and logs
if (Confirm-Action "Check service events and logs?") {
    Write-Host "=== Backend Service Events ===" -ForegroundColor Cyan
    aws ecs describe-services --cluster weathernow-cluster --services weathernow-backend-service --region $region | ConvertFrom-Json | Select-Object -ExpandProperty services | Select-Object -ExpandProperty events | Select-Object -First 5
    
    Write-Host "=== Frontend Service Events ===" -ForegroundColor Cyan
    aws ecs describe-services --cluster weathernow-cluster --services weathernow-frontend-service --region $region | ConvertFrom-Json | Select-Object -ExpandProperty services | Select-Object -ExpandProperty events | Select-Object -First 5
    
    Write-Host "=== CloudWatch Log Groups ===" -ForegroundColor Cyan
    aws logs describe-log-groups --log-group-name-prefix /ecs/weathernow --region $region
    
    # Show most recent log streams for both services
    Write-Host "=== Recent Backend Log Streams ===" -ForegroundColor Cyan
    aws logs describe-log-streams --log-group-name /ecs/weathernow-backend --order-by LastEventTime --descending --limit 3 --region $region
    
    Write-Host "=== Recent Frontend Log Streams ===" -ForegroundColor Cyan
    aws logs describe-log-streams --log-group-name /ecs/weathernow-frontend --order-by LastEventTime --descending --limit 3 --region $region
}

# Cleanup temporary files
Remove-Item -Force trust-policy.json -ErrorAction SilentlyContinue
Remove-Item -Force jenkins-pass-role-policy.json -ErrorAction SilentlyContinue

Write-Host "Script completed. Check the output above for any errors." -ForegroundColor Cyan
Write-Host "If tasks still fail to start, run these commands to debug:" -ForegroundColor Yellow
Write-Host "aws ecs list-tasks --cluster weathernow-cluster --service-name weathernow-backend-service --desired-status STOPPED --region $region" -ForegroundColor Gray
Write-Host "aws ecs describe-tasks --cluster weathernow-cluster --tasks <taskArn> --region $region" -ForegroundColor Gray