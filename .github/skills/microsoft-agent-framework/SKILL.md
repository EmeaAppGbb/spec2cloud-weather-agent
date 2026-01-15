---
name: microsoft-agent-framework
description: Expert guidance for building AI agents using Microsoft Agent Framework. Use when creating single agents, multi-agent workflows, chat applications, or integrating tools with LLMs. Covers ChatAgent, tools (@ai_function), orchestration patterns (GroupChat, Sequential, Concurrent, Handoff), memory/state management, observability, and declarative YAML agents. Supports Python and .NET.
---

# Microsoft Agent Framework

Build AI agents and multi-agent workflows using Microsoft's comprehensive agent framework.

## Installation

```bash
# Core package
pip install agent-framework --pre
```

Library name to add to the requirements.txt file: agent-framework using the pre release version

## Use the following samples to generate the code

| File | Description |
|------|-------------|
| [`azure_ai_basic.py`](samples/azure_ai_basic.py) | The simplest way to create an agent using `ChatAgent` with `AzureAIAgentClient`. It automatically handles all configuration using environment variables. |
| [`azure_ai_with_bing_custom_search.py`](samples/azure_ai_with_bing_custom_search.py) | Shows how to use Bing Custom Search with Azure AI agents to find real-time information from the web using custom search configurations. Demonstrates how to set up and use HostedWebSearchTool with custom search instances. |
| [`azure_ai_with_bing_grounding.py`](samples/azure_ai_with_bing_grounding.py) | Shows how to use Bing Grounding search with Azure AI agents to find real-time information from the web. Demonstrates web search capabilities with proper source citations and comprehensive error handling. |
| [`azure_ai_with_bing_grounding_citations.py`](samples/azure_ai_with_bing_grounding_citations.py) | Demonstrates how to extract and display citations from Bing Grounding search responses. Shows how to collect citation annotations (title, URL, snippet) during streaming responses, enabling users to verify sources and access referenced content. |
| [`azure_ai_with_code_interpreter_file_generation.py`](samples/azure_ai_with_code_interpreter_file_generation.py) | Shows how to retrieve file IDs from code interpreter generated files using both streaming and non-streaming approaches. |
| [`azure_ai_with_code_interpreter.py`](samples/azure_ai_with_code_interpreter.py) | Shows how to use the HostedCodeInterpreterTool with Azure AI agents to write and execute Python code. Includes helper methods for accessing code interpreter data from response chunks. |
| [`azure_ai_with_existing_agent.py`](samples/azure_ai_with_existing_agent.py) | Shows how to work with a pre-existing agent by providing the agent ID to the Azure AI chat client. This example also demonstrates proper cleanup of manually created agents. |
| [`azure_ai_with_existing_thread.py`](samples/azure_ai_with_existing_thread.py) | Shows how to work with a pre-existing thread by providing the thread ID to the Azure AI chat client. This example also demonstrates proper cleanup of manually created threads. |
| [`azure_ai_with_explicit_settings.py`](samples/azure_ai_with_explicit_settings.py) | Shows how to create an agent with explicitly configured `AzureAIAgentClient` settings, including project endpoint, model deployment, credentials, and agent name. |
| [`azure_ai_with_azure_ai_search.py`](samples/azure_ai_with_azure_ai_search.py) | Demonstrates how to use Azure AI Search with Azure AI agents to search through indexed data. Shows how to configure search parameters, query types, and integrate with existing search indexes. |
| [`azure_ai_with_file_search.py`](samples/azure_ai_with_file_search.py) | Demonstrates how to use the HostedFileSearchTool with Azure AI agents to search through uploaded documents. Shows file upload, vector store creation, and querying document content. Includes both streaming and non-streaming examples. |
| [`azure_ai_with_function_tools.py`](samples/azure_ai_with_function_tools.py) | Demonstrates how to use function tools with agents. Shows both agent-level tools (defined when creating the agent) and query-level tools (provided with specific queries). |
| [`azure_ai_with_hosted_mcp.py`](samples/azure_ai_with_hosted_mcp.py) | Shows how to integrate Azure AI agents with hosted Model Context Protocol (MCP) servers for enhanced functionality and tool integration. Demonstrates remote MCP server connections and tool discovery. |
| [`azure_ai_with_local_mcp.py`](samples/azure_ai_with_local_mcp.py) | Shows how to integrate Azure AI agents with local Model Context Protocol (MCP) servers for enhanced functionality and tool integration. Demonstrates both agent-level and run-level tool configuration. |
| [`azure_ai_with_multiple_tools.py`](samples/azure_ai_with_multiple_tools.py) | Demonstrates how to use multiple tools together with Azure AI agents, including web search, MCP servers, and function tools. Shows coordinated multi-tool interactions and approval workflows. |
| [`azure_ai_with_openapi_tools.py`](samples/azure_ai_with_openapi_tools.py) | Demonstrates how to use OpenAPI tools with Azure AI agents to integrate external REST APIs. Shows OpenAPI specification loading, anonymous authentication, thread context management, and coordinated multi-API conversations using weather and countries APIs. |
| [`azure_ai_with_thread.py`](samples/azure_ai_with_thread.py) | Demonstrates thread management with Azure AI agents, including automatic thread creation for stateless conversations and explicit thread management for maintaining conversation context across multiple interactions. |
