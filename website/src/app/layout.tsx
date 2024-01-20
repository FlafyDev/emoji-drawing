// import type { Metadata } from 'next'
import './globals.css'
import { AppRouterCacheProvider } from '@mui/material-nextjs/v13-appRouter';
import { ThemeProvider } from '@mui/system';
import theme from './theme';


// or `v1X-appRouter` if you are using Next.js v1X

// export const metadata: Metadata = {
//   title: 'Create Next App',
//   description: 'Generated by create next app',
// }

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>
        <ThemeProvider theme={theme}>
          <AppRouterCacheProvider>{children}</AppRouterCacheProvider>
        </ThemeProvider>
      </body>
    </html>
  )
}