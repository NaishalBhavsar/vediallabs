import { supabase } from "../lib/supabase";

export type ResourceRow = {
  id: string;
  title: string;
  type: "ppt" | "video";
  topic: string;
  bucket: string;
  object_path: string;
};

export async function findResourcesForTopic(userId: string, topic: string): Promise<ResourceRow[]> {
  const { data, error } = await supabase
    .from("resources")
    .select("id,title,type,topic,bucket,object_path")
    .eq("user_id", userId)
    .ilike("topic", `%${topic}%`)
    .limit(10);

  if (error) throw error;
  return (data ?? []) as ResourceRow[];
}

export async function createSignedUrl(bucket: string, path: string, expiresInSec = 60 * 10) {
  const { data, error } = await supabase.storage.from(bucket).createSignedUrl(path, expiresInSec);
  if (error) throw error;
  return data.signedUrl;
}
