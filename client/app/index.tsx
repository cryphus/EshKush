import { useAuth } from "@/hooks/useAuth";
import { Redirect } from "expo-router";

export default function Index() {
  const { user } = useAuth();
  return <Redirect href={user ? "/(tabs)" : "/welcome"} />;
}
