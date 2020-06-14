# public-spending

* This is a sample project to practice end-to-end data project.
* Terraform is used to deploy infrastructure to handle airflow and data lake
* Shell script to build and upload Docker image to Amazon ECR
* Airflow DAGs to ingest data and make it available to be used
* Metabase to create data visualization

## TODO
- [ ] Create Airflow Dockerfile
- [ ] Create shell scripts to build and deploy image on Amazon ECR
- [ ] Create Terraform deployment scripts
- [ ] Create data ingestion DAG
- [ ] Deploy Metabase
- [ ] Create visualization on metabase


## Manual Configuration
* Set up ~./credentials file
* export AWS_PROFILE=<your_profile>

## Docker Configuration
> **WARNING**: This Dockerfile is using a famous public Docker image for Airflow. In case you use my example for any production reason, be aware of this and check for complience: https://hub.docker.com/r/puckel/docker-airflow