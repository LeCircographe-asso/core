module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './app/assets/fonts/**/*.woff2',
    './app/assets/fonts/**/*.woff',
    './app/assets/fonts/**/*.otf'
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