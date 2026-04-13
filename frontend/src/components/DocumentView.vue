<template>
  <div class="document-view h-full flex flex-col bg-nexus-darker">
    <!-- Document Header -->
    <div class="bg-nexus-gray border-b border-gray-700 px-6 py-4">
      <div class="flex items-center justify-between mb-2">
        <h1 class="text-3xl font-bold text-gray-100">{{ doc.title }}</h1>
        <div class="flex items-center gap-2">
          <button
            @click="$emit('edit')"
            class="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg text-sm font-medium transition-colors"
          >
            Edit
          </button>
          <button
            @click="$emit('delete')"
            class="px-4 py-2 bg-red-600 hover:bg-red-700 rounded-lg text-sm font-medium transition-colors"
          >
            Delete
          </button>
        </div>
      </div>

      <!-- Metadata -->
      <div class="flex items-center gap-4 text-xs text-gray-400">
        <span :style="`color: ${getStatusColor(doc.status)}`" class="font-medium">
          {{ doc.status.toUpperCase() }}
        </span>
        <span>Created: {{ formatDate(doc.created_at) }}</span>
        <span>Updated: {{ formatDate(doc.updated_at) }}</span>
        <span v-if="doc.tags?.length">Tags: {{ doc.tags.join(', ') }}</span>
      </div>
    </div>

    <!-- Backlinks Section -->
    <div v-if="doc.backlinks?.length" class="bg-nexus-gray border-b border-gray-700 px-6 py-3">
      <button
        @click="showBacklinks = !showBacklinks"
        class="text-sm text-gray-300 hover:text-gray-100 font-medium flex items-center gap-2"
      >
        <span class="text-lg">{{ showBacklinks ? '▼' : '▶' }}</span>
        🔗 Backlinks ({{ doc.backlinks.length }})
      </button>
      <div v-if="showBacklinks" class="mt-3 space-y-2">
        <button
          v-for="link in doc.backlinks"
          :key="link.uuid"
          @click="goToDocument(link.uuid)"
          class="block text-sm text-blue-500 hover:text-blue-400 hover:underline"
        >
          ← {{ link.title }}
        </button>
      </div>
    </div>

    <!-- Document Content -->
    <div class="flex-1 overflow-y-auto px-6 py-4">
      <div
        class="prose prose-invert max-w-none"
        v-html="doc.content"
      />
    </div>

    <!-- Wikilinks Visualization -->
    <div v-if="wikilinks.length" class="border-t border-gray-700 bg-nexus-gray px-6 py-3">
      <details class="text-sm">
        <summary class="cursor-pointer font-medium text-gray-300 hover:text-gray-100">
          Linked Documents ({{ wikilinks.length }})
        </summary>
        <div class="mt-3 space-y-1">
          <button
            v-for="link in wikilinks"
            :key="link"
            @click="searchForLink(link)"
            class="block text-blue-500 hover:text-blue-400 focus:outline-none"
          >
            → {{ link }}
          </button>
        </div>
      </details>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { formatDistanceToNow } from 'date-fns'

const props = defineProps<{
  doc: any
}>()

const emit = defineEmits<{
  edit: []
  delete: []
}>()

const showBacklinks = ref(false)

const wikilinks = computed(() => {
  const regex = /\[\[([^\]]+)\]\]/g
  const matches: string[] = []
  let match
  
  while ((match = regex.exec(props.doc.markdown_raw || '')) !== null) {
    matches.push(match[1])
  }
  
  return [...new Set(matches)] // Deduplicate
})

const formatDate = (dateStr: string) => {
  if (!dateStr) return 'Unknown'
  return formatDistanceToNow(new Date(dateStr), { addSuffix: true })
}

const getStatusColor = (status: string) => {
  const colors: Record<string, string> = {
    draft: '#999',
    review: '#fbbf24',
    published: '#10b981'
  }
  return colors[status] || '#999'
}

const goToDocument = (uuid: string) => {
  // Will be handled by parent component
  emit('edit') // Temporary
}

const searchForLink = (linkText: string) => {
  // Will search for this wikilink
  console.log('Search for:', linkText)
}
</script>

<style scoped>
:deep(.prose) {
  color: rgb(229, 231, 235);
}

:deep(.prose a) {
  color: rgb(59, 130, 246);
}

:deep(.prose a:hover) {
  color: rgb(96, 165, 250);
}

:deep(.prose code) {
  color: rgb(253, 224, 71);
  background: rgb(31, 41, 55);
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
}

:deep(.prose pre) {
  background: rgb(31, 41, 55);
}

:deep(.prose strong) {
  color: rgb(243, 244, 246);
}

:deep(.prose hr) {
  border-color: rgb(75, 85, 99);
}
</style>
