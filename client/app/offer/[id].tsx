import { COLORS } from "@/constants/colors";
import { OFFERS } from "@/constants/offers";
import { Ionicons } from "@expo/vector-icons";
import { router, useLocalSearchParams } from "expo-router";
import React from "react";
import {
  Image,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";

const HERO_HEIGHT = 230;
const PANEL_RADIUS = 26;
const LOGO_W = 120;
const LOGO_H = 60;

function Section({
  icon,
  children,
}: {
  icon: keyof typeof Ionicons.glyphMap;
  children: React.ReactNode;
}) {
  return (
    <View style={styles.sectionRow}>
      <View style={styles.iconCol}>
        <View style={styles.iconCircle}>
          <Ionicons name={icon} size={18} color={COLORS.greenAccent} />
        </View>
      </View>

      <View style={styles.textCol}>
        <View style={styles.centerBox}>
          <View style={styles.innerDivider} />
          <View style={{ alignItems: "center", paddingVertical: 6 }}>
            {children}
          </View>
        </View>
      </View>
    </View>
  );
}

export default function OfferDetails() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const offer = OFFERS.find((o) => o.id === id);

  if (!offer) {
    return (
      <View style={styles.notFound}>
        <Text>Предложение не найдено</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.heroWrap}>
        <Image source={{ uri: offer.image }} style={styles.heroImage} />
        <Pressable onPress={router.back} style={styles.backBtn}>
          <Ionicons name="chevron-back" size={20} color={COLORS.text} />
        </Pressable>
      </View>

      <View style={styles.logoOverlay}>
        <View style={styles.logoBadge}>
          {!!offer.logo && (
            <Image
              source={{ uri: offer.logo }}
              style={styles.logoImage}
              resizeMode="contain"
            />
          )}
        </View>
      </View>

      <ScrollView
        style={styles.panel}
        contentContainerStyle={styles.panelContent}
      >
        <View style={styles.body}>
          <Text style={styles.title} numberOfLines={2}>
            {offer.title}
          </Text>
          <View style={styles.ratingRow}>
            <Ionicons name="star" size={16} color="#F4C542" />
            <Text style={styles.ratingText}>{offer.rating}</Text>
          </View>

          <Section icon="location-outline">
            <Text style={styles.sectionTitle}>ул. 50 лет Октября</Text>
            <Text style={styles.sectionSub}>57Б к1, 1 этаж</Text>
          </Section>

          <Section icon="time-outline">
            <Text style={styles.sectionTitle}>Сегодня</Text>
            <Text style={styles.sectionSub}>{offer.time}</Text>
          </Section>

          <Section icon="lock-closed-outline">
            <Text style={styles.sectionTitle}>
              Что вы найдете внутри бокса:
            </Text>
            <Text style={styles.description}>
              В боксе вас ожидает набор из 3 как сладких, так и мясных булочек,
              а также вкусный десерт весом примерно 400 грамм
            </Text>
          </Section>
        </View>
      </ScrollView>

      <View style={styles.buyWrap}>
        <Pressable style={styles.buyBtn} onPress={() => {}}>
          <Text style={styles.buyText}>купить {offer.price}₽</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.bgCream },
  notFound: { flex: 1, alignItems: "center", justifyContent: "center" },

  heroWrap: { height: HERO_HEIGHT, position: "relative" },
  heroImage: { width: "100%", height: "100%" },
  backBtn: {
    position: "absolute",
    left: 12,
    top: 12,
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: "#fff",
    borderWidth: 1,
    borderColor: COLORS.greenAccent,
    alignItems: "center",
    justifyContent: "center",
  },

  logoOverlay: {
    position: "absolute",
    top: HERO_HEIGHT - LOGO_H / 1.2,
    left: 0,
    right: 0,
    zIndex: 5,
    alignItems: "center",
  },
  logoBadge: {
    width: LOGO_W,
    height: LOGO_H,
    borderRadius: 10,
    borderWidth: 3,
    borderColor: COLORS.greenAccent,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
    overflow: "hidden",
    shadowColor: COLORS.shadow,
    shadowOpacity: 0.1,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 3 },
    elevation: 2,
  },
  logoImage: { width: "100%", height: "100%" },

  panel: {
    marginTop: -20,
    backgroundColor: "#fff",
    borderTopLeftRadius: PANEL_RADIUS,
    borderTopRightRadius: PANEL_RADIUS,
    shadowColor: COLORS.shadow,
    shadowOpacity: 0.08,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: -2 },
    elevation: 4,
  },
  panelContent: { paddingBottom: 120 },

  body: {
    paddingHorizontal: 16,
    paddingTop: LOGO_H / 2 + 12,
  },

  title: {
    fontSize: 22,
    fontWeight: "800",
    textAlign: "center",
    color: COLORS.text,
  },
  ratingRow: {
    flexDirection: "row",
    justifyContent: "center",
    alignItems: "center",
    gap: 6,
    marginTop: 6,
  },
  ratingText: { fontWeight: "700", color: COLORS.text },

  sectionRow: {
    flexDirection: "row",
    paddingHorizontal: 16,
    marginTop: 14,
  },
  iconCol: {
    width: 44,
    alignItems: "flex-start",
  },
  iconCircle: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: COLORS.greenBg,
    alignItems: "center",
    justifyContent: "center",
    marginTop: 2,
  },
  textCol: { flex: 1 },
  centerBox: {
    width: "75%",
    alignSelf: "center",
  },
  innerDivider: {
    height: 2,
    backgroundColor: COLORS.greenAccent,
    borderRadius: 999,
  },

  sectionTitle: {
    marginTop: 6,
    fontWeight: "700",
    textAlign: "center",
    color: COLORS.text,
  },
  sectionSub: {
    marginTop: 2,
    textAlign: "center",
    color: COLORS.textLight,
  },
  description: {
    marginTop: 6,
    lineHeight: 20,
    color: COLORS.text,
    textAlign: "center",
  },

  buyWrap: { position: "absolute", left: 16, right: 16, bottom: 24 },
  buyBtn: {
    backgroundColor: COLORS.green,
    paddingVertical: 14,
    borderRadius: 18,
    alignItems: "center",
    shadowColor: COLORS.shadow,
    shadowOpacity: 0.15,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 3,
  },
  buyText: { color: "#fff", fontWeight: "800", textTransform: "uppercase" },
});
