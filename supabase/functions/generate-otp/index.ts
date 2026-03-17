import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {

  const { phone } = await req.json();

  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  console.log("OTP:", otp);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  await supabase
    .from("phone_otps")
    .delete()
    .eq("phone", phone);

  await new Promise(resolve => setTimeout(resolve, 100));

  const now = new Date();
  const expiresAt = new Date(now.getTime() + 2 * 60 * 1000); // 2 min

  await supabase.from("phone_otps").insert({
    phone,
    otp,
    created_at: now.toISOString(),
    expires_at: expiresAt.toISOString()
  });

  return new Response(
    JSON.stringify({ otp }),
    { headers: { "Content-Type": "application/json" } }
  );
});