import { COLORS } from "@/constants/colors";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import React, { useMemo, useState } from "react";
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";

function formatPhone(raw: string) {
  const d = raw.replace(/\D/g, "").slice(0, 11); // до 11 цифр
  let out = d;

  // приводим к +7...
  if (out.startsWith("8")) out = "7" + out.slice(1);
  if (out.startsWith("7")) out = "+" + out;

  // +7 (XXX) XXX-XX-XX
  if (out.length > 2) out = out.slice(0, 2) + " (" + out.slice(2);
  if (out.length > 7) out = out.slice(0, 7) + ") " + out.slice(7);
  if (out.length > 12) out = out.slice(0, 12) + "-" + out.slice(12);
  if (out.length > 15) out = out.slice(0, 15) + "-" + out.slice(15);

  return out.slice(0, 18);
}

export default function PhoneLogin() {
  const [phoneRaw, setPhoneRaw] = useState("");
  const [agree, setAgree] = useState(false);

  const phone = useMemo(() => formatPhone(phoneRaw), [phoneRaw]);
  const isValid = useMemo(() => {
    const digits = phoneRaw.replace(/\D/g, "");
    // валиден, когда 11 цифр и начинается на 7/8 (в формате перевели в 7)
    return (
      digits.length === 11 &&
      (digits.startsWith("7") || digits.startsWith("8")) &&
      agree
    );
  }, [phoneRaw, agree]);

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.select({ ios: "padding", android: undefined })}
    >
      {/* Header */}
      <View style={styles.header}>
        <Pressable onPress={() => router.back()} style={styles.backBtn}>
          <Ionicons name="chevron-back" size={20} color={COLORS.text} />
        </Pressable>
        <Text style={styles.headerTitle}>Вход</Text>
        <View style={{ width: 32 }} />
      </View>

      {/* Поле телефона */}
      <Text style={styles.label}>Номер телефона:</Text>
      <TextInput
        value={phone}
        onChangeText={(t) => setPhoneRaw(t)}
        keyboardType="phone-pad"
        placeholder="+7 (___) ___-__-__"
        placeholderTextColor={COLORS.textLight}
        style={styles.input}
        maxLength={18}
      />

      {/* Согласие */}
      <Pressable style={styles.agreeRow} onPress={() => setAgree((v) => !v)}>
        <View style={[styles.checkbox, agree && styles.checkboxChecked]}>
          {agree ? <Ionicons name="checkmark" size={16} color="#fff" /> : null}
        </View>
        <Text style={styles.agreeText}>
          Даю согласие на обработку{"\n"}персональных данных
        </Text>
      </Pressable>

      {/* Кнопка */}
      <Pressable
        disabled={!isValid}
        style={[styles.submitBtn, !isValid && styles.submitBtnDisabled]}
        onPress={() => {
          // здесь вызовете API / отправку SMS
        }}
      >
        <Text style={styles.submitText}>Продолжить</Text>
      </Pressable>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.bgCream, padding: 16 },
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 16,
  },
  backBtn: {
    width: 32,
    height: 32,
    alignItems: "center",
    justifyContent: "center",
    borderRadius: 16,
  },
  headerTitle: { fontSize: 22, fontWeight: "800", color: COLORS.text },

  label: {
    fontSize: 16,
    fontWeight: "700",
    color: COLORS.text,
    marginBottom: 8,
  },
  input: {
    height: 44,
    borderRadius: 8,
    borderWidth: 1.5,
    borderColor: COLORS.textLight,
    paddingHorizontal: 12,
    backgroundColor: "#fff",
    color: COLORS.text,
  },

  agreeRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    marginTop: 14,
  },
  checkbox: {
    width: 28,
    height: 28,
    borderRadius: 6,
    borderWidth: 1.5,
    borderColor: COLORS.textLight,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#fff",
  },
  checkboxChecked: {
    backgroundColor: COLORS.greenAccent,
    borderColor: COLORS.greenAccent,
  },
  agreeText: { color: COLORS.text, lineHeight: 18, flexShrink: 1 },

  submitBtn: {
    marginTop: 16,
    height: 44,
    borderRadius: 10,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: COLORS.greenAccent,
  },
  submitBtnDisabled: { backgroundColor: "#E6E6E6" },
  submitText: { color: "#fff", fontWeight: "700" },
});
