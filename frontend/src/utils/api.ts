import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001'

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Add request interceptor for auth token
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Add response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Handle unauthorized
      localStorage.removeItem('auth_token')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export const createWebSocketClient = (docId: string, userId: string) => {
  const proto = import.meta.env.VITE_WS_PROTO || 'ws'
  const host = import.meta.env.VITE_WS_HOST || 'localhost:3001'
  const url = `${proto}://${host}/ws/collaborate/${docId}?userId=${userId}`
  return new WebSocket(url)
}
