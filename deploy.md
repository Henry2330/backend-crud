  aws ecs update-service \
    --cluster proyecto-cicd-dev-cluster \
    --service proyecto-cicd-dev-service \
    --force-new-deployment \
    --region us-east-1
  
  aws ecs wait services-stable \
    --cluster proyecto-cicd-dev-cluster \
    --services proyecto-cicd-dev-service \
    --region us-east-1
  shell: /usr/bin/bash -e {0}
  env:
    AWS_REGION: us-east-1
    ECR_REPOSITORY: proyecto-cicd-dev-app
    ECS_SERVICE: proyecto-cicd-dev-service
    ECS_CLUSTER: proyecto-cicd-dev-cluster
    ECS_TASK_DEFINITION: proyecto-cicd-dev-task
    CONTAINER_NAME: proyecto-cicd-dev-container
    AWS_DEFAULT_REGION: us-east-1
    AWS_ACCESS_KEY_ID: ***
    AWS_SECRET_ACCESS_KEY: ***
  
{
    "service": {
        "serviceArn": "arn:aws:ecs:us-east-1:478806200706:service/proyecto-cicd-dev-cluster/proyecto-cicd-dev-service",
        "serviceName": "proyecto-cicd-dev-service",
        "clusterArn": "arn:aws:ecs:us-east-1:478806200706:cluster/proyecto-cicd-dev-cluster",
        "loadBalancers": [
            {
                "targetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:478806200706:targetgroup/proyecto-cicd-dev-tg/d51a3e3922227021",
                "containerName": "proyecto-cicd-dev-container",
                "containerPort": 3000
            }
        ],
        "serviceRegistries": [],
        "status": "ACTIVE",
        "desiredCount": 1,
        "runningCount": 2,
        "pendingCount": 0,
        "launchType": "FARGATE",
        "platformVersion": "LATEST",
        "platformFamily": "Linux",
        "taskDefinition": "arn:aws:ecs:us-east-1:478806200706:task-definition/proyecto-cicd-dev-task:23",
        "deploymentConfiguration": {
            "deploymentCircuitBreaker": {
                "enable": false,
                "rollback": false
            },
            "maximumPercent": 200,
                "id": "ac47cf5e-fe2f-4fc5-9a7d-4bef59e3fe91",
                "createdAt": "2025-11-27T23:11:58.840000+00:00",
                "message": "(service proyecto-cicd-dev-service) registered 1 targets in (target-group arn:aws:elasticloadbalancing:us-east-1:478806200706:targetgroup/proyecto-cicd-dev-tg/d51a3e3922227021)"
            },
            {
                "id": "f58b18c4-2e91-416e-8adc-01c1523b8abf",
                "createdAt": "2025-11-27T23:11:30.005000+00:00",
                "message": "(service proyecto-cicd-dev-service) has started 1 tasks: (task f289c14ba9a64b66b35de099e6b09aeb)."
            },
            {
                "id": "08ec37b3-9c27-4a9b-a7e9-2ce6d48e977a",
                "createdAt": "2025-11-27T23:11:29.070000+00:00",
                "message": "(service proyecto-cicd-dev-service) has started 1 tasks: (task a177b386eccb49f1b36a57fb4012c2df)."
            },
            {
                "id": "586b2627-2213-4f63-951d-b455dbda401c",
                "createdAt": "2025-11-27T23:10:16.017000+00:00",
                "message": "(service proyecto-cicd-dev-service) deregistered 1 targets in (target-group arn:aws:elasticloadbalancing:us-east-1:478806200706:targetgroup/proyecto-cicd-dev-tg/d51a3e3922227021)"
            },
            {
                "id": "077c4b4d-1d61-4e8c-9a25-36702feb989d",
                "createdAt": "2025-11-27T23:10:15.942000+00:00",
                "message": "(service proyecto-cicd-dev-service, taskSet ecs-svc/5410210592584091640) has begun draining connections on 1 tasks."
            },
            {
                "id": "a3be3fff-2188-46f6-8963-8a14a119ae73",
                "createdAt": "2025-11-27T23:10:15.937000+00:00",
                "message": "(service proyecto-cicd-dev-service) deregistered 1 targets in (target-group arn:aws:elasticloadbalancing:us-east-1:478806200706:targetgroup/proyecto-cicd-dev-tg/d51a3e3922227021)"
            },
            {
                "id": "b769f993-7fa0-42a1-9545-a95c78374e1c",
                "createdAt": "2025-11-27T23:10:05.809000+00:00",
                "message": "(service proyecto-cicd-dev-service) has stopped 1 running tasks: (task 82d3e95d731b499eb89033eba032d8c2)."
            },
            {
                "id": "378ffea0-09a6-489b-a46f-f371c3531c75",
                "createdAt": "2025-11-27T23:10:05.758000+00:00",
                "message": "(service proyecto-cicd-dev-service) (task 82d3e95d731b499eb89033eba032d8c2) (port 3000) is unhealthy in (target-group arn:aws:elasticloadbalancing:us-east-1:478806200706:targetgroup/proyecto-cicd-dev-tg/d51a3e3922227021) due to (reason Health checks failed)."
            },
            {
                "id": "f2f38c23-08e1-4a79-8bf2-15d8c6d30f9a",
                "createdAt": "2025-11-27T03:19:13.638000+00:00",
                "message": "(service proyecto-cicd-dev-service) deregistered 1 targets in (target-group arn:aws:elasticloadbalancing:us-east-1:478806200706:targetgroup/proyecto-cicd-dev-tg/d51a3e3922227021)"
            },
            {
                "id": "5dac04a3-f617-414c-a0b1-f56434ef38f1",
                "createdAt": "2025-11-27T03:19:13.558000+00:00",
                "message": "(service proyecto-cicd-dev-service, taskSet ecs-svc/5732557370959576080) has begun draining connections on 1 tasks."
            },
            {
                "id": "2a695080-b148-4d9b-9f9d-610312780981",
                "createdAt": "2025-11-27T03:19:13.552000+00:00",
                "message": "(service proyecto-cicd-dev-service) deregistered 1 targets in (target-group arn:aws:elasticloadbalancing:us-east-1:478806200706:targetgroup/proyecto-cicd-dev-tg/d51a3e3922227021)"
            },
            {
                "id": "ae2dccab-da2c-4e19-b3db-9b3b9196e898",
                "createdAt": "2025-11-27T03:19:04.087000+00:00",
                "message": "(service proyecto-cicd-dev-service) has stopped 1 running tasks: (task b87d63eb3e14464e845dde885703efce)."
            },
            {
                "id": "5176db85-33d8-4e4d-88f4-bcd30b72a454",
                "createdAt": "2025-11-27T03:19:03.937000+00:00",
                "message": "(service proyecto-cicd-dev-service) (task b87d63eb3e14464e845dde885703efce) (port 3000) is unhealthy in (target-group arn:aws:elasticloadbalancing:us-east-1:478806200706:targetgroup/proyecto-cicd-dev-tg/d51a3e3922227021) due to (reason Health checks failed)."
            }
        ],
        "createdAt": "2025-11-27T02:46:57.485000+00:00",
        "placementConstraints": [],
        "placementStrategy": [],
        "networkConfiguration": {
            "awsvpcConfiguration": {
                "subnets": [
                    "subnet-01e15b432201c33c7",
                    "subnet-00b2fc15abd356e20"
                ],
                "securityGroups": [
                    "sg-0967c740aac36bb09"
                ],
                "assignPublicIp": "ENABLED"
            }
        },
        "healthCheckGracePeriodSeconds": 0,
        "schedulingStrategy": "REPLICA",
        "deploymentController": {
            "type": "ECS"
        },
        "createdBy": "arn:aws:iam::478806200706:user/proyecto-integrador",
        "enableECSManagedTags": false,
        "propagateTags": "NONE",
        "enableExecuteCommand": false,
        "availabilityZoneRebalancing": "DISABLED"
    }
}