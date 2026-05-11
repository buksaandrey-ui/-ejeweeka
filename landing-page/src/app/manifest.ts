import { MetadataRoute } from 'next'

export const dynamic = 'force-static';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'ejeweeka',
    short_name: 'ejeweeka',
    theme_color: '#F9FAFB',
    background_color: '#F9FAFB',
    display: 'standalone',
    icons: [
      {
        src: '/pwa-192.png',
        sizes: '192x192',
        type: 'image/png',
      },
      {
        src: '/pwa-512.png',
        sizes: '512x512',
        type: 'image/png',
      },
    ],
  }
}
