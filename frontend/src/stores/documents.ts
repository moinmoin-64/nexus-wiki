import { defineStore } from 'pinia'
import { ref } from 'vue'
import { apiClient } from '@/utils/api'

export interface Document {
  id?: number
  uuid?: string
  title: string
  content: string
  markdown_raw: string
  status: 'draft' | 'review' | 'published'
  tags: string[]
  created_at?: string
  updated_at?: string
  backlinks?: any[]
}

export const useDocumentStore = defineStore('documents', () => {
  const documents = ref<Document[]>([])
  const currentDocument = ref<Document | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  const fetchDocuments = async (params?: any) => {
    loading.value = true
    error.value = null
    try {
      const response = await apiClient.get('/documents', { params })
      documents.value = response.data.data
      return response.data.data
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  const fetchDocument = async (id: string) => {
    loading.value = true
    error.value = null
    try {
      const response = await apiClient.get(`/documents/${id}`)
      currentDocument.value = response.data
      return response.data
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  const createDocument = async (doc: Document) => {
    error.value = null
    try {
      const response = await apiClient.post('/documents', doc)
      documents.value.unshift(response.data)
      currentDocument.value = response.data
      return response.data
    } catch (err: any) {
      error.value = err.message
      throw err
    }
  }

  const updateDocument = async (id: string, updates: Partial<Document>) => {
    error.value = null
    try {
      const response = await apiClient.put(`/documents/${id}`, updates)
      const index = documents.value.findIndex(d => d.uuid === id)
      if (index > -1) {
        documents.value[index] = response.data
      }
      currentDocument.value = response.data
      return response.data
    } catch (err: any) {
      error.value = err.message
      throw err
    }
  }

  const deleteDocument = async (id: string) => {
    error.value = null
    try {
      await apiClient.delete(`/documents/${id}`)
      documents.value = documents.value.filter(d => d.uuid !== id)
      if (currentDocument.value?.uuid === id) {
        currentDocument.value = null
      }
    } catch (err: any) {
      error.value = err.message
      throw err
    }
  }

  const search = async (query: string, type = 'all') => {
    error.value = null
    try {
      const response = await apiClient.get('/search', {
        params: { q: query, type }
      })
      return response.data.results
    } catch (err: any) {
      error.value = err.message
      throw err
    }
  }

  return {
    documents,
    currentDocument,
    loading,
    error,
    fetchDocuments,
    fetchDocument,
    createDocument,
    updateDocument,
    deleteDocument,
    search
  }
})
