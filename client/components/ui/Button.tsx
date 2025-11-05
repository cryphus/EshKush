import { COLORS } from "@/constants/colors";
import { Pressable, StyleSheet, Text, ViewStyle } from "react-native";

type Props = { title: string; onPress?: () => void; style?: ViewStyle };

export function Button({ title, onPress, style }: Props) {
  return (
    <Pressable onPress={onPress} style={[styles.button, style]}>
      <Text style={styles.title}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    backgroundColor: COLORS.greenAccent,
    padding: 12,
    borderRadius: 12,
  },
  title: {
    color: "#fff",
    textAlign: "center",
    fontWeight: "600",
  },
});
