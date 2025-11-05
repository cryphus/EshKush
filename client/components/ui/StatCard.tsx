import { COLORS } from "@/constants/colors";
import {
  Image,
  ImageSourcePropType,
  StyleSheet,
  Text,
  View,
} from "react-native";

export function StatCard({
  icon,
  value,
}: {
  icon: ImageSourcePropType;
  value: string;
}) {
  return (
    <View style={styles.card}>
      <Image source={icon} style={styles.icon} resizeMode="contain" />
      <Text style={styles.value}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flex: 1,
    backgroundColor: COLORS.greenBg,
    borderRadius: 16,
    paddingVertical: 18,
    alignItems: "center",
    justifyContent: "center",
    shadowColor: COLORS.shadow,
    shadowOpacity: 0.05,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 3 },
    elevation: 2,
  },
  icon: {
    width: 40,
  },
  value: {
    marginTop: 8,
    fontWeight: "700",
    color: COLORS.greenAccent,
  },
});
