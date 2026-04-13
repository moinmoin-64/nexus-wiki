<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center px-4">
    <!-- Register Card -->
    <div class="w-full max-w-md">
      <div class="bg-slate-800 rounded-lg shadow-xl border border-slate-700 p-8">
        <!-- Header -->
        <div class="text-center mb-8">
          <h1 class="text-3xl font-bold text-nexus-blue-400">Nexus</h1>
          <p class="text-slate-400 mt-2">Create Your Account</p>
        </div>

        <!-- Error Alert -->
        <div v-if="error" class="mb-6 p-4 bg-red-900/20 border border-red-700 rounded text-red-300">
          {{ error }}
        </div>

        <!-- Success Alert -->
        <div v-if="success" class="mb-6 p-4 bg-green-900/20 border border-green-700 rounded text-green-300">
          Account created successfully! Redirecting to login...
        </div>

        <!-- Register Form -->
        <form v-if="!success" @submit.prevent="handleRegister" class="space-y-4">
          <!-- Username -->
          <div>
            <label class="block text-sm font-medium text-slate-300 mb-2">Username</label>
            <input
              v-model="form.username"
              type="text"
              placeholder="Choose a username"
              class="w-full px-4 py-2 bg-slate-700 border border-slate-600 rounded text-white placeholder-slate-500 focus:outline-none focus:border-nexus-blue-400 transition"
              :disabled="loading"
              minlength="3"
            />
          </div>

          <!-- Email -->
          <div>
            <label class="block text-sm font-medium text-slate-300 mb-2">Email</label>
            <input
              v-model="form.email"
              type="email"
              placeholder="Enter your email"
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
              placeholder="At least 8 characters"
              class="w-full px-4 py-2 bg-slate-700 border border-slate-600 rounded text-white placeholder-slate-500 focus:outline-none focus:border-nexus-blue-400 transition"
              :disabled="loading"
              minlength="8"
            />
          </div>

          <!-- Confirm Password -->
          <div>
            <label class="block text-sm font-medium text-slate-300 mb-2">Confirm Password</label>
            <input
              v-model="form.confirmPassword"
              type="password"
              placeholder="Confirm password"
              class="w-full px-4 py-2 bg-slate-700 border border-slate-600 rounded text-white placeholder-slate-500 focus:outline-none focus:border-nexus-blue-400 transition"
              :disabled="loading"
              minlength="8"
            />
          </div>

          <!-- Submit Button -->
          <button
            type="submit"
            :disabled="loading"
            class="w-full py-2 bg-nexus-blue-500 hover:bg-nexus-blue-600 disabled:opacity-50 text-white font-medium rounded transition mt-6"
          >
            {{ loading ? 'Creating account...' : 'Create Account' }}
          </button>
        </form>

        <!-- Divider -->
        <div class="my-6 flex items-center">
          <div class="flex-1 bg-slate-600 h-px"></div>
          <span class="px-3 text-slate-400 text-sm">or</span>
          <div class="flex-1 bg-slate-600 h-px"></div>
        </div>

        <!-- Login Link -->
        <p class="text-center text-slate-400">
          Already have an account?
          <RouterLink to="/login" class="text-nexus-blue-400 hover:text-nexus-blue-300 font-medium">
            Log in
          </RouterLink>
        </p>
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
const success = ref(false)

const form = reactive({
  username: '',
  email: '',
  password: '',
  confirmPassword: '',
})

const handleRegister = async () => {
  error.value = ''

  // Validation
  if (!form.username || !form.email || !form.password || !form.confirmPassword) {
    error.value = 'Please fill in all fields'
    return
  }

  if (form.password !== form.confirmPassword) {
    error.value = 'Passwords do not match'
    return
  }

  if (form.password.length < 8) {
    error.value = 'Password must be at least 8 characters'
    return
  }

  loading.value = true

  try {
    const response = await authApi.register(
      sanitizeInput(form.username),
      form.email,
      form.password
    )

    if (response.data.success) {
      success.value = true
      setTimeout(() => {
        router.push('/login')
      }, 2000)
    }
  } catch (err: any) {
    error.value = err.response?.data?.error?.message || 'Registration failed. Please try again.'
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
