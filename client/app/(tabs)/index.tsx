import { Card } from "@/components/ui/Card";
import { PageHeader } from "@/components/ui/PageHeader";
import { COLORS } from "@/constants/colors";
import { router } from "expo-router";
import {
  Image,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";

export default function HomeScreen() {
  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.scrollContent}
    >
      <PageHeader
        title="Главная"
        location="Тюмень"
        cartCount={1}
        onPressCart={() => router.push("/cart")}
      />

      <Card style={styles.heroCard}>
        <View style={styles.heroRow}>
          <View style={styles.heroTextBlock}>
            <Text style={styles.heroTitle}>Привет,{"\n"}Гость</Text>
            <Text style={styles.heroSubtitle}>
              Только в этом месяце ты{"\n"}сохранил 2 кг еды!
            </Text>
          </View>
          <Image
            source={require("@/assets/images/main-page-hero.png")}
            style={styles.heroImage}
          />
        </View>
      </Card>

      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>Ваши заказы</Text>
        <Pressable>
          <Text style={styles.sectionLink}>все</Text>
        </Pressable>
      </View>

      <Card style={styles.orderCard}>
        <View style={styles.orderRow}>
          <Image
            source={require("@/assets/images/main-page-mock-order.png")}
            style={styles.orderImage}
          />
          <View style={styles.orderTextBlock}>
            <Text style={styles.orderTitle}>БулоШная</Text>
            <Text style={styles.orderSubtitle}>сегодня, 19:00 - 21:00</Text>
          </View>
        </View>
      </Card>

      <Pressable style={styles.moreBtn}>
        <Text style={styles.moreBtnText}>Больше предложений</Text>
      </Pressable>

      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>Категории</Text>
        <Pressable>
          <Text style={styles.sectionLink}>все</Text>
        </Pressable>
      </View>

      <View style={styles.categoriesRow}>
        <Card style={styles.categoryCard}>
          <Text style={styles.categoryTitle}>Магазины</Text>
          <Image
            source={require("@/assets/images/main-page-rest1.png")}
            style={styles.categoryImage}
          />
        </Card>

        <Card style={styles.categoryCard}>
          <Text style={styles.categoryTitle}>Рестораны</Text>
          <Image
            source={require("@/assets/images/main-page-rest2.png")}
            style={styles.categoryImage}
          />
        </Card>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.bgCream,
  },
  scrollContent: {
    paddingBottom: 90,
  },

  sectionHeader: {
    paddingHorizontal: 16,
    marginTop: 4,
    marginBottom: 20,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: "700",
    color: COLORS.text,
  },
  sectionLink: {
    fontSize: 16,
    opacity: 0.6,
    color: COLORS.textLight,
  },

  heroCard: {
    margin: 16,
    backgroundColor: COLORS.greenBg,
    borderRadius: 18,
    shadowColor: COLORS.shadow,
    shadowOpacity: 0.2,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 3,
  },

  heroRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
  },
  heroTextBlock: { flex: 1 },
  heroTitle: {
    fontSize: 24,
    fontWeight: "700",
    marginBottom: 6,
    color: COLORS.text,
  },
  heroSubtitle: { color: COLORS.textLight, fontWeight: "600" },
  heroImage: { width: 90, height: 90, borderRadius: 12 },

  orderCard: {
    marginHorizontal: 16,
    backgroundColor: COLORS.greenAccent,
    borderRadius: 18,
    padding: 8,
  },
  orderRow: { flexDirection: "row", alignItems: "center", gap: 12 },
  orderImage: {
    width: 100,
    height: 60,
    borderRadius: 12,
    backgroundColor: "#fff",
  },
  orderTextBlock: { flex: 1 },
  orderTitle: { fontWeight: "700", fontSize: 20, color: "#fff" },
  orderSubtitle: { color: COLORS.bgCream },

  moreBtn: {
    marginHorizontal: 16,
    marginTop: 10,
    backgroundColor: COLORS.green,
    borderRadius: 14,
    paddingVertical: 12,
    alignItems: "center",
  },
  moreBtnText: { color: "#fff", fontSize: 20 },

  categoriesRow: {
    paddingHorizontal: 16,
    flexDirection: "row",
    gap: 12,
    marginBottom: 16,
  },
  categoryCard: {
    flex: 1,
    backgroundColor: COLORS.greenBg,
    borderRadius: 14,
    padding: 0,
    alignItems: "center",
  },
  categoryTitle: {
    fontWeight: "700",
    marginBottom: 8,
    fontSize: 20,
    marginTop: 8,
    color: COLORS.text,
  },
  categoryImage: {
    width: "100%",
    height: 140,
    borderRadius: 12,
    marginTop: 12,
  },
});
