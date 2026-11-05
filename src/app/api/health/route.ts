export const dynamic = "force-dynamic";

export function GET() {
  return Response.json(
    {
      service: "moyukanpan-heatmap",
      version: process.env.HEATMAP_RELEASE ?? "dev",
    },
    { headers: { "Cache-Control": "no-store" } },
  );
}
