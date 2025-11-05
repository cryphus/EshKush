import { Button } from "@/components/ui/Button";
import { OfferCard } from "@/components/ui/OfferCard";
import { PageHeader } from "@/components/ui/PageHeader";
import { COLORS } from "@/constants/colors";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import React, { useMemo, useState } from "react";
import { FlatList, Pressable, StyleSheet, Text, View } from "react-native";

// Мок списка в корзине (совместим с типом Offer)
const INITIAL_CART = [
  {
    id: "2",
    title: "Кондитерская Besel",
    rating: 4.8,
    distanceKm: 0.8,
    time: "19:00 - 22:00",
    oldPrice: 340,
    price: 189,
    image:
      "https://images.unsplash.com/photo-1499636136210-6f4ee915583e?q=80&w=1400&auto=format&fit=crop",
    logo: "https://static.rfstat.com/logo-presets/2551/thumbnail_4bc11506be31_1x.webp",
  },
  // добавь другие элементы по необходимости
];

export default function CartScreen() {
  const [items, setItems] = useState(INITIAL_CART);
  const total = useMemo(
    () => items.reduce((sum, it) => sum + (it.price ?? 0), 0),
    [items]
  );

  const removeItem = (id: string) =>
    setItems((prev) => prev.filter((it) => it.id !== id));

  return (
    <View style={styles.container}>
      <PageHeader title="Корзина" location="Тюмень" showBack />

      <FlatList
        data={items}
        keyExtractor={(x) => x.id}
        contentContainerStyle={[
          styles.listContent,
          items.length === 0 && { flex: 1 },
        ]}
        ListEmptyComponent={
          <View style={styles.empty}>
            <Ionicons name="cart-outline" size={56} color={COLORS.textLight} />
            <Text style={styles.emptyTitle}>Корзина пуста</Text>
            <Text style={styles.emptySub}>Добавьте предложения из списка</Text>
          </View>
        }
        renderItem={({ item }) => (
          <View style={styles.itemWrap}>
            <OfferCard
              item={item}
              onPress={() => router.push(`/offer/${item.id}`)}
            />
            <Pressable
              onPress={() => removeItem(item.id)}
              style={styles.removeBtn}
              hitSlop={10}
            >
              <Ionicons name="close" size={16} color="#fff" />
            </Pressable>
          </View>
        )}
      />

      {items.length > 0 && (
        <View style={styles.footer}>
          <View style={styles.totalRow}>
            <Text style={styles.totalLabel}>Итого</Text>
            <Text style={styles.totalValue}>{total}₽</Text>
          </View>
          <Button title="Оформить заказ" style={styles.checkoutBtn} />
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.bgCream },
  listContent: { padding: 16, paddingBottom: 130, gap: 12 },

  itemWrap: {
    position: "relative",
  },
  removeBtn: {
    position: "absolute",
    right: -6,
    top: -6,
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: "#E05252",
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 2,
    borderColor: "#fff",
    shadowColor: COLORS.shadow,
    shadowOpacity: 0.12,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },

  empty: { flex: 1, alignItems: "center", justifyContent: "center", gap: 8 },
  emptyTitle: { color: COLORS.text, fontWeight: "700", fontSize: 18 },
  emptySub: { color: COLORS.textLight },

  footer: {
    position: "absolute",
    left: 0,
    right: 0,
    bottom: 0,
    padding: 16,
    backgroundColor: COLORS.bgCream,
    borderTopWidth: 1,
    borderTopColor: "#E9E5DA",
    gap: 10,
  },
  totalRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "baseline",
  },
  totalLabel: { color: COLORS.textLight, fontSize: 16 },
  totalValue: { color: COLORS.text, fontSize: 22, fontWeight: "800" },
  checkoutBtn: { borderRadius: 14, paddingVertical: 14 },
});
