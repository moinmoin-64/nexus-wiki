import { defineStore } from 'pinia'
import { ref } from 'vue'
import { apiClient } from '@/utils/api'

export interface GraphNode {
  uuid: string
  title: string
  centrality: number
  inlinks: number
  outlinks: number
}

export interface GraphEdge {
  source: string
  target: string
}

export const useGraphStore = defineStore('graph', () => {
  const neighborhood = ref<{
    center: GraphNode
    neighbors: GraphNode[]
    links: GraphEdge[]
  } | null>(null)

  const backlinks = ref<any[]>([])
  const hubs = ref<GraphNode[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  const fetchNeighborhood = async (docId: string, depth = 1) => {
    loading.value = true
    error.value = null
    try {
      const response = await apiClient.get(`/graph/neighborhood/${docId}`, {
        params: { depth }
      })
      neighborhood.value = response.data
      return response.data
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  const fetchBacklinks = async (title: string) => {
    error.value = null
    try {
      const response = await apiClient.get(`/graph/backlinks/${encodeURIComponent(title)}`)
      backlinks.value = response.data.backlinks
      return response.data.backlinks
    } catch (err: any) {
      error.value = err.message
      throw err
    }
  }

  const fetchHubs = async (limit = 20) => {
    error.value = null
    try {
      const response = await apiClient.get('/graph/centrality', { params: { limit } })
      hubs.value = response.data.hubs
      return response.data.hubs
    } catch (err: any) {
      error.value = err.message
      throw err
    }
  }

  return {
    neighborhood,
    backlinks,
    hubs,
    loading,
    error,
    fetchNeighborhood,
    fetchBacklinks,
    fetchHubs
  }
})
