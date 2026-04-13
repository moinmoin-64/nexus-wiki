<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center px-4">
    <!-- Login Card -->
    <div class="w-full max-w-md">
      <div class="bg-slate-800 rounded-lg shadow-xl border border-slate-700 p-8">
        <!-- Header -->
        <div class="text-center mb-8">
          <h1 class="text-3xl font-bold text-nexus-blue-400">Nexus</h1>
          <p class="text-slate-400 mt-2">Enterprise Knowledge Management</p>
        </div>

        <!-- Error Alert -->
        <div v-if="error" class="mb-6 p-4 bg-red-900/20 border border-red-700 rounded text-red-300">
          {{ error }}
        </div>

        <!-- Login Form -->
        <form @submit.prevent="handleLogin" class="space-y-4">
          <!-- Username -->
          <div>
            <label class="block text-sm font-medium text-slate-300 mb-2">Username</label>
            <input
              v-model="form.username"
              type="text"
              placeholder="Enter username"
              class="w-full px-4 py-2 bg-slate-700 border border-slate-600 rounded text-white placeholder-slate-500 focus:outline-none focus:border-nexus-blue-400 transition"
              :disabled="loading"
            />
          </div>

          <!-- Password -->
          <div>
            <label class="block text-sm font-medium text-slate-300 mb-2">Password</label>
            <input
              v-model="form.password"
              type="password"
              placeholder="Enter password"
              class="w-full px-4 py-2 bg-slate-700 border border-slate-600 rounded text-white placeholder-slate-500 focus:outline-none focus:border-nexus-blue-400 transition"
              :disabled="loading"
            />
          </div>

          <!-- Submit Button -->
          <button
            type="submit"
            :disabled="loading"
            class="w-full py-2 bg-nexus-blue-500 hover:bg-nexus-blue-600 disabled:opacity-50 text-white font-medium rounded transition mt-6"
          >
            {{ loading ? 'Logging in...' : 'Log In' }}
          </button>
        </form>

        <!-- Divider -->
        <div class="my-6 flex items-center">
          <div class="flex-1 bg-slate-600 h-px"></div>
          <span class="px-3 text-slate-400 text-sm">or</span>
          <div class="flex-1 bg-slate-600 h-px"></div>
        </div>

        <!-- Register Link -->
        <p class="text-center text-slate-400">
          Don't have an account?
          <RouterLink to="/register" class="text-nexus-blue-400 hover:text-nexus-blue-300 font-medium">
            Sign up
          </RouterLink>
        </p>
      </div>

      <!-- Demo Credentials -->
      <div class="mt-6 p-4 bg-slate-700/50 border border-slate-600 rounded text-sm text-slate-300">
        <p class="font-medium mb-2">Demo Credentials:</p>
        <p>Username: <code class="bg-slate-800 px-2 py-1 rounded">demo</code></p>
        <p>Password: <code class="bg-slate-800 px-2 py-1 rounded">demo123</code></p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { authApi } from '@/utils/api'
import { sanitizeInput } from '@/utils/sanitization'

const router = useRouter()
const loading = ref(false)
const error = ref('')

const form = reactive({
  username: '',
  password: '',
})

const handleLogin = async () => {
  error.value = ''

  if (!form.username || !form.password) {
    error.value = 'Please enter both username and password'
    return
  }

  loading.value = true

  try {
    const response = await authApi.login(
      sanitizeInput(form.username),
      form.password
    )

    if (response.data.success) {
      const { access_token, refresh_token, user } = response.data.data

      // Store tokens
      localStorage.setItem('access_token', access_token)
      localStorage.setItem('refresh_token', refresh_token)
      localStorage.setItem('user', JSON.stringify(user))

      // Redirect to dashboard
      await router.push('/')
    }
  } catch (err: any) {
    error.value = err.response?.data?.error?.message || 'Login failed. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
code {
  font-family: 'Courier New', monospace;
  font-size: 0.875rem;
}
</style>
