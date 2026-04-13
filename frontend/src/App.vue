<template>
  <div class="nexus-app h-screen flex flex-col bg-nexus-darker text-gray-100">
    <!-- Top Navigation -->
    <header class="bg-nexus-gray border-b border-gray-700 h-14 flex items-center px-6">
      <div class="flex items-center gap-4 flex-1">
        <!-- Logo -->
        <div class="font-bold text-xl text-white">
          <span class="text-blue-500">⬢</span> Nexus
        </div>
        
        <!-- Search Bar -->
        <div class="flex-1 max-w-md">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search documents..."
            @keydown.enter="handleSearch"
            class="w-full px-4 py-2 bg-nexus-darker border border-gray-600 rounded-lg text-sm text-gray-100 placeholder-gray-500 focus:outline-none focus:border-blue-500"
          />
        </div>
      </div>

      <!-- User Menu -->
      <div class="flex items-center gap-4">
        <button
          @click="toggleGraph"
          class="p-2 hover:bg-nexus-darker rounded-lg transition-colors"
          title="Toggle knowledge graph"
        >
          <span class="text-lg">🔗</span>
        </button>
        <button
          @click="toggleTheme"
          class="p-2 hover:bg-nexus-darker rounded-lg transition-colors"
        >
          <span class="text-lg">🌙</span>
        </button>
        <button
          class="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg text-sm font-medium transition-colors"
        >
          Logout
        </button>
      </div>
    </header>

    <!-- Main Layout -->
    <div class="flex flex-1 overflow-hidden">
      <!-- Sidebar -->
      <Sidebar
        v-if="!showGraph"
        class="w-64 border-r border-gray-700"
        @select-document="selectDocument"
      />

      <!-- Knowledge Graph (replaces sidebar when active) -->
      <KnowledgeGraph
        v-if="showGraph"
        class="w-64 border-r border-gray-700"
        :current-doc-id="currentDocId"
        @select-document="selectDocument"
      />

      <!-- Main Content Area -->
      <main class="flex-1 flex flex-col overflow-hidden">
        <!-- Breadcrumb Navigation -->
        <nav
          v-if="currentDocument"
          class="bg-nexus-gray border-b border-gray-700 px-6 py-3 flex items-center gap-2 text-sm"
        >
          <router-link to="/" class="text-blue-500 hover:text-blue-400">Home</router-link>
          <span class="text-gray-500">/</span>
          <span class="text-gray-300">{{ currentDocument.title }}</span>
        </nav>

        <!-- Document Editor or View -->
        <div class="flex-1 overflow-hidden flex flex-col">
          <DocumentEditor
            v-if="currentDocument && isEditing"
            :doc="currentDocument"
            @save="saveDocument"
            @cancel="isEditing = false"
          />
          <DocumentView
            v-else-if="currentDocument"
            :doc="currentDocument"
            @edit="isEditing = true"
            @delete="deleteDocument"
          />
          <div v-else class="flex items-center justify-center h-full text-gray-500">
            <div class="text-center">
              <p class="text-2xl mb-2">Welcome to Nexus</p>
              <p class="text-sm">Select a document or create a new one to get started</p>
              <button
                @click="createNewDocument"
                class="mt-4 px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg text-sm font-medium transition-colors"
              >
                Create Document
              </button>
            </div>
          </div>
        </div>
      </main>
    </div>

    <!-- Notification Toast (if any) -->
    <div
      v-if="notification"
      class="fixed bottom-4 right-4 px-4 py-3 bg-blue-600 text-white rounded-lg shadow-lg animate-fade-in"
    >
      {{ notification }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useDocumentStore } from '@/stores/documents'
import { useUIStore } from '@/stores/ui'
import Sidebar from '@/components/Sidebar.vue'
import KnowledgeGraph from '@/components/KnowledgeGraph.vue'
import DocumentEditor from '@/components/DocumentEditor.vue'
import DocumentView from '@/components/DocumentView.vue'

const docStore = useDocumentStore()
const uiStore = useUIStore()

const searchQuery = ref('')
const currentDocId = ref<string | null>(null)
const isEditing = ref(false)
const notification = ref<string | null>(null)
const showGraph = ref(false)

const currentDocument = ref(null)

onMounted(async () => {
  await docStore.fetchDocuments()
})

const selectDocument = async (docId: string) => {
  currentDocId.value = docId
  const doc = await docStore.fetchDocument(docId)
  currentDocument.value = doc
  isEditing.value = false
}

const handleSearch = async () => {
  if (!searchQuery.value.trim()) return
  
  const results = await docStore.search(searchQuery.value)
  if (results.length > 0) {
    await selectDocument(results[0].uuid)
  }
}

const saveDocument = async (updatedDoc: any) => {
  try {
    await docStore.updateDocument(currentDocId.value, updatedDoc)
    currentDocument.value = updatedDoc
    isEditing.value = false
    notification.value = 'Document saved successfully'
    setTimeout(() => notification.value = null, 3000)
  } catch (error) {
    console.error('Save error:', error)
    notification.value = 'Error saving document'
  }
}

const deleteDocument = async () => {
  if (!confirm('Are you sure?')) return
  
  try {
    await docStore.deleteDocument(currentDocId.value)
    currentDocument.value = null
    currentDocId.value = null
    notification.value = 'Document deleted'
    setTimeout(() => notification.value = null, 3000)
  } catch (error) {
    console.error('Delete error:', error)
  }
}

const createNewDocument = () => {
  currentDocument.value = {
    uuid: null,
    title: 'New Document',
    content: '',
    markdown_raw: '',
    status: 'draft',
    tags: []
  }
  isEditing.value = true
}

const toggleGraph = () => {
  showGraph.value = !showGraph.value
}

const toggleTheme = () => {
  document.documentElement.classList.toggle('dark')
}
</script>

<style scoped>
.nexus-app {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
}
</style>
