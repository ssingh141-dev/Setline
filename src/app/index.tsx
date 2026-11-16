import { useQuery } from '@tanstack/react-query';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { isConfigured, supabase } from '@/lib/supabase';
import { colors, fonts, radius, space } from '@/ui/theme';

// Setup milestone: a check screen that proves the app, fonts and database are wired up.
// Sign-in and the project list replace this in milestone 2.

type Check = { label: string; ok: boolean | null; detail: string };

function useConnectionCheck() {
  return useQuery({
    queryKey: ['setup-check'],
    enabled: isConfigured,
    queryFn: async () => {
      // Signed out, the database must answer but return no rows (RLS working).
      const { count, error } = await supabase.from('projects').select('id', { count: 'exact', head: true });
      if (error) throw error;
      return count ?? 0;
    },
  });
}

export default function SetupCheck() {
  const q = useConnectionCheck();

  const checks: Check[] = [
    { label: 'App', ok: true, detail: 'Running' },
    {
      label: 'Supabase keys',
      ok: isConfigured,
      detail: isConfigured ? 'Found in .env' : 'Missing. See README, step 3.',
    },
    {
      label: 'Database',
      ok: !isConfigured ? null : q.isPending ? null : q.isSuccess,
      detail: !isConfigured
        ? 'Waiting for keys'
        : q.isPending
          ? 'Checking…'
          : q.isError
            ? q.error.message
            : 'Connected',
    },
    {
      label: 'Privacy rules',
      ok: q.isSuccess ? q.data === 0 : null,
      detail: q.isSuccess
        ? q.data === 0
          ? 'Signed out sees 0 projects'
          : `Signed out sees ${q.data} projects. Check RLS.`
        : 'Waiting for database',
    },
  ];

  return (
    <SafeAreaView style={s.root} edges={['top', 'bottom']}>
      <ScrollView contentContainerStyle={s.body}>
        <View>
          <Text style={s.logo}>
            SET<Text style={{ color: colors.amber }}>LINE</Text>
          </Text>
          <View style={s.slate}>
            {Array.from({ length: 8 }, (_, i) => (
              <View key={i} style={[s.slateCell, { backgroundColor: i % 2 ? colors.bg : colors.text }]} />
            ))}
          </View>
          <Text style={s.lede}>Setup check. Sign in and your shoots arrive in the next milestone.</Text>
        </View>

        <View style={s.card}>
          {checks.map((c, i) => (
            <View key={c.label} style={[s.row, i > 0 && s.rowLine]}>
              <View
                style={[
                  s.dot,
                  { backgroundColor: c.ok === null ? colors.faint : c.ok ? colors.green : colors.red },
                ]}
              />
              <Text style={s.label}>{c.label}</Text>
              <Text style={s.detail} numberOfLines={2}>
                {c.detail}
              </Text>
            </View>
          ))}
        </View>

        <Text style={s.foot}>v0.1.0 · Setup</Text>
      </ScrollView>
    </SafeAreaView>
  );
}

const s = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.bg },
  body: { padding: space.xl, gap: space.xl },
  logo: { fontFamily: fonts.headBold, fontSize: 64, lineHeight: 64, color: colors.text, letterSpacing: 1 },
  slate: { flexDirection: 'row', height: 14, marginVertical: 18, borderRadius: 2, overflow: 'hidden' },
  slateCell: { flex: 1 },
  lede: { fontFamily: fonts.body, fontSize: 15, color: colors.muted, maxWidth: 300 },
  card: {
    backgroundColor: colors.surface,
    borderColor: colors.line,
    borderWidth: 1,
    borderRadius: radius.lg,
  },
  row: { flexDirection: 'row', alignItems: 'center', gap: space.md, paddingHorizontal: space.lg, paddingVertical: 14 },
  rowLine: { borderTopColor: colors.line, borderTopWidth: 1 },
  dot: { width: 10, height: 10, borderRadius: 5 },
  label: { fontFamily: fonts.bodyMedium, fontSize: 15, color: colors.text, width: 110 },
  detail: { fontFamily: fonts.mono, fontSize: 12, color: colors.muted, flex: 1, textAlign: 'right' },
  foot: { fontFamily: fonts.mono, fontSize: 11, color: colors.faint, textAlign: 'center' },
});
