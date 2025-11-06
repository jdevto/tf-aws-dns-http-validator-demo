# DNS & HTTP Validator Demo

A demo of an **event-driven, serverless architecture** on AWS. Each component is completely independent and decoupled, allowing them to scale independently based on demand.

## The Architecture

This is built around **EventBridge** as the central event bus. Components don't talk directly to each other - they just publish and subscribe to events. This means:

- **Independent scaling**: Each Lambda can scale up/down based on its own workload
- **Loose coupling**: Add or remove components without breaking others
- **Parallel processing**: Multiple validations run simultaneously without blocking
- **Resilience**: If one component fails, others keep working

## What's Inside

- **API Gateway**: Entry point that receives validation requests
- **EventBridge**: The event bus that decouples everything
- **Lambda Functions** (each independent):
  - API handler → publishes events, doesn't wait for results
  - DNS resolver → subscribes to events, resolves domains
  - HTTP/HTTPS probers → subscribe to events, test endpoints
  - Aggregator → subscribes to completion events, saves results
  - Status API → reads from DynamoDB
  - IP authorizer → protects the API
- **DynamoDB**: Stores results (read by Status API)
- **S3**: Hosts a simple React frontend
- **CloudWatch**: Logs everything

## How It Works (Event-Driven Flow)

1. Request comes in → API handler publishes a "validation requested" event to EventBridge
2. **EventBridge triggers three Lambdas in parallel** (they don't know about each other):
   - DNS resolver processes the event
   - HTTP prober processes the event
   - HTTPS prober processes the event
3. Each Lambda publishes its result as a separate event
4. Aggregator subscribes to result events, collects them, saves to DynamoDB
5. Status API reads from DynamoDB (completely separate from the event flow)

The key: **no component waits for another**. They all just react to events.

## Quick Start

You'll need:

- Terraform installed
- AWS credentials configured
- Node.js/npm (for the frontend)
- Python 3.13 (for Lambda)

Then just:

```bash
terraform init
terraform apply
```

**Note**: You'll need to run `terraform apply` twice. The first time builds the frontend, the second time uploads it to S3. This is a Terraform quirk where `fileset()` evaluates before the build step runs.

After it's done, grab your URLs:

```bash
terraform output frontend_url
terraform output api_gateway_url
```

## Why Event-Driven?

In a traditional architecture, you'd have:

- API → calls DNS service → waits → calls HTTP service → waits → calls HTTPS service → waits → aggregates → returns

In this event-driven version:

- API → publishes event → returns immediately
- Three services process in parallel, independently
- Aggregator collects results when ready
- Everything scales based on actual demand

Want to add email notifications? Just add a Lambda that subscribes to completion events. No changes needed to existing code.

## Cleanup

When you're done playing around:

```bash
terraform destroy
```

## Notes

- The frontend auto-builds with the API endpoint baked in
- API is locked down to your current public IP (detected automatically)
- Everything uses Python 3.13 for the Lambdas
- This is a demo - don't use in production without hardening!
