# Asset Evaluation Service

A scalable and efficient Asset Evaluation Service that leverages an event-driven architecture to manage assets seamlessly. This service utilizes AWS Lambda, SQS, DynamoDB, and S3 for backend management, while Terraform automates infrastructure provisioning. The front-end is an interactive web app built using React and Express, enhanced with the ChatGPT API for improved asset evaluation.

## Features
- Scalable, event-driven architecture
- Real-time asset evaluation using ChatGPT API
- Automated infrastructure provisioning with Terraform
- CI/CD pipeline with GitHub Actions for continuous integration and deployment
- Web application for user interaction and asset management

## Technologies Used
- **AWS**: Lambda, SQS, DynamoDB, S3
- **Infrastructure Automation**: Terraform
- **Backend**: Node.js, Express
- **Frontend**: React
- **CI/CD**: GitHub Actions
- **APIs**: ChatGPT API
- **Languages**: JavaScript, Python

## Architecture

The system is built using an event-driven architecture with the following flow:
1. **AWS Lambda** handles business logic and asset evaluation.
2. **SQS** serves as a message queue for decoupling microservices.
3. **DynamoDB** stores asset data in a scalable NoSQL database.
4. **S3** is used for storing asset files and other media.
5. **Terraform** automates infrastructure provisioning for AWS services.
6. The front-end is a **React** app that communicates with an **Express** API to display asset information.
7. The **ChatGPT API** is integrated for enhanced asset evaluation using conversational AI.

## Installation

### Prerequisites
- Node.js (v14 or above)
- AWS CLI
- Terraform
- GitHub account for CI/CD setup

### Setup Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/asset-evaluation-service.git
   cd asset-evaluation-service
