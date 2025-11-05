import { OfferCard } from "@/components/ui/OfferCard";
import { PageHeader } from "@/components/ui/PageHeader";
import { Tag } from "@/components/ui/Tag";
import { COLORS } from "@/constants/colors";
import { FAVORITES } from "@/constants/favorites";
import { router } from "expo-router";
import { FlatList, StyleSheet, View } from "react-native";

export default function FavoritesScreen() {
  return (
    <View style={styles.container}>
      <PageHeader
        title="Избранное"
        location="Тюмень"
        cartCount={1}
        onPressCart={() => router.push("/cart")}
      />

      <FlatList
        data={FAVORITES}
        keyExtractor={(x) => x.id}
        contentContainerStyle={styles.listContent}
        renderItem={({ item }) => (
          <OfferCard
            item={item}
            dimmed
            rightBadge={<Tag tone="green">XP</Tag>}
          />
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.bgCream,
  },
  listContent: {
    padding: 16,
    gap: 14,
    paddingBottom: 110,
  },
});
