## To Do
1. Add dev, uat, prod environments.
2. Clean and upgrade the terraform eks cluster module codes.
    - Add cloudwatch logs
    - KMS for EBS encryption volumes on worker nodes
    - Add support for mixed instance policy
3. Clean and upgrade vpc module codes.
    - Adds VPC S3 endpoint
4. Add horizontal pod autoscaler in cluster. Ref: 
    - https://aws.amazon.com/premiumsupport/knowledge-center/eks-metrics-server-pod-autoscaler/
    - https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
    
5. Admission controller
6. Grafana Alloy