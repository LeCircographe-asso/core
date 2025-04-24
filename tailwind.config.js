module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      fontFamily: {
        'circographe': ['Circographe', 'Arial', 'sans-serif'],
        'rough-typewriter': ['Rough Typewriter', 'monospace'],
      },
    },
  },
  plugins: [],
} 