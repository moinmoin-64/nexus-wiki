import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'Home',
      component: () => import('@/views/HomePage.vue'),
    },
    {
      path: '/document/:id',
      name: 'Document',
      component: () => import('@/views/DocumentPage.vue'),
    },
    {
      path: '/search/:query',
      name: 'Search',
      component: () => import('@/views/SearchPage.vue'),
    },
    {
      path: '/graph',
      name: 'Graph',
      component: () => import('@/views/GraphPage.vue'),
    },
  ],
})

export default router
