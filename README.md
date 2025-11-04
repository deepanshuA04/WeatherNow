# WeatherNow Application

A simple weather application with React frontend and Node.js backend, containerized with Docker and deployed using Jenkins CI/CD pipeline to AWS.

## Prerequisites

- Node.js (v16 or later)
- Docker
- Jenkins
- AWS Account
- OpenWeather API Key

## Local Development

1. Clone the repository:
```bash
git clone <your-repo-url>
cd WeatherNow
```

2. Set up environment variables:
Create a `.env` file in the backend directory:
```
WEATHER_API_KEY=your_openweather_api_key
```

3. Install dependencies and start the application:

Backend:
```bash
cd backend
npm install
npm start
```

Frontend:
```bash
cd frontend
npm install
npm start
```

## Docker Deployment

1. Build and run using Docker Compose:
```bash
docker-compose up --build
```

The application will be available at:
- Frontend: http://localhost:3000
- Backend: http://localhost:5000

## CI/CD Pipeline

The project includes a Jenkinsfile that:
1. Builds Docker images for frontend and backend
2. Pushes images to Amazon ECR
3. Registers ECS task definitions and deploys to AWS ECS

### Jenkins Setup Requirements

1. Install required Jenkins plugins:
   - Docker Pipeline
   - AWS Pipeline Steps
   - Docker Hub API Token

If you use ECR/GitHub Actions or Jenkins to push to ECR, ensure you have:
   - AWS Credentials configured in Jenkins (credential id: `aws-credentials`)
   - An IAM user or role with permissions: ECR (push/pull), ECS (register/update), SecretsManager (read secret), CloudWatch logs

2. Configure Jenkins credentials:
   - Docker Hub credentials (docker-hub-credentials)
   - AWS credentials (aws-credentials)

### AWS Setup

1. Create an ECS cluster
2. Set up task definitions for both services
3. Create an ECS service
4. Configure security groups and load balancer as needed

Example placeholders used in this repo
- AWS Account ID: 484907495137
- AWS Region: us-east-1

Files added to help deploy to ECS (edit ARNs/names if needed):
- `ecs/backend-taskdef.json` — task definition for backend (references ECR image and Secrets Manager ARN)
- `ecs/frontend-taskdef.json` — task definition for frontend (references ECR image)

Note: Replace the Secrets Manager ARN in `ecs/backend-taskdef.json` with the actual ARN from your account (it often includes a random suffix).

## Security Notes

- Never commit the `.env` file
- Keep API keys and credentials secure
- Use AWS IAM roles with minimum required permissions
- Configure security groups to restrict access appropriately