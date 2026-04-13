# Project Nexus - Frontend Application

A modern, minimalist Vue.js 3 frontend for the Nexus knowledge management system, featuring a block-based editor (Tiptap), real-time collaboration, and interactive knowledge graph visualization.

## Features

### Core UI
- **Dark Mode by Default**: Professional dark theme with Tailwind CSS
- **Sidebar Navigation**: Tree view of all documents with search/filter
- **Breadcrumb Navigation**: Easy document hierarchy tracking
- **Status Indicators**: Draft/Review/Published workflow visualization

### Document Management
- **Block-Based Editor**: Tiptap/Tiptap with slash commands (`/`)
- **Real-Time Collaboration**: WebSocket support for multi-user editing
- **Markdown Support**: Save as valid Markdown, edit as rich HTML
- **Wikilink Support**: `[[Document References]]` with auto-linking
- **Tag System**: Categorize and filter documents

### Knowledge Graph
- **Interactive Visualization**: Cytoscape.js graph rendering
- **Neighborhood View**: Local context around current document
- **Hub Detection**: Identify central/important documents
- **Dynamic Scaling**: Node size based on link centrality
- **Clustering**: Color-coded by document category

### Search & Discovery
- **Full-Text Search**: Quick document search
- **Backlink Tracking**: Find documents referencing current doc
- **Graph Queries**: Explore document relationships
- **Tag Search**: Filter by tags

## Installation

### Prerequisites
- Node.js 18+
- npm or pnpm

### Setup

```bash
# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

### Environment Variables

```bash
# .env
VITE_API_URL=http://localhost:3001
VITE_WS_PROTO=ws
VITE_WS_HOST=localhost:3001
```

## Project Structure

```
frontend/
├── src/
│   ├── components/          # Vue components
│   │   ├── Sidebar.vue
│   │   ├── DocumentEditor.vue
│   │   ├── DocumentView.vue
│   │   ├── KnowledgeGraph.vue
│   │   └── ...
│   ├── views/              # Page components
│   ├── stores/             # Pinia stores
│   │   ├── documents.ts    # Document management
│   │   ├── graph.ts        # Graph operations
│   │   └── ui.ts           # UI state
│   ├── utils/
│   │   └── api.ts          # API client
│   ├── router/             # Vue Router config
│   ├── App.vue             # Root component
│   ├── main.ts             # Entry point
│   └── style.css           # Global styles
├── index.html
├── vite.config.ts
├── tailwind.config.ts
├── postcss.config.js
└── package.json
```

## Component Hierarchy

```
App.vue (Main Layout)
├── Sidebar.vue (or KnowledgeGraph.vue)
│   └── Document tree/graph
├── Main Content Area
│   ├── Breadcrumb Navigation
│   ├── DocumentEditor.vue (editing mode)
│   └── DocumentView.vue (read mode)
└── Notification Toast
```

## Technologies Used

### Core
- **Vue.js 3.3**: Composition API
- **Vite 5**: Fast build tool
- **TypeScript**: Type safety

### UI & Styling
- **Tailwind CSS 3**: Utility-first CSS
- **Radix UI**: Accessible components
- **Headless UI**: Unstyled components

### Editors & Graphs
- **Tiptap 2**: Rich text editor
- **@tiptap/starter-kit**: Common extensions
- **Cytoscape.js**: Graph visualization
- **Cytoscape-cola**: Force-directed layout

### State Management
- **Pinia**: Vue 3 state management
- **Axios**: HTTP client

### Utilities
- **date-fns**: Date formatting
- **uuid**: Unique ID generation
- **lodash-es**: Utility functions

## Editor Usage

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `/` | Open command menu |
| `#` | Heading 1 |
| `##` | Heading 2 |
| `-` | Bullet list |
| `1.` | Numbered list |
| `` ` `` | Code block |
| `>` | Blockquote |
| `---` | Divider |

### Formatting

| Syntax | Result |
|--------|--------|
| `**text**` | **Bold** |
| `*text*` | *Italic* |
| `` `code` `` | `Code` |
| `[[Document Title]]` | Wikilink |
| `[Link](url)` | Link |

## Search Syntax

```
# Simple search
architecture

# Tag filter
tag:architecture

# Status filter
status:published

# Combined
architecture status:published tag:design

# Exact phrase
"system design"
```

## Real-Time Collaboration

When multiple users edit the same document:

1. Local edits are sent via WebSocket
2. Remote edits appear in real-time
3. Cursor positions are synchronized
4. Conflicts handled gracefully (last-write-wins)

### WebSocket Events

**Send (Client → Server):**
```json
{
  "type": "edit",
  "content": "updated content",
  "cursor": { "line": 5, "column": 10 }
}
```

**Receive (Server → Client):**
```json
{
  "type": "remoteEdit",
  "userId": "user456",
  "content": "other user's edit",
  "cursor": { "line": 3, "column": 5 }
}
```

## Graph Visualization

### Nodes
- **Size**: Proportional to centrality (link count)
- **Color**: By document category/tag
- **Center**: Currently viewed document (blue)
- **Neighbors**: Linked documents (green)

### Interactions
- **Click node**: Show document info
- **Double-click node**: Open document
- **Drag**: Rearrange layout
- **Zoom**: Scroll wheel

### Queries
- **Neighborhood**: 1-2 hop radius
- **Full Network**: All connected documents
- **Hub View**: Most central documents

## Performance Optimizations

- ✅ **Code Splitting**: Lazy-loaded routes and components
- ✅ **Tree-Shaking**: Unused code removed in build
- ✅ **Image Optimization**: Automatic format conversion
- ✅ **CSS Purging**: Only used styles in production
- ⚠️ **TODO**: Virtual scrolling for large lists
- ⚠️ **TODO**: Caching strategy for API responses

## Accessibility

- ARIA labels on interactive elements
- Keyboard navigation support
- Color-blind friendly color palettes
- High contrast text

## Browser Support

- Chrome/Edge 90+
- Firefox 88+
- Safari 14+

## Development Tips

### Debug Mode

```bash
# Enable Vue DevTools
npm run dev

# Check Vite config
node -e "console.log(require('./vite.config.ts'))"
```

### Common Issues

**WebSocket connection fails**
- Ensure backend API is running on correct port
- Check CORS configuration
- Verify `VITE_WS_HOST` in .env

**Graph visualization not showing**
- Check Neo4j is connected to backend
- Verify document has wikilinks
- Open browser DevTools to check errors

**Slow editor performance**
- Use smaller documents initially
- Reduce collaboration user count
- Check browser developer tools for memory leaks

## Build & Deploy

```bash
# Production build
npm run build

# Output: dist/ folder
# Deploy dist/ to web server (Nginx)

# Preview built app
npm run preview
```

### Docker Build

```dockerfile
FROM node:18-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Vite dev server 404 | Clear cache: `rm -rf node_modules/.vite` |
| API connection refused | Start backend: `npm run backend` |
| Styles not loading | Run: `npm install -D tailwindcss` |
| Blank graph | Check Neo4j service is running |

## Contributing

1. Follow Vue 3 Composition API patterns
2. Use TypeScript for type safety
3. Component name should match file name
4. Keep components under 300 lines
5. Document complex logic with comments

## License

Proprietary - Project Nexus
