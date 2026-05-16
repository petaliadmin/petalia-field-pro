/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{html,ts}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#2E5A44', // Forest Sage
          dark: '#1B3A2C',
          light: '#4A7C5F',
        },
        accent: {
          DEFAULT: '#B38D46', // Harvest Ochre
          dark: '#8F6E32',
          light: '#D9B980',
        },
        background: '#FDFCF8',
        surface: '#FFFFFF',
        'surface-subtle': '#F6F3E8',
      }
    },
  },
  plugins: [],
}
