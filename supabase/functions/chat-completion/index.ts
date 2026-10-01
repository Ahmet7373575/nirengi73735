import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type ChatBody = {
  messages?: Array<Record<string, unknown>>;
  model?: string;
  provider?: string;
  stream?: boolean | string;
  parameters?: Record<string, unknown>;
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function keyFor(provider?: string) {
  switch (provider) {
    case "OPEN_AI": return Deno.env.get("OPENAI_API_KEY");
    case "GEMINI": return Deno.env.get("GEMINI_API_KEY");
    case "ANTHROPIC": return Deno.env.get("ANTHROPIC_API_KEY");
    case "PERPLEXITY": return Deno.env.get("PERPLEXITY_API_KEY");
    default: return undefined;
  }
}

function errorPayload(status: number, data: unknown, provider?: string) {
  const detail = typeof data === "string" ? data : JSON.stringify(data);
  return {
    error: `${(provider ?? "LLM Provider").toUpperCase()} API error: ${status}`,
    details: detail,
  };
}

function openAiRequest(body: ChatBody, apiKey: string, baseUrl: string) {
  const parameters = body.parameters ?? {};
  return fetch(`${baseUrl}/chat/completions`, {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({ model: body.model, messages: body.messages, stream: body.stream === true || body.stream === "true", ...parameters }),
  });
}

async function providerRequest(body: ChatBody, apiKey: string) {
  switch (body.provider) {
    case "OPEN_AI":
      return openAiRequest(body, apiKey, "https://api.openai.com/v1");
    case "PERPLEXITY":
      return openAiRequest(body, apiKey, "https://api.perplexity.ai");
    case "ANTHROPIC": {
      const system = (body.messages ?? []).find((m) => m.role === "system")?.content;
      const messages = (body.messages ?? []).filter((m) => m.role !== "system");
      return fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: { "x-api-key": apiKey, "anthropic-version": "2023-06-01", "Content-Type": "application/json" },
        body: JSON.stringify({ model: body.model, messages, ...(system ? { system } : {}), max_tokens: (body.parameters?.max_tokens as number) ?? 2000, stream: body.stream === true || body.stream === "true" }),
      });
    }
    case "GEMINI": {
      const model = String(body.model ?? "gemini-1.5-flash").replace(/^gemini\//, "");
      const contents = (body.messages ?? []).filter((m) => m.role !== "system").map((m) => ({ role: m.role === "assistant" ? "model" : "user", parts: [{ text: String(m.content ?? "") }] }));
      const system = (body.messages ?? []).find((m) => m.role === "system")?.content;
      const endpoint = body.stream === true || body.stream === "true" ? "streamGenerateContent?alt=sse" : "generateContent";
      return fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:${endpoint}&key=${encodeURIComponent(apiKey)}`, {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ contents, ...(system ? { systemInstruction: { parts: [{ text: String(system) }] } } : {}), generationConfig: body.parameters ?? {} }),
      });
    }
    default:
      throw new Error(`Unsupported provider: ${body.provider}`);
  }
}

async function toOpenAiChunk(provider: string | undefined, raw: Record<string, unknown>) {
  if (provider === "ANTHROPIC") {
    const delta = raw.delta as Record<string, unknown> | undefined;
    return { choices: [{ index: 0, delta: { content: delta?.text ?? "" } }] };
  }
  if (provider === "GEMINI") {
    const candidates = raw.candidates as Array<Record<string, unknown>> | undefined;
    const content = (candidates?.[0]?.content as Record<string, unknown> | undefined)?.parts as Array<Record<string, unknown>> | undefined;
    return { choices: [{ index: 0, delta: { content: content?.[0]?.text ?? "" } }] };
  }
  return raw;
}

async function streamResponse(upstream: Response, provider?: string) {
  const reader = upstream.body?.getReader();
  if (!reader) return json({ error: "Streaming response body is empty" }, 502);
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();
  const stream = new ReadableStream<Uint8Array>({
    async start(controller) {
      const send = (value: unknown) => controller.enqueue(encoder.encode(`data: ${JSON.stringify(value)}\n\n`));
      let buffer = "";
      send({ type: "start", timestamp: new Date().toISOString() });
      try {
        while (true) {
          const { value, done } = await reader.read();
          if (done) break;
          buffer += decoder.decode(value, { stream: true });
          const lines = buffer.split("\n");
          buffer = lines.pop() ?? "";
          for (const line of lines) {
            if (!line.startsWith("data:")) continue;
            const text = line.slice(5).trim();
            if (!text || text === "[DONE]") continue;
            try { send({ type: "chunk", chunk: await toOpenAiChunk(provider, JSON.parse(text)) }); } catch { /* ignore keepalive */ }
          }
        }
        send({ type: "done", timestamp: new Date().toISOString() });
      } finally { controller.close(); }
    },
  });
  return new Response(stream, { headers: { ...corsHeaders, "Content-Type": "text/event-stream", "Cache-Control": "no-cache" } });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed: Use POST" }, 405);
  let body: ChatBody;
  try { body = await req.json(); } catch { return json({ error: "Invalid request: JSON parsing failed" }, 400); }
  if (!Array.isArray(body.messages) || body.messages.length === 0) return json({ error: "Invalid request: Messages array is required" }, 400);
  const apiKey = keyFor(body.provider);
  if (!apiKey) return json({ error: `${body.provider ?? "LLM Provider"} API key is not configured`, details: "Add the provider API key to Supabase Edge Function secrets." }, 503);
  try {
    const upstream = await providerRequest(body, apiKey);
    if (!upstream.ok) return json(errorPayload(upstream.status, await upstream.text(), body.provider), upstream.status);
    if (body.stream === true || body.stream === "true") return await streamResponse(upstream, body.provider);
    return new Response(await upstream.text(), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (error) {
    return json({ error: "Edge Function error", details: String(error) }, 502);
  }
});
