import type { defineConfig } from 'vite'

declare module '@vitejs/plugin-vue' {
  import type { Plugin } from 'vite'
  const plugin: (options?: any) => Plugin
  export default plugin
}
