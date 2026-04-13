/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'nexus-dark': '#0f1419',
        'nexus-darker': '#0a0e14',
        'nexus-gray': '#1d2128',
      },
    },
  },
  darkMode: 'class',
  plugins: [
    require('@tailwindcss/typography'),
  ],
}
