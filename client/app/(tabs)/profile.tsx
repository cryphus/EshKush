import { PageHeader } from "@/components/ui/PageHeader";
import { StatCard } from "@/components/ui/StatCard";
import { COLORS } from "@/constants/colors";
import { PROFILE_STATS } from "@/constants/profile";
import { router } from "expo-router";
import { StyleSheet, Text, View } from "react-native";

export default function ProfileScreen() {
  return (
    <View style={styles.container}>
      <PageHeader
        title="Профиль"
        location="Тюмень"
        cartCount={1}
        onPressCart={() => router.push("/cart")}
      />

      <View style={styles.headings}>
        <Text style={styles.sectionTitle}>Ваш вклад:</Text>
      </View>

      <View style={styles.statsSection}>
        <View style={styles.statsRow}>
          {PROFILE_STATS.map((stat, i) => (
            <StatCard key={i} icon={stat.icon} value={stat.value} />
          ))}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.bgCream,
  },
  headings: {
    paddingHorizontal: 16,
    marginTop: 8,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: "600",
    color: COLORS.text,
  },
  statsSection: {
    paddingHorizontal: 16,
    marginTop: 14,
    gap: 12,
  },
  statsRow: {
    flexDirection: "row",
    gap: 12,
  },
});
