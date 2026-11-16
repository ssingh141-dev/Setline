// Set-friendly dark theme, matching reference/prototype.html.
export const colors = {
  bg: '#0b0c0e',
  surface: '#141619',
  surface2: '#1c1f23',
  line: '#2a2e34',
  text: '#ece8e0',
  muted: '#8e9198',
  faint: '#5d6168',
  amber: '#f0a83a', // accent
  amberInk: '#1a1206', // text on amber
  red: '#e5484d', // live mic
  green: '#3fb67a', // approved
} as const;

// Font family names as registered in src/app/_layout.tsx
export const fonts = {
  head: 'BarlowCondensed_600SemiBold',
  headBold: 'BarlowCondensed_700Bold',
  body: 'IBMPlexSans_400Regular',
  bodyMedium: 'IBMPlexSans_500Medium',
  bodySemi: 'IBMPlexSans_600SemiBold',
  mono: 'IBMPlexMono_400Regular',
} as const;

export const space = { xs: 4, sm: 8, md: 12, lg: 16, xl: 24 } as const;
export const radius = { sm: 8, md: 12, lg: 14 } as const;
