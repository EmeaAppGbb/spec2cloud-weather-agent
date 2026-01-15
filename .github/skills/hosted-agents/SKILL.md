---
name: Hosted Agents in Microsoft Foundry
description: Expert guidance for deploying and managing containerized AI agents on Microsoft Foundry Agent Service. Use this skill when building production-ready, scalable AI agents using code-based frameworks (Microsoft Agent Framework, LangGraph, or custom implementations) that need enterprise-grade hosting, scaling, observability, and integration with Azure services.
---

# Hosted Agents in Microsoft Foundry

Expert guidance for deploying and managing containerized AI agents on Microsoft Foundry Agent Service. Use this skill when building production-ready, scalable AI agents using code-based frameworks (Microsoft Agent Framework, LangGraph, or custom implementations) that need enterprise-grade hosting, scaling, observability, and integration with Azure services.

## Triggers

Use this skill when:
- "deploy agent to Azure" or "host agent on Foundry"
- "containerize my agent" or "create Docker image for agent"
- "scale agent deployment" or "production agent hosting"
- "manage agent versions" or "update deployed agent"
- "publish agent to Teams/Copilot" or "share agent publicly"
- Working with agents that need persistent state and conversation management
- Implementing enterprise observability and tracing for agents
- Integrating agents with Azure services and Foundry tools

## Core Concepts

### What are Hosted Agents?

Hosted agents are **containerized agentic AI applications** that run on Microsoft Foundry Agent Service. Unlike prompt-based agents, they are:
- Built via **code** (Python, .NET, or custom)
- Deployed as **container images**
- Run on **Microsoft-managed infrastructure** (pay-as-you-go)
- Support full **lifecycle management**: create, start, update, stop, delete

### Hosting Adapter

The hosting adapter is a **framework abstraction layer** that automatically converts agent frameworks into Foundry-compatible HTTP services. It provides:

**One-line deployment**: Transform complex deployment into a single line:
```python
from_langgraph(my_agent).run()  # Instantly hosts on localhost:8088
```

**Automatic protocol translation**:
- Conversation management
- Message serialization
- Streaming event generation
- Foundry Responses API compatibility

**Built-in production features**:
- OpenTelemetry tracing
- CORS support
- Server-sent events (SSE) streaming
- Structured logging

### Framework Support

| Framework | Python | .NET |
|-----------|--------|------|
| Microsoft Agent Framework | ✅ | ✅ |
| LangGraph | ✅ | ❌ |
| Custom code | ✅ | ✅ |

**Adapter packages**:
- Python: `azure-ai-agentserver-core`, `azure-ai-agentserver-agentframework`, `azure-ai-agentserver-langgraph`
- .NET: `Azure.AI.AgentServer.Core`, `Azure.AI.AgentServer.AgentFramework`

## Development Workflow

### Step 1: Local Development and Testing

Before deploying, test your agent locally with the hosting adapter:

```python
# Python example with Microsoft Agent Framework
from azure.ai.agentserver.agentframework import from_agentframework
from my_agent import create_agent

# Create and run agent locally
agent = create_agent()
from_agentframework(agent).run()  # Starts on localhost:8088
```

**Test with REST API**:
```bash
curl -X POST http://localhost:8088/responses \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "messages": [
        {"role": "user", "content": "What is the weather in Tokyo?"}
      ]
    }
  }'
```

This local testing allows you to:
- Validate agent behavior before containerization
- Debug in your development environment
- Test different scenarios quickly
- Verify Foundry Responses API compatibility

### Step 2: Containerization

Create a Dockerfile for your agent:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy agent code
COPY . .

# Expose port (hosting adapter default: 8088)
EXPOSE 8088

# Run the agent with hosting adapter
CMD ["python", "-m", "uvicorn", "start:app", "--host", "0.0.0.0", "--port", "8088"]
```

**Build and test container locally**:
```bash
docker build -t my-agent:latest .
docker run -p 8088:8088 my-agent:latest
```

### Step 3: Deploy to Azure Container Registry

```bash
# Login to ACR
az acr login --name myregistry

# Tag and push image
docker tag my-agent:latest myregistry.azurecr.io/my-agent:v1
docker push myregistry.azurecr.io/my-agent:v1
```

## Deployment Options

### Option 1: Azure Developer CLI (Recommended for Quick Start)

The `azd ai agent` extension simplifies provisioning and deployment:

**Initial Setup**:
```bash
# Install/update azd
azd version
# azd upgrade (if needed)

# Start with Foundry template (auto-provisions infrastructure)
azd init -t https://github.com/Azure-Samples/azd-ai-starter-basic

# OR use existing Foundry project
azd ai agent init --project-id /subscriptions/{SUB_ID}/resourceGroups/{RG}/providers/Microsoft.CognitiveServices/accounts/{ACCOUNT}/projects/{PROJECT}
```

**Configure and Deploy**:
```bash
# Initialize with agent.yaml definition
azd ai agent init -m path/to/agent.yaml

# Package, provision, and deploy in one command
azd up
```

This automatically provisions:
- Azure Container Registry
- Application Insights (monitoring)
- Managed Identity
- RBAC permissions
- Hosted agent version and deployment

**Required Roles**:
- **New project creation**: Azure AI Owner
- **Full infrastructure setup**: Azure AI Owner + Subscription Contributor
- **Deploy to existing project**: Reader on Foundry account + Azure AI User on project

**Cleanup**:
```bash
azd down  # Deletes all resources (takes ~20 minutes)
```

### Option 2: Foundry SDK (Fine-Grained Control)

For more control over agent configuration:

```python
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    ImageBasedHostedAgentDefinition,
    ProtocolVersionRecord,
    AgentProtocol
)
from azure.identity import DefaultAzureCredential

# Initialize client
client = AIProjectClient(
    endpoint="https://your-project.services.ai.azure.com/api/projects/project-name",
    credential=DefaultAzureCredential()
)

# Create agent version
agent = client.agents.create_version(
    agent_name="my-weather-agent",
    description="Weather agent with MCP tool integration",
    definition=ImageBasedHostedAgentDefinition(
        container_protocol_versions=[
            ProtocolVersionRecord(protocol=AgentProtocol.RESPONSES, version="v1")
        ],
        cpu="1",
        memory="2Gi",
        image="myregistry.azurecr.io/my-agent:v1",
        environment_variables={
            "AZURE_AI_PROJECT_ENDPOINT": "https://...",
            "MODEL_NAME": "gpt-4",
            "MCP_SERVER_URL": "http://..."
        }
    )
)
```

## Agent Lifecycle Management

### Start an Agent

```bash
az cognitiveservices agent start \
  --account-name myAccount \
  --project-name myProject \
  --name myAgent \
  --agent-version 1 \
  --min-replicas 1 \
  --max-replicas 3
```

**Status transitions**: Stopped → Starting → Started/Failed

### Stop an Agent

```bash
az cognitiveservices agent stop \
  --account-name myAccount \
  --project-name myProject \
  --name myAgent \
  --agent-version 1
```

**Status transitions**: Running → Stopping → Stopped/Running

### Update an Agent

**Versioned Update** (new runtime configuration):
- Changes to container image, CPU/memory, environment variables, protocol versions
- Creates a new agent version

```python
# Use create_version() with updated configuration
agent_v2 = client.agents.create_version(
    agent_name="my-agent",
    definition=ImageBasedHostedAgentDefinition(
        image="myregistry.azurecr.io/my-agent:v2",  # New image
        cpu="2",  # Increased resources
        memory="4Gi"
    )
)
```

**Non-Versioned Update** (scaling/metadata only):
- Changes to min/max replicas, description, tags
- Does NOT create new version

```bash
az cognitiveservices agent update \
  --account-name myAccount \
  --project-name myProject \
  --name myAgent \
  --agent-version 1 \
  --min-replicas 2 \
  --max-replicas 5 \
  --description "Updated weather agent"
```

### Delete an Agent

**Delete deployment only** (keep version):
```bash
az cognitiveservices agent delete-deployment \
  --account-name myAccount \
  --project-name myProject \
  --name myAgent \
  --agent-version 1
```

**Delete agent completely** (all versions):
```bash
az cognitiveservices agent delete \
  --account-name myAccount \
  --project-name myProject \
  --name myAgent
# Omit --agent-version to delete ALL versions
```

### List Agents

**List all versions**:
```bash
az cognitiveservices agent list-versions \
  --account-name myAccount \
  --project-name myProject \
  --name myAgent
```

**Show details**:
```bash
az cognitiveservices agent show \
  --account-name myAccount \
  --project-name myProject \
  --name myAgent
```

## Invoking Hosted Agents

### Using Azure AI Projects SDK

```python
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import AgentReference

# Configuration
PROJECT_ENDPOINT = "https://your-project.services.ai.azure.com/api/projects/your-project"
AGENT_NAME = "my-weather-agent"
AGENT_VERSION = "1"

# Initialize client and retrieve agent
client = AIProjectClient(
    endpoint=PROJECT_ENDPOINT,
    credential=DefaultAzureCredential()
)
agent = client.agents.retrieve(agent_name=AGENT_NAME)

# Send message
openai_client = client.get_openai_client()
response = openai_client.responses.create(
    input=[{"role": "user", "content": "What's the weather in Seattle?"}],
    extra_body={
        "agent": AgentReference(
            name=agent.name,
            version=AGENT_VERSION
        ).as_dict()
    }
)

print(f"Agent response: {response.output_text}")
```

### Using Agent Playground

View and test agents in the Foundry portal's agent playground UI with built-in conversation management.

## Foundry Tools Integration

### Connecting to MCP Servers

Before your hosted agent can use Foundry tools, create a Remote MCP Tool connection:

**Authentication options**:
- **Stored credentials**: Shared identity for all users
- **Project managed identity**: Azure-managed service identity
- **OAuth passthrough**: Individual user authentication (preserves user context)

### Agent with Tools Definition

```python
agent = client.agents.create_version(
    agent_name="github-coding-agent",
    description="Coding agent for GitHub issues",
    definition=ImageBasedHostedAgentDefinition(
        container_protocol_versions=[
            ProtocolVersionRecord(protocol=AgentProtocol.RESPONSES, version="v1")
        ],
        cpu="1",
        memory="2Gi",
        image="myregistry.azurecr.io/coding-agent:latest",
        tools=[
            {"type": "code_interpreter"},
            {"type": "image_generation"},
            {"type": "web_search"},
            {
                "type": "mcp",
                "project_connection_id": "github_connection_id"
            }
        ],
        environment_variables={
            "AZURE_AI_PROJECT_ENDPOINT": "https://...",
            "GITHUB_MCP_CONNECTION_ID": "github_connection_id"
        }
    )
)
```

**Supported built-in Foundry tools**:
- Code Interpreter
- Image Generation
- Web Search
- Remote MCP Tools (custom)

## Observability and Tracing

The hosting adapter provides comprehensive OpenTelemetry support:

### Local Tracing (Development)

1. Install AI Toolkit for VS Code
2. Set environment variable:
```bash
export OTEL_EXPORTER_ENDPOINT=http://localhost:4318
```
3. Start collector in AI Toolkit
4. Invoke agent and view traces

### Azure Application Insights (Production)

When using `azd ai agent`, Application Insights is auto-provisioned. Otherwise:

1. Create Application Insights resource
2. Grant Azure AI User role to project's managed identity
3. Set environment variable:
```bash
export APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=..."
```

**Built-in telemetry**:
- HTTP requests and database calls
- AI model invocations
- Performance metrics
- Live metrics dashboard
- Distributed tracing

### Foundry Portal Tracing

View traces directly in the agent playground's "Traces" tab for deployed agents.

### Custom OpenTelemetry Endpoint

Export to your own collector:
```python
environment_variables={
    "OTEL_EXPORTER_ENDPOINT": "https://my-otel-collector.com:4318"
}
```

## Conversation Management

Foundry automatically manages stateful conversations for hosted agents:

**Automatic features**:
- **Durable conversation objects**: Unique IDs that persist across interactions
- **State management**: Previous messages, tool calls, agent context maintained
- **Cross-session continuity**: Users can return to conversations with full history
- **Multi-channel access**: Same conversation accessible from different apps
- **Automatic cleanup**: Based on project retention policies

**Conversation items automatically tracked**:
- Messages (user inputs + agent responses with timestamps)
- Tool calls (function invocations + parameters + results)
- Tool outputs (structured responses)
- System messages (internal state + context)

**No manual state management required** - the platform handles everything!

## Evaluation and Testing

### Built-in Evaluation Capabilities

**Agent-specific evaluators** (Azure AI Evaluation SDK):
- **Intent Resolution**: How well agent understands user requests
- **Task Adherence**: Whether agent follows instructions and tasks
- **Tool Call Accuracy**: Correct function/tool usage
- **Response Quality**: Relevance, coherence, fluency
- **Conversation Metrics**: Context retention, multiple-turn coherence
- **Performance Metrics**: Response time, efficiency

### Testing Workflow

1. **Development**: Test locally with agent playground before deployment
2. **Staging**: Deploy to staging environment for validation with real infrastructure
3. **Production**: Continuous monitoring with automated evaluation

### Creating Test Datasets

Cover these scenarios:
- Common user interaction patterns
- Edge cases and error scenarios
- Multiple-turn conversation flows
- Tool usage scenarios
- Performance stress tests

### Evaluation Best Practices

- **Representative data**: Use real user interactions in test datasets
- **Monitor continuously**: Track performance in Foundry portal
- **Iterate regularly**: Evaluate during development to catch issues early
- **Review traces**: Use conversation traces for debugging

See [Evaluate agents locally](https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/develop/agent-evaluate-sdk) and [Agent evaluators](https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/evaluation-evaluators/agent-evaluators) for details.

## Publishing and Sharing

### Publishing Process

When you publish a hosted agent, Foundry automatically:
1. Creates agent application resource with dedicated URL
2. Provisions distinct agent identity (separate from project identity)
3. Registers in Microsoft Entra agent registry
4. Enables stable endpoint (unchanged across version updates)

### Publishing Channels

**Web Application Preview**: Instant shareable web interface for demos

**Microsoft 365 Copilot & Teams**: No-code integration into:
- Microsoft 365 Copilot
- Microsoft Teams
- Agent store (org or shared scope)

**Stable API Endpoint**: Consistent REST API for programmatic access

**Custom Applications**: Embed via SDK and stable endpoint

### Publishing Considerations

- **Identity management**: Published agents get their own identity - reconfigure Azure resource permissions
- **Version control**: Update published agent by deploying new versions without changing endpoint
- **Authentication**: RBAC-based by default, automatic Azure Bot Service integration for M365 channels

## Troubleshooting

### Common Deployment Errors

| Error | Code | Solution |
|-------|------|----------|
| SubscriptionIsNotRegistered | 400 | Register feature or subscription provider |
| InvalidAcrPullCredentials | 401 | Fix managed identity or registry RBAC |
| UnauthorizedAcrPull | 403 | Provide correct credentials/identity |
| AcrImageNotFound | 404 | Correct image name/tag or publish image |
| RegistryNotFound | 400/404 | Fix registry DNS/spelling or network |
| ValidationError | 400 | Correct invalid request fields |
| UserError | 400 | Inspect message and fix configuration |

**View deployment logs**: Select "View deployment logs" in Foundry portal

**5xx errors**: Contact Microsoft support

## Preview Limitations (as of Jan 2026)

### Limits

| Resource | Limit |
|----------|-------|
| Foundry resources with hosted agents per subscription | 100 |
| Hosted agents per Foundry resource | 200 |
| Maximum min_replica count | 2 |
| Maximum max_replica count | 5 |

### Availability

- **Region**: North Central US only
- **Pricing**: Billing enabled no earlier than Feb 1, 2026 (check [pricing page](https://azure.microsoft.com/pricing/details/ai-foundry/))
- **Private networking**: Not supported in network-isolated Foundry resources

## Best Practices

### Development
- **Test locally first**: Always validate with hosting adapter before containerization
- **Use version control**: Tag container images with meaningful versions (v1, v2, etc.)
- **Environment variables**: Use env vars for configuration (endpoints, API keys, model names)
- **Minimal images**: Use slim base images to reduce size and startup time

### Deployment
- **Start small**: Begin with min/max replicas of 1, scale based on usage
- **Versioned updates**: Create new versions for code/config changes
- **Non-versioned updates**: Use for scaling adjustments only
- **Monitor performance**: Use Application Insights and traces to identify issues

### Observability
- **Enable tracing early**: Set up OpenTelemetry from the start
- **Use structured logging**: Leverage hosting adapter's built-in logging
- **Monitor conversations**: Review traces in Foundry portal regularly
- **Set up alerts**: Configure Application Insights alerts for errors/latency

### Security
- **Managed identities**: Use Azure managed identities instead of stored credentials when possible
- **RBAC**: Follow principle of least privilege for resource access
- **OAuth passthrough**: Use for user-specific operations requiring individual context
- **Review data flow**: Understand where data goes, especially with non-Microsoft MCP servers

### Tool Integration
- **MCP connections first**: Create Remote MCP Tool connections before agent deployment
- **Test tools locally**: Verify tool calls work before deploying
- **Handle failures gracefully**: Implement error handling for tool invocations
- **Use built-in tools**: Leverage Foundry's Code Interpreter, Web Search, Image Generation

## Examples

### Complete Python Example (Microsoft Agent Framework)

```python
# start.py - Agent with hosting adapter
from azure.ai.agentserver.agentframework import from_agentframework
from azure.ai.inference import ChatCompletionsClient
from azure.identity import DefaultAzureCredential
import os

# Create agent
from my_agent_logic import WeatherAgent

def create_app():
    # Initialize agent
    agent = WeatherAgent(
        model_endpoint=os.getenv("AZURE_AI_PROJECT_ENDPOINT"),
        model_name=os.getenv("AZURE_AI_MODEL_DEPLOYMENT_NAME")
    )
    
    # Wrap with hosting adapter
    app = from_agentframework(agent)
    return app

# For local development
if __name__ == "__main__":
    app = create_app()
    app.run()  # Starts on localhost:8088

# For production (with uvicorn)
app = create_app().build()
```

### agent.yaml Definition

```yaml
name: weather-agent
version: "1.0"
description: "Weather agent with MCP tool integration"

container:
  image: myregistry.azurecr.io/weather-agent:v1
  protocol: responses/v1
  resources:
    cpu: "1"
    memory: "2Gi"
  
environment:
  AZURE_AI_PROJECT_ENDPOINT: "${AZURE_AI_PROJECT_ENDPOINT}"
  AZURE_AI_MODEL_DEPLOYMENT_NAME: "gpt-4"
  MCP_SERVER_URL: "${MCP_SERVER_URL}"

scaling:
  min_replicas: 1
  max_replicas: 3

tools:
  - type: code_interpreter
  - type: mcp
    connection_id: weather_mcp_connection
```

## Sample Projects

This skill includes several complete sample implementations demonstrating different hosted agent patterns. All samples are production-ready and can be deployed using `azd`:

### 1. Echo Agent - Minimal Custom Agent
**Location**: [samples/echo-agent](./samples/echo-agent/)

A minimal custom agent implementation demonstrating:
- Extending `BaseAgent` class for fully custom behavior
- Both streaming and non-streaming response patterns
- Basic agent structure without external dependencies
- Simple containerization and deployment

**Best for**: Understanding the minimal requirements for a hosted agent, learning custom agent implementation patterns.

```bash
cd samples/echo-agent
azd up
```

### 2. Web Search Agent - Built-in Tools
**Location**: [samples/web-search-agent](./samples/web-search-agent/)

Demonstrates using Foundry's built-in web search tool:
- Integration with Foundry's Web Search tool
- Microsoft Agent Framework with hosted tools
- Environment variable configuration
- Production-ready error handling

**Best for**: Learning how to use Foundry's built-in tools (Web Search, Code Interpreter, Image Generation).

```bash
cd samples/web-search-agent
azd up
```

### 3. Agent with Hosted MCP - External Tool Integration
**Location**: [samples/agent_with_hosted_mcp](./samples/agent_with_hosted_mcp/)

Shows integration with Hosted Model Context Protocol (MCP) servers:
- Connecting to hosted MCP servers (e.g., Microsoft Learn documentation)
- `HostedMCPTool` configuration
- Azure OpenAI Responses service automatic tool invocation
- Remote tool authentication and management

**Best for**: Integrating external APIs and services through MCP, connecting to third-party data sources.

```bash
cd samples/agent_with_hosted_mcp
azd up
```

### 4. Agent with Text Search RAG - Knowledge Base Integration
**Location**: [samples/agent_with_text_search_rag](./samples/agent_with_text_search_rag/)

Demonstrates Retrieval Augmented Generation (RAG) pattern:
- `TextSearchContextProvider` for knowledge base queries
- Context injection into agent responses
- Document citation in answers
- RAG workflow implementation

**Best for**: Building agents that need to answer questions from your own knowledge base, implementing search-driven responses.

**Production Note**: Sample uses pre-defined snippets for demonstration. Replace with actual searches against Azure AI Search, vector databases, or other data sources.

```bash
cd samples/agent_with_text_search_rag
azd up
```

### 5. Agents in Workflow - Multi-Agent Orchestration
**Location**: [samples/agents_in_workflow](./samples/agents_in_workflow/)

Multi-agent workflow with concurrent execution:
- **Research Agent** - Market and product research
- **Market Agent** - Market strategy creation
- **Legal Agent** - Legal review of strategies
- Concurrent agent execution in workflow pipelines
- Agent-to-agent communication patterns

**Best for**: Building complex multi-agent systems, orchestrating multiple specialized agents, implementing workflow patterns.

```bash
cd samples/agents_in_workflow
azd up
```

### Common Sample Features

All samples include:
- ✅ **Complete Dockerfile** - Production-ready containerization
- ✅ **agent.yaml** - Azure Developer CLI configuration
- ✅ **requirements.txt** - Python dependencies
- ✅ **README.md** - Detailed setup and deployment instructions
- ✅ **Local testing** - Run and test before deployment
- ✅ **azd integration** - One-command deployment to Azure

### Important Notes

**Architecture Compatibility**: If building locally on Apple Silicon or ARM64 machines:
```bash
# Use this command to build for the correct architecture
docker build --platform=linux/amd64 -t your-agent .
```

**Recommended**: Use `azd` cloud build which automatically builds images with the correct `linux/amd64` architecture.

**Responsible AI**: All samples should be reviewed and tested in the context of your use case. AI responses may be inaccurate and require human oversight. See:
- [Agent Service Transparency Note](https://learn.microsoft.com/en-us/azure/ai-foundry/responsible-ai/agents/transparency-note)
- [Agent Framework Transparency FAQ](https://github.com/microsoft/agent-framework/blob/main/TRANSPARENCY_FAQ.md)

## Related Skills

- [microsoft-agent-framework](../microsoft-agent-framework/SKILL.md) - Building agents with Microsoft Agent Framework
- [mcp-builder](../mcp-builder/SKILL.md) - Creating MCP servers for tool integration

## Additional Resources

- [Python code samples](https://github.com/azure-ai-foundry/foundry-samples/tree/hosted-agents/pyaf-samples/samples/microsoft/python/getting-started-agents/hosted-agents)
- [C# code samples](https://github.com/azure-ai-foundry/foundry-samples/tree/main/samples/csharp/hosted-agents)
- [Agent runtime components](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/concepts/runtime-components)
- [Agent development lifecycle](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/concepts/development-lifecycle)
- [Agent identity concepts](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/concepts/agent-identity)
- [Publish and share agents](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/how-to/publish-agent)
- [Azure Container Registry docs](https://learn.microsoft.com/en-us/azure/container-registry/)
