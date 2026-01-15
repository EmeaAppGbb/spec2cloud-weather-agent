---
title: Weather AI Agent - MVP Functional Requirements
version: 2.0
date_created: 2025-12-04
last_updated: 2026-01-14
owner: Weather Agent Team
tags: [functional, requirements, mvp, ai-agent, mcp, azure]
---

# Weather AI Agent - MVP FRD

Technical requirements for a weather information system with a chat UI, AI agent backend, and MCP weather tool.

## 1. System Overview

**Components**:
- **Frontend**: Next.js web UI with chat interface
- **Backend**: Python AI hosted agent using Microsoft Agent Framework. Use the hosted-agent skill and the `skills/hosted-agents/samples/agent_with_hosted_mcp` sample.
- **MCP Server**: Python weather tool using FastMCP with mocking data. Use the mcp-builder skill.

**Infrastructure**: Azure Container Apps, Microsoft Foundry, Container Registry

## 2. Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Frontend   │────▶│   Backend   │────▶│ MCP Server  │
│  (Next.js)  │     │  (Python)   │     │  (FastMCP)  │
│  External   │     │  Internal   │     │  Internal   │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Microsoft  │
                    │   Foundry   │
                    └─────────────┘
```

## 3. Core Requirements

### Frontend

| ID | Requirement |
|----|-------------|
| **FE-001** | Built with Next.js and Tailwind CSS |
| **FE-002** | Chat interface for user interaction |
| **FE-003** | Support streaming responses (SSE) |
| **FE-004** | Responsive design (mobile + desktop) |

### Backend

| ID | Requirement |
|----|-------------|
| **BE-001** | Python with Microsoft Agent Framework |
| **BE-002** | REST API with SSE streaming |
| **BE-003** | The agent framework will invoke MCP weather tool via `HostedMCPTool` as in the `skills/hosted-agents/samples/agent_with_hosted_mcp/main.py` from the hosted-agents skill  |
| **BE-004** | Use Microsoft Foundry for AI model |

### MCP Server

| ID | Requirement |
|----|-------------|
| **MCP-001** | Python with FastMCP |
| **MCP-002** | Streamable HTTP transport at `/mcp` endpoint |
| **MCP-003** | `get_weather(city)` tool returning structured data |
| **MCP-004** | Mock weather data for demonstration |

### Infrastructure

| ID | Requirement |
|----|-------------|
| **INF-001** | BICEP templates already provided in the `/infra` folder |
| **INF-002** | Deploy via Azure Developer CLI (azd) |
| **INF-003** | Three Container Apps (frontend, backend, MCP) |
| **INF-004** | Microsoft Foundry with deployed AI model |

## 4. Data Contracts

### Chat API

**Endpoint**: `POST /api/chat`

```typescript
// Request
{ message: string; sessionId?: string; }

// Response (SSE stream)
{ type: 'text' | 'weather_data' | 'error' | 'done'; content?: string; }
```

### Weather Data

```python
class WeatherData(BaseModel):
    city: str
    temperature: float
    condition: str
    condition_icon: str
    humidity: int
    wind_speed: float
```

## 5. Environment Variables

```bash
# Backend
AZURE_AI_PROJECT_ENDPOINT=https://{account}.services.ai.azure.com/api/projects/{project}
MCP_SERVER_URL=http://127.0.0.1:8000/mcp
AI_MODEL_DEPLOYMENT=gpt-4.1-mini
```

## 6. Acceptance Criteria

- [ ] `azd provision` creates all Azure resources
- [ ] `azd deploy` deploys all Container Apps
- [ ] User can ask "What's the weather in London?" and get a response
- [ ] MCP server returns valid weather data
- [ ] Streaming responses work end-to-end
- [ ] All components use HTTPS in production

## 7. Security (Minimal)

| ID | Requirement |
|----|-------------|
| **SEC-001** | HTTPS for all communications |
| **SEC-002** | Managed identities for Azure services |
| **SEC-003** | MCP server internal-only access |
| **SEC-004** | Input validation on all endpoints |

## 8. Dependencies

| Component | Technology |
|-----------|------------|
| Frontend | Next.js 14+, Tailwind CSS, Node.js 20 |
| Backend | Python 3.12+, Microsoft Agent Framework |
| MCP Server | Python 3.12+, FastMCP |
| Infrastructure | Azure Container Apps, Microsoft Foundry, ACR |
| Deployment | Azure Developer CLI (azd), BICEP |

## 9. Out of Scope (Future)

- Advanced security (Key Vault, WAF, private endpoints)
- Performance optimization and caching
- Multi-language support
- Real weather API integration
- User authentication
- CI/CD pipelines

## 10. Related Documents

- [Product Requirements Document (PRD)](PRD.md)
- [Model Context Protocol Documentation](https://modelcontextprotocol.io/)
- [Microsoft Agent Framework](https://learn.microsoft.com/azure/ai-services/agents/)
