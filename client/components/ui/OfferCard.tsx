import { COLORS } from "@/constants/colors";
import type { Offer } from "@/constants/offers";
import { Ionicons } from "@expo/vector-icons";
import { Image, Pressable, StyleSheet, Text, View } from "react-native";

type Props = {
  item: Offer;
  dimmed?: boolean;
  rightBadge?: React.ReactNode;
  onPress?: () => void;
};

export function OfferCard({ item, dimmed, rightBadge, onPress }: Props) {
  const distance =
    Number.isNaN(item.distanceKm) || item.distanceKm === undefined
      ? "X км от вас"
      : `${item.distanceKm} км от вас`;

  return (
    <Pressable onPress={onPress} style={[styles.card, dimmed && styles.dimmed]}>
      <View style={styles.imageWrap}>
        <Image source={{ uri: item.image }} style={styles.image} />
        {item.logo ? (
          <View style={styles.logoBadge}>
            <Image source={{ uri: item.logo }} style={styles.logoImage} />
          </View>
        ) : null}
      </View>

      <View style={styles.body}>
        <View style={styles.row}>
          <View style={styles.leftCol}>
            <View style={styles.titleRow}>
              <Text style={styles.title} numberOfLines={1}>
                {item.title}
              </Text>
              <Ionicons name="star" size={14} color="#F4C542" />
              <Text style={styles.rating}>{item.rating}</Text>
            </View>
            <View style={styles.infoRow}>
              <Ionicons
                name="bag-handle-outline"
                size={14}
                color={COLORS.greenAccent}
              />
              <Text style={styles.distanceText}>{distance}</Text>
            </View>
          </View>

          <View style={styles.rightCol}>
            <View style={styles.timeRow}>
              <Ionicons
                name="time-outline"
                size={14}
                color={COLORS.textLight}
              />
              <Text style={styles.timeText}>{item.time}</Text>
            </View>

            <View style={styles.priceRow}>
              {rightBadge ? (
                rightBadge
              ) : (
                <>
                  {item.oldPrice ? (
                    <View style={styles.oldPriceWrap}>
                      <Text style={styles.oldPrice}>{item.oldPrice}₽</Text>
                    </View>
                  ) : null}
                  <View style={styles.newPriceWrap}>
                    <Text style={styles.newPrice}>{item.price}₽</Text>
                  </View>
                </>
              )}
            </View>
          </View>
        </View>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: COLORS.bgCream,
    borderRadius: 16,
    overflow: "hidden",
    shadowColor: COLORS.shadow,
    shadowOpacity: 0.06,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 3,
  },
  dimmed: { opacity: 0.35 },

  imageWrap: { width: "100%", height: 90 },
  image: { width: "100%", height: "100%" },
  logoBadge: {
    position: "absolute",
    left: 10,
    top: 10,
    backgroundColor: "#fff",
    borderRadius: 8,
  },
  logoImage: { width: 90, height: 45, resizeMode: "contain" },

  body: { padding: 12, backgroundColor: "#fff" },

  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
  },
  leftCol: { height: "100%", justifyContent: "space-between", paddingRight: 8 },
  rightCol: { alignItems: "flex-end", gap: 6 },

  titleRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginBottom: 4,
  },
  title: {
    fontSize: 16,
    fontWeight: "700",
    flexShrink: 1,
    color: COLORS.text,
  },
  rating: { opacity: 0.8, color: COLORS.text },

  infoRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginBottom: 4,
  },
  distanceText: { color: COLORS.textLight },

  timeRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  timeText: { color: COLORS.textLight },

  priceRow: {
    flexDirection: "row",
    alignItems: "center",
    marginTop: 4,
  },
  oldPriceWrap: {
    backgroundColor: "#E6E6E6",
    borderRadius: 1000,
    paddingHorizontal: 18,
    paddingVertical: 4,
    marginRight: -20,
    zIndex: 0,
  },
  oldPrice: {
    textDecorationLine: "line-through",
    fontWeight: "500",
    fontSize: 13,
    color: COLORS.textLight,
  },
  newPriceWrap: {
    backgroundColor: COLORS.greenAccent,
    borderRadius: 1000,
    paddingHorizontal: 12,
    paddingVertical: 4,
    zIndex: 1,
  },
  newPrice: {
    color: "#fff",
    fontWeight: "600",
    fontSize: 13,
  },
});
