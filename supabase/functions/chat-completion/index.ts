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

function isStreaming(body: ChatBody) {
  return body.stream === true || body.stream === "true";
}

function geminiRequest(body: ChatBody, apiKey: string) {
  const model = String(body.model ?? "gemini-3.8-flash").replace(/^gemini\//, "");
  const contents = (body.messages ?? [])
    .filter((message) => message.role !== "system")
    .map((message) => ({
      role: message.role === "assistant" ? "model" : "user",
      parts: [{ text: String(message.content ?? "") }],
    }));
  const system = (body.messages ?? []).find((message) => message.role === "system")?.content;
  const endpoint = isStreaming(body) ? "streamGenerateContent?alt=sse" : "generateContent";

  return fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:${endpoint}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey,
      },
      body: JSON.stringify({
        contents,
        ...(system ? { systemInstruction: { parts: [{ text: String(system) }] } } : {}),
        generationConfig: body.parameters ?? {},
      }),
    },
  );
}

function toOpenAiChunk(raw: Record<string, unknown>) {
  const candidates = raw.candidates as Array<Record<string, unknown>> | undefined;
  const content = (candidates?.[0]?.content as Record<string, unknown> | undefined)?.parts as
    | Array<Record<string, unknown>>
    | undefined;
  return {
    choices: [{ index: 0, delta: { content: content?.[0]?.text ?? "" } }],
  };
}

async function streamResponse(upstream: Response) {
  const reader = upstream.body?.getReader();
  if (!reader) return json({ error: "Streaming response body is empty" }, 502);

  const encoder = new TextEncoder();
  const decoder = new TextDecoder();
  const stream = new ReadableStream<Uint8Array>({
    async start(controller) {
      const send = (value: unknown) =>
        controller.enqueue(encoder.encode(`data: ${JSON.stringify(value)}\n\n`));
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
            try {
              send({ type: "chunk", chunk: toOpenAiChunk(JSON.parse(text)) });
            } catch {
              // Ignore incomplete keepalive frames.
            }
          }
        }
        send({ type: "done", timestamp: new Date().toISOString() });
      } finally {
        controller.close();
      }
    },
  });

  return new Response(stream, {
    headers: {
      ...corsHeaders,
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
    },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed: Use POST" }, 405);

  let body: ChatBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid request: JSON parsing failed" }, 400);
  }
  if (!Array.isArray(body.messages) || body.messages.length === 0) {
    return json({ error: "Invalid request: Messages array is required" }, 400);
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY")?.trim();
  if (!apiKey) {
    return json({
      error: "GEMINI API key is not configured",
      details: "Add GEMINI_API_KEY to Supabase Edge Function secrets.",
    }, 503);
  }

  try {
    let upstream = await geminiRequest(body, apiKey);
    for (let attempt = 1; attempt <= 2 && upstream.status === 503; attempt++) {
      await new Promise((resolve) => setTimeout(resolve, attempt * 800));
      upstream = await geminiRequest(body, apiKey);
    }
    if (!upstream.ok) {
      const details = await upstream.text();
      return json({ error: `GEMINI API error: ${upstream.status}`, details }, upstream.status);
    }
    if (isStreaming(body)) return await streamResponse(upstream);
    return new Response(await upstream.text(), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return json({ error: "Edge Function error", details: String(error) }, 502);
  }
});
