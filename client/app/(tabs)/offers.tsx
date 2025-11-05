import { OfferCard } from "@/components/ui/OfferCard";
import { PageHeader } from "@/components/ui/PageHeader";
import { COLORS } from "@/constants/colors";
import { OFFERS } from "@/constants/offers";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import React, { useMemo, useRef, useState } from "react";
import {
  FlatList,
  Keyboard,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";

function FilterButton({
  icon,
  label,
  active,
  onPress,
}: {
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  active?: boolean;
  onPress?: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={[styles.filterButton, active && styles.filterButtonActive]}
    >
      <Ionicons name={icon} size={20} style={styles.filterIcon} />
      <Text style={styles.filterButtonText}>{label}</Text>
    </Pressable>
  );
}

export default function OffersScreen() {
  const [searchOpen, setSearchOpen] = useState(false);
  const [query, setQuery] = useState("");
  const inputRef = useRef<TextInput>(null);

  const data = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return OFFERS;
    return OFFERS.filter((o) => o.title.toLowerCase().includes(q));
  }, [query]);

  const toggleSearch = () => {
    setSearchOpen((prev) => {
      if (prev) {
        inputRef.current?.blur();
        Keyboard.dismiss();
        setQuery("");
      }
      return !prev;
    });
  };

  return (
    <View style={styles.container}>
      <PageHeader
        title="Предложения"
        location="Тюмень"
        cartCount={1}
        onPressCart={() => router.push("/cart")}
      />

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={styles.filtersBar}
        contentContainerStyle={styles.filtersContent}
      >
        <FilterButton icon="star-outline" label="Для вас" />
        <FilterButton icon="map-outline" label="Карта" />
        <FilterButton
          icon="search-outline"
          label="Поиск"
          active={searchOpen}
          onPress={toggleSearch}
        />
      </ScrollView>

      {searchOpen && (
        <View style={styles.searchWrap}>
          <Ionicons name="search" size={18} color={COLORS.greenAccent} />
          <TextInput
            ref={inputRef}
            autoFocus={false}
            style={styles.searchInput}
            placeholder="Поиск предложений..."
            placeholderTextColor={COLORS.textLight}
            value={query}
            onChangeText={setQuery}
            returnKeyType="search"
          />
          {query ? (
            <Pressable onPress={() => setQuery("")} style={styles.clearBtn}>
              <Ionicons name="close" size={18} color={COLORS.textLight} />
            </Pressable>
          ) : null}
        </View>
      )}

      <FlatList
        data={data}
        keyExtractor={(x) => x.id}
        contentContainerStyle={styles.listContent}
        keyboardShouldPersistTaps="handled"
        renderItem={({ item }) => (
          <OfferCard
            item={item}
            onPress={() => router.push(`/offer/${item.id}`)}
          />
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.bgCream },

  filtersBar: { paddingHorizontal: 16, marginTop: 12, maxHeight: 60 },
  filtersContent: {
    width: "100%",
    justifyContent: "space-between",
    paddingBottom: 18,
  },

  filterButton: {
    height: 55,
    minWidth: 85,
    paddingHorizontal: 16,
    borderRadius: 5,
    borderWidth: 2,
    borderColor: COLORS.greenAccent,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
  },
  filterButtonActive: { backgroundColor: COLORS.greenBg },
  filterIcon: { color: COLORS.greenAccent, marginBottom: 4 },
  filterButtonText: { fontWeight: "700", color: COLORS.greenAccent },

  searchWrap: {
    marginHorizontal: 16,
    marginTop: 6,
    height: 44,
    borderRadius: 24,
    borderWidth: 2,
    borderColor: COLORS.greenAccent,
    backgroundColor: "#fff",
    paddingHorizontal: 12,
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
  },
  searchInput: {
    flex: 1,
    color: COLORS.text,
    paddingVertical: 0,
    outlineWidth: 0,
    outlineColor: "transparent",
    borderWidth: 0,
  },

  clearBtn: {
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: "center",
    justifyContent: "center",
  },

  listContent: { padding: 16, gap: 14, paddingBottom: 110, flexGrow: 0 },
});
