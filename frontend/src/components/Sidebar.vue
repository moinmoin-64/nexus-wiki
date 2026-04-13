<template>
  <div class="sidebar h-full flex flex-col bg-nexus-gray">
    <!-- Sidebar Header -->
    <div class="p-4 border-b border-gray-700">
      <button
        @click="showNewDocForm = !showNewDocForm"
        class="w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg text-sm font-medium transition-colors"
      >
        + New Document
      </button>
    </div>

    <!-- Search in Sidebar -->
    <div class="p-4 border-b border-gray-700">
      <input
        v-model="sidebarSearch"
        type="text"
        placeholder="Filter..."
        class="w-full px-3 py-2 bg-nexus-darker border border-gray-600 rounded-lg text-sm text-gray-100 placeholder-gray-500 focus:outline-none focus:border-blue-500"
      />
    </div>

    <!-- Documents Tree -->
    <div class="flex-1 overflow-y-auto p-2">
      <div v-if="filteredDocuments.length === 0" class="text-gray-500 text-sm p-4 text-center">
        No documents found
      </div>
      
      <div
        v-for="doc in filteredDocuments"
        :key="doc.uuid"
        class="mb-1"
      >
        <button
          @click="selectDoc(doc)"
          :class="[
            'w-full text-left px-4 py-2 rounded-lg text-sm transition-colors hover:bg-nexus-darker',
            selectedDoc?.uuid === doc.uuid ? 'bg-blue-600 text-white' : 'text-gray-300'
          ]"
        >
          <div class="flex items-center gap-2">
            <span class="text-xs font-medium opacity-60" :style="`color: ${getStatusColor(doc.status)}`">
              {{ doc.status[0].toUpperCase() }}
            </span>
            <span class="truncate">{{ doc.title }}</span>
          </div>
          <div v-if="doc.tags?.length" class="text-xs opacity-60 mt-1">
            {{ doc.tags.join(', ') }}
          </div>
        </button>
      </div>
    </div>

    <!-- Sidebar Footer Stats -->
    <div class="border-t border-gray-700 p-4 text-xs text-gray-500">
      <div class="space-y-1">
        <div>📄 {{ documents.length }} documents</div>
        <div>🔗 {{ linkCount }} links</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useDocumentStore } from '@/stores/documents'

const emit = defineEmits<{
  selectDocument: [id: string]
}>()

const docStore = useDocumentStore()
const sidebarSearch = ref('')
const showNewDocForm = ref(false)
const selectedDoc = ref(null)

const documents = computed(() => docStore.documents)

const filteredDocuments = computed(() => {
  if (!sidebarSearch.value) return documents.value
  
  const query = sidebarSearch.value.toLowerCase()
  return documents.value.filter(doc =>
    doc.title.toLowerCase().includes(query) ||
    doc.tags?.some(tag => tag.toLowerCase().includes(query))
  )
})

const linkCount = computed(() => {
  return documents.value.reduce((sum, doc) => sum + (doc.backlinks?.length || 0), 0)
})

const getStatusColor = (status: string) => {
  const colors: Record<string, string> = {
    draft: '#999',
    review: '#fbbf24',
    published: '#10b981'
  }
  return colors[status] || '#999'
}

const selectDoc = (doc: any) => {
  selectedDoc.value = doc
  emit('selectDocument', doc.uuid)
}

onMounted(async () => {
  await docStore.fetchDocuments()
})
</script>

<style scoped>
.sidebar {
  background-image: linear-gradient(135deg, rgb(15, 20, 25) 0%, rgb(13, 18, 24) 100%);
}
</style>
