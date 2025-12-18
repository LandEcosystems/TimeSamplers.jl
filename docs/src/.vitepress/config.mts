import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
import path from 'path'

// https://vitepress.dev/reference/site-config

// Navigation menu items
const navItems = [
  { text: 'Home', link: '/' },
  { text: 'API', link: '/api' },
  { text: 'Types', link: '/types' },
]

// Sidebar configuration - organized by sections
const sidebarItems = [
  {
    text: 'Getting Started',
    items: [
      { text: 'Home', link: '/' },
    ]
  },
  {
    text: 'Documentation',
    collapsed: false,
    items: [
      { text: 'API', link: '/api' },
      { text: 'Types', link: '/types' },
    ]
  },
]

// Sidebar configuration that shows sections when on Types page
const sidebar = {
  '/': sidebarItems,
  '/api': sidebarItems,
  '/types': [
    {
      text: 'Getting Started',
      items: [
        { text: 'Home', link: '/' },
      ]
    },
    {
      text: 'Documentation',
      collapsed: false,
      items: [
        { text: 'API', link: '/api' },
        { text: 'Types', link: '/types' },
        { text: 'TimeSampler', link: '/types#timesampler' },
        { text: 'TimeSamplerMethod', link: '/types#timesamplermethod' },
        { text: 'Core Types', link: '/types#core-types' },
        { text: 'Basic Aggregation', link: '/types#basic-aggregation' },
        { text: 'Anomalies', link: '/types#anomalies' },
        { text: 'Climatological Statistics', link: '/types#climatological-statistics' },
        { text: 'Time Selection', link: '/types#time-selection' },
        { text: 'Special Methods', link: '/types#special-methods' },
        { text: 'All TimeSampler Types', link: '/types#all-timesampler-types' },
      ]
    },
  ],
}

export default defineConfig({
  base: 'REPLACE_ME_DOCUMENTER_VITEPRESS',
  title: "TimeSamplers.jl",
  description: "A Julia package for temporal sampling, aggregation, and resampling of time series data",
  lastUpdated: true,
  cleanUrls: false,
  ignoreDeadLinks: true,
  outDir: 'REPLACE_ME_DOCUMENTER_VITEPRESS',
  
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
  ],
  
  vite: {
    define: {
      __DEPLOY_ABSPATH__: JSON.stringify('REPLACE_ME_DOCUMENTER_VITEPRESS_DEPLOY_ABSPATH'),
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '../components')
      }
    },
    build: {
      assetsInlineLimit: 0,
    },
    optimizeDeps: {
      exclude: [ 
        '@nolebase/vitepress-plugin-enhanced-readabilities/client',
        'vitepress',
        '@nolebase/ui',
      ], 
    }, 
    ssr: { 
      noExternal: [ 
        '@nolebase/vitepress-plugin-enhanced-readabilities',
        '@nolebase/ui',
      ], 
    },
  },

  markdown: {
    config(md) {
      md.use(tabsMarkdownPlugin)
    },
    theme: {
      light: "github-light",
      dark: "github-dark"
    }
  },

  themeConfig: {
    outline: 'deep',
    search: {
      provider: 'local',
      options: {
        detailedView: true
      }
    },

    nav: navItems,
    sidebar: sidebar,
    socialLinks: [
      {
        icon: "github",
        link: 'https://github.com/LandEcosystems/TimeSamplers.jl',
        ariaLabel: 'TimeSamplers.jl repository'
      },
    ],
    footer: {
      message: 'TimeSamplers.jl - Temporal sampling and aggregation for time series data',
      copyright: '© Copyright 2025 <strong>TimeSamplers.jl Contributors</strong>'
    }
  }
})
