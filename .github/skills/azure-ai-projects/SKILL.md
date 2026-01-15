---
name: Azure AI Projects Client Library Skill
description: Expert guidance for using the Azure AI Projects client library (azure-ai-projects) to build and deploy AI applications with Microsoft Foundry. This skill covers agent creation, tools integration, evaluation, connections, datasets, deployments, fine-tuning, and telemetry operations using Python SDK.
---

# Azure AI Projects Client Library Skill

## Description
Expert guidance for using the Azure AI Projects client library (azure-ai-projects) to build and deploy AI applications with Microsoft Foundry. This skill covers agent creation, tools integration, evaluation, connections, datasets, deployments, fine-tuning, and telemetry operations using Python SDK.

## When to Use
Use this skill when:
- Creating and managing AI Agents in Microsoft Foundry projects
- Integrating specialized tools with agents (Azure AI Search, Bing, Function Tools, File Search, etc.)
- Performing evaluations of AI agents and LLM applications
- Managing connections to Azure resources
- Working with datasets and indexes
- Deploying and fine-tuning AI models
- Setting up telemetry and tracing for AI applications
- Managing memory stores for agent conversations

## Prerequisites
- Python 3.9 or later
- Azure subscription
- Microsoft Foundry project (found in Azure AI Foundry portal)
- Project endpoint URL: `https://your-ai-services-account-name.services.ai.azure.com/api/projects/your-project-name`
- Entra ID authentication (DefaultAzureCredential)
- Azure CLI installed and logged in (`az login`)

## Installation

```bash
# Core package
pip install --pre azure-ai-projects

# Additional packages for full functionality
pip install openai azure-identity aiohttp
```

## Key Concepts

### 1. Client Creation and Authentication

**Synchronous Client:**
```python
import os
from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential

with (
    DefaultAzureCredential() as credential,
    AIProjectClient(endpoint=os.environ["AZURE_AI_PROJECT_ENDPOINT"], credential=credential) as project_client,
):
    # Your code here
    pass
```

**Asynchronous Client:**
```python
import os
import asyncio
from azure.ai.projects.aio import AIProjectClient
from azure.identity.aio import DefaultAzureCredential

async with (
    DefaultAzureCredential() as credential,
    AIProjectClient(endpoint=os.environ["AZURE_AI_PROJECT_ENDPOINT"], credential=credential) as project_client,
):
    # Your async code here
    pass
```

### 2. Agent Operations

**Create and Use an Agent:**
```python
from azure.ai.projects.models import PromptAgentDefinition

with project_client.get_openai_client() as openai_client:
    # Create agent
    agent = project_client.agents.create_version(
        agent_name="MyAgent",
        definition=PromptAgentDefinition(
            model=os.environ["AZURE_AI_MODEL_DEPLOYMENT_NAME"],
            instructions="You are a helpful assistant that answers general questions",
        ),
    )
    print(f"Agent created (id: {agent.id}, name: {agent.name}, version: {agent.version})")

    # Create conversation
    conversation = openai_client.conversations.create(
        items=[{"type": "message", "role": "user", "content": "What is the size of France in square miles?"}],
    )
    print(f"Created conversation with initial user message (id: {conversation.id})")

    # Get response
    response = openai_client.responses.create(
        conversation=conversation.id,
        extra_body={"agent": {"name": agent.name, "type": "agent_reference"}},
        input="",
    )
    print(f"Response output: {response.output_text}")

    # Add more messages
    openai_client.conversations.items.create(
        conversation_id=conversation.id,
        items=[{"type": "message", "role": "user", "content": "And what is the capital city?"}],
    )

    # Clean up
    openai_client.conversations.delete(conversation_id=conversation.id)
    project_client.agents.delete_version(agent_name=agent.name, agent_version=agent.version)
```

### 3. Agent Tools

#### Built-in Tools (No Connection Required)

**Code Interpreter:**
```python
from azure.ai.projects.models import CodeInterpreterTool, CodeInterpreterToolAuto

# Upload file
file = openai_client.files.create(purpose="assistants", file=open(file_path, "rb"))
tool = CodeInterpreterTool(container=CodeInterpreterToolAuto(file_ids=[file.id]))
```

**File Search:**
```python
from azure.ai.projects.models import FileSearchTool

# Create vector store
vector_store = openai_client.vector_stores.create(name="ProductInfoStore")

# Upload file to vector store
file = openai_client.vector_stores.files.upload_and_poll(
    vector_store_id=vector_store.id, 
    file=open(file_path, "rb")
)

tool = FileSearchTool(vector_store_ids=[vector_store.id])
```

**Image Generation:**
```python
from azure.ai.projects.models import ImageGenTool

tool = ImageGenTool(
    model=image_generation_model,  # e.g., "gpt-image-1-mini"
    quality="low",
    size="1024x1024",
)
```

**Web Search:**
```python
from azure.ai.projects.models import WebSearchPreviewTool, ApproximateLocation

tool = WebSearchPreviewTool(
    user_location=ApproximateLocation(country="GB", city="London", region="London")
)
```

**Computer Use:**
```python
from azure.ai.projects.models import ComputerUsePreviewTool

tool = ComputerUsePreviewTool(display_width=1026, display_height=769, environment="windows")
```

**Function Tool:**
```python
from azure.ai.projects.models import FunctionTool

tool = FunctionTool(
    name="get_horoscope",
    parameters={
        "type": "object",
        "properties": {
            "sign": {
                "type": "string",
                "description": "An astrological sign like Taurus or Aquarius",
            },
        },
        "required": ["sign"],
        "additionalProperties": False,
    },
    description="Get today's horoscope for an astrological sign.",
    strict=True,
)
```

**OpenAPI:**
```python
from azure.ai.projects.models import OpenApiAgentTool, OpenApiFunctionDefinition, OpenApiAnonymousAuthDetails
import jsonref

with open(openapi_spec_path, "r") as f:
    openapi_spec = jsonref.loads(f.read())

tool = OpenApiAgentTool(
    openapi=OpenApiFunctionDefinition(
        name="get_weather",
        spec=openapi_spec,
        description="Retrieve weather information for a location.",
        auth=OpenApiAnonymousAuthDetails(),
    )
)
```

**Model Context Protocol (MCP):**
```python
from azure.ai.projects.models import MCPTool

mcp_tool = MCPTool(
    server_label="api-specs",
    server_url="https://gitmcp.io/Azure/azure-rest-api-specs",
    require_approval="always",
)
```

**Memory Search Tool:**
```python
from azure.ai.projects.models import MemorySearchTool

tool = MemorySearchTool(
    memory_store_name=memory_store.name,
    scope="user_123",  # or "{{$userId}}" to use authenticated user's OID
    update_delay=1,  # seconds of inactivity before updating memories
)
```

#### Connection-Based Tools (Require Project Connection)

**Azure AI Search:**
```python
from azure.ai.projects.models import (
    AzureAISearchAgentTool,
    AzureAISearchToolResource,
    AISearchIndexResource,
    AzureAISearchQueryType
)

tool = AzureAISearchAgentTool(
    azure_ai_search=AzureAISearchToolResource(
        indexes=[
            AISearchIndexResource(
                project_connection_id=os.environ["AI_SEARCH_PROJECT_CONNECTION_ID"],
                index_name=os.environ["AI_SEARCH_INDEX_NAME"],
                query_type=AzureAISearchQueryType.SIMPLE,
            ),
        ]
    )
)
```

**Bing Grounding:**
```python
from azure.ai.projects.models import (
    BingGroundingAgentTool,
    BingGroundingSearchToolParameters,
    BingGroundingSearchConfiguration
)

tool = BingGroundingAgentTool(
    bing_grounding=BingGroundingSearchToolParameters(
        search_configurations=[
            BingGroundingSearchConfiguration(
                project_connection_id=os.environ["BING_PROJECT_CONNECTION_ID"]
            )
        ]
    )
)
```

**Bing Custom Search:**
```python
from azure.ai.projects.models import (
    BingCustomSearchAgentTool,
    BingCustomSearchToolParameters,
    BingCustomSearchConfiguration
)

tool = BingCustomSearchAgentTool(
    bing_custom_search_preview=BingCustomSearchToolParameters(
        search_configurations=[
            BingCustomSearchConfiguration(
                project_connection_id=os.environ["BING_CUSTOM_SEARCH_PROJECT_CONNECTION_ID"],
                instance_name=os.environ["BING_CUSTOM_SEARCH_INSTANCE_NAME"],
            )
        ]
    )
)
```

**Microsoft Fabric:**
```python
from azure.ai.projects.models import (
    MicrosoftFabricAgentTool,
    FabricDataAgentToolParameters,
    ToolProjectConnection
)

tool = MicrosoftFabricAgentTool(
    fabric_dataagent_preview=FabricDataAgentToolParameters(
        project_connections=[
            ToolProjectConnection(project_connection_id=os.environ["FABRIC_PROJECT_CONNECTION_ID"])
        ]
    )
)
```

**SharePoint:**
```python
from azure.ai.projects.models import (
    SharepointAgentTool,
    SharepointGroundingToolParameters,
    ToolProjectConnection
)

tool = SharepointAgentTool(
    sharepoint_grounding_preview=SharepointGroundingToolParameters(
        project_connections=[
            ToolProjectConnection(project_connection_id=os.environ["SHAREPOINT_PROJECT_CONNECTION_ID"])
        ]
    )
)
```

**Browser Automation:**
```python
from azure.ai.projects.models import (
    BrowserAutomationAgentTool,
    BrowserAutomationToolParameters,
    BrowserAutomationToolConnectionParameters
)

tool = BrowserAutomationAgentTool(
    browser_automation_preview=BrowserAutomationToolParameters(
        connection=BrowserAutomationToolConnectionParameters(
            project_connection_id=os.environ["BROWSER_AUTOMATION_PROJECT_CONNECTION_ID"],
        )
    )
)
```

**Agent-to-Agent (A2A):**
```python
from azure.ai.projects.models import A2ATool

tool = A2ATool(
    project_connection_id=os.environ["A2A_PROJECT_CONNECTION_ID"],
)

# Optionally set A2A endpoint if connection is missing target
if os.environ.get("A2A_ENDPOINT"):
    tool.base_url = os.environ["A2A_ENDPOINT"]
```

### 4. Evaluation Operations

**Create and Run Agent Evaluation:**
```python
from azure.ai.projects.models import PromptAgentDefinition
from openai.types.eval_create_params import DataSourceConfigCustom
from openai.types.evals.run_create_response import RunCreateResponse
from openai.types.evals.run_retrieve_response import RunRetrieveResponse

with project_client.get_openai_client() as openai_client:
    # Create agent
    agent = project_client.agents.create_version(
        agent_name="MyAgent",
        definition=PromptAgentDefinition(
            model=model_deployment_name,
            instructions="You are a helpful assistant that answers general questions",
        ),
    )

    # Define data source config
    data_source_config = DataSourceConfigCustom(
        type="custom",
        item_schema={
            "type": "object", 
            "properties": {"query": {"type": "string"}}, 
            "required": ["query"]
        },
        include_sample_schema=True,
    )

    # Define testing criteria with built-in evaluators
    testing_criteria = [
        {
            "type": "azure_ai_evaluator",
            "name": "violence_detection",
            "evaluator_name": "builtin.violence",
            "data_mapping": {"query": "{{item.query}}", "response": "{{sample.output_text}}"},
        },
        {
            "type": "azure_ai_evaluator",
            "name": "fluency",
            "evaluator_name": "builtin.fluency",
            "initialization_parameters": {"deployment_name": f"{model_deployment_name}"},
            "data_mapping": {"query": "{{item.query}}", "response": "{{sample.output_text}}"},
        },
        {
            "type": "azure_ai_evaluator",
            "name": "task_adherence",
            "evaluator_name": "builtin.task_adherence",
            "initialization_parameters": {"deployment_name": f"{model_deployment_name}"},
            "data_mapping": {"query": "{{item.query}}", "response": "{{sample.output_items}}"},
        },
    ]

    # Create evaluation
    eval_object = openai_client.evals.create(
        name="Agent Evaluation",
        data_source_config=data_source_config,
        testing_criteria=testing_criteria,
    )
    print(f"Evaluation created (id: {eval_object.id}, name: {eval_object.name})")

    # Define data source for evaluation run
    data_source = {
        "type": "azure_ai_target_completions",
        "source": {
            "type": "file_content",
            "content": [
                {"item": {"query": "What is the capital of France?"}},
                {"item": {"query": "How do I reverse a string in Python?"}},
            ],
        },
        "input_messages": {
            "type": "template",
            "template": [
                {"type": "message", "role": "user", "content": {"type": "input_text", "text": "{{item.query}}"}}
            ],
        },
        "target": {
            "type": "azure_ai_agent",
            "name": agent.name,
            "version": agent.version,  # Optional, defaults to latest
        },
    }

    # Create and run evaluation
    agent_eval_run = openai_client.evals.runs.create(
        eval_id=eval_object.id,
        name=f"Evaluation Run for Agent {agent.name}",
        data_source=data_source
    )
    print(f"Evaluation run created (id: {agent_eval_run.id})")
```

### 5. Connection Operations

**List and Get Connections:**
```python
from azure.ai.projects.models import ConnectionType

# List all connections
for connection in project_client.connections.list():
    print(connection)

# List connections of specific type
for connection in project_client.connections.list(connection_type=ConnectionType.AZURE_OPEN_AI):
    print(connection)

# Get default connection without credentials
connection = project_client.connections.get_default(connection_type=ConnectionType.AZURE_OPEN_AI)

# Get default connection with credentials
connection = project_client.connections.get_default(
    connection_type=ConnectionType.AZURE_OPEN_AI, 
    include_credentials=True
)

# Get specific connection by name
connection = project_client.connections.get(connection_name)

# Get connection with credentials
connection = project_client.connections.get(connection_name, include_credentials=True)
```

### 6. Dataset Operations

**Upload Files and Create Datasets:**
```python
import re

# Upload single file
dataset = project_client.datasets.upload_file(
    name=dataset_name,
    version=dataset_version_1,
    file_path=data_file,
    connection_name=connection_name,
)

# Upload folder with file pattern
dataset = project_client.datasets.upload_folder(
    name=dataset_name,
    version=dataset_version_2,
    folder=data_folder,
    connection_name=connection_name,
    file_pattern=re.compile(r"\.(txt|csv|md)$", re.IGNORECASE),
)

# Get dataset
dataset = project_client.datasets.get(name=dataset_name, version=dataset_version_1)

# Get dataset credentials
dataset_credential = project_client.datasets.get_credentials(
    name=dataset_name, 
    version=dataset_version_1
)

# List latest versions of all datasets
for dataset in project_client.datasets.list():
    print(dataset)

# List all versions of specific dataset
for dataset in project_client.datasets.list_versions(name=dataset_name):
    print(dataset)

# Delete dataset
project_client.datasets.delete(name=dataset_name, version=dataset_version_1)
```

### 7. Deployment Operations

**List and Get Deployments:**
```python
from azure.ai.projects.models import ModelDeployment

# List all deployments
for deployment in project_client.deployments.list():
    print(deployment)

# List deployments by publisher
for deployment in project_client.deployments.list(model_publisher=model_publisher):
    print(deployment)

# List deployments by model name
for deployment in project_client.deployments.list(model_name=model_name):
    print(deployment)

# Get single deployment
deployment = project_client.deployments.get(model_deployment_name)

# Access deployment details
if isinstance(deployment, ModelDeployment):
    print(f"Type: {deployment.type}")
    print(f"Name: {deployment.name}")
    print(f"Model Name: {deployment.model_name}")
    print(f"Model Version: {deployment.model_version}")
    print(f"Model Publisher: {deployment.model_publisher}")
    print(f"Capabilities: {deployment.capabilities}")
    print(f"SKU: {deployment.sku}")
    print(f"Connection Name: {deployment.connection_name}")
```

### 8. Index Operations

**Create and Manage Indexes:**
```python
from azure.ai.projects.models import AzureAISearchIndex

# Create or update index
index = project_client.indexes.create_or_update(
    name=index_name,
    version=index_version,
    index=AzureAISearchIndex(
        connection_name=ai_search_connection_name, 
        index_name=ai_search_index_name
    ),
)

# Get index
index = project_client.indexes.get(name=index_name, version=index_version)

# List latest versions of all indexes
for index in project_client.indexes.list():
    print(index)

# List all versions of specific index
for index in project_client.indexes.list_versions(name=index_name):
    print(index)

# Delete index
project_client.indexes.delete(name=index_name, version=index_version)
```

### 9. File Operations (via OpenAI Client)

**Upload, Retrieve, and Delete Files:**
```python
with project_client.get_openai_client() as openai_client:
    # Upload file
    with open(file_path, "rb") as f:
        uploaded_file = openai_client.files.create(file=f, purpose="fine-tune")
    print(uploaded_file)

    # Wait for file processing (default timeout: 30 mins)
    processed_file = openai_client.files.wait_for_processing(uploaded_file.id)

    # Retrieve file metadata
    retrieved_file = openai_client.files.retrieve(processed_file.id)

    # Retrieve file content
    file_content = openai_client.files.content(processed_file.id)
    print(file_content.content)

    # List all files
    for file in openai_client.files.list():
        print(file)

    # Delete file
    deleted_file = openai_client.files.delete(processed_file.id)
```

### 10. Fine-tuning Operations

**Create Fine-tuning Jobs:**
```python
with project_client.get_openai_client() as openai_client:
    # Upload training and validation files
    with open(training_file_path, "rb") as f:
        train_file = openai_client.files.create(file=f, purpose="fine-tune")
    
    with open(validation_file_path, "rb") as f:
        validation_file = openai_client.files.create(file=f, purpose="fine-tune")

    # Wait for processing
    openai_client.files.wait_for_processing(train_file.id)
    openai_client.files.wait_for_processing(validation_file.id)

    # Create supervised fine-tuning job
    fine_tuning_job = openai_client.fine_tuning.jobs.create(
        training_file=train_file.id,
        validation_file=validation_file.id,
        model=model_name,
        method={
            "type": "supervised",
            "supervised": {
                "hyperparameters": {
                    "n_epochs": 3,
                    "batch_size": 1,
                    "learning_rate_multiplier": 1.0
                }
            },
        },
        extra_body={
            "trainingType": "GlobalStandard"  # Recommended for cost savings
        },
    )
    print(fine_tuning_job)
```

### 11. Telemetry and Tracing

**Enable Azure Monitor Tracing:**
```python
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace

# Enable Azure Monitor tracing
connection_string = project_client.telemetry.get_application_insights_connection_string()
configure_azure_monitor(connection_string=connection_string)

# Create custom span for your scenario
tracer = trace.get_tracer(__name__)
scenario = os.path.basename(__file__)

with tracer.start_as_current_span(scenario):
    # Your code here
    pass
```

**Enable Console Tracing:**
```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor

# Setup console tracing
span_exporter = ConsoleSpanExporter()
tracer_provider = TracerProvider()
tracer_provider.add_span_processor(SimpleSpanProcessor(span_exporter))
trace.set_tracer_provider(tracer_provider)

# Enable instrumentation
from azure.ai.projects.telemetry import AiProjectInstrumentation
AiProjectInstrumentation().instrument()
```

**Custom Trace Attributes:**
```python
from opentelemetry.sdk.trace import SpanProcessor, ReadableSpan
from opentelemetry.trace import Span

class CustomAttributeSpanProcessor(SpanProcessor):
    def on_start(self, span: Span, parent_context=None):
        # Add custom attributes
        span.set_attribute("trace_sample.sessionid", "123")
        
        if span.name == "create_thread":
            span.set_attribute("trace_sample.create_thread.context", "abc")

    def on_end(self, span: ReadableSpan):
        pass

# Add to tracer provider
provider = cast(TracerProvider, trace.get_tracer_provider())
provider.add_span_processor(CustomAttributeSpanProcessor())
```

**Tracing Configuration:**
```python
# Enable content recording (includes message contents)
os.environ["OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT"] = "true"

# Disable automatic instrumentation
os.environ["AZURE_TRACING_GEN_AI_INSTRUMENT_RESPONSES_API"] = "false"

# Include binary data in traces (images, files)
os.environ["AZURE_TRACING_GEN_AI_INCLUDE_BINARY_DATA"] = "true"
```

**Trace Custom Functions:**
```python
from azure.ai.projects.telemetry import trace_function

@trace_function(name="my_function")
def my_custom_function(param1: str, param2: int) -> str:
    # Function logic
    return f"Result: {param1} - {param2}"
```

### 12. Memory Store Operations

**Create and Use Memory Stores:**
```python
# Create memory store
memory_store = project_client.memory_stores.create(name="MyMemoryStore")

# Use memory search tool with agent
from azure.ai.projects.models import MemorySearchTool

tool = MemorySearchTool(
    memory_store_name=memory_store.name,
    scope="user_123",  # Associate memories with specific user
    update_delay=1,  # Seconds of inactivity before updating memories
)

# List memory stores
for store in project_client.memory_stores.list():
    print(store)

# Get memory store
store = project_client.memory_stores.get(name="MyMemoryStore")

# Delete memory store
project_client.memory_stores.delete(name="MyMemoryStore")
```

## Common Patterns

### Pattern 1: Complete Agent Workflow with Tool
```python
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    PromptAgentDefinition,
    FunctionTool
)
from azure.identity import DefaultAzureCredential
import os
import json

with (
    DefaultAzureCredential() as credential,
    AIProjectClient(
        endpoint=os.environ["AZURE_AI_PROJECT_ENDPOINT"],
        credential=credential
    ) as project_client,
    project_client.get_openai_client() as openai_client,
):
    # Define function tool
    tool = FunctionTool(
        name="get_weather",
        parameters={
            "type": "object",
            "properties": {
                "location": {"type": "string", "description": "City name"},
            },
            "required": ["location"],
            "additionalProperties": False,
        },
        description="Get weather for a location.",
        strict=True,
    )

    # Create agent with tool
    agent = project_client.agents.create_version(
        agent_name="WeatherAgent",
        definition=PromptAgentDefinition(
            model=os.environ["AZURE_AI_MODEL_DEPLOYMENT_NAME"],
            instructions="You are a helpful weather assistant.",
            tools=[tool],
        ),
    )

    # Create conversation
    conversation = openai_client.conversations.create(
        items=[{
            "type": "message",
            "role": "user",
            "content": "What's the weather in Seattle?"
        }],
    )

    # Get response
    response = openai_client.responses.create(
        conversation=conversation.id,
        extra_body={"agent": {"name": agent.name, "type": "agent_reference"}},
        input="",
    )

    # Process function calls
    for output_item in response.output:
        if output_item.type == "function_call":
            function_name = output_item.name
            function_args = json.loads(output_item.arguments)
            
            # Execute your function
            result = execute_weather_function(function_args["location"])
            
            # Send result back
            response = openai_client.responses.create(
                conversation=conversation.id,
                extra_body={"agent": {"name": agent.name, "type": "agent_reference"}},
                input="",
                function_outputs=[{
                    "call_id": output_item.call_id,
                    "output": json.dumps(result)
                }]
            )

    print(f"Final response: {response.output_text}")
```

### Pattern 2: Evaluation with Tracing
```python
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace

# Enable tracing
connection_string = project_client.telemetry.get_application_insights_connection_string()
configure_azure_monitor(connection_string=connection_string)

# Create agent with tracing enabled
tracer = trace.get_tracer(__name__)
with tracer.start_as_current_span("agent_evaluation"):
    agent = project_client.agents.create_version(
        agent_name="MyAgent",
        definition=PromptAgentDefinition(
            model=os.environ["AZURE_AI_MODEL_DEPLOYMENT_NAME"],
            instructions="You are a helpful assistant",
        ),
    )
    
    # Run evaluation
    with project_client.get_openai_client() as openai_client:
        eval_object = openai_client.evals.create(
            name="Agent Evaluation",
            data_source_config=data_source_config,
            testing_criteria=testing_criteria,
        )
        
        # Traces will be automatically captured in Application Insights
```

### Pattern 3: Multi-Tool Agent
```python
from azure.ai.projects.models import (
    PromptAgentDefinition,
    FileSearchTool,
    WebSearchPreviewTool,
    FunctionTool
)

# Define multiple tools
file_search_tool = FileSearchTool(vector_store_ids=[vector_store.id])
web_search_tool = WebSearchPreviewTool()
function_tool = FunctionTool(
    name="calculate",
    parameters={"type": "object", "properties": {"expression": {"type": "string"}}},
    description="Calculate a mathematical expression",
)

# Create agent with multiple tools
agent = project_client.agents.create_version(
    agent_name="MultiToolAgent",
    definition=PromptAgentDefinition(
        model=os.environ["AZURE_AI_MODEL_DEPLOYMENT_NAME"],
        instructions="You can search files, search the web, and perform calculations.",
        tools=[file_search_tool, web_search_tool, function_tool],
    ),
)
```

## Error Handling

```python
from azure.core.exceptions import HttpResponseError

try:
    result = project_client.connections.list()
except HttpResponseError as e:
    print(f"Status code: {e.status_code} ({e.reason})")
    print(e.message)
```

## Logging

```python
import sys
import logging

# Configure logging
logger = logging.getLogger("azure")
logger.setLevel(logging.DEBUG)

handler = logging.StreamHandler(stream=sys.stdout)
logger.addHandler(handler)

# Create client with logging enabled
project_client = AIProjectClient(
    credential=DefaultAzureCredential(),
    endpoint=os.environ["AZURE_AI_PROJECT_ENDPOINT"],
    logging_enable=True  # Disables redaction
)
```

## Best Practices

1. **Use Context Managers**: Always use `with` statements for automatic resource cleanup
2. **Environment Variables**: Store sensitive information like endpoints and API keys in environment variables
3. **Versioning**: Use agent versioning for tracking and rollback capabilities
4. **Telemetry**: Enable Application Insights for production deployments
5. **Connection Management**: Reuse connections when possible, use `.get_default()` for standard resources
6. **Error Handling**: Always wrap API calls in try-except blocks for HttpResponseError
7. **Async for Scale**: Use async client for high-throughput scenarios
8. **Content Recording**: Be cautious with `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` in production (may include sensitive data)
9. **Evaluation**: Run evaluations regularly to monitor agent quality
10. **Memory Management**: Clean up conversations, agents, and files when no longer needed

## Environment Variables Reference

Required:
- `AZURE_AI_PROJECT_ENDPOINT`: Your project endpoint URL
- `AZURE_AI_MODEL_DEPLOYMENT_NAME`: Model deployment name

Optional (based on features used):
- `AI_SEARCH_PROJECT_CONNECTION_ID`: Azure AI Search connection
- `BING_PROJECT_CONNECTION_ID`: Bing search connection
- `BING_CUSTOM_SEARCH_PROJECT_CONNECTION_ID`: Bing custom search connection
- `BING_CUSTOM_SEARCH_INSTANCE_NAME`: Bing custom instance
- `FABRIC_PROJECT_CONNECTION_ID`: Microsoft Fabric connection
- `SHAREPOINT_PROJECT_CONNECTION_ID`: SharePoint connection
- `BROWSER_AUTOMATION_PROJECT_CONNECTION_ID`: Browser automation connection
- `A2A_PROJECT_CONNECTION_ID`: Agent-to-agent connection
- `A2A_ENDPOINT`: Agent-to-agent endpoint URL
- `MCP_PROJECT_CONNECTION_ID`: MCP server connection
- `OPENAPI_PROJECT_CONNECTION_ID`: OpenAPI connection

Telemetry:
- `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT`: Enable content recording (true/false)
- `AZURE_TRACING_GEN_AI_INSTRUMENT_RESPONSES_API`: Enable automatic instrumentation (true/false)
- `AZURE_TRACING_GEN_AI_INCLUDE_BINARY_DATA`: Include binary data in traces (true/false)

## Resources

- [Product Documentation](https://aka.ms/azsdk/azure-ai-projects-v2/product-doc)
- [API Reference](https://aka.ms/azsdk/azure-ai-projects-v2/python/api-reference)
- [Samples](https://aka.ms/azsdk/azure-ai-projects-v2/python/samples/)
- [Package (PyPI)](https://aka.ms/azsdk/azure-ai-projects-v2/python/package)
- [SDK Source Code](https://aka.ms/azsdk/azure-ai-projects-v2/python/code)
- [Release History](https://aka.ms/azsdk/azure-ai-projects-v2/python/release-history)
- [REST API Reference](https://aka.ms/azsdk/azure-ai-projects-v2/api-reference-2025-11-15-preview)
- [GitHub Issues](https://github.com/Azure/azure-sdk-for-python/issues)

## Version Information

SDK Version: 2.0.0b1 (preview)
API Version: 2025-11-15-preview
Python: 3.9+
