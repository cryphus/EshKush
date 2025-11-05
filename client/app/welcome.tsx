import { COLORS } from "@/constants/colors";
import { router } from "expo-router";
import { Image, Pressable, StyleSheet, Text, View } from "react-native";

function SocialBtn({ icon, onPress }: { icon: any; onPress?: () => void }) {
  return (
    <Pressable onPress={onPress} style={styles.socialBtn}>
      <Image source={icon} style={styles.socialIcon} />
    </Pressable>
  );
}

export default function WelcomeScreen() {
  return (
    <View style={styles.container}>
      <View style={styles.titleContainer}>
        <Text style={styles.titleText}>Еда с разумным{"\n"}выбором</Text>
      </View>

      <View style={styles.heroContainer}>
        <Image
          source={require("@/assets/images/food-bag.png")}
          style={styles.heroImage}
        />
      </View>

      <View style={styles.socialsRow}>
        <SocialBtn
          icon={require("@/assets/icons/google.svg")}
          onPress={() => {}}
        />
        <SocialBtn icon={require("@/assets/icons/vk.svg")} onPress={() => {}} />
        <SocialBtn
          icon={require("@/assets/icons/phone.svg")}
          onPress={() => router.push("/auth/phone")}
        />
      </View>

      <Pressable
        style={styles.guestButton}
        onPress={() => router.replace("/(tabs)")}
      >
        <Text style={styles.guestButtonText}>Войти как гость</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.bgCream,
    paddingHorizontal: 24,
    paddingTop: 40,
    paddingBottom: 24,
    justifyContent: "center",
  },
  titleContainer: {
    alignItems: "center",
    marginBottom: 24,
  },
  titleText: {
    fontSize: 32,
    lineHeight: 34,
    fontWeight: "600",
    textAlign: "center",
    color: COLORS.text,
  },
  heroContainer: {
    alignItems: "center",
    marginBottom: 36,
  },
  heroImage: {
    width: 350,
    height: 350,
    resizeMode: "contain",
  },
  socialsRow: {
    flexDirection: "row",
    justifyContent: "center",
    alignItems: "center",
    gap: 24,
    marginBottom: 40,
  },
  socialBtn: {
    width: 64,
    height: 64,
    borderRadius: 16,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 1,
    borderColor: COLORS.strokeLight,
    shadowColor: COLORS.shadow,
    shadowOpacity: 0.06,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 3,
  },
  socialIcon: {
    width: 40,

    resizeMode: "contain",
  },
  guestButton: {
    alignSelf: "center",
    backgroundColor: COLORS.greenAccent,
    paddingVertical: 8,
    paddingHorizontal: 32,
    borderRadius: 28,
    minWidth: 220,
    alignItems: "center",
  },
  guestButtonText: {
    color: "#fff",
    fontSize: 24,
    fontWeight: "500",
    textAlign: "center",
  },
});
