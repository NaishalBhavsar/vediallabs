import { z } from "zod";

export const AskJijiSchema = z.object({
  query: z.string().min(2).max(500)
});

export type AskJijiBody = z.infer<typeof AskJijiSchema>;

export function normalizeQuery(q: string) {
  return q.trim().toLowerCase().replace(/\s+/g, " ");
}
