import { supabase } from "./supabase";

export type AuthedUser = { id: string; email?: string };

export async function requireUser(authHeader?: string): Promise<AuthedUser> {
  if (!authHeader?.startsWith("Bearer ")) {
    const err: any = new Error("Missing or invalid Authorization header");
    err.status = 401;
    throw err;
  }

  const token = authHeader.slice("Bearer ".length).trim();
  const { data, error } = await supabase.auth.getUser(token);

  if (error || !data.user) {
    const err: any = new Error("Invalid or expired token");
    err.status = 401;
    throw err;
  }

  return { id: data.user.id, email: data.user.email ?? undefined };
}
