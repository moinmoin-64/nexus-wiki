import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useUIStore = defineStore('ui', () => {
  const sidebarOpen = ref(true)
  const graphViewOpen = ref(false)
  const darkMode = ref(true)
  const notification = ref<{
    message: string
    type: 'success' | 'error' | 'info'
  } | null>(null)

  const toggleSidebar = () => {
    sidebarOpen.value = !sidebarOpen.value
  }

  const toggleGraphView = () => {
    graphViewOpen.value = !graphViewOpen.value
  }

  const toggleDarkMode = () => {
    darkMode.value = !darkMode.value
    if (darkMode.value) {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
  }

  const showNotification = (message: string, type = 'info') => {
    notification.value = { message, type }
    setTimeout(() => {
      notification.value = null
    }, 3000)
  }

  return {
    sidebarOpen,
    graphViewOpen,
    darkMode,
    notification,
    toggleSidebar,
    toggleGraphView,
    toggleDarkMode,
    showNotification
  }
})
