<template>
  <div class="document-editor h-full flex flex-col bg-nexus-darker">
    <!-- Editor Toolbar -->
    <div class="bg-nexus-gray border-b border-gray-700 px-6 py-3 flex items-center justify-between">
      <div class="flex items-center gap-4">
        <input
          v-model="editingDoc.title"
          type="text"
          placeholder="Document title..."
          class="text-lg font-semibold bg-nexus-darker border border-gray-600 rounded-lg px-4 py-2 text-gray-100 placeholder-gray-500 focus:outline-none focus:border-blue-500 w-64"
        />
        
        <!-- Status Selector -->
        <select
          v-model="editingDoc.status"
          class="px-3 py-2 bg-nexus-darker border border-gray-600 rounded-lg text-sm text-gray-100 focus:outline-none focus:border-blue-500"
        >
          <option value="draft">Draft</option>
          <option value="review">Review</option>
          <option value="published">Published</option>
        </select>
      </div>

      <!-- Action Buttons -->
      <div class="flex items-center gap-2">
        <button
          @click="emitSave"
          class="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg text-sm font-medium transition-colors"
        >
          Save
        </button>
        <button
          @click="$emit('cancel')"
          class="px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded-lg text-sm font-medium transition-colors"
        >
          Cancel
        </button>
      </div>
    </div>

    <!-- Tag Input -->
    <div class="bg-nexus-gray border-b border-gray-700 px-6 py-2 flex items-center gap-2">
      <span class="text-xs text-gray-500">Tags:</span>
      <div class="flex items-center gap-2 flex-wrap">
        <span
          v-for="tag in editingDoc.tags"
          :key="tag"
          class="px-2 py-1 bg-blue-600 rounded-full text-xs flex items-center gap-1"
        >
          {{ tag }}
          <button @click="removeTag(tag)" class="ml-1 hover:opacity-80">×</button>
        </span>
        <input
          v-model="newTag"
          @keydown.enter="addTag"
          type="text"
          placeholder="Add tag..."
          class="px-2 py-1 bg-nexus-darker border border-gray-600 rounded-lg text-xs text-gray-100 placeholder-gray-500 focus:outline-none focus:border-blue-500"
        />
      </div>
    </div>

    <!-- Main Editor -->
    <div class="flex-1 overflow-hidden flex flex-col">
      <EditorContent
        :editor="editor"
        class="editor flex-1 overflow-y-auto px-6 py-4 prose prose-invert max-w-none"
      />
    </div>

    <!-- Editor Status Bar -->
    <div class="bg-nexus-gray border-t border-gray-700 px-6 py-2 text-xs text-gray-500 flex justify-between">
      <div>
        {{ characterCount }} characters | {{ wordCount }} words
      </div>
      <div v-if="isSaving" class="animate-pulse">
        Saving...
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onBeforeUnmount } from 'vue'
import { useEditor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Link from '@tiptap/extension-link'
import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight'
import { lowlight } from 'lowlight'
import 'highlight.js/styles/atom-one-dark.css'

const props = defineProps<{
  doc: any
}>()

const emit = defineEmits<{
  save: [doc: any]
  cancel: []
}>()

const editingDoc = reactive({
  title: props.doc.title,
  status: props.doc.status,
  tags: [...(props.doc.tags || [])],
  markdown_raw: props.doc.markdown_raw || '',
  content: props.doc.content || ''
})

const newTag = ref('')
const isSaving = ref(false)

const editor = useEditor({
  content: editingDoc.markdown_raw,
  extensions: [
    StarterKit.configure({
      codeBlock: false,
    }),
    Link.configure({
      openOnClick: false,
      autolink: true,
    }),
    CodeBlockLowlight.configure({
      lowlight,
    }),
  ],
  editorProps: {
    attributes: {
      class: 'focus:outline-none',
    },
  },
  onUpdate: ({ editor }) => {
    editingDoc.markdown_raw = editor.getHTML()
  },
})

const characterCount = computed(() => {
  return editor.value?.storage.characterCount?.characters() || 0
})

const wordCount = computed(() => {
  const text = editor.value?.getText() || ''
  return text.split(/\s+/).filter(w => w.length > 0).length
})

const addTag = () => {
  if (newTag.value.trim() && !editingDoc.tags.includes(newTag.value)) {
    editingDoc.tags.push(newTag.value.trim())
  }
  newTag.value = ''
}

const removeTag = (tag: string) => {
  editingDoc.tags = editingDoc.tags.filter(t => t !== tag)
}

const emitSave = () => {
  isSaving.value = true
  emit('save', {
    ...editingDoc,
    markdown_raw: editor.value?.getHTML() || ''
  })
  setTimeout(() => {
    isSaving.value = false
  }, 1000)
}

onBeforeUnmount(() => {
  editor.value?.destroy()
})
</script>

<style scoped>
.editor :deep(.ProseMirror) {
  outline: none;
  padding: 0;
}

.editor :deep(.ProseMirror h1) {
  @apply text-3xl font-bold mt-6 mb-4;
}

.editor :deep(.ProseMirror h2) {
  @apply text-2xl font-bold mt-5 mb-3;
}

.editor :deep(.ProseMirror h3) {
  @apply text-xl font-bold mt-4 mb-2;
}

.editor :deep(.ProseMirror code) {
  @apply bg-nexus-gray px-2 py-1 rounded text-orange-400;
}

.editor :deep(.ProseMirror pre) {
  @apply bg-nexus-gray rounded-lg p-4 my-4 overflow-x-auto;
}

.editor :deep(.ProseMirror li) {
  @apply ml-4;
}
</style>
