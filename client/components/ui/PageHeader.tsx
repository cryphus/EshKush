import { COLORS } from "@/constants/colors";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";

type Props = {
  title: string;
  location?: string;
  cartCount?: number;
  showBack?: boolean;
  onPressCart?: () => void;
};

export function PageHeader({
  title,
  location = "Тюмень",
  cartCount,
  showBack,
  onPressCart,
}: Props) {
  return (
    <View style={styles.header}>
      <View style={styles.leftSection}>
        {showBack ? (
          <Pressable onPress={() => router.back()} style={styles.backBtn}>
            <Ionicons name="chevron-back" size={22} color={COLORS.text} />
          </Pressable>
        ) : (
          <Ionicons name="location-outline" size={18} color={COLORS.text} />
        )}
        <Text style={styles.locationText}>{location}</Text>
      </View>

      <View style={styles.rightSection}>
        <Pressable onPress={onPressCart}>
          <Ionicons name="cart-outline" size={22} color={COLORS.text} />
          {cartCount ? (
            <View style={styles.cartBadge}>
              <Text style={styles.cartBadgeText}>{cartCount}</Text>
            </View>
          ) : null}
        </Pressable>
      </View>

      <Text style={styles.pageTitle}>{title}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    paddingHorizontal: 16,
    paddingTop: 14,
    paddingBottom: 10,
    backgroundColor: COLORS.bgCream,
  },
  leftSection: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  rightSection: {
    position: "absolute",
    right: 16,
    top: 14,
  },
  locationText: {
    fontWeight: "600",
    color: COLORS.text,
  },
  backBtn: {
    marginRight: 4,
  },
  pageTitle: {
    fontSize: 24,
    fontWeight: "700",
    color: COLORS.text,
    marginTop: 4,
  },
  cartBadge: {
    position: "absolute",
    top: -4,
    right: -8,
    backgroundColor: COLORS.greenAccent,
    borderRadius: 10,
    paddingHorizontal: 4,
    minWidth: 16,
    alignItems: "center",
    justifyContent: "center",
  },
  cartBadgeText: {
    color: "#fff",
    fontSize: 10,
    fontWeight: "700",
  },
});
