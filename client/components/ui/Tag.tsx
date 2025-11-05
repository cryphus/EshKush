import { StyleSheet, Text, View, ViewStyle } from "react-native";

import { COLORS } from "@/constants/colors";

export function Tag({
  children,
  style,
  tone = "light",
}: {
  children: React.ReactNode;
  style?: ViewStyle;
  tone?: "light" | "green";
}) {
  const isGreen = tone === "green";
  return (
    <View style={[styles.base, isGreen ? styles.green : styles.light, style]}>
      <Text
        style={[styles.text, isGreen ? styles.textGreen : styles.textLight]}
      >
        {children}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  base: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 10,
  },
  light: { backgroundColor: COLORS.bgCream },
  green: { backgroundColor: COLORS.greenAccent },
  text: { fontWeight: "700", fontSize: 12 },
  textLight: { color: COLORS.textLight },
  textGreen: { color: "#fff" },
});
