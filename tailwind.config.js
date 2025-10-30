module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/tailwind/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      fontFamily: {
        'circographe': ['Circographe', 'Arial', 'sans-serif'],
        'rough-typewriter': ['Rough Typewriter', 'monospace'],
        'dyslexic': ['OpenDyslexic', 'Arial', 'sans-serif'],
        'inter': ['Inter', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
        'jetbrains': ['JetBrains Mono', 'Fira Code', 'Consolas', 'monospace'],
        'sans': ['Inter', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
        'mono': ['JetBrains Mono', 'Fira Code', 'Consolas', 'monospace'],
      },
      colors: {
        'circographe': {
          50: '#f0f9f7',
          100: '#dcf2ee',
          200: '#bce5dd',
          300: '#8dd1c4',
          400: '#56b5a5',
          500: '#3b9b8a',
          600: '#2f7d71',
          700: '#29655c',
          800: '#25524b',
          900: '#22443e',
          950: '#112722',
        }
      }
    },
  },
  plugins: [],
} 