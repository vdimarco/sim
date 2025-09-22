# AGENTS.md

## Project Overview
Sim is an AI agent workflow platform built with Next.js, featuring real-time collaboration, workflow execution, and multi-provider AI integration. The project uses a monorepo structure with Turbo for build orchestration and Bun as the primary runtime.

## Setup Commands

### Prerequisites
- **Bun** >= 1.2.13 (primary package manager)
- **Node.js** >= 20.0.0 (for compatibility)
- **Docker** (for containerized deployment)
- **PostgreSQL** with pgvector extension (for vector storage)

### Development Setup
```bash
# Install dependencies
bun install

# Start development server (Next.js app on port 3000)
bun run dev

# Start realtime socket server (port 3002)
bun run dev:sockets

# Start both services concurrently
bun run dev:full

# Start docs app
cd apps/docs && bun run dev
```

### Database Commands
```bash
# Push schema changes to database
bun run db:push

# Open Drizzle Studio (database GUI)
bun run db:studio

# Run database migrations
bun run db:migrate
```

### Testing Commands
```bash
# Run all tests
bun run test

# Run tests in watch mode
bun run test:watch

# Run tests with coverage
bun run test:coverage

# Run specific test suite
bun run test:billing:suite
```

### Build Commands
```bash
# Build all apps
bun run build

# Type check all code
bun run type-check

# Build for production (with Turbopack)
cd apps/sim && bun run build
```

## Code Style

### TypeScript Configuration
- Use **TypeScript strict mode** enabled
- Prefer **explicit types** over `any`
- Use **interface** over `type` for object shapes
- Enable **noUnusedLocals** and **noUnusedParameters**

### React/Next.js Patterns
- Use **functional components** with hooks
- Prefer **server components** over client components when possible
- Use **React 19** features (latest version)
- Implement **proper error boundaries**
- Use **Next.js 15** App Router patterns

### Code Formatting & Linting
- **Biome** for formatting and linting (not ESLint/Prettier)
- **Single quotes** for strings
- **2 spaces** for indentation
- **100 character** line width
- **Trailing commas** in ES5 style
- **Semicolons** as needed (not always)

### Import Organization
```typescript
// 1. Node modules and React
import { useState } from 'react'
import { NextRequest } from 'next/server'

// 2. External packages
import { z } from 'zod'
import { drizzle } from 'drizzle-orm'

// 3. Internal components
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'

// 4. Internal libs
import { db } from '@/lib/db'
import { env } from '@/lib/env'

// 5. Relative imports
import './styles.css'
import { localFunction } from './utils'
```

## Testing Guidelines

### Testing Framework
- **Vitest** for unit and integration tests
- **@testing-library/react** for component testing
- **@testing-library/jest-dom** for DOM assertions
- **jsdom** environment for browser APIs

### Test Structure
```typescript
// Test file naming: *.test.ts or *.test.tsx
// Test location: co-located with source files

describe('ComponentName', () => {
  it('should render correctly', () => {
    // Arrange
    const props = { title: 'Test' }
    
    // Act
    render(<ComponentName {...props} />)
    
    // Assert
    expect(screen.getByText('Test')).toBeInTheDocument()
  })
})
```

### Coverage Requirements
- Aim for **>80% code coverage**
- Test all **public APIs** and **edge cases**
- Mock **external dependencies** (APIs, databases)
- Use **MSW** for API mocking when needed

### Test Commands
```bash
# Run specific test file
bun test src/components/Button.test.tsx

# Run tests matching pattern
bun test --grep "workflow execution"

# Run tests with coverage
bun test --coverage
```

## Project Structure

### Monorepo Architecture
```
sim/
├── apps/
│   ├── sim/                 # Main Next.js application
│   └── docs/               # Documentation site
├── packages/
│   ├── cli/                # CLI package
│   ├── python-sdk/         # Python SDK
│   └── ts-sdk/             # TypeScript SDK
├── deploy/                 # Deployment configurations
├── docker/                 # Docker configurations
└── helm/                   # Kubernetes Helm charts
```

### Main App Structure (`apps/sim/`)
```
apps/sim/
├── app/                    # Next.js App Router
│   ├── (auth)/            # Authentication routes
│   ├── (landing)/         # Landing page routes
│   ├── api/               # API routes
│   ├── chat/              # Chat interface
│   ├── workspace/         # Main workspace
│   └── layout.tsx         # Root layout
├── components/            # Reusable UI components
├── lib/                   # Utility libraries
├── hooks/                 # Custom React hooks
├── stores/                # Zustand state management
├── tools/                 # Tool implementations
├── blocks/                # Workflow blocks
├── executor/              # Workflow execution engine
├── socket-server/         # Real-time WebSocket server
└── db/                    # Database schema and migrations
```

### Key Directories
- **`/app/api`** - Next.js API routes (REST endpoints)
- **`/lib`** - Shared utilities and configurations
- **`/components/ui`** - Reusable UI components (Radix UI based)
- **`/tools`** - Tool implementations for AI agents
- **`/blocks`** - Workflow building blocks
- **`/executor`** - Workflow execution engine
- **`/socket-server`** - Real-time collaboration server

## Development Workflow

### Git Workflow
- **Main branch**: `main` (protected)
- **Feature branches**: `feature/description`
- **Bug fixes**: `fix/description`
- **Hotfixes**: `hotfix/description`
- **Conventional commits**: Use conventional commit format

### Commit Format
```bash
# Format: type(scope): description
feat(workflow): add new workflow execution engine
fix(auth): resolve login redirect issue
docs(api): update authentication endpoints
test(executor): add unit tests for workflow execution
```

### Pull Request Process
1. **Create feature branch** from `main`
2. **Write tests** for new functionality
3. **Update documentation** if needed
4. **Run linting and tests** before committing
5. **Create pull request** with descriptive title
6. **Request review** from team members
7. **Squash commits** before merging
8. **Delete feature branch** after merge

### Code Review Guidelines
- **Review all changes** before merging
- **Test locally** if significant changes
- **Check for security vulnerabilities**
- **Ensure proper error handling**
- **Verify TypeScript types**
- **Check for performance implications**

## Architecture Patterns

### State Management
- **Zustand** for client-side state
- **Server state** via React Query/SWR
- **URL state** for filters and pagination
- **Local storage** for user preferences

### API Design
- **RESTful APIs** in `/app/api`
- **WebSocket** for real-time features
- **Server Actions** for form submissions
- **Middleware** for authentication and validation

### Database Patterns
- **Drizzle ORM** for type-safe queries
- **PostgreSQL** with pgvector for embeddings
- **Migrations** for schema changes
- **Connection pooling** for performance

### AI Integration
- **Multi-provider support** (OpenAI, Anthropic, etc.)
- **Tool system** for agent capabilities
- **Workflow execution** engine
- **Vector search** for knowledge base

## Environment Configuration

### Required Environment Variables
```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/sim

# Authentication
BETTER_AUTH_SECRET=your-secret-key
ENCRYPTION_KEY=your-encryption-key

# AI Providers
OPENAI_API_KEY=your-openai-key
ANTHROPIC_API_KEY_1=your-anthropic-key

# External Services
RESEND_API_KEY=your-resend-key
STRIPE_SECRET_KEY=your-stripe-key
```

### Development vs Production
- **Development**: Use `.env.local` for local overrides
- **Production**: Use secure secret management
- **Testing**: Use `.env.test` for test-specific configs

## Performance Guidelines

### Next.js Optimization
- Use **server components** when possible
- Implement **proper caching** strategies
- **Optimize images** with Next.js Image component
- Use **dynamic imports** for code splitting

### Database Optimization
- **Index frequently queried columns**
- Use **connection pooling**
- **Optimize queries** with proper joins
- **Monitor query performance**

### Bundle Optimization
- **Tree shake** unused code
- **Code split** by route
- **Lazy load** heavy components
- **Optimize dependencies**

## Security Guidelines

### Authentication & Authorization
- Use **Better Auth** for authentication
- Implement **proper session management**
- **Validate all inputs** with Zod schemas
- **Sanitize user content** before storage

### API Security
- **Rate limiting** on API endpoints
- **CORS** configuration for cross-origin requests
- **Input validation** on all endpoints
- **Error handling** without information leakage

### Data Protection
- **Encrypt sensitive data** at rest
- **Use HTTPS** in production
- **Implement proper logging** for security events
- **Regular security audits** of dependencies

## Deployment

### Local Development
```bash
# Start all services
bun run dev:full

# Start with specific environment
NODE_ENV=development bun run dev
```

### Production Deployment
- **Docker containers** for consistency
- **Kubernetes** for orchestration
- **Google Cloud Platform** for hosting
- **Helm charts** for configuration management

### Monitoring & Observability
- **Sentry** for error tracking
- **Prometheus** for metrics
- **Grafana** for dashboards
- **Google Cloud Operations** for logging

## Common Patterns

### Error Handling
```typescript
// API Route Error Handling
export async function GET(request: NextRequest) {
  try {
    const data = await processRequest(request)
    return NextResponse.json(data)
  } catch (error) {
    console.error('API Error:', error)
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    )
  }
}
```

### Database Queries
```typescript
// Using Drizzle ORM
import { db } from '@/lib/db'
import { users } from '@/db/schema'

export async function getUser(id: string) {
  const user = await db
    .select()
    .from(users)
    .where(eq(users.id, id))
    .limit(1)
  
  return user[0] || null
}
```

### Component Patterns
```typescript
// Server Component
export default async function Page() {
  const data = await getData()
  return <div>{data.title}</div>
}

// Client Component
'use client'
export function InteractiveComponent() {
  const [state, setState] = useState('')
  return <button onClick={() => setState('clicked')}>Click me</button>
}
```

## Troubleshooting

### Common Issues
1. **Database connection errors**: Check `DATABASE_URL` and connection pool
2. **Build failures**: Clear `.next` and `node_modules`, reinstall
3. **Type errors**: Run `bun run type-check` to identify issues
4. **Test failures**: Check test environment setup and mocks

### Debug Commands
```bash
# Check TypeScript errors
bun run type-check

# Lint and format code
bun run lint
bun run format

# Check database connection
bun run db:studio

# Run specific test with debug
bun test --reporter=verbose ComponentName.test.tsx
```

## Resources

- **Documentation**: [docs.sim.ai](https://docs.sim.ai)
- **GitHub**: [github.com/simstudioai/sim](https://github.com/simstudioai/sim)
- **Support**: help@sim.ai
- **Next.js Docs**: [nextjs.org/docs](https://nextjs.org/docs)
- **Drizzle ORM**: [orm.drizzle.team](https://orm.drizzle.team)
- **Biome**: [biomejs.dev](https://biomejs.dev)

