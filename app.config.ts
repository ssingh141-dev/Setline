import type { ExpoConfig } from 'expo/config';

// The iOS bundle id is permanent once the app is on TestFlight. Confirm it before milestone 9.
const bundleId = process.env.APP_BUNDLE_ID ?? 'com.setline.app';

const config: ExpoConfig = {
  name: 'Setline',
  slug: 'setline',
  scheme: 'setline',
  version: '0.1.0',
  orientation: 'portrait',
  icon: './assets/icon.png',
  userInterfaceStyle: 'dark',
  backgroundColor: '#0b0c0e',
  ios: {
    bundleIdentifier: bundleId,
    supportsTablet: false,
  },
  android: {
    package: bundleId,
    adaptiveIcon: {
      backgroundColor: '#0b0c0e',
      foregroundImage: './assets/android-icon-foreground.png',
      backgroundImage: './assets/android-icon-background.png',
      monochromeImage: './assets/android-icon-monochrome.png',
    },
  },
  plugins: [
    'expo-router',
    'expo-font',
    ['expo-splash-screen', { backgroundColor: '#0b0c0e', image: './assets/splash-icon.png', imageWidth: 120 }],
  ],
  experiments: { typedRoutes: true },
  extra: {
    eas: process.env.EAS_PROJECT_ID ? { projectId: process.env.EAS_PROJECT_ID } : undefined,
  },
};

export default config;
