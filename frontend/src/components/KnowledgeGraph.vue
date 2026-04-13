<template>
  <div class="knowledge-graph h-full flex flex-col bg-nexus-gray">
    <!-- Graph Header -->
    <div class="border-b border-gray-700 px-4 py-3">
      <h3 class="font-semibold text-gray-100 text-sm mb-2">Knowledge Graph</h3>
      <button
        @click="toggleType"
        class="text-xs px-3 py-1 bg-blue-600 hover:bg-blue-700 rounded transition-colors"
      >
        {{ graphType === 'neighborhood' ? 'Neighborhood' : 'Network' }}
      </button>
    </div>

    <!-- Graph Container -->
    <div ref="graphContainer" class="flex-1 overflow-hidden relative bg-nexus-darker" />

    <!-- Node Info Panel -->
    <div v-if="selectedNode" class="border-t border-gray-700 bg-nexus-gray p-4 max-h-48 overflow-y-auto">
      <div class="space-y-2 text-sm">
        <div class="font-semibold text-blue-400">{{ selectedNode.data.title }}</div>
        <div class="text-gray-400">
          <div>Centrality: {{ selectedNode.data.centrality }}</div>
          <div>Inlinks: {{ selectedNode.data.inlink_count }}</div>
          <div>Outlinks: {{ selectedNode.data.outlink_count }}</div>
        </div>
        <button
          @click="goToDocument"
          class="w-full mt-2 px-3 py-1 bg-blue-600 hover:bg-blue-700 rounded text-xs transition-colors"
        >
          Open
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="absolute inset-0 bg-black bg-opacity-50 flex items-center justify-center">
      <div class="text-gray-300">Loading graph...</div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'
import cytoscape from 'cytoscape'
import cola from 'cytoscape-cola'
import { useGraphStore } from '@/stores/graph'

cytoscape.use(cola)

const props = defineProps<{
  currentDocId: string | null
}>()

const emit = defineEmits<{
  selectDocument: [id: string]
}>()

const graphStore = useGraphStore()
const graphContainer = ref<HTMLElement | null>(null)
const cy = ref<cytoscape.Core | null>(null)
const selectedNode = ref<any>(null)
const loading = ref(false)
const graphType = ref<'neighborhood' | 'full'>('neighborhood')

const toggleType = () => {
  graphType.value = graphType.value === 'neighborhood' ? 'full' : 'neighborhood'
  if (props.currentDocId) {
    loadGraph()
  }
}

const loadGraph = async () => {
  if (!graphContainer.value || !props.currentDocId) return

  loading.value = true
  try {
    let data: any

    if (graphType.value === 'neighborhood') {
      // Load neighborhood around current document
      data = await graphStore.fetchNeighborhood(props.currentDocId, 2)
    } else {
      // Load central hubs
      await graphStore.fetchHubs(50)
      data = graphStore.hubs
    }

    if (!cy.value) {
      initializeGraph()
    }

    populateGraph(data)
  } catch (error) {
    console.error('Graph load error:', error)
  } finally {
    loading.value = false
  }
}

const initializeGraph = () => {
  if (!graphContainer.value) return

  cy.value = cytoscape({
    container: graphContainer.value,
    style: [
      {
        selector: 'node',
        style: {
          'content': 'data(title)',
          'width': 'mapData(centrality, 0, 100, 20, 80)',
          'height': 'mapData(centrality, 0, 100, 20, 80)',
          'background-color': 'data(color)',
          'text-valign': 'center',
          'text-halign': 'center',
          'font-size': 12,
          'color': '#ccc',
          'border-width': 2,
          'border-color': 'data(borderColor)',
        },
      },
      {
        selector: 'node:selected',
        style: {
          'border-color': '#3b82f6',
          'border-width': 3,
        },
      },
      {
        selector: 'edge',
        style: {
          'target-arrow-color': '#9ca3af',
          'target-arrow-shape': 'triangle',
          'line-color': '#4b5563',
          'opacity': 0.5,
        },
      },
    ],
    layout: {
      name: 'cola',
      directed: true,
      animate: true,
      animationDuration: 500,
      avoidOverlap: true,
      nodeSpacing: 10,
    },
  })

  // Node click handler
  cy.value.on('tap', 'node', (event) => {
    selectedNode.value = event.target
  })

  // Tap empty space to deselect
  cy.value.on('tap', (event) => {
    if (event.target === cy.value) {
      selectedNode.value = null
    }
  })
}

const populateGraph = (data: any) => {
  if (!cy.value) return

  cy.value.elements().remove()

  const nodes: any[] = []
  const edges: any[] = []

  // Add nodes
  if (data.center) {
    // Neighborhood view
    const center = data.center
    nodes.push({
      data: {
        id: center.uuid,
        title: center.title,
        centrality: center.centrality || 10,
        inlink_count: 0,
        outlink_count: 0,
        color: '#3b82f6', // Blue for center
        borderColor: '#1e40af',
      },
    })

    data.neighbors?.forEach((neighbor: any) => {
      nodes.push({
        data: {
          id: neighbor.uuid,
          title: neighbor.title,
          centrality: neighbor.centrality || 5,
          inlink_count: neighbor.inlinks || 0,
          outlink_count: neighbor.outlinks || 0,
          color: '#10b981', // Green for neighbors
          borderColor: '#047857',
        },
      })
    })

    // Add edges
    data.links?.forEach((link: any) => {
      edges.push({
        data: {
          source: link.source,
          target: link.target,
        },
      })
    })
  } else if (Array.isArray(data)) {
    // Hub view
    data.forEach((hub: any, index: number) => {
      const hue = (index / data.length) * 360
      nodes.push({
        data: {
          id: hub.uuid,
          title: hub.title,
          centrality: hub.centrality || 10,
          color: `hsl(${hue}, 70%, 50%)`,
          borderColor: `hsl(${hue}, 70%, 30%)`,
        },
      })
    })
  }

  cy.value.add(nodes)
  cy.value.add(edges)

  // Layout
  const layout = cy.value.layout({ name: 'cola' })
  layout.run()
}

const goToDocument = () => {
  if (selectedNode.value) {
    emit('selectDocument', selectedNode.value.data().id)
  }
}

watch(() => props.currentDocId, () => {
  loadGraph()
})

onMounted(() => {
  if (props.currentDocId) {
    loadGraph()
  }
})

onBeforeUnmount(() => {
  if (cy.value) {
    cy.value.destroy()
  }
})
</script>

<style scoped>
.knowledge-graph {
  background: linear-gradient(135deg, rgb(15, 20, 25) 0%, rgb(13, 18, 24) 100%);
}
</style>
